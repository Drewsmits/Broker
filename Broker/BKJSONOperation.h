//
//  BKJSONOperation.h
//  Broker
//
//  Created by Andrew Smith on 10/25/11.
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

#import "Conductor/CDOperation.h"
#import "BKEntityPropertiesDescription.h"

typedef id (^BKJSONOperationPreFilterBlock)(id jsonObject);
typedef void (^BKJSONOperationContextDidChangeBlock)(NSManagedObjectContext *context, NSNotification *notification);
typedef void (^BKJSONOperationEmptyJSONBlock)(NSManagedObjectContext *context);

@interface BKJSONOperation : CDOperation {
@private
    id jsonPayload;
    NSURL *entityURI;
    NSString *relationshipName;
    NSManagedObjectContext *mainContext;
    NSManagedObjectContext *backgroundContext;
}

/**
 The JSON data to be turned into a JSON object for processing
 */
@property (nonatomic, strong) id jsonPayload;

@property (nonatomic, strong) NSURL *entityURI;
@property (nonatomic, strong) BKEntityPropertiesDescription *entityDescription;
@property (nonatomic, copy) NSString *relationshipName;
@property (nonatomic, strong) NSManagedObjectContext *mainContext;
@property (nonatomic, strong) NSManagedObjectContext *backgroundContext;

@property (nonatomic, copy) BKJSONOperationPreFilterBlock preFilterBlock;
@property (nonatomic, copy) BKJSONOperationContextDidChangeBlock didChangeBlock;
@property (nonatomic, copy) BKJSONOperationEmptyJSONBlock emptyJSONBlock;


- (id)applyJSONPreFilterBlockToJSONObject:(id)jsonObject;

- (NSManagedObjectContext *)newMainStoreManagedObjectContext;

@end
