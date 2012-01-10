//
//  Broker.m
//  Broker
//
//  Created by Andrew Smith on 10/5/11.
//  Copyright (c) 2011 Andrew B. Smith ( http://github.com/drewsmits ). All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy 
// of this software and associated documentation files (the "Software"), to deal 
// in the Software without restriction, including without limitation the rights 
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies 
// of the Software, and to permit persons to whom the Software is furnished to do so, 
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included 
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "Broker.h"

#import "BKJSONOperation.h"

@interface Broker ()
@property (nonatomic, strong, readwrite) NSManagedObjectContext *mainContext;
@end

@implementation Broker

@synthesize mainContext;

+ (id)sharedInstance {
    static dispatch_once_t pred = 0;
    __strong static id _sharedInstance = nil;
    dispatch_once(&pred, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}

- (void)dealloc {
    mainContext = nil;
    entityDescriptions = nil;
        
}

#pragma mark - Setup

+ (id)brokerWithContext:(NSManagedObjectContext *)context {    
    Broker *broker = [[self alloc] init];
    broker.mainContext = context;
    return broker;
}

- (void)setupWithContext:(NSManagedObjectContext *)context {
    NSAssert(context, @"Context must not be nil!");
    if (!context) return;
    self.mainContext = context;
}

- (void)reset {
    mainContext = nil;
    entityDescriptions = nil;
}

#pragma mark - Registration

- (void)registerEntityNamed:(NSString *)entityName 
             withPrimaryKey:(NSString *)primaryKey {
    [self registerEntityNamed:entityName
               withPrimaryKey:primaryKey
      andMapNetworkProperties:nil 
            toLocalProperties:nil];
}

- (void)registerEntityNamed:(NSString *)entityName
             withPrimaryKey:(NSString *)primaryKey
      andMapNetworkProperty:(NSString *)networkProperty 
            toLocalProperty:(NSString *)localProperty {
    
    [self registerEntityNamed:entityName
               withPrimaryKey:primaryKey
      andMapNetworkProperties:[NSArray arrayWithObject:networkProperty] 
            toLocalProperties:[NSArray arrayWithObject:localProperty]];
    
}

- (void)registerEntityNamed:(NSString *)entityName
             withPrimaryKey:(NSString *)primaryKey
    andMapNetworkProperties:(NSArray *)networkProperties 
          toLocalProperties:(NSArray *)localProperties {
    
    NSAssert(self.mainContext, @"Broker must be setup with setupWithContext!");
    
//    if ([self entityPropertyDescriptionForEntityName:entityName]) {
//        WLog(@"Entity named \"%@\" already registered with Broker", entityName);
//        return;
//    }
    
    // create new object
    NSManagedObject *object = [NSEntityDescription insertNewObjectForEntityForName:entityName 
                                                            inManagedObjectContext:self.mainContext];
    
    // Build description of entity properties
    BKEntityPropertiesDescription *desc = [BKEntityPropertiesDescription descriptionForEntity:object.entity 
                                                                         withPropertiesByName:object.entity.propertiesByName
                                                                      andMapNetworkProperties:networkProperties
                                                                            toLocalProperties:localProperties];
    
    // Set primary key
    desc.primaryKey = primaryKey;
    
    // Add to descriptions
    [self.entityDescriptions setObject:desc forKey:entityName];
    
    // cleanup
    [self.mainContext deleteObject:object];
}

- (void)setDateFormat:(NSString *)dateFormat 
          forProperty:(NSString *)property 
             onEntity:(NSString *)entity {
    
    BKAttributeDescription *desc = [self attributeDescriptionForProperty:property onEntityName:entity];;
    desc.dateFormat = dateFormat;
}

- (void)setRootKeyPath:(NSString *)rootKeyPath 
             forEntity:(NSString *)entity {

    BKEntityPropertiesDescription *desc = [self entityPropertyDescriptionForEntityName:entity];
    desc.rootKeyPath = rootKeyPath;
}

- (void)mapNetworkProperty:(NSString *)networkProperty
           toLocalProperty:(NSString *)localProperty
                 forEntity:(NSString *)entity {
    
    [self mapNetworkProperties:[NSArray arrayWithObject:networkProperty]
             toLocalProperties:[NSArray arrayWithObject:localProperty]
                     forEntity:entity];

}

- (void)mapNetworkProperties:(NSArray *)networkProperties
           toLocalProperties:(NSArray *)localProperties
                   forEntity:(NSString *)entity {

    BKEntityPropertiesDescription *desc = [self entityPropertyDescriptionForEntityName:entity];
    
    NSAssert(desc, @"You must first register entity named \"%@\" before mapping properties.");
    if (!desc) return;
    
    [desc mapNetworkProperties:networkProperties toLocalProperties:localProperties];
}

#pragma mark - Object

- (void)processJSONPayload:(id)jsonPayload 
            targetEntity:(NSURL *)entityURI
     withCompletionBlock:(void (^)())CompletionBlock {
    
    [self processJSONPayload:jsonPayload
              targetEntity:entityURI
           forRelationship:nil
        JSONPreFilterBlock:nil
       withCompletionBlock:CompletionBlock];
}

- (void)processJSONPayload:(id)jsonPayload 
              targetEntity:(NSURL *)entityURI 
        JSONPreFilterBlock:(id (^)())FilterBlock
       withCompletionBlock:(void (^)())CompletionBlock {
    
    [self processJSONPayload:jsonPayload
                targetEntity:entityURI
             forRelationship:nil
          JSONPreFilterBlock:FilterBlock
         withCompletionBlock:CompletionBlock];
}

#pragma mark - Relationship Object Collection

- (void)processJSONPayload:(id)jsonPayload 
              targetEntity:(NSURL *)entityURI
           forRelationship:(NSString *)relationshipName
       withCompletionBlock:(void (^)())CompletionBlock {
    
    [self processJSONPayload:jsonPayload
                targetEntity:entityURI
             forRelationship:relationshipName 
          JSONPreFilterBlock:nil
         withCompletionBlock:CompletionBlock];
}

- (void)processJSONPayload:(id)jsonPayload
              targetEntity:(NSURL *)entityURI
           forRelationship:(NSString *)relationshipName
        JSONPreFilterBlock:(id (^)())FilterBlock
       withCompletionBlock:(void (^)())CompletionBlock {
    
    NSAssert(self.mainContext, @"Broker must be setup with setupWithContext!");
    if (!self.mainContext) return;
    
    BKJSONOperation *operation = [BKJSONOperation operation];
    
    operation.jsonPayload = jsonPayload;
    operation.entityURI = entityURI;
    operation.relationshipName = relationshipName;
    
    // Thread safe managed object context.  Will call contextDidSave when saving,
    // properly merges with main context on main thread
    operation.context = [self newMainStoreManagedObjectContext];
    
    // Blocks
    operation.preFilterBlock = FilterBlock;
    operation.completionBlock = CompletionBlock;
    
    [self addOperation:operation];
}

#pragma mark - Object Collection

- (void)processJSONPayload:(id)jsonPayload 
asCollectionOfEntitiesNamed:(NSString *)entityName 
       withCompletionBlock:(void (^)())CompletionBlock {
    [self processJSONPayload:jsonPayload 
 asCollectionOfEntitiesNamed:entityName
          JSONPreFilterBlock:nil
         withCompletionBlock:CompletionBlock];
}

- (void)processJSONPayload:(id)jsonPayload 
asCollectionOfEntitiesNamed:(NSString *)entityName
        JSONPreFilterBlock:(id (^)())FilterBlock
       withCompletionBlock:(void (^)())CompletionBlock {
    
    NSAssert(self.mainContext, @"Broker must be setup with setupWithContext!");
    if (!self.mainContext) return;
    
    BKJSONOperation *operation = [BKJSONOperation operation];
    
    operation.jsonPayload = jsonPayload;
    
    // This is the type of object the collection objects will be turned into
    BKEntityPropertiesDescription *description = [self entityPropertyDescriptionForEntityName:entityName];
    operation.entityDescription = description;
    
    // Thread safe managed object context.  Will call contextDidSave when saving,
    // properly merges with main context on main thread
    operation.context = [self newMainStoreManagedObjectContext];
    
    // Blocks
    operation.preFilterBlock = FilterBlock;
    operation.completionBlock = CompletionBlock;
    
    [self addOperation:operation];

}

#pragma mark - CoreData

- (void)contextDidSave:(NSNotification *)notification {
    SEL selector = @selector(mergeChangesFromContextDidSaveNotification:);

    NSManagedObjectContext *threadContext = (NSManagedObjectContext *)notification.object;
    
    [self.mainContext performSelectorOnMainThread:selector withObject:notification waitUntilDone:NO];

    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:NSManagedObjectContextDidSaveNotification 
                                                  object:threadContext];
}

