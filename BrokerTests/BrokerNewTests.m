//
//  BrokerNewTests.m
//  Broker
//
//  Created by Andrew Smith on 10/25/13.
//  Copyright (c) 2013 Andrew B. Smith. All rights reserved.
//

#import "BKTestCase.h"

#import <Broker/BrokerHeaders.h>

#import "BrokerTestsHelpers.h"

#define WAIT_ON_BOOL(boolToTest, timeoutInSeconds) \
NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:timeoutInSeconds];\
while ((boolToTest) == NO) {\
if ([timeoutDate timeIntervalSinceNow] <= 0) {\
XCTFail(@"WAIT_ON_BOOL timed out after %i seconds", timeoutInSeconds);\
break;\
}\
NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:0.1];\
[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:loopUntil];\
}\

@interface BrokerNewTests : BKTestCase

@property (nonatomic, strong) Broker *broker;

@end

@implementation BrokerNewTests

- (void)setUp
{
    [super setUp];
    
    self.broker = [Broker broker];
    
    [self.broker.entityMap registerEntityNamed:kDepartment
                                withPrimaryKey:kDepartmentPrimaryKey
                       andMapNetworkProperties:nil
                             toLocalProperties:nil
                                     inContext:self.testStore.managedObjectContext];
    
    [self.broker.entityMap registerEntityNamed:kEmployee
                                withPrimaryKey:kEmployeePrimaryKey
                       andMapNetworkProperties:nil
                             toLocalProperties:nil
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
    
    __block BOOL completed = NO;
    [self.broker processJSONObject:json
                     asEntityNamed:kDepartment inContext:self.testStore.managedObjectContext
                   completionBlock:^{
                       completed = YES;
                   }];
    
    WAIT_ON_BOOL(completed, 1);
    
    NSArray *allDepartments = [BrokerTestsHelpers findAllEntitiesNamed:kDepartment
                                                             inContext:self.testStore.managedObjectContext];
    
    XCTAssertEqual(allDepartments.count, 1U, @"Should have one department");
    
    NSManagedObject *department = [allDepartments firstObject];
    
    XCTAssertEqualObjects([department valueForKey:kDepartmentPrimaryKey],
                          @(1234), @"Department should have the correct primary key");
    
    XCTAssertEqualObjects([department valueForKey:kName],
                          @"Engineering", @"Department should have the correct primary key");
}

@end
