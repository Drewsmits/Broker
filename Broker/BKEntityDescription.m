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

+ (BKEntityDescription *)descriptionForObject:(NSManagedObject *)object
{
    BKEntityDescription *description = (BKEntityDescription *)[object.entity copy];
    
    //
    // Iterate through all properties and add to properties description.
    //
    NSMutableDictionary *tempPropertiesDescriptions = [[NSMutableDictionary alloc] init];
    NSDictionary *propertiesByName = description.propertiesByName;
    
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
                                           forKey:propertiesByName];
        }
        
        //
        // Relationship
        //
        if ([description isKindOfClass:[NSRelationshipDescription class]]) {
            NSRelationshipDescription *relationshipDescription = (NSRelationshipDescription *)[description copy];
            [tempPropertiesDescriptions setObject:relationshipDescription
                                           forKey:propertyName];
        }
    }
    
    //
    // Set property descriptions
    //
    description.propertiesDescriptions = tempPropertiesDescriptions;
        
    return description;
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
    NSPropertyDescription *desc = [self descriptionForLocalProperty:property];
    
    if (!desc) {
        desc = [self descriptionForNetworkProperty:property];
    }
    
    if (!desc) {
        BrokerLog(@"No description for property \"%@\" found on entity \"%@\"!  It's not in your data model.", property, self.name);
    }

    return desc;
}

- (NSPropertyDescription *)descriptionForLocalProperty:(NSString *)property
{
    return self.propertiesDescriptions[property];
}

- (NSPropertyDescription *)descriptionForNetworkProperty:(NSString *)networkProperty
{    
    NSString *localProperty     = self.networkToLocalPropertiesMap[networkProperty];
    NSPropertyDescription *desc = [self descriptionForLocalProperty:localProperty];

    if (!desc) {
        BrokerLog(@"\"%@\" is not a known network property on entity \"%@\"", networkProperty, self.name);
    }
    
    return desc;
}

- (BKAttributeDescription *)attributeDescriptionForProperty:(NSString *)property
{
    id description = [self descriptionForProperty:property];
    if (description && [description isKindOfClass:[BKAttributeDescription class]]) {
        return description;
    } else {
        return nil;
    }
}

- (BKAttributeDescription *)attributeDescriptionForLocalProperty:(NSString *)property
{
    id description = [self descriptionForLocalProperty:property];
    if (description && [description isKindOfClass:[BKAttributeDescription class]]) {
        return description;
    } else {
        return nil;
    }
}

- (BKAttributeDescription *)attributeDescriptionForNetworkProperty:(NSString *)property
{
    id description = [self descriptionForNetworkProperty:property];
    if (description && [description isKindOfClass:[BKAttributeDescription class]]) {
        return description;
    } else {
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
    
    if (description && [description isKindOfClass:[NSRelationshipDescription class]]) {
        return YES;
    } else {
        return NO;
    }
}

- (NSString *)destinationEntityNameForRelationship:(NSString *)relationship
{
    NSRelationshipDescription *desc = [self relationshipDescriptionForProperty:relationship];
    return desc.destinationEntity.name;
}

@end