- (NSManagedObjectContext *)newMainStoreManagedObjectContext {
    
    // Grab the main coordinator
    NSPersistentStoreCoordinator *coord = [self.mainContext persistentStoreCoordinator];

    // Create new context with default concurrency type
    NSManagedObjectContext *newContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
    [newContext setPersistentStoreCoordinator:coord];
    
    // Optimization
    [newContext setUndoManager:nil];
    
    // Observer saves from this context
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(contextDidSave:) 
                                                 name:NSManagedObjectContextDidSaveNotification 
                                               object:newContext];
    
    return newContext;
}

#pragma mark - Accessors

- (BKEntityPropertiesDescription *)entityPropertyDescriptionForEntityName:(NSString *)entityName {
    return (BKEntityPropertiesDescription *)[self.entityDescriptions objectForKey:entityName];
}

- (BKAttributeDescription *)attributeDescriptionForProperty:(NSString *)property 
                                               onEntityName:(NSString *)entityName {
    
    BKEntityPropertiesDescription *desc = [self.entityDescriptions objectForKey:entityName];
    if (desc) {
        return [desc attributeDescriptionForLocalProperty:property];
    }
    return nil;
}


- (BKRelationshipDescription *)relationshipDescriptionForProperty:(NSString *)property 
                                                     onEntityName:(NSString *)entityName {
    
    BKEntityPropertiesDescription *desc = [self.entityDescriptions objectForKey:entityName];
    if (desc) {
        return [desc relationshipDescriptionForProperty:property];
    }
    return nil;
}

