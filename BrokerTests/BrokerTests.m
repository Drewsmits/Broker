//
//  BrokerTests.m
//  BrokerTests
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

#import "BrokerTests.h"

#import "Broker.h"

#import "BrokerTestsHelpers.h"

#import "BKAttributeDescription.h"
#import "BKRelationshipDescription.h"
#import "BKJSONOperation.h"
#import "NSManagedObjectContext+Broker.h"

#define LOOP_WAIT_TIME 0.01

// Department
static NSString *kDepartment = @"Department";
static NSString *kEmployeesRelationship = @"employees";

// Employee
static NSString *kEmployee = @"Employee";
static NSString *kEmployeeFirstname = @"firstname";
static NSString *kDepartmentRelationship = @"department";
static NSString *kEmployeeStartDateFormat = @"yyyy/MM/dd HH:mm:ss zzzz";

// Dog
static NSString *kDog = @"Dog";


@implementation BrokerTests

- (void)setUp {
    [super setUp];
    
    // Build Model
    model = [[NSManagedObjectModel alloc] initWithContentsOfURL:DataModelURL()];
    
    STAssertNotNil(model, @"Managed Object Model should exist");
    
    // Build persistent store coordinator
    coord = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    
    // Build Store
    NSError *error = nil;
    store = [coord addPersistentStoreWithType:NSSQLiteStoreType
                                configuration:nil
                                          URL:DataStoreURL()
                                      options:nil 
                                        error:&error];

    // Build context
    context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [context setPersistentStoreCoordinator:coord];

    // Setup Broker
    [[Broker sharedInstance] setupWithContext:context
                                 andQueueName:@"BrokerTestQueue" 
              withMaxConcurrentOperationCount:1];
}

- (void)tearDown {
    
    [context release], context = nil;
    
    NSError *error = nil;
    STAssertTrue([coord removePersistentStore:store error:&error], 
                 @"couldn't remove persistent store: %@", error);
    
    store = nil;
    [coord release], coord = nil;
    [model release], model = nil;  
    
    [[Broker sharedInstance] reset];
    
    DeleteDataStore();
    
    [super tearDown];
}

#pragma mark - Registration

- (void)testRegisterRelationshipDescription {
    
    [[Broker sharedInstance] registerEntityNamed:kDepartment withPrimaryKey:nil];
    
    BKRelationshipDescription *desc = [[Broker sharedInstance] relationshipDescriptionForProperty:kEmployeesRelationship 
                                                                                     onEntityName:kDepartment];
    
    STAssertNotNil(desc, @"Should have an relationship description for property on registered entity");
    STAssertEqualObjects(desc.localPropertyName, kEmployeesRelationship, @"Relationship map should be named correctly");    
    STAssertEqualObjects(desc.destinationEntityName, kEmployee, @"Relationship map should have correct destination entity name");
    STAssertEqualObjects(desc.entityName, kDepartment, @"Relationship map should have correct entity name");
    STAssertTrue(desc.isToMany, @"Relationship map should be isToMany");
}

- (void)testRegisterAttributeDescription {
    
    [[Broker sharedInstance] registerEntityNamed:kEmployee withPrimaryKey:nil];
    
    BKAttributeDescription *desc = [[Broker sharedInstance] attributeDescriptionForProperty:@"firstname"
                                                                               onEntityName:kEmployee];
    
    STAssertNotNil(desc, @"Should have an attribute description for property on registered entity");
    STAssertEqualObjects(desc.entityName, kEmployee, @"Attribute description entity name should be set correctly");
    STAssertEqualObjects(desc.localPropertyName, kEmployeeFirstname, @"Attribute description local attribute name should be set correctly");
    STAssertNil(desc.networkPropertyName, @"Attribute description shouldn't have a network attribute name");
}

- (void)testRegisterAttributeDescriptionWithPropertyMap {
    
    [[Broker sharedInstance] registerEntityNamed:kEmployee 
                                  withPrimaryKey:nil 
                           andMapNetworkProperty:@"first-name"
                                 toLocalProperty:@"firstname"];
    
    BKAttributeDescription *desc = [[Broker sharedInstance] attributeDescriptionForProperty:@"firstname"
                                                                               onEntityName:kEmployee];
    
    STAssertEqualObjects(desc.entityName, kEmployee, @"Attribute description entity name should be set correctly");
    STAssertEqualObjects(desc.localPropertyName, kEmployeeFirstname, @"Attribute description local attribute name should be set correctly");
    STAssertEqualObjects(desc.networkPropertyName, @"first-name", @"Attribute description network attribute name should be set correctly");
}

- (void)testRegisterAttributeDescriptionWithPrimaryKey {
    
    [[Broker sharedInstance] registerEntityNamed:kEmployee withPrimaryKey:@"employeeID"];
    
    BKEntityPropertiesDescription *desc = [[Broker sharedInstance] entityPropertyDescriptionForEntityName:kEmployee];

    STAssertEqualObjects(desc.primaryKey, @"employeeID", @"Attribute description should have a primary key");
}

