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

#import "Broker.h"
#import "NSManagedObject+Broker.h"
#import "NSManagedObjectContext+Broker.h"

@interface BKJSONOperation ()

- (void)processJSONObject:(id)jsonObject;

- (void)processJSONCollection:(NSArray *)collection
                    forObject:(NSManagedObject *)object
        withEntityDescription:(BKEntityPropertiesDescription *)description
              forRelationship:(NSString *)relationship;

- (NSSet *)processJSONCollection:(NSArray *)collection 
 asEntitiesWithEntityDescription:(BKEntityPropertiesDescription *)description;

- (void)processJSONSubObject:(NSDictionary *)subDictionary 
                   forObject:(NSManagedObject *)object 
             withDescription:(BKEntityPropertiesDescription *)description;

- (NSManagedObject *)targetObject;

- (BKEntityPropertiesDescription *)targetEntityDescriptionForObject:(NSManagedObject *)object;

@end

@implementation BKJSONOperation

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)start {
    @autoreleasepool {    
        [super start];
        
        // Register for change
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(contextDidChange:) 
                                                     name:NSManagedObjectContextObjectsDidChangeNotification
                                                   object:self.backgroundContext];
        
        // Convert JSON payload data to JSON object
        NSError *error;
        id jsonObject = [NSJSONSerialization JSONObjectWithData:self.jsonPayload 
                                                        options:NSJSONReadingMutableContainers 
                                                          error:&error];

        if (!jsonObject) {
            WLog(@"Unable to create JSON object from JSON data. ERROR: %@", error);
            DLog(@"Object: %@", [[NSString alloc] initWithData:self.jsonPayload
                                                      encoding:NSUTF8StringEncoding]);
            [self finish];
            return;
        }
        
        // If there is a pre-filter, apply it now
        if (self.preFilterBlock) {
            jsonObject = [self applyJSONPreFilterBlockToJSONObject:jsonObject];
        }
        
        // Process
        [self processJSONObject:jsonObject];
        
        // Clean up
        [self finish];
    }
}

- (void)finish {
    
    // Save context
    [self saveBackgroundContext];
    
    
    // Calls finish on superclass CDOperation, part of Conductor
    [super finish];    
}

#pragma mark - Processing
                        
- (void)processJSONObject:(id)jsonObject {
    
    // Execute empty JSON block if empty
    if (!jsonObject || [jsonObject count] == 0) {
        if (self.emptyJSONBlock) {
            self.emptyJSONBlock(self.backgroundContext);
        }
        return;
    }

    // Flat JSON
    if ([jsonObject isKindOfClass:[NSDictionary class]]) {
        
        NSManagedObject *object = [self targetObject];
        if (!object) {
            WLog(@"Could not find object!");
            return;
        }
        
        // Grab the entity property description for the current working objects name,
        BKEntityPropertiesDescription *description = [self targetEntityDescriptionForObject:object];
        
        // Transform flat JSON to use local property names and native object types
        NSDictionary *transformedDict = [self.broker transformJSONDictionary:(NSDictionary *)jsonObject 
                                            usingEntityPropertiesDescription:description];
        
        [self processJSONSubObject:transformedDict
                         forObject:object
                   withDescription:description];
    }
    
    // Collection JSON
    if ([jsonObject isKindOfClass:[NSArray class]]) {
        
        // Is it a relationship on a target object?
        if (self.relationshipName) {
            
            NSManagedObject *object = [self targetObject];
            if (!object) {
                WLog(@"Could not find object!");
                return;
            }
            // Grab the entity property description for the current working objects name,
            BKEntityPropertiesDescription *description = [self targetEntityDescriptionForObject:object];
            
            [self processJSONCollection:jsonObject 
                              forObject:object 
                  withEntityDescription:description 
                        forRelationship:self.relationshipName];
            
            return;
        }
        
        // Is it a collection of entities?
        if (self.entityDescription) {
            [self processJSONCollection:jsonObject 
        asEntitiesWithEntityDescription:self.entityDescription];
            
            return;
        }
        
        WLog(@"Neither relationship name or entity description specified!");
    }
    
}

- (void)processJSONCollection:(NSArray *)collection
                    forObject:(NSManagedObject *)object
        withEntityDescription:(BKEntityPropertiesDescription *)description
              forRelationship:(NSString *)relationship {
    
    NSString *destinationEntityName = nil;
    if (relationship) {
        destinationEntityName = [description destinationEntityNameForRelationship:relationship];
    } else {
        destinationEntityName = description.entityName;
    }
    
    BKEntityPropertiesDescription *destinationEntityDesc = [self.broker entityPropertyDescriptionForEntityName:destinationEntityName];
    
    // Check for registration
    NSAssert(destinationEntityDesc, @"Entity for relationship \"%@\" is not registered with Broker instance!", relationship);
    if (!destinationEntityDesc) return;
    
    // Fetch the context relationship objects
    NSMutableSet *relationshipObjects = [object mutableSetValueForKey:relationship];
    
    // Create relationship objects to add
    NSSet *objectsToAdd = [self processJSONCollection:collection 
                    asEntitiesWithEntityDescription:destinationEntityDesc];
    
    [relationshipObjects unionSet:objectsToAdd];
}

