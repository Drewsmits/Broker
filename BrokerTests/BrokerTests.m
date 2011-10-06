//
//  BrokerTests.m
//  BrokerTests
//
//  Created by Andrew Smith on 10/5/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "BrokerTests.h"
#import "Broker.h"

@implementation BrokerTests

- (void)setUp {
    [super setUp];
    
    NSString *path = [[NSBundle bundleForClass:[BrokerTests class]] pathForResource:@"BrokerTestModel" 
                                                                             ofType:@"momd"];
    
    NSURL *modelURL = [NSURL URLWithString:path];
    
    model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    
    STAssertNotNil(model, @"Managed Object Model should exist");
    
    coord = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    
    store = [coord addPersistentStoreWithType:NSInMemoryStoreType
                                configuration:nil
                                          URL:nil
                                      options:nil 
                                        error:NULL];
    
    context = [[NSManagedObjectContext alloc] init];
    [context setPersistentStoreCoordinator:coord];

    [Broker setupWithContext:context];
}

- (void)tearDown {
    [context release], context = nil;
    
    NSError *error = nil;
    STAssertTrue([coord removePersistentStore: store error: &error], 
                 @"couldn't remove persistent store: %@", error);
    
    store = nil;
    
    [coord release], coord = nil;
    
    [model release], model = nil;    
    [super tearDown];
}

- (void)testRegisterDepartment {

    [Broker registerEntityName:@"Department"];

    
}

@end
