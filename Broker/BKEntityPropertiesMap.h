//
//  BKEntityPropertiesMap.h
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

#import <Foundation/Foundation.h>

@interface BKEntityPropertiesMap : NSObject{
@private
    NSString *entityName;
    NSMutableDictionary *networkToLocalMap;
    NSMutableDictionary *localToNetworkMap;
}

/**
 The name of the entity the map is associated with
 */
@property (nonatomic, copy, readonly) NSString *entityName;

/**
 A dictionary where the keys are the network property names and the objects are 
 the local property names.
 */
@property (nonatomic, readonly) NSMutableDictionary *networkToLocalMap;

/**
 A dictionary where the keys are the local property names and the objects are the
 network property names.
 */
@property (nonatomic, readonly) NSMutableDictionary *localToNetworkMap;


/**
 Factory method for building a property map 
 */
+ (BKEntityPropertiesMap *)propertiesMap;

/**
 Map the list of network properties to the list of local properties.  This will 
 add or edit the current map, and not replace or remove any previously mapped 
 properties.
 
 @param networkProperties The list of network properties to map on the given entity
 @param localProperties The list of local properties to map to the given network
 properties for the entity
 */
- (void)mapFromNetworkProperties:(NSArray *)networkProperties
               toLocalProperties:(NSArray *)localProperties;

/**
 Returns the network property name for the local property name
 */
- (NSString *)networkPropertyNameForLocalProperty:(NSString *)localProperty;

/**
 Returns the local property name for the network property name
 */
- (NSString *)localPropertyNameForNetworkProperty:(NSString *)networkProperty;

@end
