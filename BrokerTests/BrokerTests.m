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


@implementation BrokerTests

#pragma mark - Registration

//
//- (void)testRegisterAttributeDescription
//{    
//    [broker registerEntityNamed:kEmployee withPrimaryKey:nil];
//    
//    BKAttributeDescription *desc = [broker attributeDescriptionForProperty:@"firstname"
//                                                              onEntityName:kEmployee];
//    
//    STAssertNotNil(desc, @"Should have an attribute description for property on registered entity");
//    STAssertEqualObjects(desc.entityName, kEmployee, @"Attribute description entity name should be set correctly");
//    STAssertEqualObjects(desc.localPropertyName, kEmployeeFirstname, @"Attribute description local attribute name should be set correctly");
//    STAssertNil(desc.networkPropertyName, @"Attribute description shouldn't have a network attribute name");
//}
//
//- (void)testRegisterAttributeDescriptionWithPropertyMap
//{    
//    [broker registerEntityNamed:kEmployee 
//                 withPrimaryKey:nil
//        andMapNetworkProperties:@[@"first-name"]
//              toLocalProperties:@[@"firstname"]];
//    
//    BKAttributeDescription *desc = [broker attributeDescriptionForProperty:@"firstname"
//                                                                               onEntityName:kEmployee];
//    
//    STAssertEqualObjects(desc.entityName, kEmployee, @"Attribute description entity name should be set correctly");
//    STAssertEqualObjects(desc.localPropertyName, kEmployeeFirstname, @"Attribute description local attribute name should be set correctly");
//    STAssertEqualObjects(desc.networkPropertyName, @"first-name", @"Attribute description network attribute name should be set correctly");
//}
//
//- (void)testRegisterAttributeDescriptionWithPrimaryKey
//{    
//    [broker registerEntityNamed:kEmployee withPrimaryKey:@"employeeID"];
//    
//    BKEntityPropertiesDescription *desc = [broker entityPropertyDescriptionForEntityName:kEmployee];
//
//    STAssertEqualObjects(desc.primaryKey, @"employeeID", @"Attribute description should have a primary key");
//}
//
//- (void)testAddSingleEntryToPropertyMapAfterRegistration {
//    
//    [broker registerEntityNamed:kEmployee withPrimaryKey:nil];
//
//    [broker mapNetworkProperties:@[@"first-name"]
//               toLocalProperties:@[@"firstname"]
//                     forEntity:kEmployee];
//    
//    BKAttributeDescription *desc = [broker attributeDescriptionForProperty:@"firstname"
//                                                                               onEntityName:kEmployee];
//    
//    STAssertEqualObjects(desc.entityName, kEmployee, @"Attribute description entity name should be set correctly");
//    STAssertEqualObjects(desc.localPropertyName, kEmployeeFirstname, @"Attribute description local attribute name should be set correctly");
//    STAssertEqualObjects(desc.networkPropertyName, @"first-name", @"Attribute description network attribute name should be set correctly");
//}
//
//- (void)testRegistrationShouldntLeaveEntitiesInStore {
//    // registration creates objects in the store.  These shouldnt be saved.
//    // Could even register on a separate thread, using separate MOC to be super
//    // safe and fast.  Use isReady flag to know if it can start processing shit.
//    
//    [broker registerEntityNamed:kEmployee withPrimaryKey:@"employeeID"];
//    
//    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:kEmployee 
//                                                         inManagedObjectContext:context];
//    
//    NSFetchRequest *request = [[NSFetchRequest alloc] init];
//    
//    [request setEntity:entityDescription];
//    [request setPredicate:[NSPredicate predicateWithFormat:@"1 = 1"]];
//    
//    NSError *error = nil;
//    NSArray *array = [context executeFetchRequest:request error:&error];
//    
//    STAssertFalse((array.count > 0), @"Broker should not leave straggling entities after registration!");
//}
//
//#pragma mark - Entity Properties Description
//
//- (void)testDescriptionForLocalProperty {
//    [broker registerEntityNamed:kEmployee withPrimaryKey:@"employeeID"];
//    
//    BKEntityPropertiesDescription *desc = [broker entityPropertyDescriptionForEntityName:kEmployee];
//    BKPropertyDescription *localPropDesc = [desc descriptionForLocalProperty:@"employeeID"];
//    
//    STAssertNotNil(localPropDesc, @"Should have an attribute description for a property on a registered entity");
//}
//
//- (void)testDescriptionForLocalPropertyThatDoesntExist {
//    [broker registerEntityNamed:kEmployee withPrimaryKey:@"employeeID"];
//    
//    BKEntityPropertiesDescription *desc = [broker entityPropertyDescriptionForEntityName:kEmployee];
//    BKPropertyDescription *localPropDesc = [desc descriptionForLocalProperty:@"blah"];
//    
//    STAssertNil(localPropDesc, @"Should not have an attribute description for a fake property on a registered entity");
//}
//
//- (void)testDescriptionForNetworkPropertyThatDoesntExist {
//    [broker registerEntityNamed:kEmployee 
//                 withPrimaryKey:@"employeeID" 
//        andMapNetworkProperties:@[@"first-name"]
//              toLocalProperties:@[@"firstname"]];
//    
//    BKEntityPropertiesDescription *desc = [broker entityPropertyDescriptionForEntityName:kEmployee];
//    BKPropertyDescription *networkPropDesc = [desc descriptionForNetworkProperty:@"blah"];
//    
//    STAssertNil(networkPropDesc, @"Should not have an attribute description for a fake network property on a registered entity");
//}
//
//#pragma mark - Attribute Description
//
//- (void)testDescriptionWithAttributeDescription {
//    
//    NSManagedObjectID *employeeID = [BrokerTestsHelpers createNewEmployee:context];
//    NSManagedObject *object = [context objectWithID:employeeID];
//    
//    NSDictionary *attributes = object.entity.attributesByName;
//    
//    NSAttributeDescription *desc = (NSAttributeDescription *)[attributes objectForKey:@"firstname"];
//    
//    BKAttributeDescription *bkdesc = [BKAttributeDescription descriptionWithAttributeDescription:desc];
//    
//    NSInteger a = bkdesc.attributeType;
//    NSInteger b = NSStringAttributeType;
//    
//    STAssertEquals(a, b, @"Attributes description should have correct attribute type");
//    STAssertEqualObjects(bkdesc.entityName, @"Employee", @"Attribute description should have correct entity name");
//}
//
//- (void)testDescriptionWithAttributeDescriptionAndMapToNetworkAttributeName {
//    
//    NSManagedObjectID *employeeID = [BrokerTestsHelpers createNewEmployee:context];
//    NSManagedObject *object = [context objectWithID:employeeID];
//    
//    NSDictionary *attributes = object.entity.attributesByName;
//    
//    NSAttributeDescription *desc = (NSAttributeDescription *)[attributes objectForKey:@"firstname"];
//    
//    BKAttributeDescription *bkdesc = [BKAttributeDescription descriptionWithAttributeDescription:desc 
//                                                                    andMapToNetworkAttributeName:@"first-name"];
//    
//    STAssertEqualObjects(bkdesc.networkPropertyName, @"first-name", @"Attribute description should have correct network name");
//    STAssertEqualObjects(bkdesc.localPropertyName, @"firstname", @"Attribute description should have correct local name");
//}
//
//#pragma mark - Accessors
//
//- (void)testEntityPropertyDescriptionForEntityName {
//    [broker registerEntityNamed:kEmployee withPrimaryKey:@"employeeID"];
//    
//    BKEntityPropertiesDescription *desc = [broker entityPropertyDescriptionForEntityName:kEmployee];
//    
//    STAssertNotNil(desc, @"Should have entity property description for registered entity");
//}
//
//- (void)testAttributeDescriptionForPropertyOnEntityName
//{
//    [broker registerEntityNamed:kEmployee withPrimaryKey:@"employeeID"];
//
//    BKAttributeDescription *desc = [broker attributeDescriptionForProperty:@"employeeID" 
//                                                              onEntityName:kEmployee];
//    
//    STAssertNotNil(desc, @"Should have an attribute description for a property on a registered entity");
//}
//
//- (void)testRelationshipDescriptionForPropertyOnEntityName
//{
//    [broker registerEntityNamed:kEmployee withPrimaryKey:@"employeeID"];
//    
//    BKRelationshipDescription *desc = [broker relationshipDescriptionForProperty:@"department"
//                                                                    onEntityName:@"Employee"];
//    
//    STAssertNotNil(desc, @"Should have a relationship description for a property on a registered entity");
//}
//
//#pragma mark - Transform
//
//- (void)testTransformJSONDictionaryClassesAreCorrect
//{        
//    NSDictionary *fakeJSON = [NSDictionary dictionaryWithObjects:@[@"Andrew", @"Smith", @"5678", @"2011/10/06 00:51:10 -0700"]
//                                                         forKeys:@[@"firstname", @"lastname", @"employeeID", @"startDate"]];
//    
//    [broker registerEntityNamed:kEmployee withPrimaryKey:nil];
//    
//    [broker setDateFormat:kEmployeeStartDateFormat 
//              forProperty:@"startDate" 
//                 onEntity:kEmployee];
//    
//    BKEntityPropertiesDescription *desc = [broker entityPropertyDescriptionForEntityName:kEmployee];
//        
//    NSDictionary *transformedDict = [broker transformJSONDictionary:fakeJSON 
//                                   usingEntityPropertiesDescription:desc];
//
//    STAssertTrue([[transformedDict objectForKey:@"firstname"] isKindOfClass:[NSString class]], @"Transform dictionary should properly set class type");
//    STAssertTrue([[transformedDict objectForKey:@"lastname"] isKindOfClass:[NSString class]], @"Transform dictionary should properly set class type");
//    STAssertTrue([[transformedDict objectForKey:@"employeeID"] isKindOfClass:[NSNumber class]], @"Transform dictionary should properly set class type");
//    STAssertTrue([[transformedDict objectForKey:@"startDate"] isKindOfClass:[NSDate class]], @"Transform dictionary should properly set class type");
//}
//
//- (void)testTransformJSONDictionaryValuesAreCorrect
//{    
//    NSDictionary *fakeJSON = [NSDictionary dictionaryWithObjects:@[@"Andrew", @"Smith", @"5678", @"2011/10/06 00:51:10 -0700"]
//                                                         forKeys:@[@"firstname", @"lastname", @"employeeID", @"startDate"]];
//    
//    [broker registerEntityNamed:kEmployee withPrimaryKey:nil];
//    
//    [broker setDateFormat:kEmployeeStartDateFormat 
//              forProperty:@"startDate" 
//                 onEntity:kEmployee];
//    
//    BKEntityPropertiesDescription *desc = [broker entityPropertyDescriptionForEntityName:kEmployee];
//    
//    NSDictionary *transformedDict = [broker transformJSONDictionary:fakeJSON 
//                                                    usingEntityPropertiesDescription:desc];
//    
//    
//    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
//    [formatter setDateFormat:kEmployeeStartDateFormat];
//    NSDate *date = [formatter dateFromString:@"2011/10/06 00:51:10 -0700"];
//    
//    STAssertEqualObjects([transformedDict valueForKey:@"firstname"], @"Andrew", @"Attributes should be set correctly");
//    STAssertEqualObjects([transformedDict valueForKey:@"lastname"], @"Smith", @"Attributes should be set correctly");
//    STAssertEqualObjects([transformedDict valueForKey:@"employeeID"], @5678, @"Attributes should be set correctly");
//    STAssertEqualObjects([transformedDict valueForKey:@"startDate"], date, @"Attributes should be set correctly");
//}
//
//#pragma mark - Processing
//
//- (void)testFlatEmployeeJSONProcessing
//{
//    NSData *jsonData = DataFromFile(@"employee_flat.json");
//    
//    [broker registerEntityNamed:kEmployee withPrimaryKey:nil];
//    [broker setDateFormat:kEmployeeStartDateFormat 
//              forProperty:@"startDate" 
//                 onEntity:kEmployee];
//
//    // Add a new Employee to the store
//    NSManagedObjectID *employeeID = [BrokerTestsHelpers createNewEmployee:context];
//    
//    // Chunk dat
//    [broker processJSONPayload:jsonData
//               usingQueueNamed:kBrokerTestQueue
//                targetObjectID:employeeID
//               forRelationship:nil
//            JSONPreFilterBlock:nil
//           withCompletionBlock:nil];
//    
//    [broker waitForQueueNamed:kBrokerTestQueue];
//    
//    // Re-fetch
//    NSManagedObject *employee = [context objectWithID:employeeID];
//        
//    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
//    [formatter setDateFormat:kEmployeeStartDateFormat];
//    NSDate *date = [formatter dateFromString:@"2011/10/06 00:51:10 -0700"];
//    
//    STAssertEqualObjects([employee valueForKey:@"firstname"], @"Andrew", @"Attributes should be set correctly");
//    STAssertEqualObjects([employee valueForKey:@"lastname"], @"Smith", @"Attributes should be set correctly");
//    STAssertEqualObjects([employee valueForKey:@"employeeID"], @5678, @"Attributes should be set correctly");
//    STAssertEqualObjects([employee valueForKey:@"startDate"], date, @"Attributes should be set correctly");
//}
//
//- (void)testFlatEmployeeWithNetworkPropertyJSONProcessing {
//    
//    NSData *jsonData = DataFromFile(@"employee_network_property.json");
//    
//    [broker registerEntityNamed:kEmployee withPrimaryKey:nil];
//    
//    [broker setDateFormat:kEmployeeStartDateFormat 
//                               forProperty:@"startDate" 
//                                  onEntity:kEmployee];
//    
//    [broker mapNetworkProperties:@[@"id"]
//               toLocalProperties:@[@"employeeID"]
//                       forEntity:kEmployee];
//    
//    // Add a new Employee to the store
//    NSManagedObjectID *employeeID = [BrokerTestsHelpers createNewEmployee:context];
//    
//    // Chunk dat
//    [broker processJSONPayload:jsonData
//               usingQueueNamed:kBrokerTestQueue
//                targetObjectID:employeeID
//               forRelationship:nil
//            JSONPreFilterBlock:nil
//           withCompletionBlock:nil];
//    
//    [broker waitForQueueNamed:kBrokerTestQueue];
//    
//    // Re-fetch
//    NSManagedObject *employee = [context objectWithID:employeeID];
//        
//    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
//    [formatter setDateFormat:kEmployeeStartDateFormat];
//    NSDate *date = [formatter dateFromString:@"2011/10/06 00:51:10 -0700"];
//    
//    STAssertEqualObjects([employee valueForKey:@"firstname"], @"Andrew", @"Attributes should be set correctly");
//    STAssertEqualObjects([employee valueForKey:@"lastname"], @"Smith", @"Attributes should be set correctly");
//    STAssertEqualObjects([employee valueForKey:@"employeeID"], @5678, @"Attributes should be set correctly");
//    STAssertEqualObjects([employee valueForKey:@"startDate"], date, @"Attributes should be set correctly");
//}
//
//- (void)testNestedEmployeeJSONProcessing {
//    
//    NSData *jsonData = DataFromFile(@"employee_nested.json");
//    
//    [broker registerEntityNamed:kEmployee withPrimaryKey:nil];
//    [broker registerEntityNamed:@"ContactInfo" withPrimaryKey:nil];
//    [broker setDateFormat:kEmployeeStartDateFormat 
//                               forProperty:@"startDate" 
//                                  onEntity:kEmployee];
//
//    // Add a new Employee to the store
//    NSManagedObjectID *employeeID = [BrokerTestsHelpers createNewEmployee:context];
//    
//    // Chunk dat
//    [broker processJSONPayload:jsonData
//               usingQueueNamed:kBrokerTestQueue
//                targetObjectID:employeeID
//               forRelationship:nil
//            JSONPreFilterBlock:nil
//           withCompletionBlock:nil];
//    
//    [broker waitForQueueNamed:kBrokerTestQueue];
//    
//    // Re-fetch
//    NSManagedObject *employee = [context objectWithID:employeeID];
//        
//    STAssertNotNil([employee valueForKey:@"contactInfo"], @"Should have contactInfo object");
//    
//    id contactInfo = [employee valueForKey:@"contactInfo"];
//    
//    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
//    [formatter setDateFormat:kEmployeeStartDateFormat];
//    NSDate *date = [formatter dateFromString:@"2011/10/06 00:51:10 -0700"];
//    
//    STAssertEqualObjects([contactInfo valueForKey:@"email"], @"andrew@smith.com", @"Should set nested object attributes correctly");
//    STAssertEqualObjects([contactInfo valueForKey:@"phone"], @4155556666, @"Should set nested object attributes correctly");
//    
//    STAssertEqualObjects([employee valueForKey:@"firstname"], @"Andrew", @"Should set attributes correctly");
//    STAssertEqualObjects([employee valueForKey:@"lastname"], @"Smith", @"Should set nested object attributes correctly");
//    STAssertEqualObjects([employee valueForKey:@"employeeID"], @5678, @"Should set nested object attributes correctly");
//    STAssertEqualObjects([employee valueForKey:@"startDate"], date, @"Attributes should be set correctly");
//}
//
//- (void)testNestedDepartmentJSONProcessing {
//    
//    NSData *jsonData = DataFromFile(@"department_nested.json");
//    
//    // Register Entities
//    [broker registerEntityNamed:kDepartment withPrimaryKey:@"departmentID"];
//    [broker registerEntityNamed:kEmployee withPrimaryKey:@"employeeID"];
//    [broker setDateFormat:kEmployeeStartDateFormat
//                               forProperty:@"startDate" 
//                                  onEntity:kEmployee];
//
//    // Build Deparment
//    NSManagedObjectID *departmentID = [BrokerTestsHelpers createNewDepartment:context];
//        
//    // Chunk dat
//    [broker processJSONPayload:jsonData
//               usingQueueNamed:kBrokerTestQueue
//                targetObjectID:departmentID
//               forRelationship:nil
//            JSONPreFilterBlock:nil
//           withCompletionBlock:nil];
//    
//    [broker waitForQueueNamed:kBrokerTestQueue];
//
//    // Re-fetch
//    NSManagedObject *dept = [context objectWithID:departmentID];
//        
//    STAssertEqualObjects([dept valueForKey:@"name"], @"Engineering", @"Attribute should be set correctly");
//    STAssertEqualObjects([dept valueForKey:@"departmentID"], @1234, @"Attribute should be set correctly");
//
//    NSSet *employees = (NSSet *)[dept valueForKey:@"employees"];
//    int num = [employees count];
//    
//    STAssertEquals(num, 6, @"Should have 6 employee objects");
//}
//
//- (void)testDepartmentEmployeesJSON {
//    
//    NSData *jsonData = DataFromFile(@"department_employees.json");
//    
//    // Register Entities
//    [broker registerEntityNamed:kDepartment withPrimaryKey:nil];
//    [broker registerEntityNamed:kEmployee withPrimaryKey:@"employeeID"];
//    [broker setDateFormat:kEmployeeStartDateFormat 
//                               forProperty:@"startDate" 
//                                  onEntity:kEmployee];
//    
//    // Build Deparment
//    NSManagedObjectID *departmentID = [BrokerTestsHelpers createNewDepartment:context];
//    
//    [broker processJSONPayload:jsonData
//               usingQueueNamed:kBrokerTestQueue
//                targetObjectID:departmentID
//               forRelationship:@"employees"
//            JSONPreFilterBlock:nil
//           withCompletionBlock:nil];
//    
//    [broker waitForQueueNamed:kBrokerTestQueue];
//    
//    // Fetch
//    NSManagedObject *dept = [context objectWithID:departmentID];
//        
//    NSSet *employees = (NSSet *)[dept valueForKey:@"employees"];
//    int num = [employees count];
//    
//    STAssertEquals(num, 6, @"Should have 6 employee objects");
//}
//
//- (void)testNestedDepartmentEmployeesJSON {
//    
//    NSData *jsonData = DataFromFile(@"department_nested.json");
//    
//    // Register Entities
//    [broker registerEntityNamed:kDepartment withPrimaryKey:@"departmentID"];
//    [broker registerEntityNamed:kEmployee withPrimaryKey:@"employeeID"];
//    [broker setDateFormat:kEmployeeStartDateFormat 
//              forProperty:@"startDate" 
//                 onEntity:kEmployee];
//
//    // Build Deparment
//    NSManagedObjectID *departmentID = [BrokerTestsHelpers createNewDepartment:context];
//    
//    [broker processJSONPayload:jsonData
//               usingQueueNamed:kBrokerTestQueue
//                targetObjectID:departmentID
//               forRelationship:@"employees"
//            JSONPreFilterBlock:nil
//           withCompletionBlock:nil];
//    
//    [broker waitForQueueNamed:kBrokerTestQueue];
//    
//    // Fetch
//    NSManagedObject *dept = [context objectWithID:departmentID];
//        
//    NSSet *employees = (NSSet *)[dept valueForKey:@"employees"];
//    int num = [employees count];
//    
//    STAssertEquals(num, 6, @"Should have 6 employee objects");
//}
//
//- (void)testShouldIgnoreNonRegisteredEntity {
//    
//    NSData *jsonData = DataFromFile(@"employee_nested.json");
//    
//    [broker registerEntityNamed:kEmployee withPrimaryKey:@"employeeID"];
//    [broker setDateFormat:kEmployeeStartDateFormat 
//                               forProperty:@"startDate" 
//                                  onEntity:kEmployee];
//    
//    // Add a new Employee to the store
//    NSManagedObjectID *employeeID = [BrokerTestsHelpers createNewEmployee:context];
//    
//    // Chunk dat
//    [broker processJSONPayload:jsonData
//               usingQueueNamed:kBrokerTestQueue
//                targetObjectID:employeeID
//               forRelationship:nil
//            JSONPreFilterBlock:nil
//           withCompletionBlock:nil];
//    
//    [broker waitForQueueNamed:kBrokerTestQueue];
//    
//    // Re-fetch
//    NSManagedObject *employee = [context objectWithID:employeeID];
//        
//    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
//    [formatter setDateFormat:kEmployeeStartDateFormat];
//    NSDate *date = [formatter dateFromString:@"2011/10/06 00:51:10 -0700"];
//    
//    STAssertEqualObjects([employee valueForKey:@"firstname"], @"Andrew", @"Should set attributes correctly");
//    STAssertEqualObjects([employee valueForKey:@"lastname"], @"Smith", @"Should set nested object attributes correctly");
//    STAssertEqualObjects([employee valueForKey:@"employeeID"], @5678, @"Should set nested object attributes correctly");
//    STAssertEqualObjects([employee valueForKey:@"startDate"], date, @"Attributes should be set correctly");    
//}
//
//- (void)testEmployeeWithRootKeyPath {
//    
//    NSData *jsonData = DataFromFile(@"employee_root_key.json");
//        
//    [broker registerEntityNamed:kEmployee withPrimaryKey:@"employeeID"];
//    [broker setRootKeyPath:@"response.employee" forEntity:kEmployee];
//    [broker setDateFormat:kEmployeeStartDateFormat 
//                               forProperty:@"startDate" 
//                                  onEntity:kEmployee];
//    
//    // Add a new Employee to the store
//    NSManagedObjectID *employeeID = [BrokerTestsHelpers createNewEmployee:context];
//    
//    // Chunk dat
//    [broker processJSONPayload:jsonData
//               usingQueueNamed:kBrokerTestQueue
//                targetObjectID:employeeID
//               forRelationship:nil
//            JSONPreFilterBlock:nil
//           withCompletionBlock:nil];
//    
//    [broker waitForQueueNamed:kBrokerTestQueue];
//    
//    // Re-fetch
//    NSManagedObject *employee = [context objectWithID:employeeID];
//    
//    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
//    [formatter setDateFormat:kEmployeeStartDateFormat];
//    NSDate *date = [formatter dateFromString:@"2011/10/06 00:51:10 -0700"];
//        
//    STAssertEqualObjects([employee valueForKey:@"firstname"], @"Andrew", @"Should set attributes correctly");
//    STAssertEqualObjects([employee valueForKey:@"lastname"], @"Smith", @"Should set nested object attributes correctly");
//    STAssertEqualObjects([employee valueForKey:@"employeeID"], @5678, @"Should set nested object attributes correctly");
//    STAssertEqualObjects([employee valueForKey:@"startDate"], date, @"Attributes should be set correctly");    
//}
//
//- (void)testEmployeeCollection {
//    
//    NSData *jsonData = DataFromFile(@"department_employees.json");
//    
//    // Register Entities
//    [broker registerEntityNamed:kEmployee withPrimaryKey:@"employeeID"];
//    [broker setDateFormat:kEmployeeStartDateFormat 
//                               forProperty:@"startDate" 
//                                  onEntity:kEmployee];
//    
//    [broker processJSONPayload:jsonData
//               usingQueueNamed:kBrokerTestQueue
//   asCollectionOfEntitiesNamed:@"Employee"
//            JSONPreFilterBlock:nil
//         contextDidChangeBlock:nil
//                emptyJSONBlock:nil
//               completionBlock:nil];
//    
//    [broker waitForQueueNamed:kBrokerTestQueue];
//        
//    NSArray *employees = [BrokerTestsHelpers findAllEntitiesNamed:@"Employee" inContext:context];
//    NSInteger num = employees.count;
//    
//    STAssertEquals(num, 6, @"Should have 6 employee objects");
//}
//
//- (void)testProcess200EmployeeCollection {
//    NSData *jsonData = DataFromFile(@"department_employees_200.json");
//    
//    // Register Entities
//    [broker registerEntityNamed:kEmployee withPrimaryKey:@"employeeID"];
//    [broker setDateFormat:kEmployeeStartDateFormat 
//                               forProperty:@"startDate" 
//                                  onEntity:kEmployee];
//    
//    [broker processJSONPayload:jsonData
//               usingQueueNamed:kBrokerTestQueue
//   asCollectionOfEntitiesNamed:@"Employee"
//            JSONPreFilterBlock:nil
//         contextDidChangeBlock:nil
//                emptyJSONBlock:nil
//               completionBlock:nil];
//    
//    [broker waitForQueueNamed:kBrokerTestQueue];
//    
//    NSArray *employees = [BrokerTestsHelpers findAllEntitiesNamed:@"Employee" inContext:context];
//    NSInteger num = employees.count;
//    
//    STAssertEquals(num, 200, @"Should have 200 employee objects");
//}
//
//- (void)testProcess200EmployeeCollectionTwice {
//    NSData *jsonData = DataFromFile(@"department_employees_200.json");
//    
//    // Register Entities
//    [broker registerEntityNamed:kEmployee withPrimaryKey:@"employeeID"];
//    [broker setDateFormat:kEmployeeStartDateFormat 
//                               forProperty:@"startDate" 
//                                  onEntity:kEmployee];
//        
//    // Chunk dat    
//    [broker processJSONPayload:jsonData
//               usingQueueNamed:kBrokerTestQueue
//   asCollectionOfEntitiesNamed:@"Employee"
//            JSONPreFilterBlock:nil
//         contextDidChangeBlock:nil
//                emptyJSONBlock:nil
//               completionBlock:nil];
//                
//    // Chunk dat
//    [broker processJSONPayload:jsonData
//               usingQueueNamed:kBrokerTestQueue
//   asCollectionOfEntitiesNamed:@"Employee"
//            JSONPreFilterBlock:nil
//         contextDidChangeBlock:nil
//                emptyJSONBlock:nil
//               completionBlock:nil];
//    
//    [broker waitForQueueNamed:kBrokerTestQueue];
//
//    NSArray *employees = [BrokerTestsHelpers findAllEntitiesNamed:@"Employee" inContext:context];
//    NSInteger num = employees.count;
//    
//    STAssertEquals(num, 200, @"Should have 200 employee objects");
//}
//
//- (void)testProcess200EmployeeCollectionManyTimes {
//    NSData *jsonData = DataFromFile(@"department_employees_200.json");
//    
//    // Register Entities
//    [broker registerEntityNamed:kEmployee withPrimaryKey:@"employeeID"];
//    [broker setDateFormat:kEmployeeStartDateFormat
//              forProperty:@"startDate"
//                 onEntity:kEmployee];
//    
//    for (int i = 0; i < 5; i++){
//        // Chunk dat
//        [broker processJSONPayload:jsonData
//                   usingQueueNamed:kBrokerTestQueue
//       asCollectionOfEntitiesNamed:@"Employee"
//                JSONPreFilterBlock:nil
//             contextDidChangeBlock:nil
//                    emptyJSONBlock:nil
//                   completionBlock:nil];
//    }
//    
//    [broker waitForQueueNamed:kBrokerTestQueue];
//    
//    NSArray *employees = [BrokerTestsHelpers findAllEntitiesNamed:@"Employee" inContext:context];
//    NSInteger num = employees.count;
//    
//    STAssertEquals(num, 200, @"Should have 200 employee objects");
//}
//
//- (void)testProcess200EmployeeCollectionTwiceWithDelete {
//    NSData *jsonData = DataFromFile(@"department_employees_200.json");
//    
//    // Register Entities
//    [broker registerEntityNamed:kEmployee withPrimaryKey:@"employeeID"];
//    [broker setDateFormat:kEmployeeStartDateFormat 
//                               forProperty:@"startDate" 
//                                  onEntity:kEmployee];
//            
//    // Chunk dat
//    [broker processJSONPayload:jsonData
//               usingQueueNamed:kBrokerTestQueue
//   asCollectionOfEntitiesNamed:@"Employee"
//            JSONPreFilterBlock:nil
//         contextDidChangeBlock:nil
//                emptyJSONBlock:nil
//               completionBlock:nil];
//    
//    
//    NSArray *employees = [BrokerTestsHelpers findAllEntitiesNamed:@"Employee" inContext:context];
//    for (NSManagedObject *object in employees) {
//        [context deleteObject:object];
//    }
//            
//    // Chunk dat
//    [broker processJSONPayload:jsonData
//               usingQueueNamed:kBrokerTestQueue
//   asCollectionOfEntitiesNamed:@"Employee"
//            JSONPreFilterBlock:nil
//         contextDidChangeBlock:nil
//                emptyJSONBlock:nil
//               completionBlock:nil];
//    
//    [broker waitForQueueNamed:kBrokerTestQueue];
//    
//    employees = [BrokerTestsHelpers findAllEntitiesNamed:@"Employee" inContext:context];
//    NSInteger num = employees.count;
//    
//    STAssertEquals(num, 200, @"Should have 200 employee objects");
//}
//
//
//- (void)testDeleteStaleCollectionObjects {
//    NSData *jsonData200 = DataFromFile(@"department_employees_200.json");
//    NSData *jsonData100 = DataFromFile(@"department_employees_100.json");
//    
//    // Register Entities
//    [broker registerEntityNamed:kEmployee withPrimaryKey:@"employeeID"];
//    [broker setDateFormat:kEmployeeStartDateFormat 
//                               forProperty:@"startDate" 
//                                  onEntity:kEmployee];
//        
//    [broker processJSONPayload:jsonData200
//               usingQueueNamed:kBrokerTestQueue
//   asCollectionOfEntitiesNamed:@"Employee"
//            JSONPreFilterBlock:nil
//         contextDidChangeBlock:nil
//                emptyJSONBlock:nil
//               completionBlock:nil];
//    
//    // This will delete all stale employee objects.  IE objects not included in
//    // the new JSON response during the second processing
//    BKJSONOperationContextDidChangeBlock didChangeBlock = ^(NSManagedObjectContext *aContext, NSNotification *notification) {
//       
//        NSArray *updatedEmployess = (NSArray *)[[notification userInfo] objectForKey:NSUpdatedObjectsKey];
//        NSArray *allEmployees = [BrokerTestsHelpers findAllEntitiesNamed:@"Employee" inContext:aContext];
//        
//        for (NSManagedObject *employee in allEmployees) {                        
//            if (![updatedEmployess containsObject:employee] && [[employee valueForKey:@"employeeID"] intValue] > 100) {
//                [aContext deleteObject:employee];
//            }
//        }
//
//    };
//    
//    [broker processJSONPayload:jsonData100
//               usingQueueNamed:kBrokerTestQueue
//   asCollectionOfEntitiesNamed:@"Employee"
//            JSONPreFilterBlock:nil
//         contextDidChangeBlock:didChangeBlock
//                emptyJSONBlock:nil
//               completionBlock:nil];
//    
//    [broker waitForQueueNamed:kBrokerTestQueue]; 
//
//    NSArray *employees = [BrokerTestsHelpers findAllEntitiesNamed:@"Employee" inContext:context];
//    NSInteger num = employees.count;
//    
//    STAssertEquals(num, 100, @"Should have 100 employee objects");
//}
//
//- (void)testEmptyJSONBlock {
//    NSData *jsonData200 = DataFromFile(@"department_employees_200.json");
//    NSData *jsonData0   = DataFromFile(@"department_employees_0.json");
//    
//    // Register Entities
//    [broker registerEntityNamed:kEmployee withPrimaryKey:@"employeeID"];
//    [broker setDateFormat:kEmployeeStartDateFormat 
//                               forProperty:@"startDate" 
//                                  onEntity:kEmployee];
//    
//    [broker processJSONPayload:jsonData200
//               usingQueueNamed:kBrokerTestQueue
//   asCollectionOfEntitiesNamed:@"Employee"
//            JSONPreFilterBlock:nil
//         contextDidChangeBlock:nil
//                emptyJSONBlock:nil
//               completionBlock:nil];
//    
//    // Delete all employees on an empty JSON list
//    BKJSONOperationEmptyJSONBlock emptyJSONBlock = ^(NSManagedObjectContext *aContext) {
//        NSArray *allEmployees = [BrokerTestsHelpers findAllEntitiesNamed:@"Employee" inContext:aContext];
//        for (NSManagedObject *employee in allEmployees) {                        
//            [aContext deleteObject:employee];
//        }
//    };
//    
//    // Chunk dat
//    [broker processJSONPayload:jsonData0
//               usingQueueNamed:kBrokerTestQueue
//   asCollectionOfEntitiesNamed:@"Employee"
//            JSONPreFilterBlock:nil
//         contextDidChangeBlock:nil
//                emptyJSONBlock:emptyJSONBlock
//               completionBlock:nil];
//    
//    [broker waitForQueueNamed:kBrokerTestQueue];
//
//    NSArray *employees = [BrokerTestsHelpers findAllEntitiesNamed:@"Employee" inContext:context];
//    NSInteger num = employees.count;
//    
//    STAssertEquals(num, 0, @"Should have 0 employee objects");
//}
//
//#pragma mark - Primary Key
//
//- (void)testCollectionWithNoPrimaryKey
//{
//    NSData *jsonData = DataFromFile(@"department_dogs_nested.json");
//    
//    // Register Entities
//    [broker registerEntityNamed:kDog];
//    [broker registerEntityNamed:kDepartment withPrimaryKey:@"departmentID"];
//    
//    // Build Deparment
//    NSManagedObjectID *departmentID = [BrokerTestsHelpers createNewDepartment:context];
//    
//    // Chunk dat
//    [broker processJSONPayload:jsonData
//               usingQueueNamed:kBrokerTestQueue
//                targetObjectID:departmentID
//               forRelationship:@"dogs"
//            JSONPreFilterBlock:nil
//           withCompletionBlock:nil];
//    
//    [broker waitForQueueNamed:kBrokerTestQueue];
//    
//    // Fetch
//    NSManagedObject *dept = [context objectWithID:departmentID];
//    
//    NSSet *dogs = (NSSet *)[dept valueForKey:@"dogs"];
//    int num = [dogs count];
//    
//    STAssertEquals(num, 6, @"Should have 6 dog objects");
//}
//
//- (void)testCollectionWithNoPrimaryKeyTwice {
//    
//    NSData *jsonData = DataFromFile(@"department_dogs_nested.json");
//    
//    // Register Entities
//    [broker registerEntityNamed:kDog];
//    [broker registerEntityNamed:kDepartment withPrimaryKey:@"departmentID"];
//    
//    // Build Deparment
//    NSManagedObjectID *departmentID = [BrokerTestsHelpers createNewDepartment:context];
//    
//    // Chunk dat
//    [broker processJSONPayload:jsonData
//               usingQueueNamed:kBrokerTestQueue
//                targetObjectID:departmentID
//               forRelationship:@"dogs"
//            JSONPreFilterBlock:nil
//           withCompletionBlock:nil];
//    
//    [broker waitForQueueNamed:kBrokerTestQueue];
//    
//    [broker processJSONPayload:jsonData
//               usingQueueNamed:kBrokerTestQueue
//                targetObjectID:departmentID
//               forRelationship:@"dogs"
//            JSONPreFilterBlock:nil
//           withCompletionBlock:nil];
//
//    [broker waitForQueueNamed:kBrokerTestQueue];
//    
//    // Fetch
//    NSManagedObject *dept = [context objectWithID:departmentID];
//        
//    NSSet *dogs = (NSSet *)[dept valueForKey:@"dogs"];
//    int num = [dogs count];
//    
//    STAssertEquals(num, 12, @"Should have 12 dog objects");
//}
//
//
//#pragma mark - Core Data
//
//- (void)testFindEntityWithPrimaryKey {
//
//    [broker registerEntityNamed:kEmployee withPrimaryKey:@"employeeID"];
//    
//    NSManagedObjectID *employeeID = [BrokerTestsHelpers createNewFilledOutEmployee:context];
//    NSManagedObject *employee = [context objectWithID:employeeID];
//    
//    BKEntityPropertiesDescription *desc = [broker entityPropertyDescriptionForEntityName:kEmployee];
//    
//    NSManagedObject *foundEmployee = [context findOrCreateObjectForEntityDescribedBy:desc
//                                                                 withPrimaryKeyValue:@12345
//                                                                        shouldCreate:NO];
//    
//    STAssertEqualObjects(employee, foundEmployee, @"Found URI should be the same as the first created");
//}
//
//#pragma mark - BKJSONOperation
//
//- (void)testFilterJSONCollection {
//   
//    NSData *jsonData = DataFromFile(@"department_employees.json");
//   
//    // Register Entities
//    [broker registerEntityNamed:kDepartment withPrimaryKey:nil];
//    [broker registerEntityNamed:kEmployee withPrimaryKey:@"employeeID"];
//    [broker setDateFormat:kEmployeeStartDateFormat 
//                              forProperty:@"startDate" 
//                                 onEntity:kEmployee];
//   
//    // Build Deparment
//    NSManagedObjectID *departmentID = [BrokerTestsHelpers createNewDepartment:context];
//      
//    BKJSONOperationPreFilterBlock removeEmployeeWithID6 = (id)^(NSManagedObjectContext *context, id jsonObject) {
//
//        NSMutableArray *newCollection = [jsonObject mutableCopy];
//        
//        if ([jsonObject isKindOfClass:[NSArray class]]) {
//            for (id dictionary in jsonObject) {
//                if ([dictionary isKindOfClass:[NSDictionary class]]) {
//                    if ([[dictionary valueForKey:@"employeeID"] isEqualToNumber:@6]) {
//                        [newCollection removeObject:dictionary];
//                    }
//                }
//            }
//        }
//        
//        return newCollection;
//    };
//    
//    [broker processJSONPayload:jsonData
//               usingQueueNamed:kBrokerTestQueue
//                targetObjectID:departmentID
//               forRelationship:@"employees"
//            JSONPreFilterBlock:removeEmployeeWithID6
//           withCompletionBlock:nil];
//   
//    [broker waitForQueueNamed:kBrokerTestQueue];
//   
//    // Fetch
//    NSManagedObject *dept = [context objectWithID:departmentID];
//    
//    NSSet *employees = (NSSet *)[dept valueForKey:@"employees"];
//    int num = [employees count];
//        
//    BOOL removedEmployee6 = YES;
//    for (id employee in employees) {
//        if ([[employee valueForKey:@"employeeID"] isEqualToNumber:@6]) {
//            removedEmployee6 = NO;
//        }
//    }
//   
//    STAssertEquals(num, 5, @"Should have 5 employee objects");
//    STAssertTrue(removedEmployee6, @"Should have eliminated employee during pre filter");
//}

@end
