//
//  JWHTVJamSessionCellTableViewCell.m
//  JamWDev
//
//  Created by brendan kerr on 5/16/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

#import "JWHTVJamSessionTableViewCell.h"
#import <AVFoundation/AVFoundation.h>

@interface JWHTVJamSessionTableViewCell() {
    
    BOOL _playing;
}

@property (nonatomic) NSMutableArray *activePlayers;
@property (nonatomic) UIImage *scrubberWhiteImage;
@property (nonatomic) UIImage *scrubberBlueImage;
@property (nonatomic) UIImage *scrubberGreenImage;

@end

@implementation JWHTVJamSessionTableViewCell

-(NSMutableArray *)activePlayers {
    
    if (!_activePlayers) {
        _activePlayers = [NSMutableArray new];
    }
    return _activePlayers;
}


- (void)awakeFromNib {
    // Initialization code
    _playing = NO;
    
    _scrubberBlueImage = [UIImage imageNamed:@"scrubberIconBlue"];
    _scrubberWhiteImage = [UIImage imageNamed:@"scrubberIconWhite"];
    _scrubberGreenImage = [UIImage imageNamed:@"scrubberIconGreen"];
    
    [self.buttonImage setImage:_scrubberWhiteImage forState:UIControlStateNormal];
    //[self.buttonImage setImage:_scrubberGreenImage forState:UIControlStateHighlighted];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)previewAudio:(id)sender {
    NSLog(@"%s", __func__);
    
    
    if (!_playing) {
        
        for (NSURL *trackURL in self.audioURLsForThisCell) {
            
            NSError *error;
            AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:trackURL error:&error];
            
            if (!error) {
                NSLog(@"Player added");
                [self.activePlayers addObject:player];
            }
        }
        
        [self playActivePlayers];
        [self.buttonImage setImage:_scrubberGreenImage forState:UIControlStateNormal];
    } else {
        [self stopActivePlayers];
        [self terminateActivePlayers];
        [self.buttonImage setImage:_scrubberWhiteImage forState:UIControlStateNormal];
    }
    
    _playing = !_playing;
    [self.buttonImage setNeedsDisplay];
}

-(void)terminateActivePlayers {
    
    self.activePlayers = nil;
}


-(void)playActivePlayers {
    NSLog(@"%s", __func__);
    for (AVAudioPlayer *player in self.activePlayers) {
        [player play];
    }
}

-(void)pauseActivePlayers {
    NSLog(@"%s", __func__);
    for (AVAudioPlayer *player in self.activePlayers) {
        [player pause];
    }
}

-(void)stopActivePlayers {
    NSLog(@"%s", __func__);
    for (AVAudioPlayer *player in self.activePlayers) {
        [player stop];
    }
}


@end
