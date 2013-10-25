//
//  BKJSONController.m
//  Broker
//
//  Created by Andrew Smith on 10/24/13.
//  Copyright (c) 2013 Andrew B. Smith. All rights reserved.
//

#import "BKJSONController.h"

// Models
#import "BKEntityDescription.h"

// Controllers
#import "BKEntityController.h"

// Cats
#import "NSManagedObjectContext+Broker.h"

@implementation BKJSONController

+ (instancetype)JSONControllerWithContext:(NSManagedObjectContext *)context
                         entityController:(BKEntityController *)entityController
{
    BKJSONController *controller = [self new];
    controller.context = context;
    controller.entityController = entityController;
    return controller;
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
    id primaryKey = [entityDescription primaryKeyForJSON:json];
    if (!primaryKey) {
        NSAssert(nil, @"doh!");
    }
    
    //
    // Create a target object if it doesn't alreay exist
    //
    NSManagedObject *managedObject = [self.context findOrCreateObjectForEntityDescription:entityDescription
                                                                          primaryKeyValue:primaryKey
                                                                             shouldCreate:YES];
    
    //
    // For each property in the JSON, if it is a relationship, process the relationship.
    // Otherwise it's just a flat attribute, so set the value.
    //
    for (NSString *property in json) {
        //
        // Get the "true" object value, not the JSON value
        //
        id value = json[property];
        id object = [entityDescription objectFromValue:value forProperty:property];
        
        if ([entityDescription isPropertyRelationship:property]) {
            // Collection relationship
            if ([object isKindOfClass:[NSArray class]]) {
                [self processJSONCollection:object
                            forRelationship:property
                                   onObject:managedObject];
            }
            // Flat relationship
            if ([object isKindOfClass:[NSDictionary class]]) {
                NSManagedObject *destinationObject = [self processJSONObject:object
                                                               asEntityNamed:entityName];
                [managedObject setValue:destinationObject
                                 forKey:property];
            }
        } else {
            // Flat attribute
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
    // Get the entity description
    //
    BKEntityDescription *entityDescription = [self.entityController entityDescriptionForEntityName:object.entity.name];
    
    //
    // Grab the relationship description from the entity description
    //
    NSRelationshipDescription *relationshipDescription = [entityDescription relationshipDescriptionForProperty:relationshipName];
    if (!relationshipDescription) return;
    
    //
    // Fetch the objects relationship objects
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

@end
