//
//  NSManagedObjectContext+Broker.m
//  Broker
//
//  Created by Andrew Smith on 7/24/12.
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

#import "NSManagedObjectContext+Broker.h"
#import "BKEntityDescription.h"

@implementation NSManagedObjectContext (Broker)

- (NSManagedObject *)bkr_findOrCreateObjectForEntityDescription:(BKEntityDescription *)description
                                            primaryKeyValue:(id)value
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:description.internalEntityDescription];
    request.includesSubentities = NO;
    
    NSArray *fetchedObjects;
    
    if (description.primaryKey) {
        [request setPredicate:[NSPredicate predicateWithFormat:@"self.%@ = %@", description.primaryKey, value]];
        
        NSError *error;
        fetchedObjects = [self executeFetchRequest:request error:&error];
        if (error) {
            NSLog(@"Fetch Error: %@", error);
        }
    }
    
    if (fetchedObjects.count == 0) {
        NSManagedObject *object = [NSEntityDescription insertNewObjectForEntityForName:description.internalEntityDescription.name
                                                                inManagedObjectContext:self];
        return object;
    } else if (fetchedObjects.count >= 1) {
        return (NSManagedObject *)[fetchedObjects objectAtIndex:0];
    }
    
    return nil;

}

@end
