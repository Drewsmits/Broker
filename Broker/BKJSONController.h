//
//  BKJSONController.h
//  Broker
//
//  Created by Andrew Smith on 10/24/13.
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

@class BKEntityMap;

@interface BKJSONController : NSObject

@property (nonatomic, strong, readonly) NSManagedObjectContext *context;

@property (nonatomic, strong, readonly) BKEntityMap *entityMap;

/**
 Build a new JSON controller from the supplied context and entity map. The entity
 map must be previously built.
 */
+ (instancetype)JSONControllerWithContext:(NSManagedObjectContext *)context
                                entityMap:(BKEntityMap *)entityMap;

/**
 Process the json as the entity name indicated. This will look up the registered
 entity description and attempt to map the JSON key/value to an NSManagedObject.
 The NSManaged object will be found by looking up the registerd primary key. If
 no object is found, a new one will be created.
 @returns The object created or updated from the input json
 */
- (NSManagedObject *)processJSONObject:(NSDictionary *)json
                         asEntityNamed:(NSString *)entityName;

/**
 Process the JSON as a list of objects of the type indicated by the entity name.
 
 @returns An array of created or updated objects from the JSON array.
 */
- (NSArray *)processJSONCollection:(NSArray *)json
                   asEntitiesNamed:(NSString *)entityName;

/**
 Proces the JSON as a relationship object, which is either a to-one or to-many. 
 @param json the JSON to process
 @oaram relationshipName the name of the relationship on the object
 @param object the destination object for which the processed JSON is targeted for.
 */
- (void)processJSON:(id)json
    forRelationship:(NSString *)relationshipName
           onObject:(NSManagedObject *)object;

@end
