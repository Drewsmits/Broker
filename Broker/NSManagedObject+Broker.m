//
//  NSManagedObject+Broker.m
//  Broker
//
//  Created by Andrew Smith on 6/25/12.
//  Copyright (c) 2012 Andrew B. Smith. All rights reserved.
//

#import "NSManagedObject+Broker.h"

@implementation NSManagedObject (Broker)

- (BOOL)hasBeenDeleted {
    
    /**
     Sometimes CoreData will fault a particular instance, while there is still
     the same object in the store.  Check to see if there is a clone.
     */
    NSManagedObjectID   *objectID           = [self objectID];
    NSManagedObject     *managedObjectClone = [[self managedObjectContext] existingObjectWithID:objectID 
                                                                                          error:NULL];
    
    if (!managedObjectClone || [self isDeleted]) {
        return YES;
    } else {
        return NO;
    }
}

@end
