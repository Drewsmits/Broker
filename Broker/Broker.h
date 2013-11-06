//
//  Broker.h
//  Broker
//
//  Created by Andrew Smith on 10/25/13.
//  Copyright (c) 2013 Andrew B. Smith. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BKEntityMap;

@interface Broker : NSObject

@property (nonatomic, strong, readonly) BKEntityMap *entityMap;

+ (instancetype)broker;

- (void)processJSONObject:(NSDictionary *)json
            asEntityNamed:(NSString *)entityName
                inContext:(NSManagedObjectContext *)context
          completionBlock:(void (^)())completionBlock;

- (void)processJSON:(id)json
    forRelationship:(NSString *)relationshipName
           onObject:(NSManagedObject *)object
          inContext:(NSManagedObjectContext *)context
    completionBlock:(void (^)())completionBlock;

- (void)processJSONCollection:(NSArray *)json
              asEntitiesNamed:(NSString *)entityName
                    inContext:(NSManagedObjectContext *)context
              completionBlock:(void (^)())completionBlock;

@end
