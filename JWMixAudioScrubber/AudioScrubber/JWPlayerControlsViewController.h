//
//  JWPlayerControlsViewController.h
//  JamWIthT
//
//  co-created by joe and brendan kerr on 11/9/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JWUITransportButton.h"
#import "JWPlayerControlsProtocol.h"

@protocol JWPlayerControlsProtocol;

@interface JWPlayerControlsViewController : UIViewController

@property (nonatomic,weak) id <JWPlayerControlsProtocol> delegate;

@property (strong, nonatomic) IBOutlet UIImageView *ampImageView;
@property (strong, nonatomic) IBOutlet JWUITransportButton *rewindButton;
@property (strong, nonatomic) IBOutlet JWUITransportButton *playButton;
@property (strong, nonatomic) IBOutlet JWUITransportButton *recordButton;
@property (nonatomic) BOOL recording;
@property (nonatomic) BOOL canPlayback;
@property (nonatomic) BOOL playing;
@property (nonatomic) PlayerControllerState state;

-(void)setState:(PlayerControllerState)state withRecording:(BOOL)rec;
-(void)initializeWithState:(PlayerControllerState)state withLightBackround:(BOOL)backround;
-(void)initializeUIElements;
-(void)updateButtonStates;
@end
