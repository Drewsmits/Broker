//
//  BKEntityController.m
//  Broker
//
//  Created by Andrew Smith on 6/6/13.
//  Copyright (c) 2013 Andrew B. Smith. All rights reserved.
//

#import "BKEntityController.h"
#import "BKEntityDescription.h"
#import "BKJSONOperation.h"

// Catagories
#import "NSManagedObjectContext+Broker.h"

#define BROKER_INTERNAL_QUEUE @"com.broker.queue"

@interface BKEntityController ()

@property (nonatomic, strong, readwrite) NSMutableDictionary *entityDescriptions;

- (BKEntityDescription *)entityDescriptionForEntityName:(NSString *)entityName;

@end

@implementation BKEntityController

+ (instancetype)entityController
{
    BKEntityController *controller = [self new];
    
    controller.entityDescriptions = [NSMutableDictionary dictionary];
    
    CDOperationQueue *queue = [CDOperationQueue queueWithName:BROKER_INTERNAL_QUEUE];
    [queue setMaxConcurrentOperationCount:1];
    [controller addQueue:queue];

    return controller;
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

- (void)processJSONObject:(NSDictionary *)json
            asEntityNamed:(NSString *)entityName
                inContext:(NSManagedObjectContext *)context
          completionBlock:(void (^)())completionBlock
{
    BKEntityDescription *entityDescription = [self entityDescriptionForEntityName:entityName];
    
    BKJSONOperation *operation = [BKJSONOperation operationForJSON:json
                                                       description:entityDescription
                                                              type:BKJSONOperationTypeObject
                                                        controller:self
                                                           context:context
                                                   completionBlock:completionBlock];
    
    [self addOperation:operation
          toQueueNamed:BROKER_INTERNAL_QUEUE];
}

- (void)processJSONCollection:(NSArray *)json
              asEntitiesNamed:(NSString *)entityName
              completionBlock:(void (^)())completionBlock
{
//    BKEntityDescription *entityDescription = [self entityDescriptionForEntityName:entityName];

}

- (void)processJSONObject:(NSDictionary *)json
                 asObject:(NSManagedObject *)object
{
//    BKEntityDescription *entityDescription = [self entityDescriptionForEntityName:object.entity.name];
}

- (void)processJSONCollection:(NSArray *)json
              forRelationship:(NSString *)relationshipName
                     onObject:(NSManagedObject *)object
{
    
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
