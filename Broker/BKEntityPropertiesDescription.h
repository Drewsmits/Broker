//
//  BKEntityPropertiesMap.h
//  Broker
//
//  Created by Andrew Smith on 10/6/11.
//  Copyright (c) 2011 Andrew B. Smith. All rights reserved.
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

#import "BKAttributeDescription.h"
#import "BKRelationshipDescription.h"
#import "BKEntityPropertiesMap.h"

@interface BKEntityPropertiesDescription : NSObject {
@private
    NSString *entityName;
    NSString *primaryKey;
    NSString *rootKeyPath;
    NSMutableDictionary *propertiesDescriptions;
    BKEntityPropertiesMap *propertiesMap;
    NSEntityDescription *entityDescription;
}

/**
 * The name of the entity, capitalized.
 */
@property (readonly, nonatomic, copy) NSString *entityName;

/**
 * The name of the property used as the entity's primary key.  This needs to be
 * a guaranteed unique property, like "employeeID," which can be used to 
 * positively identify a specific entity in the store.
 */
@property (nonatomic, copy) NSString *primaryKey;

/**
 * The root key path used to when returned JSON is a nested resource
 */
@property (nonatomic, copy) NSString *rootKeyPath;

/**
 *
 */
@property (readonly, nonatomic, retain) NSMutableDictionary *propertiesDescriptions;
@property (readonly, nonatomic, retain) BKEntityPropertiesMap *propertiesMap;
@property (readonly, nonatomic, retain) NSEntityDescription *entityDescription;

/**
 * Creates a new BKEntityPropertiesDescription where the entityName is the name 
 * of the entity, the properties is the
 */
+ (BKEntityPropertiesDescription *)descriptionForEntity:(NSEntityDescription *)entity 
                                   withPropertiesByName:(NSDictionary *)properties
                                andMapNetworkProperties:(NSArray *)networkProperties
                                      toLocalProperties:(NSArray *)localProperties;

/**
 * Returns the entity's property description for the local property name
 */
- (BKPropertyDescription *)descriptionForLocalProperty:(NSString *)property;

/**
 * Returns the entity's property description for the network property name
 */
- (BKPropertyDescription *)descriptionForNetworkProperty:(NSString *)property;

/**
 * Returns the entity's attribute description for the local property name
 */
- (BKAttributeDescription *)attributeDescriptionForLocalProperty:(NSString *)property;

/**
 * Returns the attribute description for the network property name on the entity.
 * Returns nil if property not in model, or if property is not a attribute.
 */
- (BKAttributeDescription *)attributeDescriptionForNetworkProperty:(NSString *)property;

/**
 * Returns the relationship description for the local property relationship name
 * on the entity.  Returns nil if property is not in the model, or if property is
 * not a relationship.
 */
- (BKRelationshipDescription *)relationshipDescriptionForProperty:(NSString *)property;

/**
 * Returns true if the property is a relationship
 */
- (BOOL)isPropertyRelationship:(NSString *)property;

/**
 * Returns the destination entity name for the relationship name
 */
- (NSString *)destinationEntityNameForRelationship:(NSString *)relationship;

@end
