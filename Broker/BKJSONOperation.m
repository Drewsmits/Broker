//
//  BKJSONOperation.m
//  Broker
//
//  Created by Andrew Smith on 10/25/11.
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

#import "BKJSONOperation.h"

#import "BKEntityController.h"
#import "BKEntityDescription.h"
#import "NSManagedObject+Broker.h"
#import "NSManagedObjectContext+Broker.h"

@interface BKJSONOperation ()

/*!
 Some cool stuff BKEntityDescription
 */
@property (nonatomic, strong, readwrite) id json;

@property (nonatomic, weak) BKEntityController *entityController;

@property (nonatomic, strong) NSString *entityName;

@property (nonatomic, assign) BKJSONOperationType type;

@end

@implementation BKJSONOperation

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (BKJSONOperation *)operationForJSON:(id)json
                          description:(BKEntityDescription *)description
                                 type:(BKJSONOperationType)type
                           controller:(BKEntityController *)controller
                              context:(NSManagedObjectContext *)context
                      completionBlock:(void (^)())completionBlock
{
    BKJSONOperation *operation = [BKJSONOperation new];
    
    operation.type = type;
    operation.json = json;
    operation.entityController = controller;
    operation.mainContext = context;
    operation.completionBlock = completionBlock;
    
    return operation;
}

#pragma mark - Conductor

- (void)work
{
    //
    // Execute empty JSON block if empty
    //
    if (!self.json || [self.json count] == 0) {
        return;
    }
    
    switch (self.type) {
        case BKJSONOperationTypeObject:
            [self processJSONObject:self.json
                      asEntityNamed:self.entityName];
            break;
        case BKJSONOperationTypeCollection:
            [self processJSONCollection:self.json
                        asEntitiesNamed:self.entityName];
            break;
        case BKJSONOperationTypeRelationshipCollection:
//            [self processJSONCollection:self.JSONObject
//                        forRelationship:<#(NSString *)#>
//                               onObject:<#(NSManagedObject *)#>]
            break;
        default:
            break;
    }
    
    
}

- (void)cleanup
{    
    [self saveBackgroundContext];
}

#pragma mark - Processing

- (NSManagedObject *)processJSONObject:(NSDictionary *)json
                         asEntityNamed:(NSString *)entityName
{
    //
    // Get the entity description
    //
    BKEntityDescription *entityDescription = [self.entityController entityDescriptionForEntityName:entityName];
    
    //
    // Get the primary key
    //
    id primaryKey = [self primaryKeyForJSON:json];
    if (!primaryKey) {
        NSAssert(nil, @"doh!");
    }
    
    //
    // Create a target object if it doesn't alreay exist
    //
    NSManagedObject *managedObject = [self.backgroundContext findOrCreateObjectForEntityDescription:entityDescription
                                                                                    primaryKeyValue:primaryKey
                                                                                       shouldCreate:YES];
    
    //
    // For each property in the JSON, if it is a relationship, process the relationship.
    // Otherwise it's just a flat attribute, so set the value.
    //
    for (NSString *property in json) {
        id object = [self objectForProperty:property fromJSON:json];
        if ([entityDescription isPropertyRelationship:property]) {
            // Collection
            if ([object isKindOfClass:[NSArray class]]) {
                [self processJSONCollection:object
                            forRelationship:property
                                   onObject:managedObject];
            }
            // Flat
            if ([object isKindOfClass:[NSDictionary class]]) {
                NSManagedObject *destinationObject = [self processJSONObject:object
                                                               asEntityNamed:entityName];
                [managedObject setValue:destinationObject
                                 forKey:property];
            }
        } else {
            [managedObject setValue:object
                             forKey:property];
        }
    }
    
    return managedObject;
}

- (void)processJSONCollection:(NSArray *)json
              forRelationship:(NSString *)relationshipName
                     onObject:(NSManagedObject *)object
{
    //
    // Grab the relationship description
    //
    NSRelationshipDescription *relationshipDescription = [self.entityDescription relationshipDescriptionForProperty:relationshipName];
    if (!relationshipDescription) return;
    
    //
    // Fetch the context relationship objects
    //
    NSMutableSet *existingRelationshipObjects = [object mutableSetValueForKey:relationshipDescription.name];
    
    //
    // Create relationship objects to add
    //
    NSArray *objectsToAdd = [self processJSONCollection:json
                                        asEntitiesNamed:relationshipDescription.destinationEntity.name];
    
    //
    // Merge existing and new
    //
    [existingRelationshipObjects unionSet:[NSSet setWithArray:objectsToAdd]];
}

