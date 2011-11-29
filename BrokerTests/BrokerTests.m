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

// Department
static NSString *kDepartment = @"Department";
static NSString *kEmployeesRelationship = @"employees";

// Employee
static NSString *kEmployee = @"Employee";
static NSString *kEmployeeFirstname = @"firstname";
static NSString *kDepartmentRelationship = @"department";
static NSString *kEmployeeStartDateFormat = @"yyyy/MM/dd HH:mm:ss zzzz";


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
    context = [[NSManagedObjectContext alloc] init];
    [context setPersistentStoreCoordinator:coord];

    // Setup Broker
    [[Broker sharedInstance] setupWithContext:context];
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
    
    NSURL *employeeURI = [BrokerTestsHelpers createNewEmployee:context];
    NSManagedObject *object = [[Broker sharedInstance] objectForURI:employeeURI inContext:context];
    
    NSDictionary *attributes = object.entity.attributesByName;
    
    NSAttributeDescription *desc = (NSAttributeDescription *)[attributes objectForKey:@"firstname"];
    
    BKAttributeDescription *bkdesc = [BKAttributeDescription descriptionWithAttributeDescription:desc];
    
    NSInteger a = bkdesc.attributeType;
    NSInteger b = NSStringAttributeType;
    
    STAssertEquals(a, b, @"Attributes description should have correct attribute type");
    STAssertEqualObjects(bkdesc.entityName, @"Employee", @"Attribute description should have correct entity name");
}

