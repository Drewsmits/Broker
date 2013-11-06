//
//  BrokerTestsHelpers.m
//  Broker
//
//  Created by Andrew Smith on 10/6/11.
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

#import "BrokerTestsHelpers.h"

@implementation BrokerTestsHelpers

+ (NSManagedObjectID *)createNewEmployee:(NSManagedObjectContext *)context {
    NSManagedObject *employee = [NSEntityDescription insertNewObjectForEntityForName:@"Employee" 
                                                              inManagedObjectContext:context];
    [context save:nil];
    return employee.objectID;
}

+ (NSManagedObjectID *)createNewFilledOutEmployee:(NSManagedObjectContext *)context {
    NSManagedObject *employee = [NSEntityDescription insertNewObjectForEntityForName:@"Employee" 
                                                              inManagedObjectContext:context];
    
    [employee setValue:@12345 forKey:@"employeeID"];
    [employee setValue:@"Kevin" forKey:@"firstname"];
    [employee setValue:@"Bacon" forKey:@"lastname"];
    
    [context save:nil];
    return employee.objectID;
}

+ (NSManagedObject *)createNewDepartment:(NSManagedObjectContext *)context {
    NSManagedObject *dept = [NSEntityDescription insertNewObjectForEntityForName:@"Department" 
                                                              inManagedObjectContext:context];
    [context save:nil];
    return dept;
}

+ (NSArray *)findAllEntitiesNamed:(NSString *)entityName inContext:(NSManagedObjectContext *)context {

    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:entityName 
                                                         inManagedObjectContext:context];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
        
    [request setEntity:entityDescription];
    
    NSError *error = nil;
    NSArray *array = [context executeFetchRequest:request error:&error];
    
	return array;
}

+ (void)create200Employees {
    
}

+ (void)writeFakeJSON
{
//    NSArray *firstNames = @[@"Will", @"Andrew", @"Erem", @"Eric", @"David", @"Gabe", @"Sarah", @"Lucy", @"Uma"];
//    NSArray *lastNames = @[@"Chan", @"Smith", @"Boto", @"Feeny", @"Auld", @"Kapler", @"Smart", @"Lawless", @"Thurman"];
//    
//    __block NSMutableString *jsonString = @"[";
//    __block NSUInteger employeeID = 1;
//    
//    [firstNames enumerateObjectsUsingBlock:^(NSString *firstName, NSUInteger idx, BOOL *stop) {
//        NSString *first = [NSString stringWithFormat:@"{\"firstname\":\"%@\",", firstName];
//        NSString *last = [NSString stringWithFormat:@"\"lastname\":\"%@\",", [lastNames objectAtIndex:idx]];
//        NSString *idString = [NSString stringWithFormat:@"\"employeeID\":%i", employeeID];        
//    }];
//
//    
}

NSString *PathForTestResource(NSString *resouce) {
    
    NSString *testBundlePath = [[NSBundle bundleForClass:[BrokerTestsHelpers class]] pathForResource:@"TestResources" 
                                                                                              ofType:@"bundle"];
    return [NSString stringWithFormat:@"%@/%@", testBundlePath, resouce];
}

NSURL *URLForTestResource(NSString *resouce) {
    return [NSURL URLWithString:PathForTestResource(resouce)];
}

NSString *UTF8StringFromFile(NSString *fileName) {
    NSString *path = PathForTestResource(fileName);
    
    NSError *error;
    NSString *string = [[NSString alloc] initWithContentsOfFile:path
                                                       encoding:NSUTF8StringEncoding
                                                          error:&error];
    return string;
}

NSData *DataFromFile(NSString *fileName) {
    NSString *path = PathForTestResource(fileName);
    
    NSError *error;
    NSData *data = [NSData dataWithContentsOfFile:path 
                                          options:NSDataReadingUncached 
                                            error:&error];
    
    return data;
}

id JsonFromFile(NSString *fileName) {
    NSData *data = DataFromFile(fileName);
    id json = [NSJSONSerialization JSONObjectWithData:data
                                              options:NSJSONReadingMutableContainers
                                                error:nil];
    return json;
}

@end
