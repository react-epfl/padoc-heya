//
//  AppDelegate.m
//  Heya
//
//  Created by Adrian Holzer on 23.10.12.
//  Copyright (c) 2012 Seance Association. All rights reserved.
//

#import "AppDelegate.h"
#import "HeyaManager.h"
// #import "GAI.h"


@interface AppDelegate () <UISplitViewControllerDelegate>

@property (nonatomic, strong) MHPadoc *padoc;

@end


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
   
//    // Optional: automatically send uncaught exceptions to Google Analytics.
//    [GAI sharedInstance].trackUncaughtExceptions = YES;
//    
//    // Optional: set Google Analytics dispatch interval to e.g. 20 seconds.
//    [GAI sharedInstance].dispatchInterval = 60;
//    
//    // Optional: set Logger to VERBOSE for debug information.
//    [[[GAI sharedInstance] logger] setLogLevel:kGAILogLevelVerbose];
//    
//
//    // Enable IDFA collection.
//    [[[GAI sharedInstance] defaultTracker] setAllowIDFACollection:YES];
//    
//    // Initialize tracker.
//    //id<GAITracker> tracker =
//    [[GAI sharedInstance] trackerWithTrackingId:@"UA-64703399-1"];
    
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    if (self.padoc != nil) {
        [self.padoc applicationWillResignActive];
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{

    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
   // NSLog(@"applicationWillEnterForeground and thus call reset!");
   // [[HeyaManager sharedHeyaManager] resetData];
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    if (self.padoc != nil) {
        [self.padoc applicationDidBecomeActive];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    if (self.padoc != nil) {
        [self.padoc applicationWillTerminate];
    }
}

-(BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url{
   // NSLog(@"%@",[url description]);
    
  //  if ([[url description] isEqual:@"heya://reset"]) {
  //      NSLog(@"resetting the peer ID");
  //     [[HeyaManager sharedHeyaManager] resetPeerID];
   // }
    
   
    return YES;
}

@end
