//
//  BKEntityController.h
//  Broker
//
//  Created by Andrew Smith on 6/6/13.
//  Copyright (c) 2013 Andrew B. Smith. All rights reserved.
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

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

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
