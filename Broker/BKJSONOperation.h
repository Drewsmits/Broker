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

#import "Conductor/CDCoreDataOperation.h"

@class BKEntityMap;
@class BKJSONController;
@class BKEntityDescription;

typedef enum {
    BKJSONOperationTypeUnknown,
    BKJSONOperationTypeObject,
    BKJSONOperationTypeCollection,
    BKJSONOperationTypeRelationshipCollection,
} BKJSONOperationType;

typedef void (^BKJSONOperationContextDidChangeBlock)(NSManagedObjectContext *context, NSNotification *notification);
typedef void (^BKJSONOperationEmptyJSONBlock)(NSManagedObjectContext *context);

@interface BKJSONOperation : CDCoreDataOperation

/**
 This block is called when the context changes, and allows you to apply some changes
 mid stream.
 */
@property (nonatomic, copy) BKJSONOperationContextDidChangeBlock didChangeBlock;

+ (BKJSONOperation *)operationForJSON:(id)json
                           entityName:(NSString *)entityName
                            entityMap:(BKEntityMap *)entityMap
                                 type:(BKJSONOperationType)type
                              context:(NSManagedObjectContext *)context
                      completionBlock:(void (^)())completionBlock;

+ (BKJSONOperation *)operationForJSON:(id)json
                           entityName:(NSString *)entityName
                            entityMap:(BKEntityMap *)entityMap
                                 type:(BKJSONOperationType)type
                              context:(NSManagedObjectContext *)context
                      completionBlock:(void (^)())completionBlock;

@end
