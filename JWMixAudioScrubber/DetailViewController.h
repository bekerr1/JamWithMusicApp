//
//  DetailViewController.h
//  JWAudioScrubber
//
//  co-created by joe and brendan kerr on 12/25/15.
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
    JWHomeSectionTypeAudioFiles,
    JWHomeSectionTypeUser
};

@protocol JWDetailDelegate;


@interface DetailViewController : UIViewController
@property (strong, nonatomic) id detailItem;
@property (weak, nonatomic) id <JWDetailDelegate> delegate;
-(void)stopPlaying;
@end


@protocol JWDetailDelegate <NSObject>

-(NSArray*)tracks:(DetailViewController*)controller forJamTrackKey:(NSString*)key;
-(NSString*)detailController:(DetailViewController*)controller titleForJamTrackKey:(NSString*)key;
-(NSString*)detailController:(DetailViewController*)controller titleForTrackAtIndex:(NSUInteger)index
           inJamTrackWithKey:(NSString*)key;

-(void)save:(DetailViewController*)controller cachKey:(NSString*)key;
-(void)userAudioObtainedInNodeWithKey:(NSString*)nodeKey recordingId:(NSString*)rid;
-(void)effectsChanged:(NSArray*)effects inNodeWithKey:(NSString*)nodeKey;
@optional
// METhods used by test apps when detail changed items like scrubber color
-(void)itemChanged:(DetailViewController*)controller;
-(void)itemChanged:(DetailViewController*)controller cachKey:(NSString*)key;
-(void)addTrack:(DetailViewController*)controller cachKey:(NSString*)key;
-(id)addTrackNode:(id)controller toJamTrackWithKey:(NSString*)key;
@end



