//
//  BKTestAppDelegate.h
//  BrokerTestApp
//
//  Created by Andrew Smith on 11/7/13.
//  Copyright (c) 2013 Andrew B. Smith. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BKTestAppStore;

@interface BKTestAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic, strong, readonly) BKTestAppStore *store;

+ (instancetype)sharedInstance;

@end