- (void)testAddSingleEntryToPropertyMapAfterRegistration {
    
    [[Broker sharedInstance] registerEntityNamed:kEmployee withPrimaryKey:nil];

    [[Broker sharedInstance] mapNetworkProperty:@"first-name" 
                                toLocalProperty:@"firstname" 
                                      forEntity:kEmployee];
    
    BKAttributeDescription *desc = [[Broker sharedInstance] attributeDescriptionForProperty:@"firstname"
                                                                               onEntityName:kEmployee];
    
    STAssertEqualObjects(desc.entityName, kEmployee, @"Attribute description entity name should be set correctly");
    STAssertEqualObjects(desc.localPropertyName, kEmployeeFirstname, @"Attribute description local attribute name should be set correctly");
    STAssertEqualObjects(desc.networkPropertyName, @"first-name", @"Attribute description network attribute name should be set correctly");
}

- (void)testRegistrationShouldntLeaveEntitiesInStore {
    // registration creates objects in the store.  These shouldnt be saved.
    // Could even register on a separate thread, using separate MOC to be super
    // safe and fast.  Use isReady flag to know if it can start processing shit.
    
    [[Broker sharedInstance] registerEntityNamed:kEmployee withPrimaryKey:@"employeeID"];
    
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:kEmployee 
                                                         inManagedObjectContext:context];
    
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    
    [request setEntity:entityDescription];
    [request setPredicate:[NSPredicate predicateWithFormat:@"1 = 1"]];
    
    NSError *error = nil;
    NSArray *array = [context executeFetchRequest:request error:&error];
    
    STAssertFalse((array.count > 0), @"Broker should not leave straggling entities after registration!");
}

#pragma mark - Entity Properties Description

- (void)testDescriptionForLocalProperty {
    [[Broker sharedInstance] registerEntityNamed:kEmployee withPrimaryKey:@"employeeID"];
    
    BKEntityPropertiesDescription *desc = [[Broker sharedInstance] entityPropertyDescriptionForEntityName:kEmployee];
    BKPropertyDescription *localPropDesc = [desc descriptionForLocalProperty:@"employeeID"];
    
    STAssertNotNil(localPropDesc, @"Should have an attribute description for a property on a registered entity");
}

- (void)testDescriptionForLocalPropertyThatDoesntExist {
    [[Broker sharedInstance] registerEntityNamed:kEmployee withPrimaryKey:@"employeeID"];
    
    BKEntityPropertiesDescription *desc = [[Broker sharedInstance] entityPropertyDescriptionForEntityName:kEmployee];
    BKPropertyDescription *localPropDesc = [desc descriptionForLocalProperty:@"blah"];
    
    STAssertNil(localPropDesc, @"Should not have an attribute description for a fake property on a registered entity");
}

- (void)testDescriptionForNetworkPropertyThatDoesntExist {
    [[Broker sharedInstance] registerEntityNamed:kEmployee 
                                  withPrimaryKey:@"employeeID" 
                           andMapNetworkProperty:@"first-name" 
                                 toLocalProperty:@"firstname"];
    
    BKEntityPropertiesDescription *desc = [[Broker sharedInstance] entityPropertyDescriptionForEntityName:kEmployee];
    BKPropertyDescription *networkPropDesc = [desc descriptionForNetworkProperty:@"blah"];
    
    STAssertNil(networkPropDesc, @"Should not have an attribute description for a fake network property on a registered entity");
}

#pragma mark - Attribute Description

- (void)testDescriptionWithAttributeDescription {
    
    NSManagedObjectID *employeeID = [BrokerTestsHelpers createNewEmployee:context];
    NSManagedObject *object = [context objectWithID:employeeID];
    
    NSDictionary *attributes = object.entity.attributesByName;
    
    NSAttributeDescription *desc = (NSAttributeDescription *)[attributes objectForKey:@"firstname"];
    
    BKAttributeDescription *bkdesc = [BKAttributeDescription descriptionWithAttributeDescription:desc];
    
    NSInteger a = bkdesc.attributeType;
    NSInteger b = NSStringAttributeType;
    
    STAssertEquals(a, b, @"Attributes description should have correct attribute type");
    STAssertEqualObjects(bkdesc.entityName, @"Employee", @"Attribute description should have correct entity name");
}

- (void)testDescriptionWithAttributeDescriptionAndMapToNetworkAttributeName {
    
    NSManagedObjectID *employeeID = [BrokerTestsHelpers createNewEmployee:context];
    NSManagedObject *object = [context objectWithID:employeeID];
    
    NSDictionary *attributes = object.entity.attributesByName;
    
    NSAttributeDescription *desc = (NSAttributeDescription *)[attributes objectForKey:@"firstname"];
    
    BKAttributeDescription *bkdesc = [BKAttributeDescription descriptionWithAttributeDescription:desc 
                                                                    andMapToNetworkAttributeName:@"first-name"];
    
    STAssertEqualObjects(bkdesc.networkPropertyName, @"first-name", @"Attribute description should have correct network name");
    STAssertEqualObjects(bkdesc.localPropertyName, @"firstname", @"Attribute description should have correct local name");
}

#pragma mark - Accessors

- (void)testEntityPropertyDescriptionForEntityName {
    [[Broker sharedInstance] registerEntityNamed:kEmployee withPrimaryKey:@"employeeID"];
    
    BKEntityPropertiesDescription *desc = [[Broker sharedInstance] entityPropertyDescriptionForEntityName:kEmployee];
    
    STAssertNotNil(desc, @"Should have entity property description for registered entity");
}