- (NSArray *)processJSONCollection:(NSArray *)json
              asEntitiesNamed:(NSString *)entityName
{
    NSMutableArray *managedObjects = [NSMutableArray arrayWithCapacity:json.count];
    for (NSDictionary *object in json) {
        NSManagedObject *managedObject = [self processJSONObject:object
                                                   asEntityNamed:entityName];
        [managedObjects addObject:managedObject];
    }
    return managedObjects;
}

#pragma mark - WHERE TO PUT

- (id)primaryKeyForJSON:(NSDictionary *)JSON
{
    return [self objectForProperty:self.entityDescription.primaryKey
                          fromJSON:JSON];
}

- (id)objectForProperty:(NSString *)property
               fromJSON:(NSDictionary *)JSON
{
    id value = JSON[property];
    id object = [self.entityDescription objectFromValue:value
                                            forProperty:property];
    return object;
}

#pragma mark - Old

//- (void)processJSONObject:(NSDictionary *)JSONObject
//{
//    //
//    // If not flat JSON, bail
//    //
//    if (![JSONObject isKindOfClass:[NSDictionary class]]) {
//        return;
//    }
//    
//    //
//    // Grab the target object
//    //
//    NSManagedObject *object = [self targetObject];
//
//    //
//    // Grab the entity property description for the current working objects name,
//    //
//    BKEntityDescription *entityDescription = [self targetEntityDescriptionForObject:object];
//    
//    //
//    // Transform flat JSON to use local property names and native object types
//    //
//    NSDictionary *transformedDict = [BKEntityController transformJSONObject:JSONObject
//                                                      withEntityDescription:self.entityDescription];
//    
//    [self processJSONSubObject:transformedDict
//                     forObject:object
//               withDescription:self.description];
//}

//- (void)processJSONCollection:(NSDictionary *)JSONObject
//{
//    
//}

//- (void)processJSONObject:(NSDictionary *)jsonObject
//{        
////    NSManagedObject *object = [self targetObject];
////    if (!object) {
////        BrokerWarningLog(@"Could not find object!");
////        return;
////    }
//
//    //
//    // Flat JSON
//    //
//    if ([jsonObject isKindOfClass:[NSDictionary class]]) {
//        // Grab the entity property description for the current working objects name,
//        BKEntityPropertiesDescription *description = [self targetEntityDescriptionForObject:object];
//        
//        // Transform flat JSON to use local property names and native object types
//        NSDictionary *transformedDict = [self.broker transformJSONDictionary:(NSDictionary *)jsonObject 
//                                            usingEntityPropertiesDescription:description];
//        
//        [self processJSONSubObject:transformedDict
//                         forObject:object
//                   withDescription:description];
//    }
//    
//    //
//    // Collection JSON
//    //
//    if ([jsonObject isKindOfClass:[NSArray class]]) {
//        
//        //
//        // Is it a relationship on a target object?
//        //
//        if (self.relationshipName) {
//            // Grab the entity property description for the current working objects name,
//            BKEntityPropertiesDescription *description = [self targetEntityDescriptionForObject:object];
//            
//            [self processJSONCollection:jsonObject 
//                              forObject:object 
//                  withEntityDescription:description 
//                        forRelationship:self.relationshipName];
//            
//            return;
//        }
//        
//        //
//        // Is it a collection of entities?
//        //
//        if (self.entityDescription) {
//            [self processJSONCollection:jsonObject 
//        asEntitiesWithEntityDescription:self.entityDescription];
//            return;
//        }
//        
//        BrokerWarningLog(@"Neither relationship name or entity description specified!");
//    }
//    
//}

//- (void)processJSONCollection:(NSArray *)collection
//                    forObject:(NSManagedObject *)object
//        withEntityDescription:(BKEntityPropertiesDescription *)description
//              forRelationship:(NSString *)relationship
//{    
//    NSString *destinationEntityName;
//    if (relationship) {
//        destinationEntityName = [description destinationEntityNameForRelationship:relationship];
//    } else {
//        destinationEntityName = description.entityName;
//    }
//    
//    BKEntityPropertiesDescription *destinationEntityDesc = [self.broker entityPropertyDescriptionForEntityName:destinationEntityName];
//    
//    // Check for registration
//    NSAssert(destinationEntityDesc, @"Entity for relationship \"%@\" is not registered with Broker instance!", relationship);
//    if (!destinationEntityDesc) return;
//    
//    // Fetch the context relationship objects
//    NSMutableSet *relationshipObjects = [object mutableSetValueForKey:relationship];
//    
//    // Create relationship objects to add
//    NSSet *objectsToAdd = [self processJSONCollection:collection 
//                    asEntitiesWithEntityDescription:destinationEntityDesc];
//    
//    [relationshipObjects unionSet:objectsToAdd];
//}

