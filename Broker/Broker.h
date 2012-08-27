//
//  Broker.h
//  Broker
//
//  Created by Andrew Smith on 10/5/11.
//  Copyright (c) 2011 Andrew B. Smith ( http://github.com/drewsmits ). All rights reserved.
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

#import "Conductor/Conductor.h"

#import "BKEntityPropertiesDescription.h"
#import "BKAttributeDescription.h"
#import "BKRelationshipDescription.h"
#import "BKJSONOperation.h"


@interface Broker : Conductor {
@private
    NSManagedObjectContext *mainContext;
    NSMutableDictionary *entityDescriptions;
}

/** @name Properties */

/**
 The NSManagedObjectContext in which the Broker instance performs its operations
 */
@property (readonly) NSManagedObjectContext *mainContext;

/**
 The dictionary containing all BKEntityPropertiesDescriptions registered with 
 the Broker instance.
 */
@property (weak, nonatomic, readonly) NSMutableDictionary *entityDescriptions;

/**
 Set this if you want to give the underlying conductor queue a name for future
 reference.
 */
@property (nonatomic, copy) NSString *queueName;

+ (Broker *)brokerWithContext:(NSManagedObjectContext *)context
                 andQueueName:(NSString *)queueName;

/** @name Setup */

/**
 Performs basic setup operations with the provided NSManagedObjectContext
 @param context Typically this is the main app context.
 @param queueName This is the name of the queue that controls the JSON parsing 
 operations.  Keep track of this queue name to modify the queue behavior later.
 */
- (void)setupWithContext:(NSManagedObjectContext *)context 
            andQueueName:(NSString *)queueName;

/**
 Performs basic setup operations with the provided NSManagedObjectContext
 @param context Typically this is the main app context.
 @param queueName This is the name of the queue that controls the JSON parsing 
 operations.  Keep track of this queue name to modify the queue behavior later.
 @param maxOperationCount The maximum simultanious parse operations that can 
 run at once. Set this to 1 for a serial queue.  
 */
- (void)setupWithContext:(NSManagedObjectContext *)context 
            andQueueName:(NSString *)queueName
withMaxConcurrentOperationCount:(NSUInteger)maxOperationCount;

/**
 Resets Broker instance by clearing the context and entityDescriptions.
 */
- (void)reset;

/** @name Registration */

/**
 Regsister entity where network attribute names are the same as local 
 attribute names.
 
 @see [Broker registerEntityNamed:withPrimaryKey:andMapNetworkProperties:toLocalProperties]
 */
- (void)registerEntityNamed:(NSString *)entityName;

/**
 Regsister entity where network attribute names are the same as local 
 attribute names.
 
 @see [Broker registerEntityNamed:withPrimaryKey:andMapNetworkProperties:toLocalProperties]
 */
- (void)registerEntityNamed:(NSString *)entityName 
             withPrimaryKey:(NSString *)primaryKey;

/**
 Regsister entity and map a single network property to a local property.
 
 @see [Broker registerEntityNamed:withPrimaryKey:andMapNetworkProperties:toLocalProperties]
 */
- (void)registerEntityNamed:(NSString *)entityName
             withPrimaryKey:(NSString *)primaryKey
      andMapNetworkProperty:(NSString *)networkProperty 
            toLocalProperty:(NSString *)localProperty;

/**
 Register object where some of the network attribute names are not the same as
 local attribute names.

 A common excpetion for "MyObject" might be mapping a 
 network attribute 'id' to local attribute of 'myObjectID.'
 
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
          toLocalProperties:(NSArray *)localProperties;

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

/**
 Set the root key path for a given entity previously registered

 The root key path is useful when the returned resources are nested. For a
 resource named "User," the JSON might look like the following.

    { 
        'response' : { 
            'user' : {
                      <DATA>
                     }
        }
    }

 In this case, the rootKeyPath would be @"response.user".
 
 @param rootKeyPath The root key path of the entity resource.
 @param entity The name of the entity, previously registered with Broker
 */
- (void)setRootKeyPath:(NSString *)rootKeyPath 
             forEntity:(NSString *)entity;

/**
 Map a network property to a local property for an entity that is already 
 registered with Broker.
 
 @param networkProperty The name of the network property
 @param localProperty The name of the local property
 @param entity The name of the entity, previously registered with Broker
 */
- (void)mapNetworkProperty:(NSString *)networkProperty
           toLocalProperty:(NSString *)localProperty
                 forEntity:(NSString *)entity;

/**
 Map several network properties to a local properties for an entity that is already 
 registered with Broker.

 @param networkProperties An array of network property names 
 @param localProperties An array of local property names that match with the
 networkProperties
 @param entity The name of the entity, previously registered with Broker
 
 @see [Broker registerEntityNamed:withPrimaryKey:andMapNetworkProperties:toLocalProperties]
 */
- (void)mapNetworkProperties:(NSArray *)networkProperties
           toLocalProperties:(NSArray *)localProperties
                   forEntity:(NSString *)entity;

/** @name Processing */

