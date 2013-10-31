//
//  BKJSONOperation.m
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

#import "BKJSONOperation.h"

#import "BKEntityMap.h"
#import "BKJSONController.h"
#import "BKEntityDescription.h"
#import "NSManagedObject+Broker.h"
#import "NSManagedObjectContext+Broker.h"

@interface BKJSONOperation ()

/*!
 Some cool stuff BKEntityDescription
 */
@property (nonatomic, strong, readwrite) id json;

@property (nonatomic, strong) BKEntityMap *entityMap;

@property (nonatomic, strong) BKJSONController *jsonController;

@property (nonatomic, strong) NSString *entityName;

@property (nonatomic, assign) BKJSONOperationType type;

@end

@implementation BKJSONOperation

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (BKJSONOperation *)operationForJSON:(id)json
                           entityName:(NSString *)entityName
                            entityMap:(BKEntityMap *)entityMap
                                 type:(BKJSONOperationType)type
                              context:(NSManagedObjectContext *)context
                      completionBlock:(void (^)())completionBlock
{
    BKJSONOperation *operation = [BKJSONOperation new];

    operation.json = json;
    operation.entityName = entityName;
    operation.type = type;

//    operation.jsonController = controller;
    operation.mainContext = context;
    operation.completionBlock = completionBlock;
    
    return operation;
}

#pragma mark - Conductor

- (void)work
{
    //
    // Execute empty JSON block if empty
    //
    if (!self.json || [self.json count] == 0) {
        return;
    }
    
    BKJSONController *jsonController = [BKJSONController JSONControllerWithContext:self.backgroundContext
                                                                         entityMap:self.entityMap];
    
    
    switch (self.type) {
        case BKJSONOperationTypeObject:
            [jsonController processJSONObject:self.json
                            asEntityNamed:self.entityName];
            break;
        case BKJSONOperationTypeCollection:
            [jsonController processJSONCollection:self.json
                                  asEntitiesNamed:self.entityName];
            break;
        case BKJSONOperationTypeRelationshipCollection:
            break;
        default:
            break;
    }
    
    
}

- (void)cleanup
{    
    [self saveBackgroundContext];
}

#pragma mark - Core Data

- (void)contextDidChange:(NSNotification *)notification 
{    
    //
    // Make sure this is only called once
    //
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSManagedObjectContextObjectsDidChangeNotification 
                                                  object:self.backgroundContext];
    
    //
    // Process changes by passing notification to change block
    //
    if (self.didChangeBlock) self.didChangeBlock(self.backgroundContext, notification);
}

@end