- (void)testDescriptionWithAttributeDescriptionAndMapToNetworkAttributeName {
    
    NSURL *employeeURI = [BrokerTestsHelpers createNewEmployee:context];
    NSManagedObject *object = [[Broker sharedInstance] objectForURI:employeeURI inContext:context];
    
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
    NSURL *employeeURI = [BrokerTestsHelpers createNewEmployee:context];
    
    // Use to hold main thread while bg tasks complete
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    void (^CompletionBlock)(void) = ^{dispatch_semaphore_signal(sema);}; 

    // Chunk dat
    [[Broker sharedInstance] processJSONPayload:jsonData
                  targetEntity:employeeURI
           withCompletionBlock:CompletionBlock];
    
    // Wait for async code to finish
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    dispatch_release(sema);
    
    // Re-fetch
    NSManagedObject *employee = [[Broker sharedInstance] objectForURI:employeeURI inContext:context];
    
    [context refreshObject:employee mergeChanges:YES];
    
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
    NSURL *employeeURI = [BrokerTestsHelpers createNewEmployee:context];
    
    // Use to hold main thread while bg tasks complete
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    void (^CompletionBlock)(void) = ^{dispatch_semaphore_signal(sema);}; 
    
    // Chunk dat
    [[Broker sharedInstance] processJSONPayload:jsonData
                                   targetEntity:employeeURI
                            withCompletionBlock:CompletionBlock];
    
    // Wait for async code to finish
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    dispatch_release(sema);
    
    // Re-fetch
    NSManagedObject *employee = [[Broker sharedInstance] objectForURI:employeeURI inContext:context];
    
    [context refreshObject:employee mergeChanges:YES];
    
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
    NSURL *employeeURI = [BrokerTestsHelpers createNewEmployee:context];
    
    // Use to hold main thread while bg tasks complete
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    void (^CompletionBlock)(void) = ^{dispatch_semaphore_signal(sema);}; 
    
    // Chunk dat
    [[Broker sharedInstance] processJSONPayload:jsonData
                  targetEntity:employeeURI
           withCompletionBlock:CompletionBlock];
    
    // Wait for async code to finish
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    dispatch_release(sema);
    
    // Re-fetch
    NSManagedObject *employee = [[Broker sharedInstance] objectForURI:employeeURI inContext:context];
    
    [context refreshObject:employee mergeChanges:YES];
    
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
    NSURL *departmentURI = [BrokerTestsHelpers createNewDepartment:context];
    
    // Use to hold main thread while bg tasks complete
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    void (^CompletionBlock)(void) = ^{dispatch_semaphore_signal(sema);}; 
    
    // Chunk dat
    [[Broker sharedInstance] processJSONPayload:jsonData
                                   targetEntity:departmentURI
                            withCompletionBlock:CompletionBlock];
    
    // Wait for async code to finish
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    dispatch_release(sema);
    
    // Re-fetch
    NSManagedObject *dept = [[Broker sharedInstance] objectForURI:departmentURI inContext:context];
    
    [context refreshObject:dept mergeChanges:YES];
    
    STAssertEqualObjects([dept valueForKey:@"name"], @"Engineering", @"Attribute should be set correctly");
    STAssertEqualObjects([dept valueForKey:@"departmentID"], [NSNumber numberWithInt:1234], @"Attribute should be set correctly");

    NSSet *employees = (NSSet *)[dept valueForKey:@"employees"];
    int num = [employees count];
    
    STAssertEquals(num, 6, @"Should have 7 employee objects");
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
    NSURL *departmentURI = [BrokerTestsHelpers createNewDepartment:context];
    
    // Use to hold main thread while bg tasks complete
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    void (^CompletionBlock)(void) = ^{dispatch_semaphore_signal(sema);}; 
    
    // Chunk dat
    [[Broker sharedInstance] processJSONPayload:jsonData 
                  targetEntity:departmentURI 
               forRelationship:@"employees" 
           withCompletionBlock:CompletionBlock];
    
    // Wait for async code to finish
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    dispatch_release(sema);
    
    // Fetch
    NSManagedObject *dept = [[Broker sharedInstance] objectForURI:departmentURI 
                                        inContext:context];
    
    // Refresh
    [context refreshObject:dept mergeChanges:YES];
    
    NSSet *employees = (NSSet *)[dept valueForKey:@"employees"];
    int num = [employees count];
    
    STAssertEquals(num, 6, @"Should have 7 employee objects");
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
    NSURL *departmentURI = [BrokerTestsHelpers createNewDepartment:context];
    
    // Use to hold main thread while bg tasks complete
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    void (^CompletionBlock)(void) = ^{dispatch_semaphore_signal(sema);}; 
    
    // Chunk dat
    [[Broker sharedInstance] processJSONPayload:jsonData 
                  targetEntity:departmentURI 
               forRelationship:nil 
           withCompletionBlock:CompletionBlock];
    
    // Wait for async code to finish
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    dispatch_release(sema);
    
    // Fetch
    NSManagedObject *dept = [[Broker sharedInstance] objectForURI:departmentURI 
                                        inContext:context];
    
    // Refresh
    [context refreshObject:dept mergeChanges:YES];
    
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
    NSURL *employeeURI = [BrokerTestsHelpers createNewEmployee:context];
    
    // Use to hold main thread while bg tasks complete
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    void (^CompletionBlock)(void) = ^{dispatch_semaphore_signal(sema);}; 
    
    // Chunk dat
    [[Broker sharedInstance] processJSONPayload:jsonData
                                   targetEntity:employeeURI
                            withCompletionBlock:CompletionBlock];
    
    // Wait for async code to finish
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    dispatch_release(sema);
    
    // Re-fetch
    NSManagedObject *employee = [[Broker sharedInstance] objectForURI:employeeURI inContext:context];
    
    [context refreshObject:employee mergeChanges:YES];    
    
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
    NSURL *employeeURI = [BrokerTestsHelpers createNewEmployee:context];
    
    // Use to hold main thread while bg tasks complete
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    void (^CompletionBlock)(void) = ^{dispatch_semaphore_signal(sema);}; 
    
    // Chunk dat
    [[Broker sharedInstance] processJSONPayload:jsonData
                                   targetEntity:employeeURI
                            withCompletionBlock:CompletionBlock];
    
    // Wait for async code to finish
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    dispatch_release(sema);
    
    // Re-fetch
    NSManagedObject *employee = [[Broker sharedInstance] objectForURI:employeeURI inContext:context];
    
    [context refreshObject:employee mergeChanges:YES];    

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:kEmployeeStartDateFormat];
    NSDate *date = [formatter dateFromString:@"2011/10/06 00:51:10 -0700"];
        
    STAssertEqualObjects([employee valueForKey:@"firstname"], @"Andrew", @"Should set attributes correctly");
    STAssertEqualObjects([employee valueForKey:@"lastname"], @"Smith", @"Should set nested object attributes correctly");
    STAssertEqualObjects([employee valueForKey:@"employeeID"], [NSNumber numberWithInt:5678], @"Should set nested object attributes correctly");
    STAssertEqualObjects([employee valueForKey:@"startDate"], date, @"Attributes should be set correctly");    
}

#pragma mark - Core Data

- (void)testObjectWithURI {
    
    NSManagedObject *department = [NSEntityDescription insertNewObjectForEntityForName:kDepartment 
                                                                inManagedObjectContext:context];
    
    NSManagedObject *fetchedDepartment = [[Broker sharedInstance] objectForURI:department.objectID.URIRepresentation 
                                                     inContext:context];
     
    STAssertEqualObjects(department, fetchedDepartment, @"Should get the same object");
}

- (void)testFindEntityWithPrimaryKey {

    [[Broker sharedInstance] registerEntityNamed:kEmployee withPrimaryKey:@"employeeID"];
    
    NSURL *employeeURI = [BrokerTestsHelpers createNewFilledOutEmployee:context];
    NSManagedObject *employee = [[Broker sharedInstance] objectForURI:employeeURI inContext:context];
    //[context refreshObject:employee mergeChanges:YES];
    
    BKEntityPropertiesDescription *desc = [[Broker sharedInstance] entityPropertyDescriptionForEntityName:kEmployee];
    
    NSManagedObject *foundEmployee = [[Broker sharedInstance] findOrCreateObjectForEntityDescribedBy:desc
                                                                                 withPrimaryKeyValue:[NSNumber numberWithInt:12345]
                                                                                           inContext:context
                                                                                        shouldCreate:NO];
    
    STAssertEqualObjects(employee, foundEmployee, @"Found URI should be the same as the first created");
}

@end
