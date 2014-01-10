//
//  BKEntityMapTests.m
//  Broker
//
//  Created by Andrew Smith on 1/10/14.
//  Copyright (c) 2014 Andrew B. Smith. All rights reserved.
//

#import "BKTestCase.h"

#import "BrokerTestsHelpers.h"

@interface BKEntityMapTests : BKTestCase

@property (nonatomic, strong) BKEntityMap *entityMap;

@end

@implementation BKEntityMapTests

- (void)setUp
{
    [super setUp];
    _entityMap = [BKEntityMap entityMap];
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void)testEntityRegistration
{
    [self.entityMap registerEntityNamed:kEmployee
                         withPrimaryKey:kEmployeePrimaryKey
                andMapNetworkProperties:@[@"id", @"burrito"]
                      toLocalProperties:@[kEmployeePrimaryKey, @"firstname"]
                              inContext:self.testStore.managedObjectContext];
    
    BKEntityDescription *description = [self.entityMap entityDescriptionForEntityName:kEmployee];
    
    XCTAssertNotNil(description, @"Should have a description");
    
    XCTAssertEqualObjects(description.localToNetworkPropertiesMap[kEmployeePrimaryKey],
                          @"id",
                          @"Should have maked id to employeeID");

    XCTAssertEqualObjects(description.localToNetworkPropertiesMap[@"firstname"],
                          @"burrito",
                          @"Should have maked id to employeeID");
    
    XCTAssertEqualObjects(description.primaryKey,
                          kEmployeePrimaryKey,
                          @"Should have the correct primary key");
    
    NSArray *employees = [BrokerTestsHelpers findAllEntitiesNamed:kEmployee
                                                        inContext:self.testStore.managedObjectContext];
    
    XCTAssertEqual(employees.count, 0U, @"Should not have any residual employees after registration");
}

- (void)testEntityDescriptionForEntityName
{
    [self.entityMap registerEntityNamed:kEmployee
                         withPrimaryKey:kEmployeePrimaryKey
                andMapNetworkProperties:@[@"id", @"burrito"]
                      toLocalProperties:@[kEmployeePrimaryKey, @"firstname"]
                              inContext:self.testStore.managedObjectContext];
    
    BKEntityDescription *description = [self.entityMap entityDescriptionForEntityName:kEmployee];
    
    XCTAssertNotNil(description, @"Should have a description");
    XCTAssertThrows([self.entityMap entityDescriptionForEntityName:@"notAnEntity"],
                    @"Should throw an exception if trying to grab an entity that isn't registered");
}

@end