- (void)testAttributeDescriptionForPropertyOnEntityName {
    [[Broker sharedInstance] registerEntityNamed:kEmployee withPrimaryKey:@"employeeID"];

    BKAttributeDescription *desc = [[Broker sharedInstance] attributeDescriptionForProperty:@"employeeID" 
                                                              onEntityName:kEmployee];
    
    STAssertNotNil(desc, @"Should have an attribute description for a property on a registered entity");
}

- (void)testRelationshipDescriptionForPropertyOnEntityName {
    [[Broker sharedInstance] registerEntityNamed:kEmployee withPrimaryKey:@"employeeID"];
    
    BKRelationshipDescription *desc = [[Broker sharedInstance] relationshipDescriptionForProperty:@"department"
                                                                    onEntityName:@"Employee"];
    
    STAssertNotNil(desc, @"Should have a relationship description for a property on a registered entity");
}

#pragma mark - Transform

- (void)testTransformJSONDictionaryClassesAreCorrect {
        
    NSDictionary *fakeJSON = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"Andrew", @"Smith", @"5678", @"2011/10/06 00:51:10 -0700", nil]
                                                         forKeys:[NSArray arrayWithObjects:@"firstname", @"lastname", @"employeeID", @"startDate", nil]];
    
    [[Broker sharedInstance] registerEntityNamed:kEmployee withPrimaryKey:nil];
    
    [[Broker sharedInstance] setDateFormat:kEmployeeStartDateFormat 
              forProperty:@"startDate" 
                 onEntity:kEmployee];
    
    BKEntityPropertiesDescription *desc = [[Broker sharedInstance] entityPropertyDescriptionForEntityName:kEmployee];
        
    NSDictionary *transformedDict = [[Broker sharedInstance] transformJSONDictionary:fakeJSON 
                                   usingEntityPropertiesDescription:desc];

    STAssertTrue([[transformedDict objectForKey:@"firstname"] isKindOfClass:[NSString class]], @"Transform dictionary should properly set class type");
    STAssertTrue([[transformedDict objectForKey:@"lastname"] isKindOfClass:[NSString class]], @"Transform dictionary should properly set class type");
    STAssertTrue([[transformedDict objectForKey:@"employeeID"] isKindOfClass:[NSNumber class]], @"Transform dictionary should properly set class type");
    STAssertTrue([[transformedDict objectForKey:@"startDate"] isKindOfClass:[NSDate class]], @"Transform dictionary should properly set class type");
}

- (void)testTransformJSONDictionaryValuesAreCorrect {
    
    NSDictionary *fakeJSON = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"Andrew", @"Smith", @"5678", @"2011/10/06 00:51:10 -0700", nil]
                                                         forKeys:[NSArray arrayWithObjects:@"firstname", @"lastname", @"employeeID", @"startDate", nil]];
    
    [[Broker sharedInstance] registerEntityNamed:kEmployee withPrimaryKey:nil];
    
    [[Broker sharedInstance] setDateFormat:kEmployeeStartDateFormat 
              forProperty:@"startDate" 
                 onEntity:kEmployee];
    
    BKEntityPropertiesDescription *desc = [[Broker sharedInstance] entityPropertyDescriptionForEntityName:kEmployee];
    
    NSDictionary *transformedDict = [[Broker sharedInstance] transformJSONDictionary:fakeJSON 
                                                    usingEntityPropertiesDescription:desc];
    
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:kEmployeeStartDateFormat];
    NSDate *date = [formatter dateFromString:@"2011/10/06 00:51:10 -0700"];
    
    STAssertEqualObjects([transformedDict valueForKey:@"firstname"], @"Andrew", @"Attributes should be set correctly");
    STAssertEqualObjects([transformedDict valueForKey:@"lastname"], @"Smith", @"Attributes should be set correctly");
    STAssertEqualObjects([transformedDict valueForKey:@"employeeID"], [NSNumber numberWithInt:5678], @"Attributes should be set correctly");
    STAssertEqualObjects([transformedDict valueForKey:@"startDate"], date, @"Attributes should be set correctly");
}

#pragma mark - Processing

- (void)testFlatEmployeeJSONProcessing {
    
    NSData *jsonData = DataFromFile(@"employee_flat.json");
    
    [[Broker sharedInstance] registerEntityNamed:kEmployee withPrimaryKey:nil];
    [[Broker sharedInstance] setDateFormat:kEmployeeStartDateFormat 
              forProperty:@"startDate" 
                 onEntity:kEmployee];

    // Add a new Employee to the store
    NSManagedObjectID *employeeID = [BrokerTestsHelpers createNewEmployee:context];
    
    // Use to hold main thread while bg tasks complete
    __block BOOL hasFinished = NO;

    // Chunk dat
    [[Broker sharedInstance] processJSONPayload:jsonData
                  targetObjectID:employeeID
                            withCompletionBlock:^{
                                hasFinished = YES;
                            }];
    
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:LOOP_WAIT_TIME];    
    while (hasFinished == NO) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }
    
    // Re-fetch
    NSManagedObject *employee = [context objectWithID:employeeID];
        
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:kEmployeeStartDateFormat];
    NSDate *date = [formatter dateFromString:@"2011/10/06 00:51:10 -0700"];
    
    STAssertEqualObjects([employee valueForKey:@"firstname"], @"Andrew", @"Attributes should be set correctly");
    STAssertEqualObjects([employee valueForKey:@"lastname"], @"Smith", @"Attributes should be set correctly");
    STAssertEqualObjects([employee valueForKey:@"employeeID"], [NSNumber numberWithInt:5678], @"Attributes should be set correctly");
    STAssertEqualObjects([employee valueForKey:@"startDate"], date, @"Attributes should be set correctly");
}

