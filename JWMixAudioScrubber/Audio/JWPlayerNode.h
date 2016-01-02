//
//  JWPlayerNode.h
//  JamWIthT
//
//  Created by brendan kerr on 10/18/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface JWPlayerNode : AVAudioPlayerNode

@property (nonatomic) AVAudioFile *audioFile;
-(CGFloat)progressOfAudioFile;
-(CGFloat)durationInSecondsOfAudioFile;
-(CGFloat)remainingDurationInSecondsOfAudioFile;
-(CGFloat)currentPositionInSecondsOfAudioFile;
@end


//-(CGFloat)progressOfAudioFile:(AVAudioFile*)audioFile;
//-(CGFloat)durationInSecondsOfAudioFile:(AVAudioFile*)audioFile;
//-(CGFloat)remainingDurationInSecondsOfAudioFile:(AVAudioFile*)audioFile;
//-(CGFloat)currentPositionInSecondsOfAudioFile:(AVAudioFile*)audioFile;
