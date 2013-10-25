//
//  BKJSONControllerTests.m
//  Broker
//
//  Created by Andrew Smith on 10/24/13.
//  Copyright (c) 2013 Andrew B. Smith. All rights reserved.
//

#import "BKTestCase.h"

#import <Broker/Broker.h>

#import "BrokerTestsHelpers.h"

@interface BKJSONControllerTests : BKTestCase

@property (nonatomic, strong) BKJSONController *jsonController;

@property (nonatomic, strong) BKEntityController *entityController;

@end

@implementation BKJSONControllerTests

- (void)setUp
{
    [super setUp];
    
    BKEntityController *controller = [BKEntityController entityController];
    self.entityController = controller;

    [self.entityController registerEntityNamed:kDepartment
                                withPrimaryKey:kDepartmentPrimaryKey
                       andMapNetworkProperties:nil
                             toLocalProperties:nil
                                     inContext:self.testStore.managedObjectContext];
    
    BKJSONController *jsonController = [BKJSONController JSONControllerWithContext:self.testStore.managedObjectContext
                                                                  entityController:controller];
    self.jsonController = jsonController;
}

- (void)tearDown
{
    self.entityController = nil;
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
    
}

@end
