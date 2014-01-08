//
//  NSManagedObjectBrokerTests.m
//  Broker
//
//  Created by Andrew Smith on 11/1/13.
//  Copyright (c) 2013 Andrew B. Smith. All rights reserved.
//

#import "BKTestCase.h"
#import "Employee.h"
#import "NSManagedObject+Broker.h"

@interface NSManagedObjectBrokerTests : BKTestCase

@end

@implementation NSManagedObjectBrokerTests

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void)testHasBeenDeleted
{
    NSManagedObject *employee = [NSEntityDescription insertNewObjectForEntityForName:@"Employee"
                                                              inManagedObjectContext:self.testStore.managedObjectContext];
    
    XCTAssertFalse([employee bkr_hasBeenDeleted], @"Object should not be deleted");
    
    [self.testStore.managedObjectContext save:nil];
    
    XCTAssertFalse([employee bkr_hasBeenDeleted], @"Object should not be deleted");
    
    [self.testStore.managedObjectContext deleteObject:employee];
    
    XCTAssertTrue([employee bkr_hasBeenDeleted], @"Object should be deleted");
}

@end
