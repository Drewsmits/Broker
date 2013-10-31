//
//  Broker.m
//  Broker
//
//  Created by Andrew Smith on 10/25/13.
//  Copyright (c) 2013 Andrew B. Smith. All rights reserved.
//

#import "Broker.h"

#import "BKEntityMap.h"
#import "BKJSONController.h"

#import "BKEntityDescription.h"
#import "BKAttributeDescription.h"

#import "BKJSONOperation.h"

#define BROKER_INTERNAL_QUEUE @"com.broker.queue"

@interface Broker ()

@property (nonatomic, strong, readwrite) BKEntityMap *entityMap;

@property (nonatomic, strong, readwrite) BKJSONController *jsonController;

@end

@implementation Broker

+ (instancetype)broker
{
    Broker *broker = [self new];
    
    BKEntityMap *entityMap = [BKEntityMap entityMap];
    broker.entityMap = entityMap;
    
    CDOperationQueue *queue = [CDOperationQueue queueWithName:BROKER_INTERNAL_QUEUE];
    [queue setMaxConcurrentOperationCount:1];
    [broker addQueue:queue];
    
    return broker;
}

#pragma mark BKJSONController

- (void)processJSONObject:(NSDictionary *)json
            asEntityNamed:(NSString *)entityName
                inContext:(NSManagedObjectContext *)context
          completionBlock:(void (^)())completionBlock
{
    NSManagedObjectContext *childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    childContext.parentContext = context;
    
    __weak typeof(self) weakBroker = self;
    [childContext performBlock:^{
        __strong typeof(self) strongBroker = weakBroker;
       
        BKJSONController *jsonController = [BKJSONController JSONControllerWithContext:childContext
                                                                             entityMap:strongBroker.entityMap];
       
        [jsonController processJSONObject:json
                            asEntityNamed:entityName];
        
        [childContext save:nil];
        
        if (completionBlock) completionBlock();
    }];
}

- (void)processJSON:(id)json
    forRelationship:(NSString *)relationshipName
           onObject:(NSManagedObject *)object
          inContext:(NSManagedObjectContext *)context
{
    
}

- (void)processJSONCollection:(NSArray *)json
              asEntitiesNamed:(NSString *)entityName
                    inContext:(NSManagedObjectContext *)context
{
    
}

@end
