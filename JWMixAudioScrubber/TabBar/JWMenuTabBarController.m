    //
//  JWMenuTabBarController.m
//  JamWDev
//
//  Created by brendan kerr on 4/18/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

#import "JWMenuTabBarController.h"
#import "JWMixNodes.h"
#import "JWHomeTableViewController.h"
#import "JWPublicTableViewController.h"
#import "JWJamSessionCoordinator.h"
#import "JWAWSIdentityManager.h"
#import "JWFileManager.h"


#define TESTING 1

@interface JWMenuTabBarController() {
    BOOL _loggedIn;
    BOOL _blocked;
}

@property (nonatomic) JWBlockingView *blockingView;
@property (nonatomic) JWContinueView *continueView;
@property (nonatomic) JWJamSessionCoordinator *coordinator;

@end
@implementation JWMenuTabBarController 

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    NSLog(@"%s", __func__);
    
    if (self = [super initWithCoder:aDecoder]) {
        self.delegate = self;
    }
    
    return self;
}

-(void)viewDidLoad {
    [super viewDidLoad];
    _coordinator = [[JWJamSessionCoordinator alloc] init];
#ifdef TESTING
    [[JWAWSIdentityManager sharedInstance] facebookLogout];
    if (![[JWAWSIdentityManager sharedInstance] isLoggedInWithFacebook]) {
        NSLog(@"itWorked");
    }
#endif
}

//OBJECT JWJAMSESSIONCOORDINATOR
//#pragma mark - TRACK OBJECT CREATION
//
///*
//When you want a jam track object with a player that has valid url and an empty recorder
//Most likely should be called after an audio file is clipped or audio is downloaded
// */
//-(NSMutableDictionary*)newCompleteJamTrackObjectWithFileURL:(NSURL*)fileURL audioFileKey:(NSString *)key {
//    NSMutableDictionary *result = nil;
//    
//    
//    id track1 = [self newTrackObjectOfType:JWAudioNodeTypePlayer andFileURL:fileURL withAudioFileKey:key];
//    id track2 = [self newTrackObjectOfType:JWAudioNodeTypeRecorder];
//    
//    NSMutableArray *trackObjects = [@[track1, track2] mutableCopy];
//    
//    result =
//    [@{@"key":[[NSUUID UUID] UUIDString],
//       @"titletype":@"jamtrack",
//       @"title":@"jam Track",
//       @"trackobjectset":trackObjects,
//       @"date":[NSDate date],
//       } mutableCopy];
//    return result;
//}
//
//
//-(NSMutableDictionary*)newTrackObjectOfType:(JWAudioNodeType)audioNodeType andFileURL:(NSURL*)fileURL withAudioFileKey:(NSString *)key {
//    
//    NSMutableDictionary *result = nil;
//    if (audioNodeType == JWAudioNodeTypePlayer) {
//        result =
//        [@{@"key":[[NSUUID UUID] UUIDString],
//           @"starttime":@(0.0),
//           @"date":[NSDate date],
//           @"type":@(JWAudioNodeTypePlayer)
//           } mutableCopy];
//        
//    } else if (audioNodeType == JWAudioNodeTypeRecorder) {
//        result =
//        [@{@"key":[[NSUUID UUID] UUIDString],
//           @"starttime":@(0.0),
//           @"date":[NSDate date],
//           @"type":@(JWAudioNodeTypeRecorder)
//           } mutableCopy];
//    }
//    
//    if (fileURL)
//        result[@"fileURL"] = fileURL;
//    if (key)
//        result[@"audiofilekey"] = key;
//    
//    return result;
//}
//
//
//
//////Trying to deal with just valid fileURL audio or empty recorder nodes, no samples
////-(NSMutableDictionary*)newTrackObjectOfType:(JWAudioNodeType)audioNodeType {
////    
////    NSMutableDictionary *result = nil;
////    if (audioNodeType == JWAudioNodeTypePlayer) {
////        //return [self newTrackObjectOfType:audioNodeType andFileURL:[self fileURLWithFileName:JWSampleFileNameAndExtension inPath:nil] withAudioFileKey:nil];
////        
////    } else if (audioNodeType == JWAudioNodeTypeRecorder) {
////        return [self newTrackObjectOfType:audioNodeType andFileURL:nil withAudioFileKey:nil];
////    }
////    return result;
////}
////

#pragma mark - DETAIL DELEGATE 


-(void)itemChanged:(DetailViewController*)controller {
    
    //save user list
}


-(void)userAudioObtainedInNodeWithKey:(NSString*)nodeKey recordingId:(NSString*)rid {
    NSLog(@"Hit old userAudioObtained");
    id nodeInJamTrack = [_coordinator jamTrackObjectWithKey:nodeKey fromSource:[[JWFileManager defaultManager] homeItemsList]];
    
    NSAssert(rid, @"recording id must be present if user audio is obtained.");
    nodeInJamTrack[@"fileURL"] = [[JWFileManager defaultManager] fileURLWithFileName:[NSString stringWithFormat:@"clipRecording_%@.caf", rid]];
    
    NSLog(@"NEW RECORDING in track \n%@",[nodeInJamTrack description]);
}


