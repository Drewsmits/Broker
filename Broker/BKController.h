//
//  BKController.h
//  Broker
//
//  Created by Andrew Smith on 1/8/14.
//  Copyright (c) 2014 Andrew B. Smith. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BKEntityMap;

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

@end
