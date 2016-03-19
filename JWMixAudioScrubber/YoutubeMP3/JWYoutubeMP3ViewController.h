//
//  ViewController.h
//  JamWithV1.0
//
//  co-created by joe and brendan kerr on 9/4/15.
//  Copyright (c) 2015 b3k3r. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol JWYoutubeMP3ViewDelegate;

@interface JWYoutubeMP3ViewController : UIViewController <UIWebViewDelegate>
@property (nonatomic,weak) id <JWYoutubeMP3ViewDelegate> delegate;
@property (nonatomic) BOOL tapToJam; // as opposed to tap to pla
@property (nonatomic) NSURL *youTubeLinkURL;
-(void)setUrlSessionYoutubeString:(NSString *)youtubeString videoId:(NSString *)videoId andVideoTitle:(NSString *)videoTitle;
@end


@protocol JWYoutubeMP3ViewDelegate <NSObject>
@optional
-(void)finishedTrim:(JWYoutubeMP3ViewController *)controller;
-(void)finishedTrim:(JWYoutubeMP3ViewController *)controller withTrimKey:(NSString*)trimKey forKey:(NSString*)key;
-(void)finishedTrim:(JWYoutubeMP3ViewController *)controller withTrimKey:(NSString*)trimKey title:(NSString*)title forKey:(NSString*)key;

@end
