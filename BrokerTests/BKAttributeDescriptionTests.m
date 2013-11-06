//
//  BKAttributeDescriptionTests.m
//  Broker
//
//  Created by Andrew Smith on 11/1/13.
//  Copyright (c) 2013 Andrew B. Smith. All rights reserved.
//

#import "BKTestCase.h"

#import "BKAttributeDescription.h"

@interface BKAttributeDescriptionTests : BKTestCase

@end

@implementation BKAttributeDescriptionTests

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

- (void)testUndefinedAttributeType
{
    NSAttributeDescription *description = [NSAttributeDescription new];
    description.attributeType = NSUndefinedAttributeType;
    
    BKAttributeDescription *bkDescription = [BKAttributeDescription descriptionWithAttributeDescription:description];
    
    id object = [bkDescription objectForValue:@"value"];
    
    XCTAssertNil(object, @"Object for value with undefined attribute type should be nil");
}

- (void)testInteger16AttributeType
{
    NSAttributeDescription *description = [NSAttributeDescription new];
    description.attributeType = NSInteger16AttributeType;
    
    BKAttributeDescription *bkDescription = [BKAttributeDescription descriptionWithAttributeDescription:description];
    
    // One less than an overflow
    id object = [bkDescription objectForValue:@(pow(2, 15) - 1)];

    XCTAssertEqualObjects(object, @(pow(2, 15) - 1), @"Object for value with int 16 attribute type should be correct");
}

@end
