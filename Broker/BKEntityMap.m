//
//  BKEntityController.m
//  Broker
//
//  Created by Andrew Smith on 6/6/13.
//  Copyright (c) 2013 Andrew B. Smith. All rights reserved.
//

#import "BKEntityMap.h"
#import "BKEntityDescription.h"
#import "BKJSONOperation.h"

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
    [context performBlockAndWait:^{
        //
        // Create new temp object
        //
        NSManagedObject *object = [NSEntityDescription insertNewObjectForEntityForName:entityName
                                                                inManagedObjectContext:context];
        
        //
        // Build description of entity properties
        //
        BKEntityDescription *description = [BKEntityDescription descriptionForObject:object];
        
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
        // Add to descriptions
        //
        [self.entityDescriptions setObject:description
                                    forKey:entityName];
        
        //
        // Cleanup
        //
        [context deleteObject:object];
    }];
}

#pragma mark -

- (BKEntityDescription *)entityDescriptionForEntityName:(NSString *)entityName
{
    BKEntityDescription *entityDescription = [self.entityDescriptions objectForKey:entityName];
    NSAssert(entityDescription,
             @"Could not find entityDescription for entity named \"%@\". Did you register it with this controller?", entityName);
    return entityDescription;
}

#pragma mark - Pow

+ (NSDictionary *)transformJSONObject:(NSDictionary *)JSONObject
                withEntityDescription:(BKEntityDescription *)entityDescription
{
    NSMutableDictionary *transformedDict = [[NSMutableDictionary alloc] init];
    
    //
    // For each property in the JSON, loop through and transform the value class into the expected
    // class according to the entity description.
    //
    for (NSString *property in JSONObject) {
        
        // Get the property description
        NSPropertyDescription *propertyDescription = [entityDescription descriptionForProperty:property];
        
        // get the original value
        id value = [JSONObject valueForKey:property];
        
        // get the local property name
        NSString *localProperty = [entityDescription.networkToLocalPropertiesMap objectForKey:property];
        
        // Test to see if networkProperty is relationship or attribute
        if ([entityDescription isPropertyRelationship:property]) {
            // Pass the value through for later processing
            [transformedDict setObject:value
                                forKey:localProperty];
        } else {
            // transform it using the attribute desc
            id valueAsObject = [(BKAttributeDescription *)propertyDescription objectForValue:value];
            
            // Add it to the transformed dictionary
            if (valueAsObject) {
                [transformedDict setObject:valueAsObject
                                    forKey:localProperty];
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
