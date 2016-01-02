//
//  JWPlayerNode.m
//  JamWIthT
//
//  Created by brendan kerr on 10/18/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import "JWPlayerNode.h"

@interface JWPlayerNode()
@end


@implementation JWPlayerNode

-(instancetype)init {
    
    if (self = [super init]) {
        
    }
    return self;
}

-(CGFloat)progressOfAudioFile {
    return [self progressOfAudioFile:_audioFile];
}

-(CGFloat)durationInSecondsOfAudioFile {
    return [self durationInSecondsOfAudioFile:_audioFile];
}

-(CGFloat)remainingDurationInSecondsOfAudioFile {
    return [self remainingDurationInSecondsOfAudioFile:_audioFile];
}

-(CGFloat)currentPositionInSecondsOfAudioFile {
    return [self currentPositionInSecondsOfAudioFile:_audioFile];
}


-(CGFloat)progressOfAudioFile:(AVAudioFile*)audioFile
{
    CGFloat result = 0.000f;
    if (audioFile) {
        AVAudioFramePosition fileLength = audioFile.length;
        AVAudioTime *audioTime = [self lastRenderTime];
        AVAudioTime *playerTime = [self playerTimeForNodeTime:audioTime];
        
        if (playerTime==nil) {
            NSLog(@"%s NO PLAYER TIME  playing %@",__func__,@([self isPlaying]));
            result = 1.00f;
        } else {
            double fileLenInSecs = fileLength / [playerTime sampleRate];
            double currentPosInSecs = [playerTime sampleTime] / [playerTime sampleRate];
            if (currentPosInSecs > fileLenInSecs ) {
                if (/* DISABLES CODE */ (YES)) {
                    double normalizedProgress = currentPosInSecs/fileLenInSecs - floorf(currentPosInSecs/fileLenInSecs);
                    result = normalizedProgress;
                } else {
                    result = 1.0;
                }
                
            } else {
                result = currentPosInSecs/fileLenInSecs;
            }
        }
    }
    //    NSLog(@"%s %.3f",__func__,result);
    return result;
}


-(CGFloat)durationInSecondsOfAudioFile:(AVAudioFile*)audioFile
{
    CGFloat result = 0.000f;
    
    if (audioFile) {
        AVAudioFramePosition fileLength = audioFile.length;
        AVAudioTime *audioTime = [self lastRenderTime];
        AVAudioTime *playerTime = [self playerTimeForNodeTime:audioTime];
        
        double fileLenInSecs = 0.0f;
        if (playerTime) {
            fileLenInSecs = fileLength / [playerTime sampleRate];
        } else {
            Float64 mSampleRate = audioFile.processingFormat.streamDescription->mSampleRate;
            Float64 duration =  (1.0 / mSampleRate) * audioFile.processingFormat.streamDescription->mFramesPerPacket;
            fileLenInSecs = duration * fileLength;
        }
        result = (CGFloat)fileLenInSecs;
    }
    //    NSLog(@"%s %.3f",__func__,result);
    return result;
}

-(CGFloat)remainingDurationInSecondsOfAudioFile:(AVAudioFile*)audioFile
{
    CGFloat result = 0.000f;
    if (audioFile) {
        AVAudioTime *audioTime = [self lastRenderTime];
        AVAudioFramePosition fileLength = audioFile.length;
        AVAudioTime *playerTime = [self playerTimeForNodeTime:audioTime];
        
        double fileLenInSecs = fileLength / [playerTime sampleRate];
        double currentPosInSecs = [playerTime sampleTime] / [playerTime sampleRate];
        if (currentPosInSecs >= fileLenInSecs ) {
            if (/* DISABLES CODE */ (YES)) {
                double normalizedProgress = currentPosInSecs/fileLenInSecs - floorf(currentPosInSecs/fileLenInSecs);
                result = fileLenInSecs - (normalizedProgress * fileLenInSecs);
            } else {
                result = 0.0;
            }
        } else {
            result = (fileLenInSecs - currentPosInSecs);
        }
    }
//        NSLog(@"%s %.3f",__func__,result);
    return result;
}

-(CGFloat)currentPositionInSecondsOfAudioFile:(AVAudioFile*)audioFile
{
    CGFloat result = 0.000f;
    if (audioFile) {
        AVAudioFramePosition fileLength = audioFile.length;
        AVAudioTime *audioTime = [self lastRenderTime];
        AVAudioTime *playerTime = [self playerTimeForNodeTime:audioTime];
        
        double fileLenInSecs = fileLength / [playerTime sampleRate];
        double currentPosInSecs = [playerTime sampleTime] / [playerTime sampleRate];
        if (currentPosInSecs > fileLenInSecs ) {
            if (/* DISABLES CODE */ (YES)) {
                // Looops player time keeps playing past ened figure out where in Loop
                double normalizedProgress = currentPosInSecs/fileLenInSecs - floorf(currentPosInSecs/fileLenInSecs);
                result = fileLenInSecs / (normalizedProgress * fileLenInSecs);
            } else {
                result = fileLenInSecs;
            }
        } else {
            result = currentPosInSecs;
        }
    }
    //    NSLog(@"%s %.3f",__func__,result);
    return result;
}

@end
