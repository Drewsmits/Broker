//
//  NSManagedObject+Broker.m
//  Broker
//
//  Created by Andrew Smith on 6/25/12.
//  Copyright (c) 2012 Andrew B. Smith. All rights reserved.
//

#import "NSManagedObject+Broker.h"

#import "BKController.h"
#import "BKEntityMap.h"

@implementation NSManagedObject (Broker)

+ (void)bkr_registerWithBroker:(BKController *)controller
                     inContext:(NSManagedObjectContext *)context
{
    NSString *lowercaseDescription = self.description.lowercaseString;
    NSString *defaultPrimaryKey = [NSString stringWithFormat:@"%@ID", lowercaseDescription];
    
    [controller.entityMap registerEntityNamed:[self description]
                               withPrimaryKey:defaultPrimaryKey
                      andMapNetworkProperties:nil
                            toLocalProperties:nil
                                    inContext:context];
}

- (BOOL)bkr_hasBeenDeleted
{    
    /**
     Sometimes CoreData will fault a particular instance, while there is still
     the same object in the store.  Check to see if there is a clone.
     */
    NSManagedObjectID *objectID           = [self objectID];
    NSManagedObject   *managedObjectClone = [[self managedObjectContext] existingObjectWithID:objectID 
                                                                                        error:NULL];
    
    if (!managedObjectClone || [self isDeleted]) {
        return YES;
    } else {
        return NO;
    }
}

@end