- (NSSet *)processJSONCollection:(NSArray *)collection 
 asEntitiesWithEntityDescription:(BKEntityPropertiesDescription *)description {
    
    NSMutableSet *collectionObjects = [NSMutableSet setWithCapacity:collection.count];
    
    for (id dictionary in collection) {
        
        NSAssert([dictionary isKindOfClass:[NSDictionary class]], @"Collection object must be a dictionary");
        if (![dictionary isKindOfClass:[NSDictionary class]]) continue;
        
        // Transform
        NSDictionary *transformedDict = [self.broker transformJSONDictionary:(NSDictionary *)dictionary 
                                            usingEntityPropertiesDescription:description];
        
        // Get the primary key value
        id value = [transformedDict objectForKey:description.primaryKey];
        
        NSManagedObject *collectionObject = [self.backgroundContext findOrCreateObjectForEntityDescribedBy:description 
                                                                                       withPrimaryKeyValue:value
                                                                                              shouldCreate:YES];
        
        if (!collectionObject) {
            WLog(@"Got nil back for collection object!");
            continue;
        }
        
        [self processJSONSubObject:transformedDict
                         forObject:collectionObject
                   withDescription:description];
        
        [collectionObjects addObject:collectionObject];
    }

    return collectionObjects;
}

- (void)processJSONSubObject:(NSDictionary *)subDictionary 
                   forObject:(NSManagedObject *)object 
             withDescription:(BKEntityPropertiesDescription *)description {
    
    for (NSString *property in subDictionary) {
        if ([description isPropertyRelationship:property]) {
            
            id value = [subDictionary valueForKey:property];            
            
            BKEntityPropertiesDescription *destinationEntityDesc = [self.broker destinationEntityPropertiesDescriptionForRelationship:property
                                                                                                                        onEntityNamed:object.entity.name];
            
            if (!destinationEntityDesc) {
                WLog(@"Destination entity for relationship \"%@\" on entity \"%@\" not registered with Broker!  Skipping...", property, [object.objectID.entity name]);
                continue;
            }
            
            // Flat
            if ([value isKindOfClass:[NSDictionary class]]) {
                
                NSDictionary *transformedDict = [self.broker transformJSONDictionary:value 
                                                    usingEntityPropertiesDescription:destinationEntityDesc];
                
                // Get the primary key value
                id primaryKeyValue = [transformedDict objectForKey:destinationEntityDesc.primaryKey];
                
                NSManagedObject *relationshipObject = [self.backgroundContext findOrCreateObjectForEntityDescribedBy:destinationEntityDesc 
                                                                                                 withPrimaryKeyValue:primaryKeyValue
                                                                                                        shouldCreate:YES];                
                [self processJSONSubObject:transformedDict
                                 forObject:relationshipObject
                           withDescription:destinationEntityDesc];
                
                // Set the destination object
                [object setValue:relationshipObject forKey:property];
            }
            
            // Collection
            if ([value isKindOfClass:[NSArray class]]) {
                [self processJSONCollection:value
                                  forObject:object
                      withEntityDescription:description
                            forRelationship:property];
            }
            
        } else {
            [object setValue:[subDictionary valueForKey:property]
                      forKey:property];        
        }
    }
}

- (id)applyJSONPreFilterBlockToJSONObject:(id)jsonObject {
    
    id newJSONObject = self.preFilterBlock(self.backgroundContext, jsonObject);
    
    NSAssert(newJSONObject, @"JSON Pre-filter blocks must not return nil! Did you forget to return a value with your block?");
    if (!newJSONObject) return jsonObject;
    
    return newJSONObject;
}

#pragma mark - Accessors

- (NSManagedObject *)targetObject {
    
    // Grabs the object from the threaded context (thread safe)
    __block NSManagedObject *object = nil;
    
    [self.backgroundContext performBlockAndWait:^ {
        object = [self.backgroundContext objectWithID:self.objectID];
    }];
        
    NSAssert(object, @"Object not found in store!  Did you remember to save the managed object context to get the URI?");
    if ([object hasBeenDeleted]) return nil;
    
    return object;
}

- (BKEntityPropertiesDescription *)targetEntityDescriptionForObject:(NSManagedObject *)object {
    BKEntityPropertiesDescription *description = [self.broker entityPropertyDescriptionForEntityName:object.entity.name];
    NSAssert(description, @"Entity named \"%@\" is not registered with Broker instance!", object.entity.name);
    return description;
}
                        
#pragma mark - Core Data

- (void)contextDidChange:(NSNotification *)notification 
{    
    // Make sure this is only called once
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:NSManagedObjectContextObjectsDidChangeNotification 
                                                  object:self.backgroundContext];
    
    if (self.didChangeBlock) {
        self.didChangeBlock(self.backgroundContext, notification);
    };
}

@end