- (void)testFlatEmployeeWithNetworkPropertyJSONProcessing {
    
    NSData *jsonData = DataFromFile(@"employee_network_property.json");
    
    [[Broker sharedInstance] registerEntityNamed:kEmployee withPrimaryKey:nil];
    
    [[Broker sharedInstance] setDateFormat:kEmployeeStartDateFormat 
                               forProperty:@"startDate" 
                                  onEntity:kEmployee];
    
    [[Broker sharedInstance] mapNetworkProperty:@"id" 
                                toLocalProperty:@"employeeID" 
                                      forEntity:kEmployee];
    
    // Add a new Employee to the store
    NSManagedObjectID *employeeID = [BrokerTestsHelpers createNewEmployee:context];
    
    // Use to hold main thread while bg tasks complete
    __block BOOL hasFinished = NO;
    
    // Chunk dat
    [[Broker sharedInstance] processJSONPayload:jsonData
                                 targetObjectID:employeeID
                            withCompletionBlock:^{
                                hasFinished = YES;
                            }];
    
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:LOOP_WAIT_TIME];    
    while (hasFinished == NO) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }
    
    // Re-fetch
    NSManagedObject *employee = [context objectWithID:employeeID];
        
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:kEmployeeStartDateFormat];
    NSDate *date = [formatter dateFromString:@"2011/10/06 00:51:10 -0700"];
    
    STAssertEqualObjects([employee valueForKey:@"firstname"], @"Andrew", @"Attributes should be set correctly");
    STAssertEqualObjects([employee valueForKey:@"lastname"], @"Smith", @"Attributes should be set correctly");
    STAssertEqualObjects([employee valueForKey:@"employeeID"], [NSNumber numberWithInt:5678], @"Attributes should be set correctly");
    STAssertEqualObjects([employee valueForKey:@"startDate"], date, @"Attributes should be set correctly");
}

- (void)testNestedEmployeeJSONProcessing {
    
    NSData *jsonData = DataFromFile(@"employee_nested.json");
    
    [[Broker sharedInstance] registerEntityNamed:kEmployee withPrimaryKey:nil];
    [[Broker sharedInstance] registerEntityNamed:@"ContactInfo" withPrimaryKey:nil];
    [[Broker sharedInstance] setDateFormat:kEmployeeStartDateFormat 
                               forProperty:@"startDate" 
                                  onEntity:kEmployee];

    // Add a new Employee to the store
    NSManagedObjectID *employeeID = [BrokerTestsHelpers createNewEmployee:context];
    
    // Use to hold main thread while bg tasks complete
    __block BOOL hasFinished = NO;
    
    // Chunk dat
    [[Broker sharedInstance] processJSONPayload:jsonData
                                 targetObjectID:employeeID
                            withCompletionBlock:^{
                                hasFinished = YES;
                            }];
    
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:LOOP_WAIT_TIME];  
    while (hasFinished == NO) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }
    
    // Re-fetch
    NSManagedObject *employee = [context objectWithID:employeeID];
        
    STAssertNotNil([employee valueForKey:@"contactInfo"], @"Should have contactInfo object");
    
    id contactInfo = [employee valueForKey:@"contactInfo"];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:kEmployeeStartDateFormat];
    NSDate *date = [formatter dateFromString:@"2011/10/06 00:51:10 -0700"];

    
    STAssertEqualObjects([contactInfo valueForKey:@"email"], @"andrew@smith.com", @"Should set nested object attributes correctly");
    STAssertEqualObjects([contactInfo valueForKey:@"phone"], [NSNumber numberWithInt:4155556666], @"Should set nested object attributes correctly");
    
    STAssertEqualObjects([employee valueForKey:@"firstname"], @"Andrew", @"Should set attributes correctly");
    STAssertEqualObjects([employee valueForKey:@"lastname"], @"Smith", @"Should set nested object attributes correctly");
    STAssertEqualObjects([employee valueForKey:@"employeeID"], [NSNumber numberWithInt:5678], @"Should set nested object attributes correctly");
    STAssertEqualObjects([employee valueForKey:@"startDate"], date, @"Attributes should be set correctly");
}

- (void)testNestedDepartmentJSONProcessing {
    
    NSData *jsonData = DataFromFile(@"department_nested.json");
    
    // Register Entities
    [[Broker sharedInstance] registerEntityNamed:kDepartment withPrimaryKey:@"departmentID"];
    [[Broker sharedInstance] registerEntityNamed:kEmployee withPrimaryKey:@"employeeID"];
    [[Broker sharedInstance] setDateFormat:kEmployeeStartDateFormat
                               forProperty:@"startDate" 
                                  onEntity:kEmployee];

    // Build Deparment
    NSManagedObjectID *departmentID = [BrokerTestsHelpers createNewDepartment:context];
    
    // Use to hold main thread while bg tasks complete
    __block BOOL hasFinished = NO;
    
    // Chunk dat
    [[Broker sharedInstance] processJSONPayload:jsonData
                                 targetObjectID:departmentID
                            withCompletionBlock:^{
                                hasFinished = YES;
                            }];
    
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:LOOP_WAIT_TIME];    
    while (hasFinished == NO) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }
    
    // Re-fetch
    NSManagedObject *dept = [context objectWithID:departmentID];
        
    STAssertEqualObjects([dept valueForKey:@"name"], @"Engineering", @"Attribute should be set correctly");
    STAssertEqualObjects([dept valueForKey:@"departmentID"], [NSNumber numberWithInt:1234], @"Attribute should be set correctly");

    NSSet *employees = (NSSet *)[dept valueForKey:@"employees"];
    int num = [employees count];
    
    STAssertEquals(num, 6, @"Should have 6 employee objects");
}

