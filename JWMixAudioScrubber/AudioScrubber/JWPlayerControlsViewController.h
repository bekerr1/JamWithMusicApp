//
//  JWPlayerControlsViewController.h
//  JamWIthT
//
//  Created by JOSEPH KERR on 11/9/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JWUITransportButton.h"
#import "JWPlayerControlsProtocol.h"

@protocol JWPlayerControlsProtocol;

@interface JWPlayerControlsViewController : UIViewController
@property (strong, nonatomic) IBOutlet UIImageView *ampImageView;
@property (nonatomic,assign) id <JWPlayerControlsProtocol> delegate;
@property (strong, nonatomic) IBOutlet JWUITransportButton *rewindButton;
@property (strong, nonatomic) IBOutlet JWUITransportButton *playButton;
@property (strong, nonatomic) IBOutlet JWUITransportButton *recordButton;
@property (nonatomic) BOOL recording;
@property (nonatomic) BOOL canPlayback;
@property (nonatomic) BOOL playing;
@property (nonatomic) PlayerControllerState state;

-(void)setState:(PlayerControllerState)state withRecording:(BOOL)rec;

-(void)initializeWithState:(PlayerControllerState)state withLightBackround:(BOOL)backround;
- (void)initializeUIElements;
-(void) updateButtonStates;

@end


// Protocol builds on JWAudioEngineDelegate with additional clip specific methods
//@protocol JWPlayerControlsDelegate  <NSObject>
////- (IBAction)playPauseAction:(id)sender {
//- (void)playPauseAction:(id)sender;
//- (void)rewindAction:(id)sender;
//- (void)recordAction:(id)sender;
//@end
//
