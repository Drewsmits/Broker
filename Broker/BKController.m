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
    __weak typeof(self) weakBroker = self;
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        __strong typeof(self) strongBroker = weakBroker;
        
        // Background context
        NSManagedObjectContext *childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        childContext.parentContext = context;
        
        BKJSONController *jsonController = [BKJSONController JSONControllerWithContext:childContext
                                                                             entityMap:strongBroker.entityMap];
        
        [jsonController processJSONObject:json
                            asEntityNamed:entityName];
        
        [childContext save:nil];
    }];
    
    // Finish
    operation.completionBlock = completionBlock;
    
    // Queue it up
    [self.queue addOperation:operation];
}

- (void)processJSON:(id)json
    forRelationship:(NSString *)relationshipName
           onObject:(NSManagedObject *)object
          inContext:(NSManagedObjectContext *)context
    completionBlock:(void (^)())completionBlock
{
    NSManagedObjectID *objectId = object.objectID;
    
    __weak typeof(self) weakBroker = self;
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        __strong typeof(self) strongBroker = weakBroker;
        
        // Background context
        NSManagedObjectContext *childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        childContext.parentContext = context;
        
        // Fetch object from background child context
        NSManagedObject *backgroundObject = [childContext objectWithID:objectId];
        
        // Grab a new JSON controller
        BKJSONController *jsonController = [BKJSONController JSONControllerWithContext:childContext
                                                                             entityMap:strongBroker.entityMap];
        
        // Process
        [jsonController processJSON:json
                    forRelationship:relationshipName
                           onObject:backgroundObject];
        
        // Save
        [childContext save:nil];
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
    __weak typeof(self) weakBroker = self;
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        __strong typeof(self) strongBroker = weakBroker;
        
        // Background context
        NSManagedObjectContext *childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        childContext.parentContext = context;
        
        // Grab a new JSON controller
        BKJSONController *jsonController = [BKJSONController JSONControllerWithContext:childContext
                                                                             entityMap:strongBroker.entityMap];
        
        // Process
        [jsonController processJSONCollection:json
                              asEntitiesNamed:entityName];
        
        // Save
        [childContext save:nil];
    }];
    
    // Finish
    operation.completionBlock = completionBlock;
    
    // Queue it up
    [self.queue addOperation:operation];
}

@end