- (void)testDepartmentEmployeesJSON {
    
    NSData *jsonData = DataFromFile(@"department_employees.json");
    
    // Register Entities
    [[Broker sharedInstance] registerEntityNamed:kDepartment withPrimaryKey:nil];
    [[Broker sharedInstance] registerEntityNamed:kEmployee withPrimaryKey:@"employeeID"];
    [[Broker sharedInstance] setDateFormat:kEmployeeStartDateFormat 
                               forProperty:@"startDate" 
                                  onEntity:kEmployee];
    
    // Build Deparment
    NSManagedObjectID *departmentID = [BrokerTestsHelpers createNewDepartment:context];
    
    // Use to hold main thread while bg tasks complete
    __block BOOL hasFinished = NO;
    
    // Chunk dat
    [[Broker sharedInstance] processJSONPayload:jsonData 
                                 targetObjectID:departmentID 
                                forRelationship:@"employees" 
                            withCompletionBlock:^{
                                hasFinished = YES;
                            }];
    
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:LOOP_WAIT_TIME];  
    while (hasFinished == NO) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }
    
    // Fetch
    NSManagedObject *dept = [context objectWithID:departmentID];
        
    NSSet *employees = (NSSet *)[dept valueForKey:@"employees"];
    int num = [employees count];
    
    STAssertEquals(num, 6, @"Should have 6 employee objects");
}

- (void)testNestedDepartmentEmployeesJSON {
    
    NSData *jsonData = DataFromFile(@"department_nested.json");
    
    // Register Entities
    [[Broker sharedInstance] registerEntityNamed:kDepartment withPrimaryKey:@"departmentID"];
    [[Broker sharedInstance] registerEntityNamed:kEmployee withPrimaryKey:@"employeeID"];
    [[Broker sharedInstance] setDateFormat:kEmployeeStartDateFormat 
              forProperty:@"startDate" 
                 onEntity:kEmployee];

    // Build Deparment
    NSManagedObjectID *departmentID = [BrokerTestsHelpers createNewDepartment:context];
    
    // Use to hold main thread while bg tasks complete
    __block BOOL hasFinished = NO;
    
    // Chunk dat
    [[Broker sharedInstance] processJSONPayload:jsonData 
                                 targetObjectID:departmentID 
                                forRelationship:@"employees" 
                            withCompletionBlock:^ {
                                hasFinished = YES;
                            }];
    
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:LOOP_WAIT_TIME];
    while (hasFinished == NO) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }
    
    // Fetch
    NSManagedObject *dept = [context objectWithID:departmentID];
        
    NSSet *employees = (NSSet *)[dept valueForKey:@"employees"];
    int num = [employees count];
    
    STAssertEquals(num, 6, @"Should have 6 employee objects");
}

- (void)testShouldIgnoreNonRegisteredEntity {
    
    NSData *jsonData = DataFromFile(@"employee_nested.json");
    
    [[Broker sharedInstance] registerEntityNamed:kEmployee withPrimaryKey:@"employeeID"];
    [[Broker sharedInstance] setDateFormat:kEmployeeStartDateFormat 
                               forProperty:@"startDate" 
                                  onEntity:kEmployee];
    
    // Add a new Employee to the store
    NSManagedObjectID *employeeID = [BrokerTestsHelpers createNewEmployee:context];
    
    // Use to hold main thread while bg tasks complete
    __block BOOL hasFinished = NO;
    
    // Chunk dat
    [[Broker sharedInstance] processJSONPayload:jsonData
                                   targetObjectID:employeeID
                            withCompletionBlock:^{
                                hasFinished = YES;
                            }];
    
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:LOOP_WAIT_TIME]; 
    while (hasFinished == NO) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }
    
    // Re-fetch
    NSManagedObject *employee = [context objectWithID:employeeID];
        
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:kEmployeeStartDateFormat];
    NSDate *date = [formatter dateFromString:@"2011/10/06 00:51:10 -0700"];
    
    STAssertEqualObjects([employee valueForKey:@"firstname"], @"Andrew", @"Should set attributes correctly");
    STAssertEqualObjects([employee valueForKey:@"lastname"], @"Smith", @"Should set nested object attributes correctly");
    STAssertEqualObjects([employee valueForKey:@"employeeID"], [NSNumber numberWithInt:5678], @"Should set nested object attributes correctly");
    STAssertEqualObjects([employee valueForKey:@"startDate"], date, @"Attributes should be set correctly");    
}

