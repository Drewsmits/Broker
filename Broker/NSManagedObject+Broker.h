//
//  NSManagedObject+Broker.h
//  Broker
//
//  Created by Andrew Smith on 6/25/12.
//  Copyright (c) 2012 Andrew B. Smith. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Broker;

@interface NSManagedObject (Broker)

/**
 Registers the entity with the Broker instance. Any custom NSManagedObject that
 registers with broker should override this method if you want to do things like
 map local property names to network property names. By default this will register
 the primary key as lowercase claseNameID. So for an Employee object, the
 primary key will be employeeID.
 
 @param broker The Broker instance to register the entity with
 @param context The main thread NSManagedObjectContext;
 */
+ (void)registerWithBroker:(Broker *)broker
                 inContext:(NSManagedObjectContext *)context;

/**
 The absolute truth as to whether the object has been deleted in its context.
 */
- (BOOL)hasBeenDeleted;

@end
