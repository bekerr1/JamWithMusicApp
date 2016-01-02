//
//  JWPlayerControlsViewController.m
//  JamWIthT
//
//  Created by JOSEPH KERR on 11/9/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import "JWPlayerControlsViewController.h"

@interface JWPlayerControlsViewController() {
    BOOL _lightBackground;
}


@end


@implementation JWPlayerControlsViewController



-(void)initializeWithState:(PlayerControllerState)state withLightBackround:(BOOL)backround {

    _lightBackground = backround;
    [self initializeUIElements];
    self.state = state;
    
}

-(void)setState:(PlayerControllerState)state withRecording:(BOOL)rec {
    
    _state = state;
    _recordButton.enabled = rec;
    [self updateButtonStates];
}

- (void)initializeUIElements {
    
    
    _rewindButton.drawingStyle = rewindButtonStyle;
    _rewindButton.fillColor = _lightBackground ? [UIColor blackColor].CGColor :[UIColor whiteColor].CGColor;
    
    _playButton.drawingStyle = playButtonStyle;
    _playButton.fillColor = _lightBackground ? [UIColor blackColor].CGColor :[UIColor whiteColor].CGColor;
    
    _recordButton.drawingStyle = recordButtonStyle;
    _recordButton.fillColor = [UIColor redColor].CGColor;
    
}

-(void) updateButtonStates {
    
    
    if (_state == JWPlayerStatePlayFromPos) {
        [self setButtonsToR1];
    } else if (_state == JWPlayerStateRecFromPos) {
        [self setButtonsToR2];
    } else if (_state == JWPlayerStateSetToBeg || _state == JWPlayerStateSetToPos) {
        [self setButtonsToRoot];
    } else {
        
    }
    
    _rewindButton.alpha = _rewindButton.enabled ? 1.0 : 0.25;
    _recordButton.alpha = _recordButton.enabled ? 1.0 : 0.25;
    //[self.view setNeedsLayout];
}

-(void)setButtonsToR1 {
    
    _playButton.drawingStyle = pauseButtonStyle;
    _rewindButton.enabled = YES;
    _recordButton.drawingStyle = recordButtonStyle;
    
}

-(void)setButtonsToRoot {
    
    _playButton.drawingStyle = playButtonStyle;
    _rewindButton.enabled = YES;
    _recordButton.drawingStyle = recordButtonStyle;
    
}

-(void)setButtonsToR2 {
    
    _playButton.drawingStyle = pauseButtonStyle;
    _rewindButton.enabled = NO;
    _recordButton.drawingStyle = recordEnabledButtonStyle;
}



- (IBAction)playPressed:(UIButton *)sender {
    NSLog(@"%s", __func__);
//    [(JWUITransportButton*)sender drawingStyle];
    _playButton.drawingStyle == playButtonStyle ?
    [_delegate play] :
    [_delegate pause];
}


- (IBAction)recordPressed:(id)sender {
    NSLog(@"%s", __func__);
    [_delegate record];
}

- (IBAction)rewindPressed:(id)sender {
    NSLog(@"%s", __func__);
    [_delegate rewind];
}


//-(void)viewDidLayoutSubviews {
////    [self updateUIElements];
////    [self updateButtonStates];
//
//    
//}


@end