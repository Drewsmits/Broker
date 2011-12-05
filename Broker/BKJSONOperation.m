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

@implementation BKJSONOperation

@synthesize jsonPayload,
            entityURI,
            relationshipName,
            context;

- (void)dealloc {
    [jsonPayload release], jsonPayload = nil;
    [entityURI release], entityURI = nil;
    [relationshipName release], relationshipName = nil;
    [context release], context = nil;
    
    
    [super dealloc];
}

- (void)start {
    @autoreleasepool {    
        [super start];
        
        NSError *error;
        id jsonObject = [NSJSONSerialization JSONObjectWithData:self.jsonPayload 
                                                        options:NSJSONReadingMutableContainers 
                                                          error:&error];
        
        NSAssert(jsonObject, @"Unable to create JSON object from JSON data. ERROR: %@", error);
        if (!jsonObject) [self finish];
        
        [self processJSONObject:jsonObject];
        
        [self finish];
    }
}

- (void)finish {
    
    // Save context
    if (self.context.hasChanges) {
        NSError *error = nil;
        [self.context save:&error];
    }
    
    // Calls finish on superclass CDOperation, part of Conductor
    [super finish];    
}

- (void)processJSONObject:(id)jsonObject {
    
    NSManagedObject *object = [[Broker sharedInstance] objectForURI:self.entityURI 
                                                           inContext:self.context];
    
    NSAssert(object, @"Object not found in store!  Did you remember to save the managed object context to get the URI?");
    if (!object) return;
    
    BKEntityPropertiesDescription *description = [[Broker sharedInstance] entityPropertyDescriptionForEntityName:object.entity.name];

    NSAssert(description, @"Entity named \"%@\" not registered with Broker instance!", object.entity.name);
    if (!description) return;
    
    // Flat
    if ([jsonObject isKindOfClass:[NSDictionary class]]) {
        
        // Transform
        NSDictionary *transformedDict = [[Broker sharedInstance] transformJSONDictionary:(NSDictionary *)jsonObject 
                                                        usingEntityPropertiesDescription:description];
        
        [self processJSONSubObject:transformedDict
                         forObject:object
                   withDescription:description];        
    }
    
    // Collection
    if ([jsonObject isKindOfClass:[NSArray class]]) {
    
        [self processJSONCollection:jsonObject
                          forObject:object
              withEntityDescription:description
                    forRelationship:self.relationshipName];
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
    
    BKEntityPropertiesDescription *destinationEntityDesc = [[Broker sharedInstance] entityPropertyDescriptionForEntityName:destinationEntityName];
    
    // Check for registration
    NSAssert(destinationEntityDesc, @"Entity for relationship \"%@\" is not registered with Broker instance!", relationship);
    if (!destinationEntityDesc) return;
    
    // Check for primary key
    NSAssert(destinationEntityDesc.primaryKey, @"Processing a collection of %@ objects requires registration of an %@ primaryKey using [Broker registerEntityName:withPrimaryKey]", destinationEntityName, destinationEntityName);
    if (!destinationEntityDesc.primaryKey) return;
    
    NSMutableSet *relationshipObjects = [object mutableSetValueForKey:relationship];
    
    for (id dictionary in collection) {
        
        NSAssert([dictionary isKindOfClass:[NSDictionary class]], @"Collection object must be a dictionary");
        if (![dictionary isKindOfClass:[NSDictionary class]]) continue;
        
        // Transform
        NSDictionary *transformedDict = [[Broker sharedInstance] transformJSONDictionary:(NSDictionary *)dictionary 
                                                        usingEntityPropertiesDescription:destinationEntityDesc];
        
        // Get the primary key value
        id value = [transformedDict objectForKey:destinationEntityDesc.primaryKey];
    
        
        NSManagedObject *collectionObject = [[Broker sharedInstance] findOrCreateObjectForEntityDescribedBy:destinationEntityDesc 
                                                                                        withPrimaryKeyValue:value
                                                                                                  inContext:self.context
                                                                                               shouldCreate:YES];
        
        [self processJSONSubObject:transformedDict
                         forObject:collectionObject
                   withDescription:destinationEntityDesc];
        
        if (collectionObject) {
            [relationshipObjects addObject:collectionObject];
        }
    }
}

- (void)processJSONSubObject:(NSDictionary *)subDictionary 
                   forObject:(NSManagedObject *)object 
             withDescription:(BKEntityPropertiesDescription *)description {
    
    for (NSString *property in subDictionary) {
        if ([description isPropertyRelationship:property]) {
            
            id value = [subDictionary valueForKey:property];            
            
            BKEntityPropertiesDescription *destinationEntityDesc = [[Broker sharedInstance] destinationEntityPropertiesDescriptionForRelationship:property
                                                                                                                                    onEntityNamed:object.entity.name];
            
            if (!destinationEntityDesc) {
                WLog(@"Destination entity for relationship \"%@\" on entity \"%@\" not registered with Broker!  Skipping...", property, [object.objectID.entity name]);
                continue;
            }
            
            // Flat
            if ([value isKindOfClass:[NSDictionary class]]) {
                
                NSDictionary *transformedDict = [[Broker sharedInstance] transformJSONDictionary:value 
                                                                usingEntityPropertiesDescription:destinationEntityDesc];
                
                // Get the primary key value
                id primaryKeyValue = [transformedDict objectForKey:destinationEntityDesc.primaryKey];
                
                NSManagedObject *relationshipObject = [[Broker sharedInstance] findOrCreateObjectForEntityDescribedBy:destinationEntityDesc 
                                                                                                  withPrimaryKeyValue:primaryKeyValue
                                                                                                            inContext:self.context
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


@end
