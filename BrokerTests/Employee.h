//
//  Employee.h
//  Broker
//
//  Created by Andrew Smith on 10/30/13.
//  Copyright (c) 2013 Andrew B. Smith. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Employee : NSManagedObject

@property (nonatomic, retain) NSNumber * employeeID;
@property (nonatomic, retain) NSString * firstname;
@property (nonatomic, retain) NSString * lastname;
@property (nonatomic, retain) NSDate * startDate;
@property (nonatomic, retain) NSManagedObject *contactInfo;
@property (nonatomic, retain) NSManagedObject *department;

@end
