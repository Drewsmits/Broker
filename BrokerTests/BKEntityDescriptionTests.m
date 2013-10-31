//
//  BKEntityDescriptionTests.m
//  Broker
//
//  Created by Andrew Smith on 10/24/13.
//  Copyright (c) 2013 Andrew B. Smith. All rights reserved.
//

#import "BKTestCase.h"

#import <Broker/BrokerHeaders.h>

#import "BrokerTestsHelpers.h"

@interface BKEntityDescriptionTests : BKTestCase

@end

@implementation BKEntityDescriptionTests

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

- (void)testDescriptionForObject
{
    NSManagedObject *department = [BrokerTestsHelpers createNewDepartment:self.testStore.managedObjectContext];
    
    BKEntityDescription *description = [BKEntityDescription descriptionForObject:department];
    
    XCTAssertNotNil([description descriptionForLocalProperty:kDepartmentPrimaryKey], @"Should have a description for the attribute");
    XCTAssertNotNil([description descriptionForLocalProperty:kName], @"Should have a description for the attribute");
    XCTAssertNotNil([description descriptionForLocalProperty:kDogs], @"Should have a description for the attribute");
    XCTAssertNotNil([description descriptionForLocalProperty:kEmployees], @"Should have a description for the attribute");

    XCTAssertTrue([description isPropertyRelationship:kDogs], @"Dogs property should be a relationship");
    XCTAssertTrue([description isPropertyRelationship:kEmployees], @"Dogs property should be a relationship");
}

@end
