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

@synthesize mainContext = mainContext_,
            queueName = queueName_;



+ (id)sharedInstance {
    static dispatch_once_t pred = 0;
    __strong static Broker *_sharedInstance = nil;
    dispatch_once(&pred, ^{
        _sharedInstance = [[Broker alloc] init];
    });
    return _sharedInstance;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Setup

- (void)setupWithContext:(NSManagedObjectContext *)context
            andQueueName:(NSString *)queueName
{
    NSAssert(context, @"Context must not be nil!");
    if (!context) return;
    
    // Share the main context
    self.mainContext = context;
    
    // This is the name of the queue that will be used to keep track of the 
    // parse operations
    self.queueName = queueName;
}

- (void)setupWithContext:(NSManagedObjectContext *)context
            andQueueName:(NSString *)queueName
    withMaxConcurrentOperationCount:(NSUInteger)maxOperationCount
{
    [self setupWithContext:context andQueueName:queueName];
    
    // Presist JSON processing queue
    self.removeQueuesWhenEmpty = NO;
        
    // Set max operation count
    [self setMaxConcurrentOperationCount:maxOperationCount 
                           forQueueNamed:self.queueName];
}

- (void)reset {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    mainContext = nil;
    entityDescriptions = nil;
}

#pragma mark - Registration

- (void)registerEntityNamed:(NSString *)entityName {
    [self registerEntityNamed:entityName
               withPrimaryKey:nil
      andMapNetworkProperties:nil 
            toLocalProperties:nil];
}

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
            targetObjectID:(NSManagedObjectID *)objectID
       withCompletionBlock:(void (^)())completionBlock {
    
    [self processJSONPayload:jsonPayload
              targetObjectID:objectID
             forRelationship:nil
          JSONPreFilterBlock:nil
         withCompletionBlock:completionBlock];
}

- (void)processJSONPayload:(id)jsonPayload 
            targetObjectID:(NSManagedObjectID *)objectID 
        JSONPreFilterBlock:(id (^)())FilterBlock
       withCompletionBlock:(void (^)())completionBlock {
    
    [self processJSONPayload:jsonPayload
              targetObjectID:objectID
             forRelationship:nil
          JSONPreFilterBlock:FilterBlock
         withCompletionBlock:completionBlock];
}

#pragma mark - Relationship Object Collection

- (void)processJSONPayload:(id)jsonPayload 
            targetObjectID:(NSManagedObjectID *)objectID
           forRelationship:(NSString *)relationshipName
       withCompletionBlock:(void (^)())completionBlock {
    
    [self processJSONPayload:jsonPayload
            targetObjectID:objectID
             forRelationship:relationshipName 
          JSONPreFilterBlock:nil
         withCompletionBlock:completionBlock];
}

- (void)processJSONPayload:(id)jsonPayload
            targetObjectID:(NSManagedObjectID *)objectID
           forRelationship:(NSString *)relationshipName
        JSONPreFilterBlock:(id (^)())filterBlock
       withCompletionBlock:(void (^)())completionBlock 
{    
    NSAssert(self.mainContext, @"Broker must be setup with setupWithContext!");
    if (!self.mainContext) return;
    
    BKJSONOperation *operation = [BKJSONOperation operation];
    
    operation.jsonPayload = jsonPayload;
    operation.broker = self;
    operation.objectID = objectID;
    operation.relationshipName = relationshipName;
    operation.mainContext = self.mainContext;;
    
    // Blocks
    operation.preFilterBlock = filterBlock;
    operation.completionBlock = completionBlock;
    
    // Add operation
    [self addOperation:operation toQueueNamed:self.queueName];
}

#pragma mark - Object Collection

- (void)processJSONPayload:(id)jsonPayload 
asCollectionOfEntitiesNamed:(NSString *)entityName 
       withCompletionBlock:(void (^)())completionBlock {
    [self processJSONPayload:jsonPayload 
 asCollectionOfEntitiesNamed:entityName
          JSONPreFilterBlock:nil
       contextDidChangeBlock:nil
              emptyJSONBlock:nil
         withCompletionBlock:completionBlock];
}

- (void)processJSONPayload:(id)jsonPayload 
asCollectionOfEntitiesNamed:(NSString *)entityName
        JSONPreFilterBlock:(id (^)())filterBlock
       withCompletionBlock:(void (^)())completionBlock {
    
    [self processJSONPayload:jsonPayload 
 asCollectionOfEntitiesNamed:entityName
          JSONPreFilterBlock:filterBlock
       contextDidChangeBlock:nil
              emptyJSONBlock:nil
         withCompletionBlock:completionBlock];
}

- (void)processJSONPayload:(id)jsonPayload 
asCollectionOfEntitiesNamed:(NSString *)entityName
        JSONPreFilterBlock:(id (^)())filterBlock
     contextDidChangeBlock:(void (^)())didChangeBlock
            emptyJSONBlock:(void (^)())emptyJSONBlock
       withCompletionBlock:(void (^)())completionBlock
{    
    NSAssert(self.mainContext, @"Broker must be setup with setupWithContext!");
    if (!self.mainContext) return;
    
    BKJSONOperation *operation = [BKJSONOperation operation];
    
    operation.jsonPayload = jsonPayload;
    operation.broker = self;
    
    // This is the type of object the collection objects will be turned into
    BKEntityPropertiesDescription *description = [self entityPropertyDescriptionForEntityName:entityName];
    
    if (!description) {
        WLog(@"No entity description found!  Did you remember to register it?");
        return;
    }
    
    operation.entityDescription = description;
    
    // Thread safe managed object context.  Will call contextDidSave when saving,
    // properly merges with main context on main thread
    operation.mainContext = self.mainContext;
    
    // Blocks
    operation.didChangeBlock = didChangeBlock;
    operation.emptyJSONBlock = emptyJSONBlock;
    operation.preFilterBlock = filterBlock;
    operation.completionBlock = completionBlock;
    
    // Add operation
    [self addOperation:operation toQueueNamed:self.queueName];
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

@end
