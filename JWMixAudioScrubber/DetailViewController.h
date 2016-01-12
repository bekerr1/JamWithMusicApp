//
//  DetailViewController.h
//  JWAudioScrubber
//
//  Created by brendan kerr on 12/25/15.
//  Copyright © 2015 b3k3r. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, JWHomeSectionType) {
    JWHomeSectionTypeNone     =1,
    JWHomeSectionTypeOther,
    JWHomeSectionTypeDownloaded,
    JWHomeSectionTypePreloaded,
    JWHomeSectionTypeYoutube,
    JWHomeSectionTypeMyTracks,
    JWHomeSectionTypeAudioFiles
};

@protocol JWDetailDelegate;

@interface DetailViewController : UIViewController
@property (strong, nonatomic) id detailItem;
@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@property (weak, nonatomic) id <JWDetailDelegate> delegate;

-(void)stopPlaying;

@end

@protocol JWDetailDelegate <NSObject>
-(void)itemChanged:(DetailViewController*)controller;
-(void)itemChanged:(DetailViewController*)controller cachKey:(NSString*)key;
-(void)save:(DetailViewController*)controller cachKey:(NSString*)key;
-(void)addTrack:(DetailViewController*)controller cachKey:(NSString*)key;
-(NSArray*)tracks:(DetailViewController*)controller cachKey:(NSString*)key;
-(NSArray*)tracks:(DetailViewController*)controller forJamTrackKey:(NSString*)key;

@optional
-(void) userAudioObtainedInNodeWithKey:(NSString*)nodeKey recordingId:(NSString*)rid;

@end

@protocol JWAudioControlsDelegate <NSObject>


@end
