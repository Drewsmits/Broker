//
//  BKTestCase.h
//  Broker
//
//  Created by Andrew Smith on 10/24/13.
//  Copyright (c) 2013 Andrew B. Smith. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BKTestStore.h"
#import "BKTestConstants.h"

@interface BKTestCase : XCTestCase

@property (nonatomic, strong) BKTestStore *testStore;

@end