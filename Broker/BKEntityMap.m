//
//  BKEntityController.m
//  Broker
//
//  Created by Andrew Smith on 6/6/13.
//  Copyright (c) 2013 Andrew B. Smith. All rights reserved.
//

#import "BKEntityMap.h"
#import "BKEntityDescription.h"

// Catagories
#import "NSManagedObjectContext+Broker.h"

@interface BKEntityMap ()

@property (nonatomic, strong, readwrite) NSMutableDictionary *entityDescriptions;

- (BKEntityDescription *)entityDescriptionForEntityName:(NSString *)entityName;

@end

@implementation BKEntityMap

+ (instancetype)entityMap
{
    BKEntityMap *map = [self new];
    map.entityDescriptions = [NSMutableDictionary dictionary];
    return map;
}

- (void)registerEntityNamed:(NSString *)entityName
             withPrimaryKey:(NSString *)primaryKey
    andMapNetworkProperties:(NSArray *)networkProperties
          toLocalProperties:(NSArray *)localProperties
                  inContext:(NSManagedObjectContext *)context
{
    __block BKEntityDescription *description;
    [context performBlockAndWait:^{
        //
        // Create new temp object
        //
        NSManagedObject *object = [NSEntityDescription insertNewObjectForEntityForName:entityName
                                                                inManagedObjectContext:context];
        
        //
        // Build description of entity properties
        //
        description = [BKEntityDescription descriptionForObject:object];
        
        //
        // Map property names
        //
        [description mapNetworkProperties:networkProperties
                        toLocalProperties:localProperties];
                
        //
        // Set primary key
        //
        description.primaryKey = primaryKey;
        
        //
        // Cleanup
        //
        [context deleteObject:object];
    }];
    
    @synchronized (self.entityDescriptions) {
        [self.entityDescriptions setObject:description
                                    forKey:entityName];
    }
}

- (void)setDateFormat:(NSString *)dateFormat
          forProperty:(NSString *)property
             onEntity:(NSString *)entity
{
    BKEntityDescription *description = [self entityDescriptionForEntityName:entity];
    BKAttributeDescription *attributeDescription = [description attributeDescriptionForProperty:property];
    [attributeDescription setDateFormat:dateFormat];
}

#pragma mark -

- (BKEntityDescription *)entityDescriptionForEntityName:(NSString *)entityName
{
    BKEntityDescription *entityDescription = [self.entityDescriptions objectForKey:entityName];
    NSAssert(entityDescription,
             @"Could not find entityDescription for entity named \"%@\". Did you register it with this controller?", entityName);
    return entityDescription;
}

@end
