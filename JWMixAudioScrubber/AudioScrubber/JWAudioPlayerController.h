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

@protocol JWAudioPlayerControllerDelegate;

@interface JWAudioPlayerController : NSObject <JWPlayerControlsProtocol>

@property (strong, nonatomic) id trackItem;
@property (strong, nonatomic) id trackItems;
@property (nonatomic, readonly) PlayerControllerState state;
@property (nonatomic, readonly) NSUInteger numberOfTracks;
@property (nonatomic) id <JWAudioPlayerControllerDelegate> delegate;

-(void) initializePlayerControllerWithScrubber:(id)svc playerControls:(id)pvc mixEdit:(id)me;
-(void) selectValidTrack;
@end

@protocol JWAudioPlayerControllerDelegate <NSObject>

-(CGSize)updateScrubberHeight:(JWAudioPlayerController *)controller;
-(void)save:(JWAudioPlayerController *)controller;
-(void)playTillEnd;

-(void)noTrackSelected:(JWAudioPlayerController *)controller;
-(void)trackSelected:(JWAudioPlayerController *)controller;

@end
