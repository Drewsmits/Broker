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
#import "BKEntityMap.h"

// Cats
#import "NSManagedObjectContext+Broker.h"
#import "NSString+Broker.h"

@interface BKJSONController ()

@property (nonatomic, strong, readwrite) NSManagedObjectContext *context;

@property (nonatomic, strong, readwrite) BKEntityMap *entityMap;

@end

@implementation BKJSONController

+ (instancetype)JSONControllerWithContext:(NSManagedObjectContext *)context
                                entityMap:(BKEntityMap *)entityMap
{
    BKJSONController *controller = [self new];
    controller.context = context;
    controller.entityMap = entityMap;
    return controller;
}

#pragma mark - Processing

- (NSManagedObject *)processJSONObject:(NSDictionary *)json
                         asEntityNamed:(NSString *)entityName
{
    //
    // Get the entity description
    //
    BKEntityDescription *entityDescription = [self.entityMap entityDescriptionForEntityName:entityName];
    
    //
    // Get the primary key. If there is no primary key, then duplicate objects may
    // be created.
    //
    id primaryKey = [entityDescription primaryKeyForJSON:json];
    
    //
    // Find target object, or create a new one if it doesn't exist
    //
    NSManagedObject *managedObject = [self.context bkr_findOrCreateObjectForEntityDescription:entityDescription
                                                                              primaryKeyValue:primaryKey];
    
    //
    // For each property in the JSON, if it is a relationship, process the relationship.
    // Otherwise it's just a flat attribute, so set the value.
    //
    for (NSString *jsonProperty in json) {
        //
        // Get the local NSManagedObject property name.
        //
        NSString *localProperty = [entityDescription localPropertyNameForProperty:jsonProperty];
        
        //
        // Bail if this property is not yet implemented
        //
        NSString *setter = [NSString stringWithFormat:@"set%@:", [localProperty bkr_uppercaseFirstLetterOnlyString]];
        if (![managedObject respondsToSelector:NSSelectorFromString(setter)]) {
            BrokerLog(@"No description for property \"%@\" found on entity \"%@\"!\
                      Tried to use setter named \"%@\".",
                      localProperty,
                      entityDescription.internalEntityDescription.name,
                      setter);
            continue;
        }
        
        //
        // Get the NSObject value
        //
        id value = json[jsonProperty];
        id object = [entityDescription objectFromValue:value forProperty:localProperty];
        
        if ([entityDescription isPropertyRelationship:localProperty]) {
            //
            // Process as a relationship on parent object.
            //
            [self processJSON:object
              forRelationship:localProperty
                     onObject:managedObject];
        } else {
            //
            // Flat attribute. Simply set the value.
            //
            [managedObject setValue:object
                             forKey:localProperty];
        }
    }
    return managedObject;
}

- (NSArray *)processJSONCollection:(NSArray *)json
                   asEntitiesNamed:(NSString *)entityName
{
    //
    // An array of entities. Find or create each.
    //
    NSMutableArray *managedObjects = [NSMutableArray arrayWithCapacity:json.count];
    for (NSDictionary *object in json) {
        NSManagedObject *managedObject = [self processJSONObject:object
                                                   asEntityNamed:entityName];
        [managedObjects addObject:managedObject];
    }
    return managedObjects;
}

- (void)processJSON:(id)json
    forRelationship:(NSString *)relationshipName
           onObject:(NSManagedObject *)object
{
    //
    // Get the entity description
    //
    BKEntityDescription *entityDescription = [self.entityMap entityDescriptionForEntityName:object.entity.name];
    
    //
    // Grab the relationship description from the entity description
    //
    NSRelationshipDescription *relationshipDescription = [entityDescription relationshipDescriptionForProperty:relationshipName];
    if (!relationshipDescription) return;
    
    //
    // Sanity check. Can't be a toMany without an array.
    //
    NSAssert(!(relationshipDescription.isToMany && ![json isKindOfClass:[NSArray class]]),
             @"Looks like your JSON is malformed. The registerd relationship is\
             expecting an array for the attribute named \"%@\"", relationshipName);
    
    if (relationshipDescription.isToMany) {
        //
        // Fetch the objects relationship objects. We add the found or created
        // objects to this mutable set.
        //
        NSMutableSet *existingRelationshipObjects = [object mutableSetValueForKey:relationshipDescription.name];
        
        //
        // Find or create relationship objects to add
        //
        NSArray *objectsToAdd = [self processJSONCollection:json
                                            asEntitiesNamed:relationshipDescription.destinationEntity.name];
        
        //
        // Merge existing and new
        //
        [existingRelationshipObjects unionSet:[NSSet setWithArray:objectsToAdd]];
    } else {
        //
        // Single object. Find or create, then set value.
        //
        NSManagedObject *destinationObject = [self processJSONObject:json
                                                       asEntityNamed:relationshipDescription.destinationEntity.name];
        [object setValue:destinationObject
                  forKey:relationshipName];
    }
}

@end
