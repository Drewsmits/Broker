//
//  Employee.m
//  Broker
//
//  Created by Andrew Smith on 10/30/13.
//  Copyright (c) 2013 Andrew B. Smith. All rights reserved.
//

#import "Employee.h"

#import "NSManagedObject+Broker.h"
#import "BKController.h"
#import "BKEntityMap.h"

@implementation Employee

@dynamic employeeID;
@dynamic firstname;
@dynamic lastname;
@dynamic startDate;
@dynamic contactInfo;
@dynamic department;

+ (void)bkr_registerWithBroker:(BKController *)controller
                     inContext:(NSManagedObjectContext *)context
{
    [controller.entityMap registerEntityNamed:NSStringFromClass(self)
                               withPrimaryKey:@"employeeID"
                      andMapNetworkProperties:nil
                            toLocalProperties:nil
                                    inContext:context];
}

@end
