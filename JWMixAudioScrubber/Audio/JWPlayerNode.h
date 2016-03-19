//
//  JWPlayerNode.h
//  JamWIthT
//
//  co-created by joe and brendan kerr on 10/18/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface JWPlayerNode : AVAudioPlayerNode

@property (nonatomic) AVAudioFile *audioFile;
-(CGFloat)progressOfAudioFile;
-(CGFloat)durationInSecondsOfAudioFile;
-(CGFloat)remainingDurationInSecondsOfAudioFile;
-(CGFloat)currentPositionInSecondsOfAudioFile;
-(NSString*)processingFormatStrOfAudioFile;

@property (nonatomic) NSDictionary *fileReference;
@property (nonatomic) float delayStart;
@property (nonatomic) NSTimeInterval startPlayingInset;

@end
