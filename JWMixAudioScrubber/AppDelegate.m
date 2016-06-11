//
//  AppDelegate.m
//  JWMixAudioScrubber
//
//  co-created by joe and brendan kerr on 1/1/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

#import "AppDelegate.h"
#import "DetailViewController.h"
#import "MasterViewController.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import "JWCurrentWorkItem.h"
#import "JWFileController.h"
#import "JWFileManager.h"

@interface AppDelegate () <UISplitViewControllerDelegate, UITabBarControllerDelegate>

@end


@implementation AppDelegate



- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    

    //[[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:
     [NSDictionary dictionaryWithObjectsAndKeys:
      [UIColor whiteColor], NSForegroundColorAttributeName, nil]];
    
    [JWFileManager defaultManager];
    [JWFileController sharedInstance];
    [[JWFileController sharedInstance] reload];
    
    NSLog(@"%s %@",__func__,[launchOptions description]);

    NSNumber *ampIndexNumber = [[NSUserDefaults standardUserDefaults] valueForKey:@"currentAmp"];
    if (ampIndexNumber)
        [JWCurrentWorkItem sharedInstance].currentAmpImageIndex = [ampIndexNumber unsignedIntegerValue];
    
    
    // Override point for customization after application launch.
//    UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
//    UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
//    navigationController.topViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem;
//    splitViewController.delegate = self;
    return [[FBSDKApplicationDelegate sharedInstance] application:application
                                    didFinishLaunchingWithOptions:launchOptions];
}

/*
Jan 30 01:10:55 JOes-Phone JamWDev[2111] <Warning>: -[AppDelegate application:didFinishLaunchingWithOptions:] {
    UIApplicationLaunchOptionsAnnotationKey =     {
        LSMoveDocumentOnOpen = 1;
    };
    UIApplicationLaunchOptionsURLKey = "file:///private/var/mobile/Containers/Data/Application/FE75359C-1B9E-4B09-B1C3-97E29BC1CBD4/Documents/Inbox/trimmedMP3_7710DD31-7046-497E-AA09-B30BA8AB3080.m4a";
}
Jan 30 01:10:55 JOes-Phone
*/

//- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString *,id> *)options {
//    
//    NSLog(@"%s %@ %@",__func__,[url description],[options description]);
//    
//    BOOL moveDocOnOpen = NO;
//    id optionsAnnotation = options[UIApplicationOpenURLOptionsAnnotationKey];
//    if (optionsAnnotation) {
//        id moveDocument = optionsAnnotation[@"LSMoveDocumentOnOpen"];
//        if (moveDocument) {
//            moveDocOnOpen = [moveDocument boolValue];
//        }
//    }
//    BOOL openInPlace = NO;
//    id optionsOpenInPlace = options[UIApplicationOpenURLOptionsOpenInPlaceKey];
//    if (optionsOpenInPlace) {
//        openInPlace = [optionsOpenInPlace boolValue];
//    }
//    BOOL isMusicMemos = NO;
//    id optionsSourceApp = options[UIApplicationOpenURLOptionsSourceApplicationKey];
//    if (optionsSourceApp) {
//        NSLog(@"optionsSourceApp %@",optionsSourceApp);
//        if ([optionsSourceApp isEqualToString:@"com.apple.musicmemos"]) {
//            NSLog(@"MusicMemos %@",[url lastPathComponent]);
//            isMusicMemos = YES;
//        }
//    }
//
//    
//    NSURL *resultURL = [[JWFileController sharedInstance] processInBoxItem:url options:options];
//
//    UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
//    UINavigationController *navigationController = [splitViewController.viewControllers firstObject];
////    UIViewController *vc = [navigationController topViewController];
//    MasterViewController *master = [[navigationController viewControllers] firstObject];
//    
////    if (resultURL && isMusicMemos) {
////        
////        [master performNewJamTrack:resultURL];
////    }
//
//    if (resultURL) {
//        
//        [master performNewJamTrack:resultURL];
//    } else {
//        
//        
//        NSString *message;
//        if (resultURL)
//            message = [NSString stringWithFormat:@"Successfully Copied file %@",[url lastPathComponent]];
//        else
//            message = [NSString stringWithFormat:@"There was a problem copying file %@",[url lastPathComponent]];
//        
//        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"File Import" message:message
//                                                                          preferredStyle:UIAlertControllerStyleAlert];
//        
//        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
//        }];
//        
//        [alertController addAction:okAction];
//        [splitViewController presentViewController:alertController animated:YES completion:nil];
//    }
//    
//    return (resultURL != nil);
//}
//



- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [[FBSDKApplicationDelegate sharedInstance] application:application
                                                                  openURL:url
                                                        sourceApplication:sourceApplication
                                                               annotation:annotation];
}
/*
 
 AIRDROP from mac
-[AppDelegate application:openURL:options:] file:///private/var/mobile/Containers/Data/Application/6BABD702-3B1E-42F3-8C6D-2532196EDC05/Documents/Inbox/trimmedMP3_B01D917D-5253-4D23-AA05-E39C5FB93A72.m4a {
UIApplicationOpenURLOptionsAnnotationKey =     {
    LSMoveDocumentOnOpen = 1;
};
UIApplicationOpenURLOptionsOpenInPlaceKey = 0;
}
 
 AIRDROP FROM app MusicMemos
2016-01-29 22:16:31.445 JamWDev[2035:868086] -[AppDelegate application:openURL:options:] file:///private/var/mobile/Containers/Data/Application/6BABD702-3B1E-42F3-8C6D-2532196EDC05/Documents/Inbox/My%20Idea%207.m4a {
UIApplicationOpenURLOptionsAnnotationKey =     {
};
UIApplicationOpenURLOptionsOpenInPlaceKey = 0;
UIApplicationOpenURLOptionsSourceApplicationKey = "com.apple.musicmemos";
}
 
 */


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
    
    //[FBSDKAppEvents activateApp];
    
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"AppWillForeground" object:nil]];

}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Split view

//- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController {
//    
//    if ([secondaryViewController isKindOfClass:[UINavigationController class]] && [[(UINavigationController *)secondaryViewController topViewController] isKindOfClass:[DetailViewController class]] && ([(DetailViewController *)[(UINavigationController *)secondaryViewController topViewController] detailItem] == nil)) {
//        // Return YES to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
//        return YES;
//    } else {
//        return NO;
//    }
//}


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
