//
//  BKEntityController.m
//  Broker
//
//  Created by Andrew Smith on 6/6/13.
//  Copyright (c) 2013 Andrew B. Smith. All rights reserved.
//

#import "BKEntityController.h"

#import "BKEntityPropertiesDescription.h"

@implementation BKEntityController

- (void)registerEntityNamed:(NSString *)entityName
             withPrimaryKey:(NSString *)primaryKey
    andMapNetworkProperties:(NSArray *)networkProperties
          toLocalProperties:(NSArray *)localProperties
                  inContext:(NSManagedObjectContext *)context
{
    [context performBlock:^{
        // create new object
        NSManagedObject *object = [NSEntityDescription insertNewObjectForEntityForName:entityName
                                                                inManagedObjectContext:context];
        
        // Build description of entity properties
        BKEntityPropertiesDescription *desc = [BKEntityPropertiesDescription descriptionForEntity:object.entity
                                                                             withPropertiesByName:object.entity.propertiesByName
                                                                          andMapNetworkProperties:networkProperties
                                                                                toLocalProperties:localProperties];
        
        // Set primary key
        desc.primaryKey = primaryKey;
        
        // Add to descriptions
        [self.entityDescriptions setObject:desc forKey:entityName];
        
        // cleanup
        [context deleteObject:object];
    }];
}



@end
