//
//  JWRecorderTableViewCell.m
//  JamWIthT
//
//  Created by JOSEPH KERR on 11/11/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import "JWRecorderTableViewCell.h"

@implementation JWRecorderTableViewCell

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder])
    {
        [self updateUIElements];
    }
    return self;
}

- (IBAction)recordAction:(id)sender {
    
    NSLog(@"%s",__func__);
    
    _recording = !_recording;

    [self updateButtonStates];
}

-(void)setRecording:(BOOL)recording {
    _recording = recording;
//    [self updateUIElements];
    [self updateButtonStates];
}

-(void)setRecordingEnabled:(BOOL)recordingEnabled {
    _recordingEnabled = recordingEnabled;
    _recordButton.enabled = _recordingEnabled;
//    [self updateUIElements];
    [self updateButtonStates];
}


#pragma mark -

- (void)updateUIElements {
    _recordButton.drawingStyle = recordButtonStyle;
    _recordButton.fillColor = [UIColor redColor].CGColor;
    [self updateButtonStates];
}

-(void) updateButtonStates {
 
    if (_recordingEnabled) {
        _recordButton.drawingStyle = _recording ? recordEnabledButtonStyle : recordButtonStyle;
        _recordButton.enabled = YES;

    } else {
        _recordButton.enabled = NO;
        _recordButton.drawingStyle = recordDisabledButtonStyle;
    }
    
    [_recordButton setNeedsDisplay];
//    [self.contentView setNeedsDisplay];

    [self.contentView setNeedsLayout];
}

@end
