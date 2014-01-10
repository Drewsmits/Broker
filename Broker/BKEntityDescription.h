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
//
///**
// Dictionary used for fast key finding
// */
//@property (nonatomic, strong) NSMutableDictionary *localToNetworkPropertiesMap;

/**
 Creates a new BKEntityPropertiesDescription
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
 Returns the entity's attribute description for the property
 */
- (BKAttributeDescription *)attributeDescriptionForProperty:(NSString *)property;

/**
  Returns the relationship description for the local property relationship name
  on the entity.  Returns nil if property is not in the model, or if property is
  not a relationship.
 */
- (NSRelationshipDescription *)relationshipDescriptionForProperty:(NSString *)property;

/**
  Returns true if the property is a relationship
 */
- (BOOL)isPropertyRelationship:(NSString *)property;

- (id)objectFromValue:(id)value
          forProperty:(NSString *)property;

- (id)primaryKeyForJSON:(NSDictionary *)JSON;

- (NSString *)localPropertyNameForProperty:(NSString *)property;

- (NSString *)networkPropertyNameForProperty:(NSString *)property;

@end
