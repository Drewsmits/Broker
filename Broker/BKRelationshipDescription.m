//
//  BKRelationshipMap.m
//  Broker
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

#import "BKRelationshipDescription.h"

@interface BKRelationshipDescription ()

@property (nonatomic, strong) NSRelationshipDescription *relationshipDescription;

@end

@implementation BKRelationshipDescription

+ (BKRelationshipDescription *)descriptionWithRelationshipDescription:(NSRelationshipDescription *)description
{    
    BKRelationshipDescription *bkDescription = [BKRelationshipDescription new];
    bkDescription.relationshipDescription = description;
    return bkDescription;
}

- (NSString *)name
{
    return self.relationshipDescription.name;
}

- (NSEntityDescription *)entity
{
    return self.relationshipDescription.entity;
}

- (NSEntityDescription *)destinationEntity
{
    return self.relationshipDescription.destinationEntity;
}

- (BOOL)isToMany
{
    return self.relationshipDescription.isToMany;
}

@end
