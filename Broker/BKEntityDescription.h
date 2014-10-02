//
//  BKEntityPropertiesDescription.h
//  Broker
//
//  Created by Andrew Smith on 10/6/11.
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

#import "BKAttributeDescription.h"

@interface BKEntityDescription : NSObject

/**
 The internal NSEntityDescription that is used to help map JSON to local properties.
 */
@property (nonatomic, strong, readonly) NSEntityDescription *internalEntityDescription;

/**
 The name of the property used as the entity's primary key.  This needs to be
 a guaranteed unique property, like "employeeID," which can be used to
 positively identify a specific entity in the store.
 */
@property (nonatomic, strong) NSString *primaryKey;

/**
 Dictionary used for fast key finding
 */
@property (nonatomic, strong, readonly) NSMutableDictionary *networkToLocalPropertiesMap;

/**
 Dictionary used for fast key finding
 */
@property (nonatomic, strong, readonly) NSMutableDictionary *localToNetworkPropertiesMap;

/**
 @returns A new BKEntityPropertiesDescription
 */
+ (instancetype)descriptionForObject:(NSManagedObject *)object;

/**
 Map several network properties to a local properties for an entity that is already 
 registered with Broker.
 
 @param networkProperties An array of network property names 
 @param localProperties An array of local property names that match with the
 networkProperties
 
 @see [Broker registerEntityNamed:withPrimaryKey:andMapNetworkProperties:toLocalProperties]
 */
- (void)mapNetworkProperties:(NSArray *)networkProperties
           toLocalProperties:(NSArray *)localProperties;

/**
  Returns the entity property description given the property name
 */
- (NSPropertyDescription *)descriptionForProperty:(NSString *)property;

/**
 @returns the entity's attribute description for the property
 */
- (BKAttributeDescription *)attributeDescriptionForProperty:(NSString *)property;

/**
  @returns the relationship description for the local property relationship name
  on the entity.  Returns nil if property is not in the model, or if property is
  not a relationship.
 */
- (NSRelationshipDescription *)relationshipDescriptionForProperty:(NSString *)property;

/**
  @returns true if the property is a relationship
 */
- (BOOL)isPropertyRelationship:(NSString *)property;

/**
 @returns the object from the input value for the given property. For instance, if you have an NSString property, "firstName"
 on an Employee object, the value that gets passed in will return the proper NSString object. This is a necessary step
 due to the fact that the value could be another nested object, or a relationship, or an NSSNumber that requires the
 correct type.
 */
- (id)objectFromValue:(id)value
          forProperty:(NSString *)property;

/**
 @returns the primary key value for the JSON. For instance, if you mapped set a primary key of "employeeId" on your Employee object
 when you registered it with a broker controller, this would return the "employeeId" field for the json, if present.
 */
- (id)primaryKeyForJSON:(NSDictionary *)JSON;

/**
 @returns the local property name for the property. This looks at the map you created of network property names to local
 properties and returns the local one. For instance, you may register "id" for your local property "employeeId". Passing
 in "id" would return "employeeId", allowing you to map remote JSON to local NSManagendObject properties.
 */
- (NSString *)localPropertyNameForProperty:(NSString *)property;


@end