- (BKEntityPropertiesDescription *)destinationEntityPropertiesDescriptionForRelationship:(NSString *)relationship
                                                                           onEntityNamed:(NSString *)entityName {
    
    BKRelationshipDescription *desc = [self relationshipDescriptionForProperty:relationship onEntityName:entityName];
    return [self entityPropertyDescriptionForEntityName:desc.destinationEntityName];
}

- (NSMutableDictionary *)entityDescriptions {
    if (entityDescriptions) return entityDescriptions;
    entityDescriptions = [[NSMutableDictionary alloc] init];
    return entityDescriptions;
}

- (NSDictionary *)transformJSONDictionary:(NSDictionary *)jsonDictionary 
         usingEntityPropertiesDescription:(BKEntityPropertiesDescription *)propertiesDescription {
    
    NSMutableDictionary *transformedDict = [[NSMutableDictionary alloc] init];
    
    if (propertiesDescription.rootKeyPath) {
        jsonDictionary = [jsonDictionary valueForKeyPath:propertiesDescription.rootKeyPath];
    }
    
    for (NSString *property in jsonDictionary) {
        
        // Get the property description
        BKPropertyDescription *description = [propertiesDescription descriptionForProperty:property];
        if (!description) {continue;}
        
        // get the original value
        id value = [jsonDictionary valueForKey:property];
        
        // Test to see if networkProperty is relationship or attribute
        if ([propertiesDescription isPropertyRelationship:property]) {
            [transformedDict setObject:value forKey:description.localPropertyName];
        } else {
            
            // transform it using the attribute desc
            id valueAsObject = [(BKAttributeDescription *)description objectForValue:value];
            
            // Add it to the transformed dictionary
            if (valueAsObject) {
                [transformedDict setObject:valueAsObject
                                    forKey:description.localPropertyName];
            }
        }
    }
    
    if ([transformedDict count] == 0) {
        // empty
        return nil;
    }
    
    return [NSDictionary dictionaryWithDictionary:transformedDict];
}

#pragma mark - CoreData

- (NSManagedObject *)objectForURI:(NSURL *)objectURI inContext:(NSManagedObjectContext *)aContext {
    NSManagedObjectID *objectID = [[aContext persistentStoreCoordinator] managedObjectIDForURIRepresentation:objectURI];
    
    if (!objectID) return nil;
    
    NSManagedObject *objectForID = [aContext objectWithID:objectID];
    
    if (![objectForID isFault]) return objectForID;
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[objectID entity]];
    
    // Predicate for fetching self.  Code is faster than string predicate equivalent of 
    // [NSPredicate predicateWithFormat:@"SELF = %@", objectForID];
    NSPredicate *predicate = [NSComparisonPredicate predicateWithLeftExpression:[NSExpression expressionForEvaluatedObject] 
                                                                rightExpression:[NSExpression expressionForConstantValue:objectForID]
                                                                       modifier:NSDirectPredicateModifier
                                                                           type:NSEqualToPredicateOperatorType
                                                                        options:0];
    
    [request setPredicate:predicate];
    
    NSArray *results = [aContext executeFetchRequest:request error:nil];
    if ([results count] > 0 ) {
        return [results objectAtIndex:0];
    }
    
    return nil;
}

- (NSManagedObject *)findOrCreateObjectForEntityDescribedBy:(BKEntityPropertiesDescription *)description 
                                        withPrimaryKeyValue:(id)value
                                                  inContext:(NSManagedObjectContext *)aContext
                                               shouldCreate:(BOOL)create {  
    
    NSAssert(description, @"Must have a description");
    if (!description) return nil;
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    [request setEntity:description.entityDescription];
    
    if (description.primaryKey) {
        [request setPredicate:[NSPredicate predicateWithFormat:@"SELF.%@ == %@", description.primaryKey, value]];
    }
        
    NSError *error;
    NSArray *array = [aContext executeFetchRequest:request error:&error];
    
    if (create && array.count == 0) {
        NSManagedObject *object = [NSEntityDescription insertNewObjectForEntityForName:description.entityName 
                                                                inManagedObjectContext:aContext];
        return object;
    } else if (array.count == 1) {
        return (NSManagedObject *)[array objectAtIndex:0];
    }
    
    return nil;
}


@end
