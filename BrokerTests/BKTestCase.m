//
//  BKTestCase.m
//  Broker
//
//  Created by Andrew Smith on 10/24/13.
//  Copyright (c) 2013 Andrew B. Smith. All rights reserved.
//

#import "BKTestCase.h"

@implementation BKTestCase

- (void)setUp
{
    [super setUp];
    self.testStore = [BKTestStore new];
}

- (void)tearDown
{
    NSError *error;
    [self.testStore reset:error];
    XCTAssertNil(error, @"Error!");
    [super tearDown];
}

@end
