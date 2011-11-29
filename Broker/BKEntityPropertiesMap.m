//
//  BKEntityPropertiesMap.m
//  Broker
//
//  Created by Andrew Smith on 10/7/11.
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

#import "BKEntityPropertiesMap.h"

@interface BKEntityPropertiesMap ()
@property (nonatomic, copy, readwrite) NSString *entityName;
@end

@implementation BKEntityPropertiesMap

@synthesize entityName;

- (void)dealloc {
    [entityName release], entityName = nil;
    [networkToLocalMap release], networkToLocalMap = nil;
    [localToNetworkMap release], localToNetworkMap = nil;
    
    [super dealloc];
}

+ (BKEntityPropertiesMap *)propertiesMap {
    return [[[BKEntityPropertiesMap alloc] init] autorelease];
}

#pragma mark - Modifiers

- (void)mapFromNetworkProperties:(NSArray *)networkProperties
               toLocalProperties:(NSArray *)localProperties{
    
    NSAssert((networkProperties.count == localProperties.count), @"Mapping network properties to local properties expects arrays of the same size");
    
    if (networkProperties.count != localProperties.count) return;
    if (!networkProperties || !localProperties) return;
    
    for (NSString *networkProperty in networkProperties) {
        
        NSString *localProperty = [localProperties objectAtIndex:[networkProperties indexOfObject:networkProperty]];
        
        [self.networkToLocalMap setValue:localProperty forKey:networkProperty];
        
        [self.localToNetworkMap setValue:networkProperty forKey:localProperty];
    }
    
    NSLog(@"bfreak");
}

#pragma mark - Accessors

- (NSString *)networkPropertyNameForLocalProperty:(NSString *)localProperty {
    return [self.localToNetworkMap valueForKey:localProperty];
}

- (NSString *)localPropertyNameForNetworkProperty:(NSString *)networkProperty {
    return [self.networkToLocalMap valueForKey:networkProperty];
}

- (NSMutableDictionary *)networkToLocalMap {
    if (networkToLocalMap) return [[networkToLocalMap retain] autorelease];
    networkToLocalMap = [[NSMutableDictionary alloc] init];
    return [[networkToLocalMap retain] autorelease];
}

- (NSMutableDictionary *)localToNetworkMap {
    if (localToNetworkMap) return [[localToNetworkMap retain] autorelease];
    localToNetworkMap = [[NSMutableDictionary alloc] init];
    return [[localToNetworkMap retain] autorelease];
}

@end
