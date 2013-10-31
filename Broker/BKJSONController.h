//
//  BKJSONController.h
//  Broker
//
//  Created by Andrew Smith on 10/24/13.
//  Copyright (c) 2013 Andrew B. Smith. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BKEntityMap;

@interface BKJSONController : NSObject

@property (nonatomic, strong) NSManagedObjectContext *context;

@property (nonatomic, strong) BKEntityMap *entityMap;

+ (instancetype)JSONControllerWithContext:(NSManagedObjectContext *)context
                                entityMap:(BKEntityMap *)entityMap;

- (NSManagedObject *)processJSONObject:(NSDictionary *)json
                         asEntityNamed:(NSString *)entityName;

- (NSArray *)processJSONCollection:(NSArray *)json
                   asEntitiesNamed:(NSString *)entityName;

- (void)processJSON:(id)json
    forRelationship:(NSString *)relationshipName
           onObject:(NSManagedObject *)object;

@end
