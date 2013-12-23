//
//  BKTestAppStore.m
//  BrokerTestApp
//
//  Created by Andrew Smith on 11/7/13.
//  Copyright (c) 2013 Andrew B. Smith. All rights reserved.
//

#import "BKTestAppStore.h"

@implementation BKTestAppStore

- (void)reset:(NSError *)error
{
    @synchronized(self) {
        // Delete SQlite
        [self deleteStore:error];
        
        // Nil local variables
        _managedObjectContext = nil;
        _managedObjectModel = nil;
        _persistentStoreCoordinator = nil;
        
        // Rebuild
        [self managedObjectContext];
    }
}

- (void)deleteStore:(NSError *)error
{
    @synchronized(self) {
        // Ensure we are on the main thread
        NSAssert([[NSThread currentThread] isEqual:[NSThread mainThread]], @"Delete operation must occur on the main thread");
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (self.dataStoreURL) {
            [fileManager removeItemAtURL:self.dataStoreURL error:&error];
        }
    }
}

#pragma mark - CoreData Stack

- (NSURL *)dataModelURL
{
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    
    NSString *path = [testBundle pathForResource:@"BrokerTestModel"
                                          ofType:@"momd"];
    
    NSString *escapedPath = [path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    return [NSURL URLWithString:escapedPath];
}

- (NSURL *)dataStoreURL
{
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    
    NSURL *storeURL = [[testBundle resourceURL] URLByAppendingPathComponent:@"BrokerTestApp.sqlite"];
    
    return storeURL;
}

- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator) {
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    
    return _managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel) {
        return _managedObjectModel;
    }
    
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:self.dataModelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                   configuration:nil
                                                             URL:self.dataStoreURL
                                                         options:nil
                                                           error:&error])
    {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        
        NSLog(@"The model used to open the store is incompatable with the one used to create the store! Performing lightweight migration.");
        
        NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption : @(YES),
                                  NSInferMappingModelAutomaticallyOption       : @(YES)};
        
        if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:self.dataStoreURL options:options error:&error]) {
            
            // probably shouldn't do this??!
            //[[NSFileManager defaultManager] removeItemAtURL:self.storeURL error:nil];
            
            if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:self.dataStoreURL options:options error:&error]) {
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                abort();
            }
        }
        
    }
    
    return _persistentStoreCoordinator;
}

@end
