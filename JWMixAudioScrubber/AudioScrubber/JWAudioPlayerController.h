//
//  JWAudioPlayerController.h
//  JWAudioScrubber
//
//  Created by brendan kerr on 12/27/15.
//  Copyright © 2015 b3k3r. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JWPlayerControlsProtocol.h"
#import "JWEffectsHandler.h"
@import UIKit;


typedef void (^JWPlayerCompletionHandler)(void);

@protocol JWAudioPlayerControllerDelegate;

@interface JWAudioPlayerController : NSObject <JWPlayerControlsProtocol>

@property (strong, nonatomic) id trackItem;
@property (strong, nonatomic) id trackItems;
@property (nonatomic, readonly) PlayerControllerState state;
@property (nonatomic, readonly) NSUInteger numberOfTracks;
@property (nonatomic) id <JWAudioPlayerControllerDelegate> delegate;
@property (nonatomic) BOOL autoPlay;

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

@end


@protocol JWAudioPlayerControllerDelegate <NSObject>

-(CGSize)updateScrubberHeight:(JWAudioPlayerController *)controller;
-(void)save:(JWAudioPlayerController *)controller;
-(void)playTillEnd;

-(void)noTrackSelected:(JWAudioPlayerController *)controller;
-(void)trackSelected:(JWAudioPlayerController *)controller;
-(void)playerController:(JWAudioPlayerController *)controller didLongPressForTrackAtIndex:(NSUInteger)index;

-(void) userAudioObtainedAtIndex:(NSUInteger)index recordingId:(NSString*)rid;

-(NSString*)playerControllerTitleForTrackSetContainingKey:(JWAudioPlayerController*)controllerkey;

@optional
-(NSString*)playerController:(JWAudioPlayerController*)controller titleForTrackWithKey:(NSString*)key;
-(NSString*)playerController:(JWAudioPlayerController*)controller titleDetailForTrackWithKey:(NSString*)key;


@end
