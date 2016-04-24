//
//  JWMenuTabBarController.m
//  JamWDev
//
//  Created by brendan kerr on 4/18/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

#import "JWMenuTabBarController.h"
#import "JWMixNodes.h"
#import "JWPublicTableViewController.h"
#import "JWAWSIdentityManager.h"
#import "JWBlockingView.h"


@interface JWMenuTabBarController() {
    BOOL _loggedIn;
    BOOL _blocked;
}

@property (nonatomic) JWBlockingView *blockingView;

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
    
}


#pragma mark - TRACK OBJECT CREATION

/*
When you want a jam track object with a player that has valid url and an empty recorder
Most likely should be called after an audio file is clipped or audio is downloaded
 */
-(NSMutableDictionary*)newCompleteJamTrackObjectWithFileURL:(NSURL*)fileURL audioFileKey:(NSString *)key {
    NSMutableDictionary *result = nil;
    
    
    id track1 = [self newTrackObjectOfType:JWAudioNodeTypePlayer andFileURL:fileURL withAudioFileKey:key];
    id track2 = [self newTrackObjectOfType:JWAudioNodeTypeRecorder];
    
    NSMutableArray *trackObjects = [@[track1, track2] mutableCopy];
    
    result =
    [@{@"key":[[NSUUID UUID] UUIDString],
       @"titletype":@"jamtrack",
       @"title":@"jam Track",
       @"trackobjectset":trackObjects,
       @"date":[NSDate date],
       } mutableCopy];
    return result;
}


-(NSMutableDictionary*)newTrackObjectOfType:(JWAudioNodeType)audioNodeType andFileURL:(NSURL*)fileURL withAudioFileKey:(NSString *)key {
    
    NSMutableDictionary *result = nil;
    if (audioNodeType == JWAudioNodeTypePlayer) {
        result =
        [@{@"key":[[NSUUID UUID] UUIDString],
           @"starttime":@(0.0),
           @"date":[NSDate date],
           @"type":@(JWAudioNodeTypePlayer)
           } mutableCopy];
        
    } else if (audioNodeType == JWAudioNodeTypeRecorder) {
        result =
        [@{@"key":[[NSUUID UUID] UUIDString],
           @"starttime":@(0.0),
           @"date":[NSDate date],
           @"type":@(JWAudioNodeTypeRecorder)
           } mutableCopy];
    }
    
    if (fileURL)
        result[@"fileURL"] = fileURL;
    if (key)
        result[@"audiofilekey"] = key;
    
    return result;
}



//Trying to deal with just valid fileURL audio or empty recorder nodes, no samples
-(NSMutableDictionary*)newTrackObjectOfType:(JWAudioNodeType)audioNodeType {
    
    NSMutableDictionary *result = nil;
    if (audioNodeType == JWAudioNodeTypePlayer) {
        //return [self newTrackObjectOfType:audioNodeType andFileURL:[self fileURLWithFileName:JWSampleFileNameAndExtension inPath:nil] withAudioFileKey:nil];
        
    } else if (audioNodeType == JWAudioNodeTypeRecorder) {
        return [self newTrackObjectOfType:audioNodeType andFileURL:nil withAudioFileKey:nil];
    }
    return result;
}


#pragma mark - TAB BAR DELEGATE

-(void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    
    UINavigationController *current = (UINavigationController *)viewController;
    id root = [current.childViewControllers firstObject];
    
    if ([root isKindOfClass:[JWPublicTableViewController class]]) {
        NSLog(@"%s", __func__);
        
        if (![[JWAWSIdentityManager sharedInstance] isLoggedInWithFacebook]) {
            
            if (!_blocked) {
                self.blockingView = [[JWBlockingView alloc] initWithFrame:self.view.frame];
                
                self.blockingView.pageStatement.text = @"This page allows artists to search for other registered users and download their content to use inside JamWith.";
                
                //Originaly i set the views alpha to 0.5 but that affected all of its subviews which wasnt the desired look.  Now i am setting the background color to a color with an alpha component.
                self.blockingView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
                [current.view addSubview:_blockingView];
                _blocked = YES;
            }
        }
        
        

    }
}


#pragma mark - BLOCKING VIEW DELEGATE 

-(void)unblock {
    NSLog(@"%s", __func__);
    [[JWAWSIdentityManager sharedInstance] completeFBLoginWithCompletion:^id(AWSTask *task) {
        NSLog(@"Completion.");
        dispatch_async(dispatch_get_main_queue(), ^{
            [self removeBlock];
        });
        return nil;
    }];

}

-(void)stayBlockedWithMessage {
    
    
}

#pragma mark - VIEW BLOCK CALLS


-(void)removeBlock {
    
    [self.blockingView removeFromSuperview];
}



@end
