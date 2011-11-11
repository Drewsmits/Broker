//
//  BKJSONOperation.m
//  Broker
//
//  Created by Andrew Smith on 10/25/11.
//  Copyright (c) 2011 Andrew B. Smith. All rights reserved.
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
        
        id jsonObject = [NSJSONSerialization JSONObjectWithData:self.jsonPayload 
                                                        options:NSJSONReadingMutableContainers 
                                                          error:NULL];
        
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
        
        NSString *entityName = nil;
        
        if (self.relationshipName) {
            entityName = [description destinationEntityNameForRelationship:self.relationshipName];
        } else {
            entityName = description.entityName;
        }
        
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
