//
//  BKTestAppStore.h
//  BrokerTestApp
//
//  Created by Andrew Smith on 11/7/13.
//  Copyright (c) 2013 Andrew B. Smith. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BKTestAppStore : NSObject

@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;

- (void)reset:(NSError *)error;

@end
