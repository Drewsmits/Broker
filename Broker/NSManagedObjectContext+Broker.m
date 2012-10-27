//
//  NSManagedObjectContext+Broker.m
//  Broker
//
//  Created by Andrew Smith on 7/24/12.
//  Copyright (c) 2012 Andrew B. Smith. All rights reserved.
//

#import "NSManagedObjectContext+Broker.h"
#import "BKEntityPropertiesDescription.h"

@implementation NSManagedObjectContext (Broker)

- (NSManagedObject *)findOrCreateObjectForEntityDescribedBy:(BKEntityPropertiesDescription *)description 
                                        withPrimaryKeyValue:(id)value
                                               shouldCreate:(BOOL)create 
{
    NSAssert(description, @"Must have a description");
    if (!description) return nil;
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:description.entityDescription];
    request.includesSubentities = NO;
    
    NSArray *fetchedObjects;
    
    if (description.primaryKey) {
        [request setPredicate:[NSPredicate predicateWithFormat:@"SELF.%@ == %@", description.primaryKey, value]];
        
        NSError *error;
        fetchedObjects = [self executeFetchRequest:request error:&error];
        if (error) {
            NSLog(@"Fetch Error: %@", error);
        }
    }
    
    if (create && fetchedObjects.count == 0) {
        NSManagedObject *object = [NSEntityDescription insertNewObjectForEntityForName:description.entityName 
                                                                inManagedObjectContext:self];
        return object;
    } else if (fetchedObjects.count >= 1) {
        return (NSManagedObject *)[fetchedObjects objectAtIndex:0];
    }
    
    return nil;
}


@end
