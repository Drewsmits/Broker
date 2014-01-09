//
//  NSString+Broker.m
//  Broker
//
//  Created by Andrew Smith on 1/8/14.
//  Copyright (c) 2014 Andrew B. Smith. All rights reserved.
//

#import "NSString+Broker.h"

@implementation NSString (Broker)

- (NSString *)bkr_uppercaseFirstLetterOnlyString
{
    NSString *firstCharacterInString = [[self substringToIndex:1] uppercaseString];
    return [self stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:firstCharacterInString];
}

@end
