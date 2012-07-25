//
//  NSManagedObjectContext+Broker.h
//  Broker
//
//  Created by Andrew Smith on 7/24/12.
//  Copyright (c) 2012 Andrew B. Smith. All rights reserved.
//

#import <CoreData/CoreData.h>

@class BKEntityPropertiesDescription;

@interface NSManagedObjectContext (Broker)

- (NSManagedObject *)findOrCreateObjectForEntityDescribedBy:(BKEntityPropertiesDescription *)description 
                                        withPrimaryKeyValue:(id)value
                                               shouldCreate:(BOOL)create;

@end
