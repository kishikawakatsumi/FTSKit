//
//  FTSKitAppDelegate.m
//  FTSKit
//
//  Created by Kishikawa Katsumi on 11/04/28.
//  Copyright 2011 Kishikawa Katsumi. All rights reserved.
//

#import "FTSKitAppDelegate.h"

@implementation FTSKitAppDelegate

@synthesize window;
@synthesize navigationController;

- (void)dealloc {
    self.window = nil;
    self.navigationController = nil;
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    [window addSubview:navigationController.view];
    [window makeKeyAndVisible];
    return YES;
}

@end
