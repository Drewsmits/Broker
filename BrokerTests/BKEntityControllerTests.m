//
//  BKEntityControllerTests.m
//  Broker
//
//  Created by Andrew Smith on 10/24/13.
//  Copyright (c) 2013 Andrew B. Smith. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Broker/Broker.h>
#import "BKTestCase.h"

@interface BKEntityControllerTests : BKTestCase

@property (nonatomic, strong) BKEntityController *entityController;

@end

@implementation BKEntityControllerTests

- (void)setUp
{
    [super setUp];
    BKEntityController *controller = [BKEntityController entityController];
    self.entityController = controller;
}

- (void)tearDown
{
    self.entityController = nil;
    [super tearDown];
}

- (void)testRegisterEntity
{
    [self.entityController registerEntityNamed:@"Department"
                                withPrimaryKey:Nil
                       andMapNetworkProperties:nil
                             toLocalProperties:nil
                                     inContext:self.testStore.managedObjectContext];
    
    BKEntityDescription *desc = [self.entityController entityDescriptionForEntityName:kDepartment];
    
    XCTAssertNotNil(desc, @"Should have an entity description");
}

@end
