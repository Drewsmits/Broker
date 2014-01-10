//
//  BKEntityPropertiesDescription.m
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

#import "BKEntityDescription.h"
#import "BKAttributeDescription.h"

@interface BKEntityDescription ()

@property (nonatomic, strong, readwrite) NSEntityDescription *internalEntityDescription;

/**
 Keys are property names, values are BKAttributeDescription
 */
@property (nonatomic, strong) NSMutableDictionary *propertiesDescriptions;

/**
 Dictionary used for fast key finding
 */
@property (nonatomic, strong, readwrite) NSMutableDictionary *networkToLocalPropertiesMap;

/**
 Dictionary used for fast key finding
 */
@property (nonatomic, strong, readwrite) NSMutableDictionary *localToNetworkPropertiesMap;

@end

@implementation BKEntityDescription

- (id)init
{
    self = [super init];
    if (self) {
        _networkToLocalPropertiesMap = [[NSMutableDictionary alloc] init];
        _localToNetworkPropertiesMap = [[NSMutableDictionary alloc] init];
    }
    return self;
}

+ (instancetype)descriptionForObject:(NSManagedObject *)object
{
    BKEntityDescription *entityDescription = [BKEntityDescription new];
    entityDescription.internalEntityDescription = object.entity;
    
    //
    // Iterate through all properties and add to properties description.
    //
    NSMutableDictionary *tempPropertiesDescriptions = [[NSMutableDictionary alloc] init];
    NSDictionary *propertiesByName = entityDescription.internalEntityDescription.propertiesByName;
    
    for (NSString *propertyName in propertiesByName) {
        
        //
        // It's either an NSAttributeDescription or an NSRelationshipDescription
        //
        id description = [propertiesByName objectForKey:propertyName];
        
        //
        // Attribute
        //
        if ([description isKindOfClass:[NSAttributeDescription class]]) {
            BKAttributeDescription *attrDescription = [BKAttributeDescription descriptionWithAttributeDescription:description];
            [tempPropertiesDescriptions setObject:attrDescription
                                           forKey:propertyName];
        }
        
        //
        // Relationship
        //
        if ([description isKindOfClass:[NSRelationshipDescription class]]) {
            NSRelationshipDescription *relationshipDescription = description;
            [tempPropertiesDescriptions setObject:relationshipDescription
                                           forKey:propertyName];
        }
    }
    
    //
    // Set property descriptions
    //
    entityDescription.propertiesDescriptions = tempPropertiesDescriptions;
        
    return entityDescription;
}

#pragma mark - Modifiers

- (void)mapNetworkProperties:(NSArray *)networkProperties
           toLocalProperties:(NSArray *)localProperties
{
    NSAssert((networkProperties.count == localProperties.count),
             @"Mapping network properties to local properties expects arrays of the same size");
    
    if (!networkProperties || !localProperties) return;
    if (networkProperties.count != localProperties.count) return;
    
    for (int i = 0; i < localProperties.count; i++) {
        
        NSString *localProperty   = [localProperties objectAtIndex:i];
        NSString *networkProperty = [networkProperties objectAtIndex:i];
        
        if (localProperties && networkProperties) {
            [self.networkToLocalPropertiesMap setValue:localProperty forKey:networkProperty];
            [self.localToNetworkPropertiesMap setValue:networkProperty forKey:localProperty];
        }
    }
}

#pragma mark - Accessors

- (NSPropertyDescription *)descriptionForProperty:(NSString *)property
{
    NSPropertyDescription *desc = self.propertiesDescriptions[property];
    if (!desc) {
        BrokerLog(@"No description for property \"%@\" found on entity \"%@\"!  It's not in your data model.",
                  property,
                  self.internalEntityDescription.name);
    }
    return desc;
}

- (BKAttributeDescription *)attributeDescriptionForProperty:(NSString *)property
{
    id description = [self descriptionForProperty:property];
    if (description && [description isKindOfClass:[BKAttributeDescription class]]) {
        return description;
    } else {
        BrokerLog(@"No description for property \"%@\" found on entity \"%@\"!  It's not in your data model.",
                  property,
                  self.internalEntityDescription.name);
        return nil;
    }
}

- (NSRelationshipDescription *)relationshipDescriptionForProperty:(NSString *)property
{
    id description = [self.propertiesDescriptions objectForKey:property];
    
    if (description && [description isKindOfClass:[NSRelationshipDescription class]]) {
        return description;
    } else {
        return nil;
    }
}

- (BOOL)isPropertyRelationship:(NSString *)property
{
    id description = [self.propertiesDescriptions objectForKey:property];
    return (description && [description isKindOfClass:[NSRelationshipDescription class]]);
}

#pragma mark - Transform

- (id)objectFromValue:(id)value
          forProperty:(NSString *)property
{
    // Get the property description
    NSPropertyDescription *propertyDescription = [self descriptionForProperty:property];
    
    // Test to see if networkProperty is relationship or attribute
    if ([self isPropertyRelationship:property]) {
        // Pass the value through for later processing
        return value;
    } else {
        // transform it using the attribute desc
        id valueAsObject = [(BKAttributeDescription *)propertyDescription objectForValue:value];
        return valueAsObject;
    }
}

- (id)primaryKeyForJSON:(NSDictionary *)JSON
{
    if (!self.primaryKey) return nil;
    NSString *networkPrimaryKey = [self networkPropertyNameForProperty:self.primaryKey];
    id value = JSON[networkPrimaryKey];
    id object = [self objectFromValue:value
                          forProperty:self.primaryKey];
    return object;
}

- (NSString *)localPropertyNameForProperty:(NSString *)property
{
    NSString *localPropertyName = self.networkToLocalPropertiesMap[property];
    return localPropertyName ? localPropertyName : property;
}

- (NSString *)networkPropertyNameForProperty:(NSString *)property
{
    NSString *networkPropertyName = self.localToNetworkPropertiesMap[property];
    return networkPropertyName ? networkPropertyName : property;
}

@end
