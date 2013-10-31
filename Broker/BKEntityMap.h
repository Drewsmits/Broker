//
//  BKEntityController.h
//  Broker
//
//  Created by Andrew Smith on 6/6/13.
//  Copyright (c) 2013 Andrew B. Smith. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Conductor/Conductor.h>

@class BKEntityDescription;

@interface BKEntityMap : NSObject

/**
 The dictionary containing all BKEntityPropertiesDescriptions for registered objects.
 */
@property (nonatomic, strong, readonly) NSMutableDictionary *entityDescriptions;

+ (instancetype)entityMap;

/**
 Register object. Map local attribute names to the remote resource. A common excpetion for "MyObject" 
 might be mapping a network attribute 'id' to local attribute of 'myObjectID.'
 
 @param entityName The entity name of the NSManagedObject.
 @param primaryKey The designated primary key of the entity. A nil primaryKey
 may result in duplicate objects created when working with collections.
 @param networkProperties An array of network property names
 @param localProperties An array of local property names that match with the
 networkProperties
 
 @see [BKEntityPropertiesDescription primaryKey]
 */
- (void)registerEntityNamed:(NSString *)entityName
             withPrimaryKey:(NSString *)primaryKey
    andMapNetworkProperties:(NSArray *)networkProperties
          toLocalProperties:(NSArray *)localProperties
                  inContext:(NSManagedObjectContext *)context;

/**
 After registering an object you can set the expected date format to be used
 when transforming JSON date strings to NSDate objects
 
 @param dateFormat String representation of the date format
 @param property The name of the property for the given entity that is an NSDate
 @param entity The name of the entity, previously registered with Broker,
 to set the date format on
 */
- (void)setDateFormat:(NSString *)dateFormat
          forProperty:(NSString *)property
             onEntity:(NSString *)entity;

- (BKEntityDescription *)entityDescriptionForEntityName:(NSString *)entityName;

@end
