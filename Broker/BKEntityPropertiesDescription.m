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

#import "BKEntityPropertiesDescription.h"
#import <CoreData/CoreData.h>

#import "BKAttributeDescription.h"
#import "BKRelationshipDescription.h"

@implementation BKEntityPropertiesDescription

- (id)init
{
    self = [super init];
    if (self) {
        _networkToLocalPropertiesMap = [[NSMutableDictionary alloc] init];
        _localToNetworkPropertiesMap = [[NSMutableDictionary alloc] init];
    }
    return self;
}

+ (BKEntityPropertiesDescription *)descriptionForEntity:(NSEntityDescription *)entity 
                                   withPropertiesByName:(NSDictionary *)properties
                                andMapNetworkProperties:(NSArray *)networkProperties
                                      toLocalProperties:(NSArray *)localProperties
{    
    // Build initial description
    BKEntityPropertiesDescription *propertiesDescription = [BKEntityPropertiesDescription new];
    
    propertiesDescription.entityDescription = entity;
    propertiesDescription.entityName = entity.name;
    
    NSMutableDictionary *tempPropertiesDescriptions = [[NSMutableDictionary alloc] init];
    
    // For each property, create a property description
    for (NSString *property in properties) {
        
        // Either an NSAttributeDescription or an NSRelationshipDescription
        id description = [properties objectForKey:property];
        
        //
        // Attribute
        //
        if ([description isKindOfClass:[NSAttributeDescription class]]) {
            BKAttributeDescription *attrDescription = description;
            attrDescription.networkPropertyName = [propertiesDescription.localToNetworkPropertiesMap valueForKey:property];
            [tempPropertiesDescriptions setObject:attrDescription forKey:property];
        }
        
        //
        // Relationship
        //
        if ([description isKindOfClass:[NSRelationshipDescription class]]) {
            BKRelationshipDescription *relationshipDescription = 
                    [BKRelationshipDescription descriptionWithRelationshipDescription:(NSRelationshipDescription *)description];            
            [tempPropertiesDescriptions setObject:relationshipDescription forKey:property];
        }
    }
    
    //
    // Set property descriptions
    //
    propertiesDescription.propertiesDescriptions = tempPropertiesDescriptions;
    
    //
    // Map any network properties to local properties
    //
    [propertiesDescription mapNetworkProperties:networkProperties
                              toLocalProperties:localProperties];
    
    return propertiesDescription;
}

#pragma mark - Modifiers

- (void)mapNetworkProperties:(NSArray *)networkProperties
           toLocalProperties:(NSArray *)localProperties
{
    NSAssert((networkProperties.count == localProperties.count), @"Mapping network properties to local properties expects arrays of the same size");
    
    if (networkProperties.count != localProperties.count) return;
    if (!networkProperties || !localProperties) return;
    
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
    
    if (!desc) {BrokerLog(@"No description for property \"%@\" found on entity \"%@\"!  It's not in your data model.", property, self.entityName);}

    return desc;
}

- (NSPropertyDescription *)descriptionForLocalProperty:(NSString *)property
{
    return (NSPropertyDescription *)[self.propertiesDescriptions objectForKey:property];
}

- (NSPropertyDescription *)descriptionForNetworkProperty:(NSString *)property
{    
    NSPropertyDescription *desc = [self descriptionForLocalProperty:[self.networkToLocalPropertiesMap objectForKey:property]];
    if (!desc) {
        BrokerLog(@"\"%@\" is not a known network property on entity \"%@\"", property, self.entityName);
        return nil;
    }
    
    return desc;
}

- (NSAttributeDescription *)attributeDescriptionForProperty:(NSString *)property
{
    id description = [self descriptionForProperty:property];
    if (description && [description isKindOfClass:[BKAttributeDescription class]]) {
        return (BKAttributeDescription *)description;
    } else {
        return nil;
    }
}

- (NSAttributeDescription *)attributeDescriptionForLocalProperty:(NSString *)property
{
    id description = [self descriptionForLocalProperty:property];
    if (description && [description isKindOfClass:[BKAttributeDescription class]]) {
        return (BKAttributeDescription *)description;
    } else {
        return nil;
    }
}

- (NSAttributeDescription *)attributeDescriptionForNetworkProperty:(NSString *)property
{
    id description = [self descriptionForNetworkProperty:property];
    if (description && [description isKindOfClass:[BKAttributeDescription class]]) {
        return (BKAttributeDescription *)description;
    } else {
        return nil;
    }
}

- (NSRelationshipDescription *)relationshipDescriptionForProperty:(NSString *)property
{
    id description = [self.propertiesDescriptions objectForKey:property];
    
    if (description && [description isKindOfClass:[NSRelationshipDescription class]]) {
        return (BKRelationshipDescription *)description;
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
