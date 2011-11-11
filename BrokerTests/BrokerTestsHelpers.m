//
//  BrokerTestsHelpers.m
//  Broker
//
//  Created by Andrew Smith on 10/6/11.
//  Copyright (c) 2011 Andrew B. Smith. All rights reserved.
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

+ (NSURL *)createNewEmployee:(NSManagedObjectContext *)context {
    NSManagedObject *employee = [NSEntityDescription insertNewObjectForEntityForName:@"Employee" 
                                                              inManagedObjectContext:context];
    [context save:nil];
    return employee.objectID.URIRepresentation;
}

+ (NSURL *)createNewFilledOutEmployee:(NSManagedObjectContext *)context {
    NSManagedObject *employee = [NSEntityDescription insertNewObjectForEntityForName:@"Employee" 
                                                              inManagedObjectContext:context];
    
    [employee setValue:[NSNumber numberWithInt:12345] forKey:@"employeeID"];
    [employee setValue:@"Kevin" forKey:@"firstname"];
    [employee setValue:@"Bacon" forKey:@"lastname"];
    
    [context save:nil];
    return employee.objectID.URIRepresentation;
}

+ (NSURL *)createNewDepartment:(NSManagedObjectContext *)context {
    NSManagedObject *dept = [NSEntityDescription insertNewObjectForEntityForName:@"Department" 
                                                              inManagedObjectContext:context];
    [context save:nil];
    return dept.objectID.URIRepresentation;
}

NSString *PathForTestResource(NSString *resouce) {
    
    NSString *testBundlePath = [[NSBundle bundleForClass:[BrokerTestsHelpers class]] pathForResource:@"TestResources" 
                                                                                              ofType:@"bundle"];
    return [NSString stringWithFormat:@"%@/%@", testBundlePath, resouce];
}

NSURL *URLForTestResource(NSString *resouce) {
    return [NSURL URLWithString:PathForTestResource(resouce)];
}

NSURL *DataModelURL(void) {
    
    NSBundle *testBundle = [NSBundle bundleForClass:[BrokerTestsHelpers class]];
    
    NSString *path = [testBundle pathForResource:@"BrokerTestModel" 
                                          ofType:@"momd"];
    return [NSURL URLWithString:path];
}

NSURL *DataStoreURL(void) {
    
    NSBundle *testBundle = [NSBundle bundleForClass:[BrokerTestsHelpers class]];
    
    NSURL *storeURL = [[testBundle resourceURL] URLByAppendingPathComponent:@"BrokerTests.sqlite"];

    return storeURL;
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

void DeleteDataStore(void) {
    
    NSURL *url = DataStoreURL();
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (url) {
        [fileManager removeItemAtURL:url error:NULL];
    }
}


@end
