//
//  BrokerNewTests.m
//  Broker
//
//  Created by Andrew Smith on 10/25/13.
//  Copyright (c) 2013 Andrew B. Smith. All rights reserved.
//

#import "BKTestCase.h"

#import <Broker/Broker.h>

#import "BrokerTestsHelpers.h"
#import "TestCounter.h"
#import "Employee.h"

@interface BKControllerTests : BKTestCase

@property (nonatomic, strong) BKController *controller;

@end

@implementation BKControllerTests

- (void)setUp
{
    [super setUp];
    
    self.controller = [BKController controller];
    
    // Department
    [self.controller.entityMap registerEntityNamed:kDepartment
                                    withPrimaryKey:kDepartmentPrimaryKey
                           andMapNetworkProperties:nil
                                 toLocalProperties:nil
                                         inContext:self.testStore.managedObjectContext];
    
    // Employee
    [Employee bkr_registerWithBroker:self.controller
                           inContext:self.testStore.managedObjectContext];
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void)testBrokerFlatJSON
{
    NSData *jsonData = DataFromFile(@"department_flat.json");
    id json = [NSJSONSerialization JSONObjectWithData:jsonData
                                              options:NSJSONReadingMutableContainers
                                                error:nil];
    
    __block TestCounter *counter = [TestCounter new];
    [self.controller processJSONObject:json
                         asEntityNamed:kDepartment inContext:self.testStore.managedObjectContext
                       completionBlock:^{
                           [counter subtract];
                       }];
    
    [counter waitUntil:0 timeout:5];
    
    NSArray *allDepartments = [BrokerTestsHelpers findAllEntitiesNamed:kDepartment
                                                             inContext:self.testStore.managedObjectContext];
    
    XCTAssertEqual(allDepartments.count, 1U, @"Should have one department");
    
    NSManagedObject *department = [allDepartments firstObject];
    
    XCTAssertEqualObjects([department valueForKey:kDepartmentPrimaryKey],
                          @(1234), @"Department should have the correct primary key");
    
    XCTAssertEqualObjects([department valueForKey:kName],
                          @"Engineering", @"Department should have the correct primary key");
}

- (void)testBrokerNestedJSON
{
    NSData *jsonData = DataFromFile(@"department_nested.json");
    id json = [NSJSONSerialization JSONObjectWithData:jsonData
                                              options:NSJSONReadingMutableContainers
                                                error:nil];
    
    __block TestCounter *counter = [TestCounter new];
    [self.controller processJSONObject:json
                         asEntityNamed:kDepartment
                             inContext:self.testStore.managedObjectContext
                       completionBlock:^{
                           [counter subtract];
                       }];
    
    [counter waitUntil:0 timeout:5];
    
    NSArray *allDepartments = [BrokerTestsHelpers findAllEntitiesNamed:kDepartment
                                                             inContext:self.testStore.managedObjectContext];
    
    XCTAssertEqual(allDepartments.count, 1U, @"Should have one department");
    
    NSManagedObject *department = [allDepartments firstObject];
    
    XCTAssertEqualObjects([department valueForKey:kDepartmentPrimaryKey],
                          @(1234), @"Department should have the correct primary key");
    
    XCTAssertEqualObjects([department valueForKey:kName],
                          @"Engineering", @"Department should have the correct primary key");
    
    NSArray *employees = [department valueForKey:kEmployees];
    XCTAssertEqual(employees.count, 6U, @"Department should have the right amount of employees");
}

- (void)test200EmployeesJSON
{
    id json = JsonFromFile(@"department_employees_200.json");
    
    __block TestCounter *counter = [TestCounter new];
    [self.controller processJSONCollection:json
                           asEntitiesNamed:kEmployee
                                 inContext:self.testStore.managedObjectContext
                           completionBlock:^{
                               [counter subtract];
                           }];
    
    [counter waitUntil:0 timeout:5];
    
    NSArray *allEmployees = [BrokerTestsHelpers findAllEntitiesNamed:kEmployee
                                                           inContext:self.testStore.managedObjectContext];
    
    XCTAssertEqual(allEmployees.count, 200U, @"Should have the right number of employees");
}

- (void)test200EmployeesJSONTwice
{
    NSData *jsonData = DataFromFile(@"department_employees_200.json");
    
    id json = [NSJSONSerialization JSONObjectWithData:jsonData
                                              options:NSJSONReadingMutableContainers
                                                error:nil];
    
    __block TestCounter *counter = [TestCounter new];
    [self.controller processJSONCollection:json
                           asEntitiesNamed:kEmployee
                                 inContext:self.testStore.managedObjectContext
                           completionBlock:^{
                               [counter subtract];
                           }];
    
    [counter waitUntil:0 timeout:5];
    
    NSArray *allEmployees = [BrokerTestsHelpers findAllEntitiesNamed:kEmployee
                                                           inContext:self.testStore.managedObjectContext];
    
    XCTAssertEqual(allEmployees.count, 200U, @"Should have the right number of employees");
    
    [counter add];
    [self.controller processJSONCollection:json
                           asEntitiesNamed:kEmployee
                                 inContext:self.testStore.managedObjectContext
                           completionBlock:^{
                               [counter subtract];
                           }];
    
    [counter waitUntil:0 timeout:5];
    
    allEmployees = [BrokerTestsHelpers findAllEntitiesNamed:kEmployee
                                                  inContext:self.testStore.managedObjectContext];
    
    XCTAssertEqual(allEmployees.count, 200U, @"Should have the right number of employees");
}

//- (void)testNestedDepartmentEmployeesJSON {
//
//    NSData *jsonData = DataFromFile(@"department_nested.json");
//
//    // Register Entities
//    [broker registerEntityNamed:kDepartment withPrimaryKey:@"departmentID"];
//    [broker registerEntityNamed:kEmployee withPrimaryKey:@"employeeID"];
//    [broker setDateFormat:kEmployeeStartDateFormat
//              forProperty:@"startDate"
//                 onEntity:kEmployee];
//
//    // Build Deparment
//    NSManagedObjectID *departmentID = [BrokerTestsHelpers createNewDepartment:context];
//
//    [broker processJSONPayload:jsonData
//               usingQueueNamed:kBrokerTestQueue
//                targetObjectID:departmentID
//               forRelationship:@"employees"
//            JSONPreFilterBlock:nil
//           withCompletionBlock:nil];
//
//    [broker waitForQueueNamed:kBrokerTestQueue];
//
//    // Fetch
//    NSManagedObject *dept = [context objectWithID:departmentID];
//
//    NSSet *employees = (NSSet *)[dept valueForKey:@"employees"];
//    int num = [employees count];
//
//    STAssertEquals(num, 6, @"Should have 6 employee objects");
//}


@end
