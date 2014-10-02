//
//  BKEntityController.m
//  Broker
//
//  Created by Andrew Smith on 6/6/13.
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

#import "BKEntityMap.h"
#import "BKEntityDescription.h"

// Catagories
#import "NSManagedObjectContext+Broker.h"

@interface BKEntityMap ()

@property (nonatomic, strong, readwrite) NSMutableDictionary *entityDescriptions;

@end

@implementation BKEntityMap

+ (instancetype)entityMap
{
    BKEntityMap *map = [self new];
    map.entityDescriptions = [NSMutableDictionary dictionary];
    return map;
}

- (void)registerEntityNamed:(NSString *)entityName
             withPrimaryKey:(NSString *)primaryKey
    andMapNetworkProperties:(NSArray *)networkProperties
          toLocalProperties:(NSArray *)localProperties
                  inContext:(NSManagedObjectContext *)context
{
    __block BKEntityDescription *description;
    [context performBlockAndWait:^{
        //
        // Create new temp object
        //
        NSManagedObject *object = [NSEntityDescription insertNewObjectForEntityForName:entityName
                                                                inManagedObjectContext:context];
        
        //
        // Build description of entity properties
        //
        description = [BKEntityDescription descriptionForObject:object];
        
        //
        // Map property names
        //
        [description mapNetworkProperties:networkProperties
                        toLocalProperties:localProperties];
                
        //
        // Set primary key
        //
        description.primaryKey = primaryKey;
        
        //
        // Cleanup
        //
        [context deleteObject:object];
    }];
    
    @synchronized (self.entityDescriptions) {
        [self.entityDescriptions setObject:description
                                    forKey:entityName];
    }
}

- (void)setDateFormat:(NSString *)dateFormat
          forProperty:(NSString *)property
             onEntity:(NSString *)entity
{
    BKEntityDescription *description = [self entityDescriptionForEntityName:entity];
    BKAttributeDescription *attributeDescription = [description attributeDescriptionForProperty:property];
    [attributeDescription setDateFormat:dateFormat];
}

#pragma mark -

- (BKEntityDescription *)entityDescriptionForEntityName:(NSString *)entityName
{
    BKEntityDescription *entityDescription = [self.entityDescriptions objectForKey:entityName];
    NSAssert(entityDescription,
             @"Could not find entityDescription for entity named \"%@\". Did you\
             register it with this controller?", entityName);
    return entityDescription;
}

@end
