//
//  BKTestCase.m
//  Broker
//
//  Created by Andrew Smith on 10/24/13.
//  Copyright (c) 2013 Andrew B. Smith. All rights reserved.
//

#import "BKTestCase.h"

extern void __gcov_flush(void);

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
    
//    __gcov_flush();
}

@end
