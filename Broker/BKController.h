//
//  BKController.h
//  Broker
//
//  Created by Andrew Smith on 1/8/14.
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

@class BKEntityMap, BKJSONController;

@interface BKController : NSObject

@property (nonatomic, strong, readonly) BKEntityMap *entityMap;

+ (instancetype)controller;

- (void)processJSONObject:(NSDictionary *)json
            asEntityNamed:(NSString *)entityName
                inContext:(NSManagedObjectContext *)context
          completionBlock:(void (^)())completionBlock;

- (void)processJSON:(id)json
    forRelationship:(NSString *)relationshipName
           onObject:(NSManagedObject *)object
    completionBlock:(void (^)())completionBlock;

- (void)processJSONCollection:(NSArray *)json
              asEntitiesNamed:(NSString *)entityName
                    inContext:(NSManagedObjectContext *)context
              completionBlock:(void (^)())completionBlock;

/**
 *  Allows more flexibility in processing JSON. The workBlock is executed in 
 *  the background, with a childContext spun up fron the provided context. Use
 *  this if you want to do some custom stuff while working with your JSON.
 *
 *  @param json            JSON input
 *  @param workBlock       The work to be performed in the background
 *  @param context         The main context
 *  @param completionBlock The completion block to be run after everything is complete
 */
- (void)processJSON:(id)json
          workBlock:(void (^)(NSManagedObjectContext *childContext, BKJSONController *jsonController))workBlock
          inContext:(NSManagedObjectContext *)context
    completionBlock:(void (^)())completionBlock;

@end
