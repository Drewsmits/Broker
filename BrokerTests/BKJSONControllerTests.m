//
//  BKJSONControllerTests.m
//  Broker
//
//  Created by Andrew Smith on 10/24/13.
//  Copyright (c) 2013 Andrew B. Smith. All rights reserved.
//

#import "BKTestCase.h"

#import <Broker/Broker.h>

#import "Employee.h"

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

- (void)registerEntities
{
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
    
    [self.entityMap registerEntityNamed:@"ContactInfo"
                         withPrimaryKey:nil
                andMapNetworkProperties:nil
                      toLocalProperties:nil
                              inContext:self.testStore.managedObjectContext];
}

#pragma mark - Tests

- (void)testFlatJSON
{
    [self registerEntities];
    
    id json = JsonFromFile(@"department_flat.json");

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

- (void)testEmployeeCollectionJson
{
    [self registerEntities];
    
    id json = JsonFromFile(@"department_employees_100.json");
    
    [self.jsonController processJSONCollection:json
                               asEntitiesNamed:kEmployee];
    
    NSArray *employees = [BrokerTestsHelpers findAllEntitiesNamed:kEmployee
                                                        inContext:self.testStore.managedObjectContext];
    
    XCTAssertEqual(employees.count, 100U, @"Should have the right amount of employee objects");
}

- (void)testNoPrimaryKey
{
    //
    // Without a primary key, we should end up with duplicat objects. Test this
    // by processing the same JSON twice.
    //
    [self.entityMap registerEntityNamed:kEmployee
                         withPrimaryKey:nil
                andMapNetworkProperties:nil
                      toLocalProperties:nil
                              inContext:self.testStore.managedObjectContext];
    
    id json = JsonFromFile(@"department_employees.json");
    
    [self.jsonController processJSONCollection:json
                               asEntitiesNamed:kEmployee];

    NSArray *allEmployees = [BrokerTestsHelpers findAllEntitiesNamed:kEmployee
                                                           inContext:self.testStore.managedObjectContext];
    
    XCTAssertEqual(allEmployees.count, 6U, @"Should have the right number of employees");
    
    [self.jsonController processJSONCollection:json
                               asEntitiesNamed:kEmployee];
    
    allEmployees = [BrokerTestsHelpers findAllEntitiesNamed:kEmployee
                                                  inContext:self.testStore.managedObjectContext];
    
    XCTAssertEqual(allEmployees.count, 12U, @"Should have the right number of employees");
}

- (void)testNestedJSON
{
    [self registerEntities];
    
    id json = JsonFromFile(@"department_nested.json");

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
    
    NSArray *employees = [department valueForKey:kEmployees];
    XCTAssertEqual(employees.count, 6U, @"Department should have the right amount of employees");
}

- (void)testDepartmentEmployeesRelationshipJSON
{
    [self registerEntities];
    
    id json = JsonFromFile(@"department_employees_100.json");

    // Build Deparment
    NSManagedObject *department = [BrokerTestsHelpers createNewDepartment:self.testStore.managedObjectContext];

    [self.jsonController processJSON:json
                     forRelationship:kEmployees
                            onObject:department];

    NSSet *employees = (NSSet *)[department valueForKey:kEmployees];

    XCTAssertEqual(employees.count, 100U, @"Should have the right amount of employee objects");
}

- (void)testFlatEmployeeWithNetworkPropertyJSONProcessing
{
    [self.entityMap registerEntityNamed:kEmployee
                         withPrimaryKey:kEmployeePrimaryKey
                andMapNetworkProperties:@[@"id"]
                      toLocalProperties:@[kEmployeePrimaryKey]
                              inContext:self.testStore.managedObjectContext];

    id json = JsonFromFile(@"employee_network_property.json");

    [self.jsonController processJSONObject:json
                             asEntityNamed:kEmployee];
    
    NSArray *allEmployees = [BrokerTestsHelpers findAllEntitiesNamed:kEmployee
                                                           inContext:self.testStore.managedObjectContext];
    
    XCTAssertEqual(allEmployees.count, 1U, @"Should have one employee");
    
    Employee *employee = [allEmployees firstObject];

//    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
//    [formatter setDateFormat:kEmployeeStartDateFormat];
//    NSDate *date = [formatter dateFromString:@"2011/10/06 00:51:10 -0700"];

    XCTAssertEqualObjects([employee valueForKey:@"firstname"], @"Andrew", @"Attributes should be set correctly");
    XCTAssertEqualObjects([employee valueForKey:@"lastname"], @"Smith", @"Attributes should be set correctly");
    XCTAssertEqualObjects([employee valueForKey:kEmployeePrimaryKey], @5678, @"Attributes should be set correctly");
//    STAssertEqualObjects([employee valueForKey:@"startDate"], date, @"Attributes should be set correctly");
}

- (void)testEmployeeWithContactInfo
{
    [self registerEntities];
    
    id json = JsonFromFile(@"employee_nested.json");
    
    [self.jsonController processJSONObject:json
                             asEntityNamed:kEmployee];
    
    NSArray *allEmployees = [BrokerTestsHelpers findAllEntitiesNamed:kEmployee
                                                           inContext:self.testStore.managedObjectContext];
    
    XCTAssertEqual(allEmployees.count, 1U, @"Should have one employee");
    
    Employee *employee = [allEmployees firstObject];
    
    XCTAssertNotNil(employee.contactInfo, @"Should have contact info");

}


@end
