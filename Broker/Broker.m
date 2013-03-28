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

@end

@implementation Broker

+ (id)sharedInstance
{
    static dispatch_once_t pred = 0;
    __strong static Broker *_sharedInstance = nil;
    dispatch_once(&pred, ^{
        _sharedInstance = [Broker new];
    });
    return _sharedInstance;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)init
{
    self = [super init];
    if (self) {
        _entityDescriptions = [[NSMutableDictionary alloc] init];
    }
    return self;
}

+ (Broker *)brokerWithContext:(NSManagedObjectContext *)context
{
    Broker *broker = [Broker new];
    broker.mainContext = context;    
    return broker;
}

#pragma mark - Reset

- (void)reset
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    _mainContext = nil;
    
    _entityDescriptions = nil;
    _entityDescriptions = [[NSMutableDictionary alloc] init];
}

#pragma mark - Registration

- (void)registerEntityNamed:(NSString *)entityName
{
    [self registerEntityNamed:entityName
               withPrimaryKey:nil
      andMapNetworkProperties:nil 
            toLocalProperties:nil];
}

- (void)registerEntityNamed:(NSString *)entityName 
             withPrimaryKey:(NSString *)primaryKey
{
    [self registerEntityNamed:entityName
               withPrimaryKey:primaryKey
      andMapNetworkProperties:nil 
            toLocalProperties:nil];
}

- (void)registerEntityNamed:(NSString *)entityName
             withPrimaryKey:(NSString *)primaryKey
      andMapNetworkProperty:(NSString *)networkProperty 
            toLocalProperty:(NSString *)localProperty
{    
    [self registerEntityNamed:entityName
               withPrimaryKey:primaryKey
      andMapNetworkProperties:@[networkProperty] 
            toLocalProperties:@[localProperty]];
    
}

- (void)registerEntityNamed:(NSString *)entityName
             withPrimaryKey:(NSString *)primaryKey
    andMapNetworkProperties:(NSArray *)networkProperties 
          toLocalProperties:(NSArray *)localProperties
{    
    NSAssert(self.mainContext, @"Broker must be setup with setupWithContext!");
    
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
             onEntity:(NSString *)entity
{
    BKAttributeDescription *desc = [self attributeDescriptionForProperty:property onEntityName:entity];;
    desc.dateFormat = dateFormat;
}

- (void)setRootKeyPath:(NSString *)rootKeyPath 
             forEntity:(NSString *)entity
{
    BKEntityPropertiesDescription *desc = [self entityPropertyDescriptionForEntityName:entity];
    desc.rootKeyPath = rootKeyPath;
}

- (void)mapNetworkProperty:(NSString *)networkProperty
           toLocalProperty:(NSString *)localProperty
                 forEntity:(NSString *)entity
{    
    [self mapNetworkProperties:@[networkProperty]
             toLocalProperties:@[localProperty]
                     forEntity:entity];
}

- (void)mapNetworkProperties:(NSArray *)networkProperties
           toLocalProperties:(NSArray *)localProperties
                   forEntity:(NSString *)entity
{
    BKEntityPropertiesDescription *desc = [self entityPropertyDescriptionForEntityName:entity];
    
    NSAssert(desc, @"You must first register entity named before mapping properties.");
    if (!desc) return;
    
    [desc mapNetworkProperties:networkProperties toLocalProperties:localProperties];
}

#pragma mark - Relationship Object Collection

- (void)processJSONPayload:(id)jsonPayload
           usingQueueNamed:(NSString *)queueName
            targetObjectID:(NSManagedObjectID *)objectID
           forRelationship:(NSString *)relationshipName
        JSONPreFilterBlock:(id (^)())filterBlock
       withCompletionBlock:(void (^)())completionBlock 
{    
    NSAssert(self.mainContext, @"Broker must be setup with setupWithContext!");
    if (!self.mainContext) return;
    
    BKJSONOperation *operation = [BKJSONOperation new];
    
    operation.jsonPayload = jsonPayload;
    operation.broker = self;
    operation.objectID = objectID;
    operation.relationshipName = relationshipName;
    operation.mainContext = self.mainContext;
    operation.identifier = [[objectID URIRepresentation] path];
    
    // Blocks
    operation.preFilterBlock = filterBlock;
    operation.completionBlock = completionBlock;
    
    // Add operation
    [self addOperation:operation toQueueNamed:queueName];
}

#pragma mark - Object Collection

- (void)processJSONPayload:(id)jsonPayload
           usingQueueNamed:(NSString *)queueName
asCollectionOfEntitiesNamed:(NSString *)entityName
        JSONPreFilterBlock:(id (^)())filterBlock
     contextDidChangeBlock:(void (^)())didChangeBlock
            emptyJSONBlock:(void (^)())emptyJSONBlock
           completionBlock:(void (^)())completionBlock
{    
    NSAssert(self.mainContext, @"Broker must be setup with setupWithContext!");
    if (!self.mainContext) return;
    
    BKJSONOperation *operation = [BKJSONOperation new];
    
    operation.jsonPayload = jsonPayload;
    operation.broker = self;
    
    // This is the type of object the collection objects will be turned into
    BKEntityPropertiesDescription *description = [self entityPropertyDescriptionForEntityName:entityName];
    
    if (!description) {
        BrokerWarningLog(@"No entity description found!  Did you remember to register it?");
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
    [self addOperation:operation toQueueNamed:queueName];
}

#pragma mark - Accessors

- (BKEntityPropertiesDescription *)entityPropertyDescriptionForEntityName:(NSString *)entityName
{
    return (BKEntityPropertiesDescription *)[self.entityDescriptions objectForKey:entityName];
}

- (BKAttributeDescription *)attributeDescriptionForProperty:(NSString *)property 
                                               onEntityName:(NSString *)entityName
{    
    BKEntityPropertiesDescription *desc = [self.entityDescriptions objectForKey:entityName];
    if (desc) {
        return [desc attributeDescriptionForLocalProperty:property];
    }
    return nil;
}

- (BKRelationshipDescription *)relationshipDescriptionForProperty:(NSString *)property 
                                                     onEntityName:(NSString *)entityName
{    
    BKEntityPropertiesDescription *desc = [self.entityDescriptions objectForKey:entityName];
    if (desc) {
        return [desc relationshipDescriptionForProperty:property];
    }
    return nil;
}

- (BKEntityPropertiesDescription *)destinationEntityPropertiesDescriptionForRelationship:(NSString *)relationship
                                                                           onEntityNamed:(NSString *)entityName
{    
    BKRelationshipDescription *desc = [self relationshipDescriptionForProperty:relationship onEntityName:entityName];
    return [self entityPropertyDescriptionForEntityName:desc.destinationEntityName];
}

- (NSDictionary *)transformJSONDictionary:(NSDictionary *)jsonDictionary 
         usingEntityPropertiesDescription:(BKEntityPropertiesDescription *)propertiesDescription
{
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