- (void)testEmployeeWithRootKeyPath {
    
    NSData *jsonData = DataFromFile(@"employee_root_key.json");
        
    [[Broker sharedInstance] registerEntityNamed:kEmployee withPrimaryKey:@"employeeID"];
    [[Broker sharedInstance] setRootKeyPath:@"response.employee" forEntity:kEmployee];
    [[Broker sharedInstance] setDateFormat:kEmployeeStartDateFormat 
                               forProperty:@"startDate" 
                                  onEntity:kEmployee];
    
    // Add a new Employee to the store
    NSManagedObjectID *employeeID = [BrokerTestsHelpers createNewEmployee:context];
    
    // Use to hold main thread while bg tasks complete
    __block BOOL hasFinished = NO;
    
    // Chunk dat
    [[Broker sharedInstance] processJSONPayload:jsonData
                                 targetObjectID:employeeID
                            withCompletionBlock:^{
                                hasFinished = YES;
                            }];
    
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:LOOP_WAIT_TIME];    
    while (hasFinished == NO) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }
    
    // Re-fetch
    NSManagedObject *employee = [context objectWithID:employeeID];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:kEmployeeStartDateFormat];
    NSDate *date = [formatter dateFromString:@"2011/10/06 00:51:10 -0700"];
        
    STAssertEqualObjects([employee valueForKey:@"firstname"], @"Andrew", @"Should set attributes correctly");
    STAssertEqualObjects([employee valueForKey:@"lastname"], @"Smith", @"Should set nested object attributes correctly");
    STAssertEqualObjects([employee valueForKey:@"employeeID"], [NSNumber numberWithInt:5678], @"Should set nested object attributes correctly");
    STAssertEqualObjects([employee valueForKey:@"startDate"], date, @"Attributes should be set correctly");    
}

- (void)testEmployeeCollection {
    
    NSData *jsonData = DataFromFile(@"department_employees.json");
    
    // Register Entities
    [[Broker sharedInstance] registerEntityNamed:kEmployee withPrimaryKey:@"employeeID"];
    [[Broker sharedInstance] setDateFormat:kEmployeeStartDateFormat 
                               forProperty:@"startDate" 
                                  onEntity:kEmployee];
    
    // Use to hold main thread while bg tasks complete
    __block BOOL hasFinished = NO;
    
    // Chunk dat
    [[Broker sharedInstance] processJSONPayload:jsonData 
                    asCollectionOfEntitiesNamed:@"Employee"
                            withCompletionBlock:^{
                                hasFinished = YES;
                            }];
    
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:LOOP_WAIT_TIME];    
    while (hasFinished == NO) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }
        
    NSArray *employees = [BrokerTestsHelpers findAllEntitiesNamed:@"Employee" inContext:context];
    NSInteger num = employees.count;
    
    STAssertEquals(num, 6, @"Should have 6 employee objects");
}

- (void)testProcess200EmployeeCollection {
    NSData *jsonData = DataFromFile(@"department_employees_200.json");
    
    // Register Entities
    [[Broker sharedInstance] registerEntityNamed:kEmployee withPrimaryKey:@"employeeID"];
    [[Broker sharedInstance] setDateFormat:kEmployeeStartDateFormat 
                               forProperty:@"startDate" 
                                  onEntity:kEmployee];
    
    // Use to hold main thread while bg tasks complete
    __block BOOL hasFinished = NO;
    
    // Chunk dat
    [[Broker sharedInstance] processJSONPayload:jsonData 
                    asCollectionOfEntitiesNamed:@"Employee"
                            withCompletionBlock:^{
                                hasFinished = YES;
                            }];
    
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:LOOP_WAIT_TIME];
    while (hasFinished == NO) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }
    
    NSArray *employees = [BrokerTestsHelpers findAllEntitiesNamed:@"Employee" inContext:context];
    NSInteger num = employees.count;
    
    STAssertEquals(num, 200, @"Should have 200 employee objects");
}

- (void)testProcess200EmployeeCollectionTwice {
    NSData *jsonData = DataFromFile(@"department_employees_200.json");
    
    // Register Entities
    [[Broker sharedInstance] registerEntityNamed:kEmployee withPrimaryKey:@"employeeID"];
    [[Broker sharedInstance] setDateFormat:kEmployeeStartDateFormat 
                               forProperty:@"startDate" 
                                  onEntity:kEmployee];
        
    // Chunk dat
    [[Broker sharedInstance] processJSONPayload:jsonData 
                    asCollectionOfEntitiesNamed:@"Employee"
                            withCompletionBlock:nil];
            
    __block BOOL hasFinished = NO;
    
    // Chunk dat
    [[Broker sharedInstance] processJSONPayload:jsonData 
                    asCollectionOfEntitiesNamed:@"Employee"
                            withCompletionBlock:^{
                                hasFinished = YES;
                            }];
    
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:LOOP_WAIT_TIME];
    while (hasFinished == NO) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }
    
    NSArray *employees = [BrokerTestsHelpers findAllEntitiesNamed:@"Employee" inContext:context];
    NSInteger num = employees.count;
    
    STAssertEquals(num, 200, @"Should have 200 employee objects");
}

