//
//  BKEntityMap.m
//  Broker
//
//  Created by Andrew Smith on 10/5/11.
//  Copyright (c) 2011 Andrew B. Smith ( http://github.com/drewsmits ). All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy 
// of this software and associated documentation files (the "Software"), to deal 
// in the Software without restriction, including without limitation the rights 
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies 
// of the Software, and to permit persons to whom the Software is furnished to do so, 
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included 
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "BKAttributeDescription.h"

@interface BKAttributeDescription ()

@property (nonatomic, strong, readwrite) NSAttributeDescription *internalAttributeDescription;

@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

@implementation BKAttributeDescription

- (id)init
{
    self = [super init];
    if (self) {
        _dateFormatter = [[NSDateFormatter alloc] init];
    }
    return self;
}

+ (instancetype)descriptionWithAttributeDescription:(NSAttributeDescription *)description
{
    BKAttributeDescription *bkDescription = [self new];
    bkDescription.internalAttributeDescription = description;
    return bkDescription;
}

- (id)objectForValue:(id)value
{    
    NSAttributeType type = [self.internalAttributeDescription attributeType];
    
    switch (type) {
        case NSUndefinedAttributeType:
            return nil;
            break;
        case NSInteger16AttributeType:
            return @([value shortValue]);
            break;
        case NSInteger32AttributeType:
            return @([value integerValue]);
            break;
        case NSInteger64AttributeType:
            return @([value longLongValue]);
            break;
        case NSDecimalAttributeType:
            return [NSDecimalNumber decimalNumberWithDecimal:[value decimalValue]];
            break;
        case NSDoubleAttributeType:
            return @([value doubleValue]);
            break;
        case NSFloatAttributeType:
            return @([value floatValue]);
        case NSStringAttributeType:
            return [NSString stringWithString:value];
            break;
        case NSBooleanAttributeType:
            return @([value boolValue]);
        case NSDateAttributeType:
            if (!self.dateFormatter.dateFormat) {
                BrokerWarningLog(@"NSDate attribute named \"%@\" on entity \"%@\" requires "
                                 @"date format to be set.  Use [Broker setDateFormat:forProperty:onEntity:]",
                                 self.internalAttributeDescription.name,
                                 self.internalAttributeDescription.entity.name);
                return nil;
            }
            
            return [self.dateFormatter dateFromString:value];
            break;
        case NSBinaryDataAttributeType:
            NSAssert(YES, @"Not implemented yet");
            return nil;
            break;
        case NSTransformableAttributeType:
            NSAssert(YES, @"Not implemented yet");
            return nil;
            break;
        case NSObjectIDAttributeType:
            NSAssert(YES, @"Not implemented yet");
            return nil;
            break;
        default:
            return nil;
            break;
    }
}

#pragma mark - Date

- (void)setDateFormat:(NSString *)dateFormat
{
    [self.dateFormatter setDateFormat:dateFormat];
}

@end
