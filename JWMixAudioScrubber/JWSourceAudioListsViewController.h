//
//  JWSourceAudioListsViewController.h
//  JWMixAudioScrubber
//
//  co-created by joe and brendan kerr on 1/10/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol JWSourceAudioListsDelegate;

@interface JWSourceAudioListsViewController : UIViewController
@property (nonatomic,weak) id <JWSourceAudioListsDelegate> delegate;
@property (nonatomic) BOOL selectToClip;  // otherwise will preview
@end


@protocol JWSourceAudioListsDelegate <NSObject>
@optional
-(void)finishedTrim:(JWSourceAudioListsViewController *)controller;
-(void)finishedTrim:(JWSourceAudioListsViewController *)controller withDBKey:(NSString*)key;
-(void)finishedTrim:(JWSourceAudioListsViewController *)controller title:(NSString*)title withDBKey:(NSString*)key;
@end
