//
//  BKEntityPropertiesMap.m
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
@property (readwrite, nonatomic, retain) NSMutableDictionary *propertiesDescriptions;
@property (readwrite, nonatomic, retain) BKEntityPropertiesMap *propertiesMap;
@property (readwrite, nonatomic, retain) NSEntityDescription *entityDescription;
@end

@implementation BKEntityPropertiesDescription

@synthesize entityName,
            primaryKey,
            rootKeyPath,
            propertiesDescriptions,
            propertiesMap,
            entityDescription;

- (void)dealloc {
    [entityName release], entityName = nil;
    [primaryKey release], primaryKey = nil;
    [rootKeyPath release], rootKeyPath = nil;
    [propertiesDescriptions release], propertiesDescriptions = nil;
    [propertiesMap release], propertiesMap = nil;
    [entityDescription release], entityDescription = nil;
    
    [super dealloc];
}

+ (BKEntityPropertiesDescription *)descriptionForEntity:(NSEntityDescription *)entity 
                                   withPropertiesByName:(NSDictionary *)properties
                                andMapNetworkProperties:(NSArray *)networkProperties
                                      toLocalProperties:(NSArray *)localProperties {
    
    // Build initial description
    BKEntityPropertiesDescription *description = [[[BKEntityPropertiesDescription alloc] init] autorelease];
    description.entityDescription = entity;
    description.entityName = entity.name;
    
    // Map any network properties to local properties
    BKEntityPropertiesMap *map = [BKEntityPropertiesMap mapFromNetworkProperties:networkProperties
                                                               toLocalProperties:localProperties
                                                                   forEntityName:entity.name];
    
    NSMutableDictionary *tempPropertiesDescriptions = [[[NSMutableDictionary alloc] init] autorelease];
    
    // For each property, create a property description
    for (NSString *property in properties) {
        
        // Either an NSAttributeDescription or an NSRelationshipDescription
        id description = [properties objectForKey:property];
        
        // Attribute
        if ([description isKindOfClass:[NSAttributeDescription class]]) {
            BKAttributeDescription *attrDescription = [BKAttributeDescription descriptionWithAttributeDescription:(NSAttributeDescription *)description
                                                                                     andMapToNetworkAttributeName:[map networkPropertyNameForLocalProperty:property]];
                        
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
    description.propertiesDescriptions = tempPropertiesDescriptions;
    
    return description;
}

- (BKPropertyDescription *)descriptionForLocalProperty:(NSString *)property {
    return (BKPropertyDescription *)[self.propertiesDescriptions objectForKey:property];
}

- (BKPropertyDescription *)descriptionForNetworkProperty:(NSString *)property {
    __block id result = nil;
    
    [self.propertiesDescriptions enumerateKeysAndObjectsWithOptions:NSEnumerationConcurrent
                                                         usingBlock:^(id key, id obj, BOOL *stop) {
                                                             
                                                             BKPropertyDescription *description = [self descriptionForLocalProperty:key];
                                                             
                                                             if (description && [description.networkPropertyName isEqualToString:property]) {
                                                                 result = obj;
                                                                 *stop = YES;
                                                             }
                                                         }];
    
    if (!result) {
        DLog(@"\"%@\" is not a known network property on entity \"%@\"", property, self.entityName);
        return nil;
    }
    
    return (BKPropertyDescription *)result;
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

@end