//- (NSSet *)processJSONCollection:(NSArray *)collection 
// asEntitiesWithEntityDescription:(BKEntityPropertiesDescription *)description
//{    
//    NSMutableSet *collectionObjects = [NSMutableSet setWithCapacity:collection.count];
//    
//    for (id dictionary in collection) {
//        
//        NSAssert([dictionary isKindOfClass:[NSDictionary class]], @"Collection object must be a dictionary");
//        if (![dictionary isKindOfClass:[NSDictionary class]]) continue;
//        
//        // Transform
//        NSDictionary *transformedDict = [self.broker transformJSONDictionary:(NSDictionary *)dictionary 
//                                            usingEntityPropertiesDescription:description];
//        
//        // Get the primary key value
//        id value = [transformedDict objectForKey:description.primaryKey];
//        
//        NSManagedObject *collectionObject = [self.backgroundContext findOrCreateObjectForEntityDescribedBy:description 
//                                                                                       withPrimaryKeyValue:value
//                                                                                              shouldCreate:YES];
//        
//        if (!collectionObject) {
//            BrokerWarningLog(@"Got nil back for collection object!");
//            continue;
//        }
//        
//        [self processJSONSubObject:transformedDict
//                         forObject:collectionObject
//                   withDescription:description];
//        
//        [collectionObjects addObject:collectionObject];
//    }
//
//    return collectionObjects;
//}

//- (void)processJSONSubObject:(NSDictionary *)subDictionary 
//                   forObject:(NSManagedObject *)object 
//             withDescription:(BKEntityDescription *)description
//{    
//    
//    
//    
//    
//    for (NSString *property in subDictionary) {
//        if ([description isPropertyRelationship:property]) {
//            
//            id value = [subDictionary valueForKey:property];            
//            
//            BKEntityPropertiesDescription *destinationEntityDesc = [self.broker destinationEntityPropertiesDescriptionForRelationship:property
//                                                                                                                        onEntityNamed:object.entity.name];
//            
//            if (!destinationEntityDesc) {
//                BrokerWarningLog(@"Destination entity for relationship \"%@\" on entity \"%@\" not registered with Broker!  Skipping...", property, [object.objectID.entity name]);
//                continue;
//            }
//            
//            //
//            // Flat
//            //
//            if ([value isKindOfClass:[NSDictionary class]]) {
//                
//                NSDictionary *transformedDict = [self.broker transformJSONDictionary:value 
//                                                    usingEntityPropertiesDescription:destinationEntityDesc];
//                
//                // Get the primary key value
//                id primaryKeyValue = [transformedDict objectForKey:destinationEntityDesc.primaryKey];
//                
//                NSManagedObject *relationshipObject = [self.backgroundContext findOrCreateObjectForEntityDescribedBy:destinationEntityDesc 
//                                                                                                 withPrimaryKeyValue:primaryKeyValue
//                                                                                                        shouldCreate:YES];                
//                [self processJSONSubObject:transformedDict
//                                 forObject:relationshipObject
//                           withDescription:destinationEntityDesc];
//                
//                // Set the destination object
//                [object setValue:relationshipObject forKey:property];
//            }
//            
//            //
//            // Collection
//            //
//            if ([value isKindOfClass:[NSArray class]]) {
//                [self processJSONCollection:value
//                                  forObject:object
//                      withEntityDescription:description
//                            forRelationship:property];
//            }
//            
//        } else {
//            [object setValue:[subDictionary valueForKey:property]
//                      forKey:property];        
//        }
//    }
//}

#pragma mark - Accessors

//- (NSManagedObject *)targetObject
//{    
//    //
//    // Grabs the object from the threaded context (thread safe)
//    //
//    __block NSManagedObject *object;
//    
//    [self.backgroundContext performBlockAndWait:^ {
//        object = [self.backgroundContext objectWithID:self.objectID];
//    }];
//        
//    NSAssert(object, @"Object not found in store!  Did you remember to save the managed object context to get the URI?");
//    if ([object hasBeenDeleted]) return nil;
//    
//    return object;
//}

//- (BKEntityPropertiesDescription *)targetEntityDescriptionForObject:(NSManagedObject *)object
//{
//    BKEntityPropertiesDescription *description = [self.broker entityPropertyDescriptionForEntityName:object.entity.name];
//    NSAssert(description, @"Entity named \"%@\" is not registered with Broker instance!", object.entity.name);
//    return description;
//}

#pragma mark - Core Data

- (void)contextDidChange:(NSNotification *)notification 
{    
    //
    // Make sure this is only called once
    //
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSManagedObjectContextObjectsDidChangeNotification 
                                                  object:self.backgroundContext];
    
    //
    // Process changes by passing notification to change block
    //
    if (self.didChangeBlock) self.didChangeBlock(self.backgroundContext, notification);
}

@end
