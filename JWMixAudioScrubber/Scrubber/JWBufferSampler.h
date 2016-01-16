//
//  JWBufferSampler.h
//  JamWIthT
//
//  Created by JOSEPH KERR on 9/27/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import <Foundation/Foundation.h>
@import AVFoundation;

typedef NS_ENUM(NSInteger, SamplerSampleSize) {
    SSampleSizeMin = 1,
    SSampleSize4,
    SSampleSize6,
    SSampleSize8,
    SSampleSize10,
    SSampleSize14,
    SSampleSize18,
    SSampleSize24,
    SSampleSizeMax
};


@interface JWBufferSampler : NSObject

-(instancetype)initWith:(SamplerSampleSize)sampleSize;

// record
-(instancetype)initWithBuffer:(AVAudioPCMBuffer *)buffer atReadPosition:(AVAudioFramePosition)readPosition
                   sampleSize:(SamplerSampleSize)sampleSize
                  dualChannel:(BOOL)dualChannel
              computeAverages:(BOOL)averages
                 pulseSamples:(BOOL)pulseSamples
           loudestSampleSoFar:(float)loudestSamplesoFar;

// play - we no loudest
-(instancetype)initWithBuffer:(AVAudioPCMBuffer *)buffer atReadPosition:(AVAudioFramePosition)readPosition
                   sampleSize:(SamplerSampleSize)sampleSize
                  dualChannel:(BOOL)dualChannel
              computeAverages:(BOOL)averages
                 pulseSamples:(BOOL)pulseSamples
                loudestSample:(float)loudestSampleAllBuffers;

@property (nonatomic,readwrite) SamplerSampleSize sampleSize;
@property (nonatomic,readwrite) BOOL dualChannel;
@property (nonatomic,readonly) NSArray *samples;
@property (nonatomic,readonly) NSArray *samplesChannel2;
@property (nonatomic,readonly) NSArray *averageSamples;
@property (nonatomic,readonly) NSArray *averageSamplesChannel2;
@property (nonatomic,readonly) Float64 durationThisBuffer;
@property (nonatomic,readwrite) NSUInteger trackNumber;
@property (nonatomic,readwrite) float loudestSampleSoFar;
@property (nonatomic,readonly) float loudestSample;
@property (nonatomic,readonly) float loudestSampleValue;
@property (nonatomic,readonly) float lowestSampleValue;
@property (nonatomic,readonly) AVAudioFramePosition loudestSampleFramePostion;
@property (nonatomic,readonly) AVAudioFramePosition lowestSampleFramePostion;
@end
