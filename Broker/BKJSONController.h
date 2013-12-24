//
//  BKJSONController.h
//  Broker
//
//  Created by Andrew Smith on 10/24/13.
//  Copyright (c) 2013 Andrew B. Smith. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BKEntityMap;

@interface BKJSONController : NSObject

@property (nonatomic, strong, readonly) NSManagedObjectContext *context;

@property (nonatomic, strong, readonly) BKEntityMap *entityMap;

/**
 Build a new JSON controller from the supplied context and entity map. The entity
 map must be previously built.
 */
+ (instancetype)JSONControllerWithContext:(NSManagedObjectContext *)context
                                entityMap:(BKEntityMap *)entityMap;

/**
 Process the json as the entity name indicated. This will look up the registered
 entity description and attempt to map the JSON key/value to an NSManagedObject.
 The NSManaged object will be found by looking up the registerd primary key. If
 no object is found, a new one will be created.
 @returns The object created or updated from the input json
 */
- (NSManagedObject *)processJSONObject:(NSDictionary *)json
                         asEntityNamed:(NSString *)entityName;

/**
 Process the JSON as a list of objects of the type indicated by the entity name.
 
 @returns An array of created or updated objects from the JSON array.
 */
- (NSArray *)processJSONCollection:(NSArray *)json
                   asEntitiesNamed:(NSString *)entityName;

- (void)processJSON:(id)json
    forRelationship:(NSString *)relationshipName
           onObject:(NSManagedObject *)object;

@end
