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
    
    
    return [[FBSDKApplicationDelegate sharedInstance] application:application
                                    didFinishLaunchingWithOptions:launchOptions];
}


#pragma mark - open url

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url options:(NSDictionary<NSString *,id> *)options {
    
    NSLog(@"%s %@ %@",__func__,[url description],[options description]);

    BOOL moveDocOnOpen = NO;
    BOOL openInPlace = NO;
    BOOL isMusicMemos = NO;
    BOOL isFaceBook = NO;
    BOOL isSafariViewService = NO;

    id optionsAnnotation = options[UIApplicationOpenURLOptionsAnnotationKey];
    if (optionsAnnotation) {
        id moveDocument = optionsAnnotation[@"LSMoveDocumentOnOpen"];
        if (moveDocument) {
            moveDocOnOpen = [moveDocument boolValue];
        }
    }
    
    id optionsOpenInPlace = options[UIApplicationOpenURLOptionsOpenInPlaceKey];
    if (optionsOpenInPlace) {
        openInPlace = [optionsOpenInPlace boolValue];
    }

    id optionsSourceApp = options[UIApplicationOpenURLOptionsSourceApplicationKey];
    if (optionsSourceApp) {
        NSLog(@"optionsSourceApp %@",optionsSourceApp);
        if ([optionsSourceApp isEqualToString:@"com.apple.musicmemos"]) {
            NSLog(@"MusicMemos %@",[url lastPathComponent]);
            isMusicMemos = YES;
            
        } else if ([optionsSourceApp isEqualToString:@"com.apple.SafariViewService"]) {
            NSLog(@"SafariViewService urlscheme %@",[url scheme]);
            isSafariViewService = YES;
        }
    }

    

    //NSString *faceBookAppScheme = [NSString stringWithFormat:@"fb%@",@"769979083137410"]; //fb769979083137410
    //[[NSBundle mainBundle] objectForInfoDictionaryKey:@"FacebookAppID"];
//    NSString *faceBookAppScheme =
//    [NSString stringWithFormat:@"fb%@",
//     [[NSBundle mainBundle] objectForInfoDictionaryKey:@"FacebookAppID"]];

    
    NSLog(@"urlscheme %@",[url scheme]);

    if ([[url scheme] isEqualToString:[NSString stringWithFormat:@"fb%@",
                                       [[NSBundle mainBundle] objectForInfoDictionaryKey:@"FacebookAppID"]]]) {
        isFaceBook = YES;
    }

    // IF its facebook API handle it with FBSDKApplicationDelegate
    if (isFaceBook) {
        
        id optionsAnnotation = options[UIApplicationOpenURLOptionsAnnotationKey];

        return [[FBSDKApplicationDelegate sharedInstance] application:application
                                                              openURL:url
                                                    sourceApplication:optionsSourceApp
                                                           annotation:optionsAnnotation];
        // process facebook simply returns its openURL
    }
    
    
    
    // Otherwise is a URL we handle
    NSURL *resultURL = [[JWFileController sharedInstance] processInBoxItem:url options:options];

    if (resultURL && isMusicMemos) {
        NSLog(@"JAM With MusicMemos file %@",[url lastPathComponent]);

//        [master performNewJamTrack:resultURL];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"JWAudioFileAddedToSystem" object:self
                                                          userInfo:@{@"URL":resultURL}
         ];
        
    }

//    if (resultURL) {
//        NSLog(@"JAM With filename %@",[url lastPathComponent]);
////        [master performNewJamTrack:resultURL];
//        [[NSNotificationCenter defaultCenter] postNotificationName:@"JWAudioFileAddedToSystem" object:self
//                                                          userInfo:@{@"URL":resultURL}
//         ];
//    }
    
    else {
        
        
        NSString *message;
        if (resultURL)
            message = [NSString stringWithFormat:@"Successfully Copied file %@",[url lastPathComponent]];
        else
            message = [NSString stringWithFormat:@"There was a problem copying file %@",[url lastPathComponent]];
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"File Import" message:message
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        }];
        
        [alertController addAction:okAction];
        
        [self.window.rootViewController presentViewController:alertController animated:YES completion:nil];
        
//        [splitViewController presentViewController:alertController animated:YES completion:nil];
    }
    
    return (resultURL != nil);
}


// OLD API deprectaed in iOS9 use openURL:(NSURL *)url options:
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    
    return [[FBSDKApplicationDelegate sharedInstance] application:application
                                                                  openURL:url
                                                        sourceApplication:sourceApplication
                                                               annotation:annotation];
}


