//
//  BKJSONController.h
//  Broker
//
//  Created by Andrew Smith on 10/24/13.
//  Copyright (c) 2013 Andrew B. Smith. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BKEntityController;

@interface BKJSONController : NSObject

@property (nonatomic, strong) NSManagedObjectContext *context;

@property (nonatomic, strong) BKEntityController *entityController;

+ (instancetype)JSONControllerWithContext:(NSManagedObjectContext *)context
                         entityController:(BKEntityController *)entityController;

- (NSManagedObject *)processJSONObject:(NSDictionary *)json
                         asEntityNamed:(NSString *)entityName;

@end
