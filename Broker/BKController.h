//
//  BKController.h
//  Broker
//
//  Created by Andrew Smith on 1/8/14.
//  Copyright (c) 2014 Andrew B. Smith. All rights reserved.
//

#import <Foundation/Foundation.h>

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
