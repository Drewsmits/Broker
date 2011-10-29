//
//  BKEntityMap.h
//  Broker
//
//  Created by Andrew Smith on 10/5/11.
//  Copyright (c) 2011 Andrew B. Smith. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "BKPropertyDescription.h"

@interface BKAttributeDescription : BKPropertyDescription {
@private
    NSString *dateFormat;
    NSDateFormatter *dateFormatter;
}

@property (nonatomic, copy) NSString *dateFormat;
@property (nonatomic, readonly) NSDateFormatter *dateFormatter;

@property (nonatomic, assign) NSAttributeType attributeType;

+ (BKAttributeDescription *)descriptionWithAttributeDescription:(NSAttributeDescription *)description;

+ (BKAttributeDescription *)descriptionWithAttributeDescription:(NSAttributeDescription *)description
                                   andMapToNetworkAttributeName:(NSString *)networkAttributeName;

/**
 * Returns the correct object type with the given value
 */
- (id)objectForValue:(id)value;

@end