- (void)testProcess200EmployeeCollectionTwiceWithDelete {
    NSData *jsonData = DataFromFile(@"department_employees_200.json");
    
    // Register Entities
    [[Broker sharedInstance] registerEntityNamed:kEmployee withPrimaryKey:@"employeeID"];
    [[Broker sharedInstance] setDateFormat:kEmployeeStartDateFormat 
                               forProperty:@"startDate" 
                                  onEntity:kEmployee];
            
    // Chunk dat
    [[Broker sharedInstance] processJSONPayload:jsonData 
                    asCollectionOfEntitiesNamed:@"Employee"
                            withCompletionBlock:nil];
    
    
    NSArray *employees = [BrokerTestsHelpers findAllEntitiesNamed:@"Employee" inContext:context];
    for (NSManagedObject *object in employees) {
        [context deleteObject:object];
    }
        
    __block BOOL hasFinished = NO;
    
    // Chunk dat
    [[Broker sharedInstance] processJSONPayload:jsonData 
                    asCollectionOfEntitiesNamed:@"Employee"
                            withCompletionBlock:^{
                                hasFinished = YES;
                            }];
    
    // Wait for async code to finish
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:LOOP_WAIT_TIME];   
    while (hasFinished == NO) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }  
    
    employees = [BrokerTestsHelpers findAllEntitiesNamed:@"Employee" inContext:context];
    NSInteger num = employees.count;
    
    STAssertEquals(num, 200, @"Should have 200 employee objects");
}


- (void)testDeleteStaleCollectionObjects {
    NSData *jsonData200 = DataFromFile(@"department_employees_200.json");
    NSData *jsonData100 = DataFromFile(@"department_employees_100.json");
    
    // Register Entities
    [[Broker sharedInstance] registerEntityNamed:kEmployee withPrimaryKey:@"employeeID"];
    [[Broker sharedInstance] setDateFormat:kEmployeeStartDateFormat 
                               forProperty:@"startDate" 
                                  onEntity:kEmployee];
        
    [[Broker sharedInstance] processJSONPayload:jsonData200 
                    asCollectionOfEntitiesNamed:@"Employee"
                            withCompletionBlock:nil];

    // This will delete all stale employee objects.  IE objects not included in
    // the new JSON response during the second processing
    BKJSONOperationContextWillSaveBlock willSaveBlock = ^(NSManagedObjectContext *aContext, NSNotification *notification) {
       
        NSArray *updatedEmployess = (NSArray *)[[notification userInfo] objectForKey:NSUpdatedObjectsKey];
        NSArray *allEmployees = [BrokerTestsHelpers findAllEntitiesNamed:@"Employee" inContext:aContext];
        
        for (NSManagedObject *employee in allEmployees) {                        
            if (![updatedEmployess containsObject:employee] && [[employee valueForKey:@"employeeID"] intValue] > 100) {
                [aContext deleteObject:employee];
            }
        }

    };
    
    // Wait
    __block BOOL hasFinished = NO;
    
    // Chunk dat
    [[Broker sharedInstance] processJSONPayload:jsonData100
                    asCollectionOfEntitiesNamed:@"Employee"
                             JSONPreFilterBlock:nil
                          contextWillSaveBlock:willSaveBlock
                                 emptyJSONBlock:nil
                            withCompletionBlock:^{
                                hasFinished = YES;
                            }];
    
    // Wait for async code to finish
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:LOOP_WAIT_TIME];    
    while (hasFinished == NO) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }  

    NSArray *employees = [BrokerTestsHelpers findAllEntitiesNamed:@"Employee" inContext:context];
    NSInteger num = employees.count;
    
    STAssertEquals(num, 100, @"Should have 100 employee objects");
}

- (void)testEmptyJSONBlock {
    NSData *jsonData200 = DataFromFile(@"department_employees_200.json");
    NSData *jsonData0   = DataFromFile(@"department_employees_0.json");
    
    // Register Entities
    [[Broker sharedInstance] registerEntityNamed:kEmployee withPrimaryKey:@"employeeID"];
    [[Broker sharedInstance] setDateFormat:kEmployeeStartDateFormat 
                               forProperty:@"startDate" 
                                  onEntity:kEmployee];
    
    
    [[Broker sharedInstance] processJSONPayload:jsonData200 
                    asCollectionOfEntitiesNamed:@"Employee"
                            withCompletionBlock:nil];
    
    // Delete all employees on an empty JSON list
    BKJSONOperationEmptyJSONBlock emptyJSONBlock = ^(NSManagedObjectContext *aContext) {
        NSArray *allEmployees = [BrokerTestsHelpers findAllEntitiesNamed:@"Employee" inContext:aContext];
        for (NSManagedObject *employee in allEmployees) {                        
            [aContext deleteObject:employee];
        }
    };
    
    // Wait
    __block BOOL hasFinished = NO;
    
    // Chunk dat
    [[Broker sharedInstance] processJSONPayload:jsonData0
                    asCollectionOfEntitiesNamed:@"Employee"
                             JSONPreFilterBlock:nil
                          contextWillSaveBlock:nil
                                 emptyJSONBlock:emptyJSONBlock
                            withCompletionBlock:^ {
                                hasFinished = YES;
                            }];
    
    // Wait for async code to finish
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:LOOP_WAIT_TIME];  
    while (hasFinished == NO) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }  
    
    NSArray *employees = [BrokerTestsHelpers findAllEntitiesNamed:@"Employee" inContext:context];
    NSInteger num = employees.count;
    
    STAssertEquals(num, 0, @"Should have 0 employee objects");
}

#pragma mark - Primary Key

