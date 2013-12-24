//
//  NSManagedObjectContext+Broker.h
//  Broker
//
//  Created by Andrew Smith on 7/24/12.
//  Copyright (c) 2012 Andrew B. Smith. All rights reserved.
//

#import <CoreData/CoreData.h>

@class BKEntityDescription;

@interface NSManagedObjectContext (Broker)

- (NSManagedObject *)findOrCreateObjectForEntityDescription:(BKEntityDescription *)description
                                            primaryKeyValue:(id)value;

@end
