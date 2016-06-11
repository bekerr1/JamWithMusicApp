//
//  JWAudioPlayerController.h
//  JWAudioScrubber
//
//  co-created by joe and brendan kerr on 12/27/15.
//  Copyright © 2015 b3k3r. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JWPlayerControlsProtocol.h"
#import "JWEffectsHandler.h"
#import "JWScrubberController.h"
#import "JWMTEffectsAudioEngine.h"
#import "JWPlayerControlsViewController.h"
@import UIKit;


typedef void (^JWPlayerCompletionHandler)(void);

@protocol JWAudioPlayerControllerDelegate;

@interface JWAudioPlayerController : NSObject <JWPlayerControlsProtocol>

@property (nonatomic) JWScrubberController *sc;
@property (strong, nonatomic) JWMTEffectsAudioEngine *audioEngine;
@property (nonatomic) JWPlayerControlsViewController* pcvc;
@property (strong, nonatomic) id trackItem;
@property (strong, nonatomic) id trackItems;
@property (nonatomic, readonly) PlayerControllerState state;
@property (nonatomic, readonly) NSUInteger numberOfTracks;
@property (nonatomic) id <JWAudioPlayerControllerDelegate> delegate;
@property (nonatomic) BOOL autoPlay;
//TODO: more five second stuff
@property (nonatomic) BOOL fiveSecondCountDown;
@property (nonatomic) BOOL hasFiveSecondClip;
@property (nonatomic) BOOL listenToPositionChanges;

@property (nonatomic) NSTimer *mixerValueFadeTimer;

-(void)setTrackSet:(id)trackSet;

-(void) initializePlayerControllerWithScrubber:(id)svc playerControls:(id)pvc mixEdit:(id)me;

-(void) initializePlayerControllerWithScrubber:(id)svc playerControls:(id)pvc
                                       mixEdit:(id)me withCompletion:(JWPlayerCompletionHandler)completion;

-(void) initializePlayerControllerWithScrubberWithAutoplayOn:(BOOL)autoplay
                                           usingScrubberView:(id)svc playerControls:(id)pvc
                                                     mixEdit:(id)me withCompletion:(JWPlayerCompletionHandler)completion;

-(void) selectValidTrack;
-(void) deSelectTrack;
-(BOOL) editSelectedTrackBeginInset;
-(BOOL) editSelectedTrackEndInset;
-(BOOL) editSelectedTrackStartPosition;
-(BOOL) stopEditingSelectedTrackSave;
-(BOOL) stopEditingSelectedTrackCancel;
-(void) stop;
-(void)addEffectToEngineNodelist:(NSString *)effect;

-(NSDictionary*)defaultWhiteColors;
-(NSUInteger)numberOfTracksWithAudio;
-(void)configureScrubbers:(BOOL)tap;

-(void)effectsCurrentSettings;

@end


@protocol JWAudioPlayerControllerDelegate <NSObject>

-(CGSize)updateScrubberHeight:(JWAudioPlayerController *)controller;
-(void)save:(JWAudioPlayerController *)controller;
-(void)playTillEnd;
-(void)noTrackSelected:(JWAudioPlayerController *)controller;
-(void)trackSelected:(JWAudioPlayerController *)controller;
-(void)playerController:(JWAudioPlayerController *)controller didLongPressForTrackAtIndex:(NSUInteger)index;

-(void)userAudioObtainedAtIndex:(NSUInteger)index recordingId:(NSString*)rid;
-(void)userAudioObtainedAtIndex:(NSUInteger)index recordingURL:(NSURL *)rurl;
-(void) userAudioObtainedWithComponents:(NSDictionary *)components atIndex:(NSUInteger)index;
-(void)effectsChanged:(NSArray*)effects inNodeWithKey:(NSString*)nodeKey;
-(void)startRecordCountDown:(void(^)())completion;
-(NSString*)playerControllerTitleForTrackSet:(JWAudioPlayerController*)controllerkey;

@optional

-(NSString*)playerController:(JWAudioPlayerController*)controller titleForTrackWithKey:(NSString*)key;
-(NSString*)playerController:(JWAudioPlayerController*)controller titleDetailForTrackWithKey:(NSString*)key;
//TODO: so i can set the target of a timer to the detail view controller
//becuase it hold the label that needs to be manipulated
-(id)countDownTarget;

@end
