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

@interface BKEntityPropertiesDescription ()
@property (readwrite, nonatomic, copy) NSString *entityName;
@property (readwrite, nonatomic, strong) NSMutableDictionary *propertiesDescriptions;
@property (readwrite, nonatomic, strong) NSEntityDescription *entityDescription;
@end

@implementation BKEntityPropertiesDescription

@synthesize entityName,
            primaryKey,
            rootKeyPath,
            propertiesDescriptions,
            entityDescription;


+ (BKEntityPropertiesDescription *)descriptionForEntity:(NSEntityDescription *)entity 
                                   withPropertiesByName:(NSDictionary *)properties
                                andMapNetworkProperties:(NSArray *)networkProperties
                                      toLocalProperties:(NSArray *)localProperties {
    
    // Build initial description
    BKEntityPropertiesDescription *propertiesDescription = [[BKEntityPropertiesDescription alloc] init];
    propertiesDescription.entityDescription = entity;
    propertiesDescription.entityName = entity.name;
    
    NSMutableDictionary *tempPropertiesDescriptions = [[NSMutableDictionary alloc] init];
    
    // For each property, create a property description
    for (NSString *property in properties) {
        
        // Either an NSAttributeDescription or an NSRelationshipDescription
        id description = [properties objectForKey:property];
        
        // Attribute
        if ([description isKindOfClass:[NSAttributeDescription class]]) {
            BKAttributeDescription *attrDescription = [BKAttributeDescription descriptionWithAttributeDescription:(NSAttributeDescription *)description
                                                                                     andMapToNetworkAttributeName:[propertiesDescription.localToNetworkPropertiesMap valueForKey:property]];
                        
            [tempPropertiesDescriptions setObject:attrDescription forKey:property];
        }
        
        // Relationship
        if ([description isKindOfClass:[NSRelationshipDescription class]]) {
            BKRelationshipDescription *relationshipDescription = 
                    [BKRelationshipDescription descriptionWithRelationshipDescription:(NSRelationshipDescription *)description];            
            [tempPropertiesDescriptions setObject:relationshipDescription forKey:property];
        }
    }
    
    // Set property descriptions
    propertiesDescription.propertiesDescriptions = tempPropertiesDescriptions;
    
    // Map any network properties to local properties
    [propertiesDescription mapNetworkProperties:networkProperties 
                              toLocalProperties:localProperties];
    
    return propertiesDescription;
}

#pragma mark - Modifiers

- (void)mapNetworkProperties:(NSArray *)networkProperties
           toLocalProperties:(NSArray *)localProperties {

    NSAssert((networkProperties.count == localProperties.count), @"Mapping network properties to local properties expects arrays of the same size");
    
    if (networkProperties.count != localProperties.count) return;
    if (!networkProperties || !localProperties) return;
    
    for (NSString *networkProperty in networkProperties) {
        
        NSString *localProperty = [localProperties objectAtIndex:[networkProperties indexOfObject:networkProperty]];
        
        BKAttributeDescription *attrDescription = [self attributeDescriptionForProperty:localProperty];

        if (!attrDescription) 
            DLog(@"shmu?");
        
        [self.networkToLocalPropertiesMap setValue:localProperty forKey:networkProperty];
        
        [self.localToNetworkPropertiesMap setValue:networkProperty forKey:localProperty];
                
        if (attrDescription) {
            attrDescription.networkPropertyName = networkProperty;
        }
    }
}

#pragma mark - Accessors

- (BKPropertyDescription *)descriptionForProperty:(NSString *)property {
    BKPropertyDescription *desc = [self descriptionForLocalProperty:property];
    
    if (!desc) {
        desc = [self descriptionForNetworkProperty:property];
    }
    
    if (!desc) {DLog(@"No description for property \"%@\" found on entity \"%@\"!  It's not in your data model.", property, self.entityName);}

    return desc;
}

- (BKPropertyDescription *)descriptionForLocalProperty:(NSString *)property {
    return (BKPropertyDescription *)[self.propertiesDescriptions objectForKey:property];
}

- (BKPropertyDescription *)descriptionForNetworkProperty:(NSString *)property {
    
    BKPropertyDescription *desc = [self descriptionForLocalProperty:[self.networkToLocalPropertiesMap objectForKey:property]];
    if (!desc) {
        DLog(@"\"%@\" is not a known network property on entity \"%@\"", property, self.entityName);
        return nil;
    }
    
    return desc;
}

- (BKAttributeDescription *)attributeDescriptionForProperty:(NSString *)property {
    id description = [self descriptionForProperty:property];
    if (description && [description isKindOfClass:[BKAttributeDescription class]]) {
        return (BKAttributeDescription *)description;
    } else {
        return nil;
    }
}

- (BKAttributeDescription *)attributeDescriptionForLocalProperty:(NSString *)property {
    id description = [self descriptionForLocalProperty:property];
    if (description && [description isKindOfClass:[BKAttributeDescription class]]) {
        return (BKAttributeDescription *)description;
    } else {
        return nil;
    }
}

- (BKAttributeDescription *)attributeDescriptionForNetworkProperty:(NSString *)property {
    id description = [self descriptionForNetworkProperty:property];
    if (description && [description isKindOfClass:[BKAttributeDescription class]]) {
        return (BKAttributeDescription *)description;
    } else {
        return nil;
    }
}

- (BKRelationshipDescription *)relationshipDescriptionForProperty:(NSString *)property {
    id description = [self.propertiesDescriptions objectForKey:property];
    
    if (description && [description isKindOfClass:[BKRelationshipDescription class]]) {
        return (BKRelationshipDescription *)description;
    } else {
        return nil;
    }
}

- (BOOL)isPropertyRelationship:(NSString *)property {
    id description = [self.propertiesDescriptions objectForKey:property];
    
    if (description && [description isKindOfClass:[BKRelationshipDescription class]]) {
        return YES;
    } else {
        return NO;
    }
}

- (NSString *)destinationEntityNameForRelationship:(NSString *)relationship {
    BKRelationshipDescription *desc = [self relationshipDescriptionForProperty:relationship];
    return desc.destinationEntityName;
}

- (NSMutableDictionary *)networkToLocalPropertiesMap {
    if (networkToLocalPropertiesMap) return networkToLocalPropertiesMap;
    networkToLocalPropertiesMap = [[NSMutableDictionary alloc] init];
    return networkToLocalPropertiesMap;
}

- (NSMutableDictionary *)localToNetworkPropertiesMap {
    if (localToNetworkPropertiesMap) return localToNetworkPropertiesMap;
    localToNetworkPropertiesMap = [[NSMutableDictionary alloc] init];
    return localToNetworkPropertiesMap;
}

@end
