//
//  NSManagedObject+Broker.h
//  Broker
//
//  Created by Andrew Smith on 6/25/12.
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

#import <CoreData/CoreData.h>

@class BKController;

@interface NSManagedObject (Broker)

/**
 Registers the entity with the Broker instance. Any custom NSManagedObject that
 registers with broker should override this method if you want to do things like
 map local property names to network property names. By default this will register
 the primary key as lowercase claseNameID. So for an Employee object, the
 primary key will be employeeID.
 
 @param broker The Broker instance to register the entity with
 @param context The main thread NSManagedObjectContext;
 */
+ (void)bkr_registerWithBroker:(BKController *)controller
                     inContext:(NSManagedObjectContext *)context;

/**
 The absolute truth as to whether the object has been deleted in its context.
 */
- (BOOL)bkr_hasBeenDeleted;

@end