/**
 Processes a JSON payload returned from an API onto the target entity.
 
 @param jsonPayload The data returned from the API
 @param objectID The URI representation of the managed object to process the
 JSON for
 @param completionBlock The block to run when the operation is complete
 */
- (void)processJSONPayload:(id)jsonPayload 
            targetObjectID:(NSManagedObjectID *)objectID
       withCompletionBlock:(void (^)())completionBlock;

/**
 Processes a JSON payload returned from an API onto the target entity.
 
 @param jsonPayload The data returned from the API
 @param objectID The URI representation of the managed object to process the
 JSON for
 @param FilterBlock A block passed in to apply to the incoming JSON before
 any processing takes place.
 @param completionBlock The block to run when the operation is complete
 */
- (void)processJSONPayload:(id)jsonPayload
            targetObjectID:(NSManagedObjectID *)objectID
        JSONPreFilterBlock:(id (^)())FilterBlock
       withCompletionBlock:(void (^)())completionBlock;

/**
 Process a JSON payload returned from an API for a given relationship on an entity.
 You might have a Department with many Employees.  If your Department object has
 a method called getEmployees, it would hit the API and return a chunk of JSON that
 is a list of Employees.  In that case, you would call
 
 [myBrokerInstance processJSONPayload:apiJSONData targetEntity:departmentURI forRelationship:@"employees" withCompletionBlock:myBlock]
 
 @param jsonPayload The data returned from the API
 @param objectID The URI representation of the managed object to process the
 JSON for
 @param relationshipName The name of the relationship on the entity to recieve the
 processed JSON objects
 @param completionBlock The block to run when the operation is complete
 */
- (void)processJSONPayload:(id)jsonPayload 
            targetObjectID:(NSManagedObjectID *)objectID
           forRelationship:(NSString *)relationshipName
       withCompletionBlock:(void (^)())completionBlock;

/**
 Process a JSON payload returned from an API for a given relationship on an entity.
 The JSON pre filter block will allow you to massage and returned JSON before it
 is processed into Core Data objects.  You may want to remove some entities based
 on some logic, for example.

 @see [Broker processJSONPayload:targetEntity:forRelationship:withCompletionBlock:]
 */
- (void)processJSONPayload:(id)jsonPayload
            targetObjectID:(NSManagedObjectID *)objectID
           forRelationship:(NSString *)relationshipName
        JSONPreFilterBlock:(id (^)())filterBlock
       withCompletionBlock:(void (^)())completionBlock;

/**
 Process a JSON payload returned from an API as a collection of a particluar
 type of entity.
 
 @see [Broker processJSONPayload:asCollectionOfEntitiesNamed:JSONPreFilterBlock:withCompletionBlock]
 */
- (void)processJSONPayload:(id)jsonPayload 
asCollectionOfEntitiesNamed:(NSString *)entityName 
       withCompletionBlock:(void (^)())completionBlock;

/**
 Process a JSON payload returned from an API as a collection of a particluar
 type of entity and run a JSON pre filter on the payload before processing.
 
 @see [Broker processJSONPayload:asCollectionOfEntitiesNamed:JSONPreFilterBlock:withCompletionBlock]
 */
- (void)processJSONPayload:(id)jsonPayload 
asCollectionOfEntitiesNamed:(NSString *)entityName
        JSONPreFilterBlock:(id (^)())filterBlock
       withCompletionBlock:(void (^)())completionBlock;

/**
 Process a JSON payload returned from an API as a collection of a particluar
 type of entity and run a JSON pre filter on the payload before processing.
 
 @param jsonPayload The data returned from the API
 @param entityName The name of the objects in the returned collection
 @param FilterBlock A block passed in to apply to the incoming JSON before
 any processing takes place.
 @param deleteStaleEntities If YES, Broker will delete all entities of the type specified
 by entityName that were not included in the jsonPayload.  This is useful if you
 want to delete objects when you get an empty JSON response.
 @param CompletionBlock The block to run when the operation is complete
 */
- (void)processJSONPayload:(id)jsonPayload 
asCollectionOfEntitiesNamed:(NSString *)entityName
        JSONPreFilterBlock:(id (^)())filterBlock
     contextDidChangeBlock:(void (^)())didChangeBlock
            emptyJSONBlock:(void (^)())emptyJSONBlock
       withCompletionBlock:(void (^)())completionBlock;

/** @name Accessors */

- (BKEntityPropertiesDescription *)entityPropertyDescriptionForEntityName:(NSString *)entityName;

- (BKAttributeDescription *)attributeDescriptionForProperty:(NSString *)attribute 
                                               onEntityName:(NSString *)entityName;

- (BKRelationshipDescription *)relationshipDescriptionForProperty:(NSString *)relationship 
                                                     onEntityName:(NSString *)entityName;

- (BKEntityPropertiesDescription *)destinationEntityPropertiesDescriptionForRelationship:(NSString *)relationship
                                                                           onEntityNamed:(NSString *)entityName;

/** @name Private */

- (NSDictionary *)transformJSONDictionary:(NSDictionary *)jsonDictionary 
         usingEntityPropertiesDescription:(BKEntityPropertiesDescription *)entityMap;

@end
