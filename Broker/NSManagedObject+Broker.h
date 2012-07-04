//
//  NSManagedObject+Broker.h
//  Broker
//
//  Created by Andrew Smith on 6/25/12.
//  Copyright (c) 2012 Andrew B. Smith. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObject (Broker)

/**
 The absolute truth as to whether the object has been deleted in its context.
 */
- (BOOL)hasBeenDeleted;

@end