/*
 
 AIRDROP from mac
-[AppDelegate application:openURL:options:]
 file:// /private/var/mobile/Containers/Data/Application/6BABD702-3B1E-42F3-8C6D-2532196EDC05/Documents/Inbox/trimmedMP3_B01D917D-5253-4D23-AA05-E39C5FB93A72.m4a {
UIApplicationOpenURLOptionsAnnotationKey =     {
    LSMoveDocumentOnOpen = 1;
};
UIApplicationOpenURLOptionsOpenInPlaceKey = 0;
}
 
 FROM app MusicMemos
 -[AppDelegate application:openURL:options:]
 file:// /private/var/mobile/Containers/Data/Application/6BABD702-3B1E-42F3-8C6D-2532196EDC05/Documents/Inbox/My%20Idea%207.m4a {
UIApplicationOpenURLOptionsAnnotationKey =     {
};
UIApplicationOpenURLOptionsOpenInPlaceKey = 0;
UIApplicationOpenURLOptionsSourceApplicationKey = "com.apple.musicmemos";
}
 
 ???? NotSure But looks like AIR Drop when app is not launched
-[AppDelegate application:didFinishLaunchingWithOptions:] {
 UIApplicationLaunchOptionsAnnotationKey =     {
 LSMoveDocumentOnOpen = 1;
 };
 UIApplicationLaunchOptionsURLKey = "file:///private/var/mobile/Containers/Data/Application/FE75359C-1B9E-4B09-B1C3-97E29BC1CBD4/Documents/Inbox/trimmedMP3_7710DD31-7046-497E-AA09-B30BA8AB3080.m4a";
 }
 
 
 FROM FaceBook nonApp Safari Interface
 [AppDelegate application:openURL:options:]
 url	NSURL *	@"fb769979083137410://authorize/#state=%7B%22challenge%22%3A%22CgxVGEcQ1Y66OFz8kayAOZBOJPw%253D%22%2C%220_auth_logger_id%22%3A%220AE4F3E9-3558-487C-966F-DDA78EF67E2B%22%2C%22com.facebook.sdk_client_state%22%3Atrue%2C%223_method%22%3A%22sfvc_auth%22%7D&granted_scopes=email%2Ccontact_email%2Cuser_actions.music%2Cpublic_profile&denied_scopes=&signed_request=mJ-HW86txz4Jp29Amtb7VrJkVziQgSfVrOAr3JZBjd4.eyJhbGdvcml0aG0iOiJITUFDLVNIQTI1NiIsImNvZGUiOiJBUURzOFVrM1lGclA3d1h0Zm9vSjNGaTllanpnWjVrak9mVTVhVF9yZmNvcjZsSTc5U1ZBbDJ4bXlBV2tTcG5LRkpFT2lNcmxDVzFnOWMxVWFCNDB0SW40UW1DQ2l4YzRQci0zLTFMTGdWQ0R3LWNOam5NSXkwWXo4c21QTzc5c1hTekNsaU5kQjJhd1o4SWpuSGc2blF2UnMzZWFvYVRza2wtbzNYdDR2ZzBhY3ZveV9JT29Tb2M5a1BJREJXSDQ1QXZzRDhHemU2MEhPZHRXV01iQWFiTHRZckxwNmUxLVk0VmNXanBVdXhZM2RwVEI3V2VwSGdNRG1MdnJWQXc5VHlia0U1VkZjRlYzVHJweElYczZQbklMcFRZdGVjeHhNcVVsdU9udzNnS3Z1emRRbmtlT1lrbUZKdG5oWGVQNjQ5T29kaFVHWmNSckF4MUd6Z2xYNlZhTjFsWTg3bmI5NEZpODlseE9aSzNXYjZ6VkFFN3BxUll4VzRYMzNkX3hvVGsiLCJpc3N1ZWRfYXQiOjE0NjYyMjIyNzIsInVzZXJfaWQiOiIxMDIwODIwMTgx"
 
 info.plist FacebookAppID 769979083137410
 
 options	__NSDictionaryM *	2 key/value pairs	0x000000013a92a380
 [0]	(null)	@"UIApplicationOpenURLOptionsSourceApplicationKey" : @"com.apple.SafariViewService"
 key	__NSCFConstantString *	@"UIApplicationOpenURLOptionsSourceApplicationKey"	0x000000019c88d440
 value	__NSCFString *	@"com.apple.SafariViewService"	0x0000000135df30a0
 [1]	(null)	@"UIApplicationOpenURLOptionsOpenInPlaceKey" : @"0"
 key	__NSCFConstantString *	@"UIApplicationOpenURLOptionsOpenInPlaceKey"	0x000000019c88d480
 value	__NSCFBoolean *	@"0"	0x00000001a0a366d8
 
 
 MUSIC MEMOS
 options	__NSDictionaryM *	3 key/value pairs	0x000000015fd61970
 [0]	(null)	@"UIApplicationOpenURLOptionsSourceApplicationKey" : @"com.apple.musicmemos"
 [1]	(null)	@"UIApplicationOpenURLOptionsOpenInPlaceKey" : @"0"
 [2]	(null)	@"UIApplicationOpenURLOptionsAnnotationKey" : 0 key/value pairs
 
 
 AIRDROP
 [AppDelegate application:openURL:options:] file:///private/var/mobile/Containers/Data/Application/328CAF3F-3A9F-41BC-92FD-FF9BA4C3BF57/Documents/Inbox/trimmedMP3_0B828B36-BE9F-4074-9538-D4E0EBA3A7D5.m4a {
 
 [AppDelegate application:openURL:options:] file:///private/var/mobile/Containers/Data/Application/328CAF3F-3A9F-41BC-92FD-FF9BA4C3BF57/Documents/Inbox/trimmedMP3_0B828B36-BE9F-4074-9538-D4E0EBA3A7D5.m4a {
 UIApplicationOpenURLOptionsAnnotationKey =     {
 LSMoveDocumentOnOpen = 1;
 };
 UIApplicationOpenURLOptionsOpenInPlaceKey = 0;
 }

 */

#pragma mark - appl state

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



@end


#pragma mark - Split view


//    didFinishLaunchingWithOptions
// Override point for customization after application launch.
//    UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
//    UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
//    navigationController.topViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem;
//    splitViewController.delegate = self;


//    - (BOOL)application:(UIApplication *)application openURL:(NSURL *)url options:(NSDictionary<NSString *,id> *)options {

//    UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
//    UINavigationController *navigationController = [splitViewController.viewControllers firstObject];
////    UIViewController *vc = [navigationController topViewController];
//    MasterViewController *master = [[navigationController viewControllers] firstObject];
//
//    if (resultURL && isMusicMemos) {
//        [master performNewJamTrack:resultURL];
//    }


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


