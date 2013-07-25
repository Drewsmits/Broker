//
//  BKEntityController.m
//  Broker
//
//  Created by Andrew Smith on 6/6/13.
//  Copyright (c) 2013 Andrew B. Smith. All rights reserved.
//

#import "BKEntityController.h"
#import "BKEntityDescription.h"

@implementation BKEntityController

- (void)registerEntityNamed:(NSString *)entityName
             withPrimaryKey:(NSString *)primaryKey
    andMapNetworkProperties:(NSArray *)networkProperties
          toLocalProperties:(NSArray *)localProperties
                  inContext:(NSManagedObjectContext *)context
{
    [context performBlock:^{
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

- (void)processJSONObject:(NSDictionary *)json
          usingQueueNamed:(NSString *)queueName
   asArrayOfEntitiesNamed:(NSString *)entityName
    contextDidChangeBlock:(void (^)())didChangeBlock
          completionBlock:(void (^)())completionBlock
{
    
}

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
