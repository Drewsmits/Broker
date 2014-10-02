//
//  BKController.m
//  Broker
//
//  Created by Andrew Smith on 1/8/14.
//  Copyright (c) 2014 Andrew B. Smith. All rights reserved.
//

#import "BKController.h"

#import "BKEntityMap.h"
#import "BKJSONController.h"
#import "BKEntityDescription.h"
#import "BKAttributeDescription.h"
#import "BrokerLog.h"

#define BROKER_INTERNAL_QUEUE @"com.broker.queue"

@interface BKController ()

@property (nonatomic, strong, readwrite) BKEntityMap *entityMap;

/**
 Internal serial queue for core data processing off the main thread.
 */
@property (nonatomic, strong) NSOperationQueue *queue;

@end

@implementation BKController

+ (instancetype)controller
{
    BKController *controller = [self new];
    
    //
    // Entity Map
    //
    BKEntityMap *entityMap = [BKEntityMap entityMap];
    controller.entityMap = entityMap;
    
    //
    // Serial queue
    //
    NSOperationQueue *queue = [NSOperationQueue new];
    queue.maxConcurrentOperationCount = 1;
    controller.queue = queue;
    
    return controller;
}

#pragma mark BKJSONController

- (void)processJSONObject:(NSDictionary *)json
            asEntityNamed:(NSString *)entityName
                inContext:(NSManagedObjectContext *)context
          completionBlock:(void (^)())completionBlock
{
    NSOperation *operation = [self operationForContext:context
                                                  JSON:json
                                         withJSONBlock:^(id jsonCopy,
                                                         NSManagedObjectContext *backgroundContext,
                                                         BKJSONController *jsonController) {
                                             [jsonController processJSONObject:json
                                                                 asEntityNamed:entityName];
                                         }];
    
    // Finish
    operation.completionBlock = completionBlock;
    
    // Queue it up
    [self.queue addOperation:operation];
}

- (void)processJSONObject:(NSDictionary *)json
                 onObject:(NSManagedObject *)object
          completionBlock:(void (^)())completionBlock
{
    
}

- (void)processJSON:(id)json
    forRelationship:(NSString *)relationshipName
           onObject:(NSManagedObject *)object
    completionBlock:(void (^)())completionBlock
{
    NSManagedObjectID *objectId = object.objectID;
    
    // Operation
    NSOperation *operation = [self operationForContext:object.managedObjectContext
                                                  JSON:json
                                         withJSONBlock:^(id jsonCopy,
                                                         NSManagedObjectContext *backgroundContext,
                                                         BKJSONController *jsonController) {
                                             NSManagedObject *backgroundObject = [backgroundContext objectWithID:objectId];
                                             [jsonController processJSON:json
                                                         forRelationship:relationshipName
                                                                onObject:backgroundObject];
                                         }];
    
    // Finish
    operation.completionBlock = completionBlock;
    
    // Queue it up
    [self.queue addOperation:operation];
}

- (void)processJSONCollection:(NSArray *)json
              asEntitiesNamed:(NSString *)entityName
                    inContext:(NSManagedObjectContext *)context
              completionBlock:(void (^)())completionBlock
{
    // Operation
    NSOperation *operation = [self operationForContext:context
                                                  JSON:json
                                         withJSONBlock:^(id jsonCopy,
                                                         NSManagedObjectContext *backgroundContext,
                                                         BKJSONController *jsonController) {
                                             [jsonController processJSONCollection:json
                                                                   asEntitiesNamed:entityName];
                                         }];
    
    // Finish
    operation.completionBlock = completionBlock;
    
    // Queue it up
    [self.queue addOperation:operation];
}

- (void)processJSON:(id)json
          workBlock:(void (^)(id jsonCopy, NSManagedObjectContext *childContext, BKJSONController *jsonController))workBlock
          inContext:(NSManagedObjectContext *)context
    completionBlock:(void (^)())completionBlock
{
    // Operation
    NSOperation *operation = [self operationForContext:context
                                                  JSON:json
                                         withJSONBlock:workBlock];
    
    // Finish
    operation.completionBlock = completionBlock;
    
    // Queue it up
    [self.queue addOperation:operation];
}

#pragma mark -

- (NSOperation *)operationForContext:(NSManagedObjectContext *)context
                                JSON:(id)json
                       withJSONBlock:(void (^)(id jsonCopy,
                                               NSManagedObjectContext *childContext,
                                               BKJSONController *jsonController))block
{
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        // Background context
        NSManagedObjectContext *backgroundContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        backgroundContext.parentContext = context;
        
        // Memory optimization
        backgroundContext.undoManager = nil;
        
        // Grab a new JSON controller
        BKJSONController *jsonController = [BKJSONController JSONControllerWithContext:backgroundContext
                                                                             entityMap:self.entityMap];
        
        // Perform work
        id jsonCopy = [json copy];
        if (block) block(jsonCopy, backgroundContext, jsonController);
        
        // Save background context. Does not automatically save parent context.
        NSError *error;
        [backgroundContext save:&error];
        if (error) {
            BrokerLog(@"%@", error.localizedDescription);
        }
    }];

    return operation;
}

@end
