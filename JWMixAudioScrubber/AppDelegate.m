//
//  AppDelegate.m
//  JWMixAudioScrubber
//
//  Created by JOSEPH KERR on 1/1/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

#import "AppDelegate.h"
#import "DetailViewController.h"
#import "JWCurrentWorkItem.h"
#import "JWFileController.h"

@interface AppDelegate () <UISplitViewControllerDelegate>

@end


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [JWFileController sharedInstance];
    [[JWFileController sharedInstance] reload];
    
    NSNumber *ampIndexNumber = [[NSUserDefaults standardUserDefaults] valueForKey:@"currentAmp"];
    if (ampIndexNumber)
        [JWCurrentWorkItem sharedInstance].currentAmpImageIndex = [ampIndexNumber unsignedIntegerValue];
    
    // Override point for customization after application launch.
    UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
    UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
    navigationController.topViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem;
    splitViewController.delegate = self;
    return YES;
}



- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"AppWillBackground" object:nil]];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.

}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"AppWillForeground" object:nil]];

}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Split view

- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController {
    
    if ([secondaryViewController isKindOfClass:[UINavigationController class]] && [[(UINavigationController *)secondaryViewController topViewController] isKindOfClass:[DetailViewController class]] && ([(DetailViewController *)[(UINavigationController *)secondaryViewController topViewController] detailItem] == nil)) {
        // Return YES to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
        return YES;
    } else {
        return NO;
    }
}


//- (BOOL)splitViewController:(UISplitViewController *)splitViewController
//         showViewController:(UIViewController *)vc
//                     sender:(id)sender
//{
//    return YES;
//}

//- (UISplitViewControllerDisplayMode)targetDisplayModeForActionInSplitViewController:(UISplitViewController *)svc
//{
//    NSLog(@"%s",__func__);
//    return UISplitViewControllerDisplayModeAutomatic;
//}
//
//
//- (void)splitViewController:(UISplitViewController *)svc
//     willShowViewController:(UIViewController *)aViewController
//  invalidatingBarButtonItem:(UIBarButtonItem *)button
//{
//    NSLog(@"%s",__func__);
//}

//- (UIViewController *)primaryViewControllerForCollapsingSplitViewController:(UISplitViewController *)splitViewController
//{
//
//    NSLog(@"%s",__func__);
//
//    return nil;
//}

//- (void)splitViewController:(UISplitViewController *)svc
//    willChangeToDisplayMode:(UISplitViewControllerDisplayMode)displayMode
//{
//    if (displayMode == UISplitViewControllerDisplayModePrimaryOverlay){
////        UINavigationController *navigationController = [svc.viewControllers lastObject];
////        DetailViewController *detailViewController = navigationController.viewControllers[0];
////        [detailViewController stopPlaying];
//    }
//}
//
//- (void)splitViewController:(UISplitViewController *)svc
//     willHideViewController:(UIViewController *)aViewController
//          withBarButtonItem:(UIBarButtonItem *)barButtonItem
//       forPopoverController:(UIPopoverController *)pc
//{
//    UINavigationController *navigationController = [svc.viewControllers lastObject];
//    if (aViewController ==  navigationController) {
////        DetailViewController *detailViewController = navigationController.viewControllers[0];
////        [detailViewController stopPlaying];
//    }
//}


@end