- (void)testCollectionWithNoPrimaryKey {
    NSData *jsonData = DataFromFile(@"department_dogs_nested.json");
    
    // Register Entities
    [[Broker sharedInstance] registerEntityNamed:kDog];
    [[Broker sharedInstance] registerEntityNamed:kDepartment withPrimaryKey:@"departmentID"];
    
    // Build Deparment
    NSManagedObjectID *departmentID = [BrokerTestsHelpers createNewDepartment:context];
    
    // Wait
    __block BOOL hasFinished = NO;
    
    // Chunk dat
    [[Broker sharedInstance] processJSONPayload:jsonData 
                                 targetObjectID:departmentID 
                                forRelationship:@"dogs" 
                            withCompletionBlock:^{
                                hasFinished = YES;
                            }];
    
    // Wait for async code to finish
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:LOOP_WAIT_TIME];   
    while (hasFinished == NO) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }    
        
    // Fetch
    NSManagedObject *dept = [context objectWithID:departmentID];
    
    NSSet *dogs = (NSSet *)[dept valueForKey:@"dogs"];
    int num = [dogs count];
    
    STAssertEquals(num, 6, @"Should have 6 dog objects");
}

- (void)testCollectionWithNoPrimaryKeyTwice {
    
    NSData *jsonData = DataFromFile(@"department_dogs_nested.json");
    
    // Register Entities
    [[Broker sharedInstance] registerEntityNamed:kDog];
    [[Broker sharedInstance] registerEntityNamed:kDepartment withPrimaryKey:@"departmentID"];
    
    // Build Deparment
    NSManagedObjectID *departmentID = [BrokerTestsHelpers createNewDepartment:context];

    
    // Chunk dat
    [[Broker sharedInstance] processJSONPayload:jsonData 
                                 targetObjectID:departmentID 
                                forRelationship:@"dogs" 
                            withCompletionBlock:nil];
    
    // Wait
    __block BOOL hasFinished = NO;
    
    [[Broker sharedInstance] processJSONPayload:jsonData 
                                 targetObjectID:departmentID 
                                forRelationship:@"dogs" 
                            withCompletionBlock:^{
                                hasFinished = YES;
                            }];

    // Wait for async code to finish
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:LOOP_WAIT_TIME];    
    while (hasFinished == NO) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }
    
    // Fetch
    NSManagedObject *dept = [context objectWithID:departmentID];
        
    NSSet *dogs = (NSSet *)[dept valueForKey:@"dogs"];
    int num = [dogs count];
    
    STAssertEquals(num, 12, @"Should have 12 dog objects");
}


#pragma mark - Core Data

- (void)testFindEntityWithPrimaryKey {

    [[Broker sharedInstance] registerEntityNamed:kEmployee withPrimaryKey:@"employeeID"];
    
    NSManagedObjectID *employeeID = [BrokerTestsHelpers createNewFilledOutEmployee:context];
    NSManagedObject *employee = [context objectWithID:employeeID];
    
    BKEntityPropertiesDescription *desc = [[Broker sharedInstance] entityPropertyDescriptionForEntityName:kEmployee];
    
    NSManagedObject *foundEmployee = [context findOrCreateObjectForEntityDescribedBy:desc
                                                                 withPrimaryKeyValue:[NSNumber numberWithInt:12345]
                                                                        shouldCreate:NO];
    
    STAssertEqualObjects(employee, foundEmployee, @"Found URI should be the same as the first created");
}

#pragma mark - BKJSONOperation

- (void)testFilterJSONCollection {
   
    NSData *jsonData = DataFromFile(@"department_employees.json");
   
    // Register Entities
    [[Broker sharedInstance] registerEntityNamed:kDepartment withPrimaryKey:nil];
    [[Broker sharedInstance] registerEntityNamed:kEmployee withPrimaryKey:@"employeeID"];
    [[Broker sharedInstance] setDateFormat:kEmployeeStartDateFormat 
                              forProperty:@"startDate" 
                                 onEntity:kEmployee];
   
    // Build Deparment
    NSManagedObjectID *departmentID = [BrokerTestsHelpers createNewDepartment:context];
      
    BKJSONOperationPreFilterBlock removeEmployeeWithID6 = (id)^(NSManagedObjectContext *context, id jsonObject) {
        if ([jsonObject isKindOfClass:[NSArray class]]) {
            NSMutableArray *newCollection = [[jsonObject mutableCopy] autorelease];
            for (id dictionary in jsonObject) {
                if ([dictionary isKindOfClass:[NSDictionary class]]) {
                    if ([[dictionary valueForKey:@"employeeID"] isEqualToNumber:[NSNumber numberWithInt:6]]) {
                        [newCollection removeObject:dictionary];
                    }
                }
            }
            return newCollection;
        }
        return nil;
    };
    
    __block BOOL hasFinished = NO;
    
    // Chunk dat
    [[Broker sharedInstance] processJSONPayload:jsonData 
                                 targetObjectID:departmentID 
                                forRelationship:@"employees"
                             JSONPreFilterBlock:removeEmployeeWithID6
                            withCompletionBlock:^{
                                hasFinished = YES;
                            }];
   
    // Wait for async code to finish
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:LOOP_WAIT_TIME];  
    while (hasFinished == NO) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }
   
    // Fetch
    NSManagedObject *dept = [context objectWithID:departmentID];
    
    NSSet *employees = (NSSet *)[dept valueForKey:@"employees"];
    int num = [employees count];
        
    BOOL removedEmployee6 = YES;
    for (id employee in employees) {
        if ([[employee valueForKey:@"employeeID"] isEqualToNumber:[NSNumber numberWithInt:6]]) {
            removedEmployee6 = NO;
        }
    }
   
    STAssertEquals(num, 5, @"Should have 5 employee objects");
    STAssertTrue(removedEmployee6, @"Should have eliminated employee during pre filter");
}

@end
