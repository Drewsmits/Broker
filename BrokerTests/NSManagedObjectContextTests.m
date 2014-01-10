//
//  NSManagedObjectContextTests.m
//  Broker
//
//  Created by Andrew Smith on 1/10/14.
//  Copyright (c) 2014 Andrew B. Smith. All rights reserved.
//

#import "BKTestCase.h"

#import "BrokerTestsHelpers.h"
#import "Employee.h"

@interface NSManagedObjectContextTests : BKTestCase

@end

@implementation NSManagedObjectContextTests

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

- (void)testFindEntityWithPrimaryKey
{
    Employee *employee = (Employee *)[BrokerTestsHelpers createNewFilledOutEmployee:self.testStore.managedObjectContext];
    
    BKEntityDescription *description = [BKEntityDescription descriptionForObject:employee];
    description.primaryKey = kEmployeePrimaryKey;
    
    Employee *foundEmployee = (Employee *)[self.testStore.managedObjectContext bkr_findOrCreateObjectForEntityDescription:description
                                                                                                          primaryKeyValue:@12345];

    NSArray *employees = [BrokerTestsHelpers findAllEntitiesNamed:kEmployee inContext:self.testStore.managedObjectContext];
    
    XCTAssertEqual(employees.count, 1U, @"Should be only one Employee");
    XCTAssertEqualObjects(employee, foundEmployee, @"Found object should be the same as the first created");
}

@end
