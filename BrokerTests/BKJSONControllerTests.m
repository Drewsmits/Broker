//
//  BKJSONControllerTests.m
//  Broker
//
//  Created by Andrew Smith on 10/24/13.
//  Copyright (c) 2013 Andrew B. Smith. All rights reserved.
//

#import "BKTestCase.h"

#import <Broker/BrokerHeaders.h>

#import "BrokerTestsHelpers.h"

@interface BKJSONControllerTests : BKTestCase

@property (nonatomic, strong) BKJSONController *jsonController;

@property (nonatomic, strong) BKEntityMap *entityMap;

@end

@implementation BKJSONControllerTests

- (void)setUp
{
    [super setUp];
    
    self.entityMap = [BKEntityMap entityMap];

    [self.entityMap registerEntityNamed:kDepartment
                         withPrimaryKey:kDepartmentPrimaryKey
                andMapNetworkProperties:nil
                      toLocalProperties:nil
                              inContext:self.testStore.managedObjectContext];
    
    [self.entityMap registerEntityNamed:kEmployee
                         withPrimaryKey:kEmployeePrimaryKey
                andMapNetworkProperties:nil
                      toLocalProperties:nil
                              inContext:self.testStore.managedObjectContext];
    
    BKJSONController *jsonController = [BKJSONController JSONControllerWithContext:self.testStore.managedObjectContext
                                                                         entityMap:self.entityMap];
    self.jsonController = jsonController;
}

- (void)tearDown
{
    self.entityMap = nil;
    self.jsonController = nil;
    [super tearDown];
}

- (void)testFlatJSON
{
    NSData *jsonData = DataFromFile(@"department_flat.json");
    id json = [NSJSONSerialization JSONObjectWithData:jsonData
                                              options:NSJSONReadingMutableContainers
                                                error:nil];

    [self.jsonController processJSONObject:json
                             asEntityNamed:kDepartment];
    
    NSArray *allDepartments = [BrokerTestsHelpers findAllEntitiesNamed:kDepartment
                                                             inContext:self.testStore.managedObjectContext];
    
    XCTAssertEqual(allDepartments.count, 1U, @"Should have one department");
    
    NSManagedObject *department = [allDepartments firstObject];
    
    XCTAssertEqualObjects([department valueForKey:kDepartmentPrimaryKey],
                          @(1234), @"Department should have the correct primary key");
    
    XCTAssertEqualObjects([department valueForKey:kName],
                          @"Engineering", @"Department should have the correct primary key");
}

- (void)testNextedJSON
{
    NSData *jsonData = DataFromFile(@"department_nested.json");
    id json = [NSJSONSerialization JSONObjectWithData:jsonData
                                              options:NSJSONReadingMutableContainers
                                                error:nil];
    [self.jsonController processJSONObject:json
                             asEntityNamed:kDepartment];
    
    NSArray *allDepartments = [BrokerTestsHelpers findAllEntitiesNamed:kDepartment
                                                             inContext:self.testStore.managedObjectContext];
    
    XCTAssertEqual(allDepartments.count, 1U, @"Should have one department");
    
    NSManagedObject *department = [allDepartments firstObject];
    
    XCTAssertEqualObjects([department valueForKey:kDepartmentPrimaryKey],
                          @(1234), @"Department should have the correct primary key");
    
    XCTAssertEqualObjects([department valueForKey:kName],
                          @"Engineering", @"Department should have the correct primary key");
    
    NSArray *employees = [department valueForKey:@"employees"];
    XCTAssertEqual(employees.count, 6U, @"Department should have the right amount of employees");
}

@end