-(void)userAudioObtainedWithComponents:(NSDictionary*)components atNodeWithKey:(NSString *)key {
    NSLog(@"Hit new userAudioObtained");
    NSMutableArray *homeList = [[JWFileManager defaultManager] homeItemsList];
    NSMutableDictionary *nodeInJamTrack = [_coordinator jamTrackObjectWithKey:key fromSource:homeList];
    [nodeInJamTrack addEntriesFromDictionary:components];
    
    [[JWFileManager defaultManager] updateHomeObjectsAndSave:homeList];
    
    NSLog(@"NEW RECORDING in track \n%@",[nodeInJamTrack description]);
}



-(void)addNewJamSessionToTop:(DetailViewController *)controller {
    
    //Maybe should do it this way in the hometvc method too, then update the home data set instead of updating the home data set then updating the home items list
    NSMutableArray *newList = [[JWFileManager defaultManager] homeItemsList];
    
    for (NSDictionary *section in newList) {
        JWHomeSectionType sectionType = [section[@"type"] integerValue];
        if (sectionType == JWHomeSectionTypeSessions) {
            
            NSMutableArray *sessions = section[@"sessionset"];
            [sessions insertObject:controller.detailItem atIndex:0];
        }
    }
    
    [[JWFileManager defaultManager] updateHomeObjectsAndSave:newList];
    
}


-(UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - TAB BAR DELEGATE


-(void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {
    NSLog(@"%s", __func__);
    
    if ([item.title isEqualToString:@"Detail"]) {
        UIStoryboard *main = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        UINavigationController *presentedNav = [main instantiateViewControllerWithIdentifier:@"DetailNav"];
        DetailViewController *presented = [[presentedNav viewControllers] objectAtIndex:0];
        
        //presented.delegate = self;
        [presented setDetailItem:[_coordinator newJamTrackObjectWithRecorderFileURL:nil]];
        [presented setNewRecording:YES];
        presented.delegate = self;
        
        [self presentViewController:presentedNav animated:YES completion:^() {
        
        }];

    }
    
}


-(id<UIViewControllerAnimatedTransitioning>)tabBarController:(UITabBarController *)tabBarController animationControllerForTransitionFromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC {
    NSLog(@"%s", __func__);
    
    return nil;
}

-(BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    NSLog(@"%s", __func__);
    
    if ([viewController.title isEqualToString:@"Detail"]) {
        return NO;
    }
    return YES;
    
}

-(void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    
    UINavigationController *current = (UINavigationController *)viewController;
    id root = [current.childViewControllers firstObject];
    
    if ([root isKindOfClass:[JWPublicTableViewController class]]) {
        NSLog(@"%s", __func__);
        
        if (![[JWAWSIdentityManager sharedInstance] isLoggedInWithFacebook]) {
            
            if (!_blocked) {
                self.blockingView = [[JWBlockingView alloc] initWithFrame:self.view.frame];
                self.blockingView.delegate = self;
                self.blockingView.pageStatement.text = @"This page allows artists to search for other registered users and download their content to use inside JamWith.";
                
                //Originaly i set the views alpha to 0.5 but that affected all of its subviews which wasnt the desired look.  Now i am setting the background color to a color with an alpha component.
                self.blockingView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
                [current.view addSubview:_blockingView];
                _blocked = YES;
            }
        }
        
        

    } else if ([root isKindOfClass:[JWHomeTableViewController class]]) {
        //Do nothing yet
        
        
    }
    
}


#pragma mark - BLOCKING VIEW DELEGATE s

-(void)unblock {
    NSLog(@"%s", __func__);
    
    [[JWAWSIdentityManager sharedInstance] completeFBLoginWithCompletion:^id(AWSTask *task) {
        NSLog(@"Completion.");
        dispatch_async(dispatch_get_main_queue(), ^{
            [self removeBlock];
            [self continueWithUsername];
        });
        return nil;
    }];

}

-(void)stayBlockedWithMessage {
    
    
}

-(void)registrationComplete {
    NSLog(@"%s", __func__);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.continueView removeFromSuperview];
    });
    
}

#pragma mark - VIEW CALLS


-(void)removeBlock {
    NSLog(@"%s", __func__);
    [self.blockingView removeFromSuperview];
}


-(void)continueWithUsername {
    NSLog(@"%s", __func__);
    
    self.continueView = [[JWContinueView alloc] initWithFrame:self.view.frame];
    self.continueView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    self.continueView.delegate = self;
    
    [self.view addSubview:self.continueView];
}



@end
