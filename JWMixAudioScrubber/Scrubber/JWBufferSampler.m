//
//  JWBufferSampler.m
//  JamWIthT
//
//  Created by JOSEPH KERR on 9/27/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import "JWBufferSampler.h"
@import AVFoundation;

@interface JWBufferSampler () {
    BOOL _computeAverages;
    BOOL _gatherPulseSamples;
}
@property (nonatomic,readwrite) NSArray *samples;
@property (nonatomic,readwrite) NSArray *samplesChannel2;
@property (nonatomic,readwrite) NSArray *averageSamples;
@property (nonatomic,readwrite) NSArray *averageSamplesChannel2;
@property (nonatomic,readwrite) float loudestSample1;
@property (nonatomic,readwrite) float loudestSample2;
@property (nonatomic,readwrite) Float64 durationThisBuffer;
@property (nonatomic,readwrite) float loudestSample;
@property (nonatomic,readwrite) float loudestSampleValue;
@property (nonatomic,readwrite) float lowestSampleValue;
@property (nonatomic,readwrite) AVAudioFramePosition loudestSampleFramePostion;
@property (nonatomic,readwrite) AVAudioFramePosition lowestSampleFramePostion;
@end


@implementation JWBufferSampler

-(instancetype)initWith:(SamplerSampleSize)sampleSize
{
    if (self == [super init]) {
        _sampleSize = sampleSize;
        _loudestSample = 0.000f;
        _durationThisBuffer = 0.000f;
    }
    return self;
}


-(instancetype)initWithBuffer:(AVAudioPCMBuffer *)buffer atReadPosition:(AVAudioFramePosition)readPosition
                   sampleSize:(SamplerSampleSize)sampleSize
                  dualChannel:(BOOL)dualChannel
              computeAverages:(BOOL)averages
              pulseSamples:(BOOL)pulseSamples
                loudestSampleSoFar:(float)loudestSamplesoFar
{
    // when using the listener - we doo NOT know loudestSampleAllBuffers, we trackit
    if (self == [super init]) {
        _sampleSize = sampleSize;
        _loudestSample = 0.00000f;
        _durationThisBuffer = 0.00000f;
        _dualChannel = dualChannel;
        _loudestSampleSoFar = loudestSamplesoFar;
        _computeAverages = averages;
        _gatherPulseSamples = pulseSamples;

        [self bufferReceived:(AVAudioPCMBuffer *)buffer
              atReadPosition:(AVAudioFramePosition)readPosition];
    }
    return self;
}

-(instancetype)initWithBuffer:(AVAudioPCMBuffer *)buffer atReadPosition:(AVAudioFramePosition)readPosition
                   sampleSize:(SamplerSampleSize)sampleSize
                  dualChannel:(BOOL)dualChannel
              computeAverages:(BOOL)averages
                 pulseSamples:(BOOL)pulseSamples
                loudestSample:(float)loudestSampleAllBuffers
{
    // PLAYING - we know loudestSampleAllBuffers
    if (self == [super init]) {
        _sampleSize = sampleSize;
        _loudestSample = 0.000f;
        _durationThisBuffer = 0.000f;
        _dualChannel = dualChannel;
        _computeAverages = averages;
        _gatherPulseSamples = pulseSamples;

        [self bufferReceived:(AVAudioPCMBuffer *)buffer
              atReadPosition:(AVAudioFramePosition)readPosition loudestSample:loudestSampleAllBuffers];
    }
    return self;
}


- (void)sampleTheBuffer:(AVAudioPCMBuffer *)buffer atReadPosition:(AVAudioFramePosition)readPosition
{
    [self bufferReceived:(AVAudioPCMBuffer *)buffer atReadPosition:(AVAudioFramePosition)readPosition];
}

- (void)sampleTheBuffer:(AVAudioPCMBuffer *)buffer atReadPosition:(AVAudioFramePosition)readPosition loudestSample:(float)loudestSampleAllBuffers
{
    [self bufferReceived:(AVAudioPCMBuffer *)buffer atReadPosition:(AVAudioFramePosition)readPosition
           loudestSample:(float)loudestSampleAllBuffers];
}


// PLAY
- (void)bufferReceived:(AVAudioPCMBuffer *)buffer atReadPosition:(AVAudioFramePosition)readPosition loudestSample:(float)loudestSampleAllBuffers {
    
    // NSLog(@"%s %lld framLen %d ",__func__,readPosition, buffer.frameLength);
    if (buffer.frameLength == 0) {
        NSLog(@"%s empty buffer ",__func__);
        return;
    }
    
    BOOL averages=_computeAverages;
    NSUInteger sampleSize = 18;
    if (_sampleSize == SSampleSize4) {
        sampleSize = 4;
    } else if (_sampleSize == SSampleSize8) {
        sampleSize = 8;
    } else if (_sampleSize == SSampleSize10) {
        sampleSize = 10;
    } else if (_sampleSize == SSampleSize14) {
        sampleSize = 14;
    } else if (_sampleSize == SSampleSize18) {
        sampleSize = 18;
    }
    
    float loudestPulseSample = 0.0;
    float lowestPulseSample = 0.0;
    AVAudioFramePosition loudestPulseSampleFramePostion = 0;
    AVAudioFramePosition lowestPulseSampleFramePostion = 0;

    AVAudioFrameCount frameIndexes1[sampleSize];
    AVAudioFrameCount frameIndexes2[sampleSize];

    float loudestSamples1[sampleSize];
    float loudestSamples2[sampleSize];
    int nSamplesInSectionSet1[sampleSize];
    int nSamplesInSectionSet2[sampleSize];
    float sumOfSamples1[sampleSize];
    float sumOfSamples2[sampleSize];
    float avgOfSamples1[sampleSize];
    float avgOfSamples2[sampleSize];

    for (int frameSampleIndex = 0; frameSampleIndex < sampleSize; frameSampleIndex++) {
        frameIndexes1[frameSampleIndex] = (frameSampleIndex + 1) / (float)sampleSize  * buffer.frameLength;
        frameIndexes2[frameSampleIndex] = frameIndexes1[frameSampleIndex];
        loudestSamples1[frameSampleIndex] = 0.0f;
        loudestSamples2[frameSampleIndex] = 0.0f;
        nSamplesInSectionSet1[frameSampleIndex] = 0;
        nSamplesInSectionSet2[frameSampleIndex] = 0;
        sumOfSamples1[frameSampleIndex] = 0.0f;
        sumOfSamples2[frameSampleIndex] = 0.0f;
        avgOfSamples1[frameSampleIndex] = 0.0f;
        avgOfSamples2[frameSampleIndex]= 0.0f;
    }

    //    for (int frameSampleIndex = 0; frameSampleIndex < sampleSize; frameSampleIndex++) {
    //        NSLog(@" frame samples index %d",frameIndexes[frameSampleIndex]);
    //    }
    
    //duration = (1 / mSampleRate) * mFramesPerPacket
    
    Float64 mSampleRate = buffer.format.streamDescription->mSampleRate;
    Float64 duration =  (1.0 / mSampleRate) * buffer.format.streamDescription->mFramesPerPacket;
    Float64 durThisBuffer = duration * buffer.frameLength;
    
    
    lowestPulseSample = loudestSampleAllBuffers;  // initially set to highest
    
//    NSLog(@"%s mSampleRate %.3f duration %.7f durThisBuffer %.5f frameLength %d",__func__,mSampleRate,duration,durThisBuffer,buffer.frameLength);
    
    self.durationThisBuffer = durThisBuffer;

//    NSLog(@"loudestSampleAllBuffers %.3f",loudestSampleAllBuffers);
    //NSLog(@" %.3f dur this buffer",durThisBuffer);
    
    for (AVAudioChannelCount channelIndex = 0; channelIndex < buffer.format.channelCount; ++channelIndex)
    {
        if (_dualChannel == NO) {
            if (channelIndex > 0) {
                break;
            }
        }
        float *channelData = buffer.floatChannelData[channelIndex];
        for (AVAudioFrameCount frameIndex = 0; frameIndex < buffer.frameLength; ++frameIndex)
        {
            float sampleAbsLevel = fabs(channelData[frameIndex]);
            
            // CHANNEL 1
            if (channelIndex == 0) {
                
                for (int i=0; i < sampleSize; i++) {
                    if (frameIndex < frameIndexes1[i]) {
                        
                        if  (i > 0) {
                            if (frameIndex > frameIndexes1[i-1]) {
                                
                                if (averages) {
                                    nSamplesInSectionSet1[i]++;
                                    sumOfSamples1[i] += sampleAbsLevel;
                                }
                                if (_gatherPulseSamples) {
                                    if (sampleAbsLevel > loudestPulseSample){
                                        loudestPulseSample = sampleAbsLevel;
                                        loudestPulseSampleFramePostion = frameIndex;
                                    }
                                    if (sampleAbsLevel < lowestPulseSample){
                                        lowestPulseSample = sampleAbsLevel;
                                        lowestPulseSampleFramePostion = frameIndex;
                                    }
                                }
                                
                                if (sampleAbsLevel > loudestSamples1[i])
                                    loudestSamples1[i] = sampleAbsLevel;
                            } else {
                                break;
                            }
                        } else {
                            
                            if (averages) {
                                nSamplesInSectionSet1[i]++;
                                sumOfSamples1[i] += sampleAbsLevel;
                            }
                            if (_gatherPulseSamples) {
                                if (sampleAbsLevel > loudestPulseSample){
                                    loudestPulseSample = sampleAbsLevel;
                                    loudestPulseSampleFramePostion = frameIndex;
                                }
                                if (sampleAbsLevel < lowestPulseSample){
                                    lowestPulseSample = sampleAbsLevel;
                                    lowestPulseSampleFramePostion = frameIndex;
                                }
                            }
                            
                            if (sampleAbsLevel > loudestSamples1[i])
                                loudestSamples1[i] = sampleAbsLevel;
                        }
                    }
                    
                    
                } // frameindex in range
                
            } // channel
            
            // CHANNEL 2

            else if (channelIndex == 1) {
                
                for (int i=0; i < sampleSize; ++i) {
                    if (frameIndex < frameIndexes2[i]) {
                        
                        if  (i > 0) {
                            if (frameIndex > frameIndexes2[i-1]) {
                                
                                if (averages) {
                                    nSamplesInSectionSet2[i]++;
                                    sumOfSamples2[i] += sampleAbsLevel;
                                }
                                if (_gatherPulseSamples) {
                                    if (sampleAbsLevel > loudestPulseSample){
                                        loudestPulseSample = sampleAbsLevel;
                                        loudestPulseSampleFramePostion = frameIndex;
                                    }
                                    if (sampleAbsLevel < lowestPulseSample){
                                        lowestPulseSample = sampleAbsLevel;
                                        lowestPulseSampleFramePostion = frameIndex;
                                    }
                                }
                                
                                if (sampleAbsLevel > loudestSamples2[i])
                                    loudestSamples2[i] = sampleAbsLevel;
                                
                            } else {
                                break; //i = (int)sampleSize;//break;
                            }
                        } else {
                            
                            if (averages) {
                                nSamplesInSectionSet2[i]++;
                                sumOfSamples2[i] += sampleAbsLevel;
                            }
                            if (_gatherPulseSamples) {
                                if (sampleAbsLevel > loudestPulseSample){
                                    loudestPulseSample = sampleAbsLevel;
                                    loudestPulseSampleFramePostion = frameIndex;
                                }
                                if (sampleAbsLevel < lowestPulseSample){
                                    lowestPulseSample = sampleAbsLevel;
                                    lowestPulseSampleFramePostion = frameIndex;
                                }
                            }
                            
                            if (sampleAbsLevel > loudestSamples2[i])
                                loudestSamples2[i] = sampleAbsLevel;
                        }
                    } // frameindex in range
                }
                
            }  // channelindex = 1
            
        } // for each frame
        
        
        // We are done with the channel
        
        if (channelIndex == 0) {
            
            // PLAYing
            // compute the stats
            for (int frameSampleIndex = 0; frameSampleIndex < sampleSize; frameSampleIndex++) {
                avgOfSamples1[frameSampleIndex] = sumOfSamples1[frameSampleIndex] / nSamplesInSectionSet1[frameSampleIndex];
                // clear the stats
                nSamplesInSectionSet1[frameSampleIndex] = 0;
                sumOfSamples1[frameSampleIndex] = 0.0f;
//                NSLog(@"1 average %.5f largest  %.5f",avgOfSamples1[frameSampleIndex], loudestSamples1[frameSampleIndex] );
            }
            
        } else if (_dualChannel && channelIndex == 1 ) {

            // compute the stats
            for (int frameSampleIndex = 0; frameSampleIndex < sampleSize; frameSampleIndex++) {
                avgOfSamples2[frameSampleIndex] = sumOfSamples2[frameSampleIndex] / nSamplesInSectionSet2[frameSampleIndex];
                // clear the stats
                nSamplesInSectionSet2[frameSampleIndex] = 0;
                sumOfSamples2[frameSampleIndex] = 0.0f;
            }
        }  // channel
        
    }  // for channel index count
    
    self.loudestSampleValue = loudestPulseSample/loudestSampleAllBuffers;
    self.lowestSampleValue = lowestPulseSample/loudestSampleAllBuffers;
    self.loudestSampleFramePostion = loudestPulseSampleFramePostion;
    self.lowestSampleFramePostion = lowestPulseSampleFramePostion;
    
    if (_sampleSize == SSampleSize4) {
        self.samples = @[@(loudestSamples1[0]/loudestSampleAllBuffers),
                         @(loudestSamples1[1]/loudestSampleAllBuffers),
                         @(loudestSamples1[2]/loudestSampleAllBuffers),
                         @(loudestSamples1[3]/loudestSampleAllBuffers)
                         ];
        if (_dualChannel)
            self.samplesChannel2 = @[@(loudestSamples2[0]/loudestSampleAllBuffers),
                                     @(loudestSamples2[1]/loudestSampleAllBuffers),
                                     @(loudestSamples2[2]/loudestSampleAllBuffers),
                                     @(loudestSamples2[3]/loudestSampleAllBuffers)
                                     ];
    }

    // SIX
    
    else if (_sampleSize == SSampleSize6) {
        self.samples = @[@(loudestSamples1[0]/loudestSampleAllBuffers),
                         @(loudestSamples1[1]/loudestSampleAllBuffers),
                         @(loudestSamples1[2]/loudestSampleAllBuffers),
                         @(loudestSamples1[3]/loudestSampleAllBuffers),
                         @(loudestSamples1[4]/loudestSampleAllBuffers),
                         @(loudestSamples1[5]/loudestSampleAllBuffers)
                         ];
        
        if (_dualChannel)
            self.samplesChannel2 = @[@(loudestSamples2[0]/loudestSampleAllBuffers),
                                     @(loudestSamples2[1]/loudestSampleAllBuffers),
                                     @(loudestSamples2[2]/loudestSampleAllBuffers),
                                     @(loudestSamples2[3]/loudestSampleAllBuffers),
                                     @(loudestSamples2[4]/loudestSampleAllBuffers),
                                     @(loudestSamples2[5]/loudestSampleAllBuffers)
                                     ];
        
        if (averages) {
            self.averageSamples = @[
                                    @(avgOfSamples1[0]/loudestSampleAllBuffers),
                                    @(avgOfSamples1[1]/loudestSampleAllBuffers),
                                    @(avgOfSamples1[2]/loudestSampleAllBuffers),
                                    @(avgOfSamples1[3]/loudestSampleAllBuffers),
                                    @(avgOfSamples1[4]/loudestSampleAllBuffers),
                                    @(avgOfSamples1[5]/loudestSampleAllBuffers),
                                    ];
            
            if (_dualChannel)
                self.averageSamplesChannel2 = @[
                                                @(avgOfSamples2[0]/loudestSampleAllBuffers),
                                                @(avgOfSamples2[1]/loudestSampleAllBuffers),
                                                @(avgOfSamples2[2]/loudestSampleAllBuffers),
                                                @(avgOfSamples2[3]/loudestSampleAllBuffers),
                                                @(avgOfSamples2[4]/loudestSampleAllBuffers),
                                                @(avgOfSamples2[5]/loudestSampleAllBuffers),
                                                ];
        }

        
    }
    
    // EIGHT
    
    else if (_sampleSize == SSampleSize8) {
        self.samples = @[
                         @(loudestSamples1[0]/loudestSampleAllBuffers),
                         @(loudestSamples1[1]/loudestSampleAllBuffers),
                         @(loudestSamples1[2]/loudestSampleAllBuffers),
                         @(loudestSamples1[3]/loudestSampleAllBuffers),
                         @(loudestSamples1[4]/loudestSampleAllBuffers),
                         @(loudestSamples1[5]/loudestSampleAllBuffers),
                         @(loudestSamples1[6]/loudestSampleAllBuffers),
                         @(loudestSamples1[7]/loudestSampleAllBuffers)
                         ];

        if (_dualChannel)
            self.samplesChannel2 = @[
                                     @(loudestSamples2[0]/loudestSampleAllBuffers),
                                     @(loudestSamples2[1]/loudestSampleAllBuffers),
                                     @(loudestSamples2[2]/loudestSampleAllBuffers),
                                     @(loudestSamples2[3]/loudestSampleAllBuffers),
                                     @(loudestSamples2[4]/loudestSampleAllBuffers),
                                     @(loudestSamples2[5]/loudestSampleAllBuffers),
                                     @(loudestSamples2[6]/loudestSampleAllBuffers),
                                     @(loudestSamples2[7]/loudestSampleAllBuffers)
                                     ];
        
        if (averages) {
            self.averageSamples = @[
                                    @(avgOfSamples1[0]/loudestSampleAllBuffers),
                                    @(avgOfSamples1[1]/loudestSampleAllBuffers),
                                    @(avgOfSamples1[2]/loudestSampleAllBuffers),
                                    @(avgOfSamples1[3]/loudestSampleAllBuffers),
                                    @(avgOfSamples1[4]/loudestSampleAllBuffers),
                                    @(avgOfSamples1[5]/loudestSampleAllBuffers),
                                    @(avgOfSamples1[6]/loudestSampleAllBuffers),
                                    @(avgOfSamples1[7]/loudestSampleAllBuffers),
                                    ];
            
            if (_dualChannel)
                self.averageSamplesChannel2 = @[
                                                @(avgOfSamples2[0]/loudestSampleAllBuffers),
                                                @(avgOfSamples2[1]/loudestSampleAllBuffers),
                                                @(avgOfSamples2[2]/loudestSampleAllBuffers),
                                                @(avgOfSamples2[3]/loudestSampleAllBuffers),
                                                @(avgOfSamples2[4]/loudestSampleAllBuffers),
                                                @(avgOfSamples2[5]/loudestSampleAllBuffers),
                                                @(avgOfSamples2[6]/loudestSampleAllBuffers),
                                                @(avgOfSamples2[7]/loudestSampleAllBuffers),
                                                ];
        }

        
    }
    
    // TEN
    
    else if (_sampleSize == SSampleSize10) {
        self.samples = @[
                         @(loudestSamples1[0]/loudestSampleAllBuffers),
                         @(loudestSamples1[1]/loudestSampleAllBuffers),
                         @(loudestSamples1[2]/loudestSampleAllBuffers),
                         @(loudestSamples1[3]/loudestSampleAllBuffers),
                         @(loudestSamples1[4]/loudestSampleAllBuffers),
                         @(loudestSamples1[5]/loudestSampleAllBuffers),
                         @(loudestSamples1[6]/loudestSampleAllBuffers),
                         @(loudestSamples1[7]/loudestSampleAllBuffers),
                         @(loudestSamples1[8]/loudestSampleAllBuffers),
                         @(loudestSamples1[9]/loudestSampleAllBuffers)
                         ];

        if (_dualChannel)
            self.samplesChannel2 = @[
                                     @(loudestSamples2[0]/loudestSampleAllBuffers),
                                     @(loudestSamples2[1]/loudestSampleAllBuffers),
                                     @(loudestSamples2[2]/loudestSampleAllBuffers),
                                     @(loudestSamples2[3]/loudestSampleAllBuffers),
                                     @(loudestSamples2[4]/loudestSampleAllBuffers),
                                     @(loudestSamples2[5]/loudestSampleAllBuffers),
                                     @(loudestSamples2[6]/loudestSampleAllBuffers),
                                     @(loudestSamples2[7]/loudestSampleAllBuffers),
                                     @(loudestSamples2[8]/loudestSampleAllBuffers),
                                     @(loudestSamples2[9]/loudestSampleAllBuffers)
                                     ];
        
        
        if (averages) {
            self.averageSamples = @[
                                    @(avgOfSamples1[0]/loudestSampleAllBuffers),
                                    @(avgOfSamples1[1]/loudestSampleAllBuffers),
                                    @(avgOfSamples1[2]/loudestSampleAllBuffers),
                                    @(avgOfSamples1[3]/loudestSampleAllBuffers),
                                    @(avgOfSamples1[4]/loudestSampleAllBuffers),
                                    @(avgOfSamples1[5]/loudestSampleAllBuffers),
                                    @(avgOfSamples1[6]/loudestSampleAllBuffers),
                                    @(avgOfSamples1[7]/loudestSampleAllBuffers),
                                    @(avgOfSamples1[8]/loudestSampleAllBuffers),
                                    @(avgOfSamples1[9]/loudestSampleAllBuffers),
                                    ];
            
            if (_dualChannel)
                self.averageSamplesChannel2 = @[
                                                @(avgOfSamples2[0]/loudestSampleAllBuffers),
                                                @(avgOfSamples2[1]/loudestSampleAllBuffers),
                                                @(avgOfSamples2[2]/loudestSampleAllBuffers),
                                                @(avgOfSamples2[3]/loudestSampleAllBuffers),
                                                @(avgOfSamples2[4]/loudestSampleAllBuffers),
                                                @(avgOfSamples2[5]/loudestSampleAllBuffers),
                                                @(avgOfSamples2[6]/loudestSampleAllBuffers),
                                                @(avgOfSamples2[7]/loudestSampleAllBuffers),
                                                @(avgOfSamples2[8]/loudestSampleAllBuffers),
                                                @(avgOfSamples2[9]/loudestSampleAllBuffers)
                                                ];

        }
        
    }
    
    // FOURTEEN
    
    else if (_sampleSize == SSampleSize14) {
        self.samples = @[@(loudestSamples1[0]/loudestSampleAllBuffers),
                         @(loudestSamples1[1]/loudestSampleAllBuffers),
                         @(loudestSamples1[2]/loudestSampleAllBuffers),
                         @(loudestSamples1[3]/loudestSampleAllBuffers),
                         @(loudestSamples1[4]/loudestSampleAllBuffers),
                         @(loudestSamples1[5]/loudestSampleAllBuffers),
                         @(loudestSamples1[6]/loudestSampleAllBuffers),
                         @(loudestSamples1[7]/loudestSampleAllBuffers),
                         @(loudestSamples1[8]/loudestSampleAllBuffers),
                         @(loudestSamples1[9]/loudestSampleAllBuffers),
                         @(loudestSamples1[10]/loudestSampleAllBuffers),
                         @(loudestSamples1[11]/loudestSampleAllBuffers),
                         @(loudestSamples1[12]/loudestSampleAllBuffers),
                         @(loudestSamples1[13]/loudestSampleAllBuffers)
                         ];

        if (_dualChannel)
            self.samplesChannel2 = @[@(loudestSamples2[0]/loudestSampleAllBuffers),
                                     @(loudestSamples2[1]/loudestSampleAllBuffers),
                                     @(loudestSamples2[2]/loudestSampleAllBuffers),
                                     @(loudestSamples2[3]/loudestSampleAllBuffers),
                                     @(loudestSamples2[4]/loudestSampleAllBuffers),
                                     @(loudestSamples2[5]/loudestSampleAllBuffers),
                                     @(loudestSamples2[6]/loudestSampleAllBuffers),
                                     @(loudestSamples2[7]/loudestSampleAllBuffers),
                                     @(loudestSamples2[8]/loudestSampleAllBuffers),
                                     @(loudestSamples2[9]/loudestSampleAllBuffers),
                                     @(loudestSamples2[10]/loudestSampleAllBuffers),
                                     @(loudestSamples2[11]/loudestSampleAllBuffers),
                                     @(loudestSamples2[12]/loudestSampleAllBuffers),
                                     @(loudestSamples2[13]/loudestSampleAllBuffers)
                                     ];
        
        if (averages) {
            self.averageSamples = @[@(avgOfSamples1[0]/loudestSampleAllBuffers),
                                    @(avgOfSamples1[1]/loudestSampleAllBuffers),
                                    @(avgOfSamples1[2]/loudestSampleAllBuffers),
                                    @(avgOfSamples1[3]/loudestSampleAllBuffers),
                                    @(avgOfSamples1[4]/loudestSampleAllBuffers),
                                    @(avgOfSamples1[5]/loudestSampleAllBuffers),
                                    @(avgOfSamples1[6]/loudestSampleAllBuffers),
                                    @(avgOfSamples1[7]/loudestSampleAllBuffers),
                                    @(avgOfSamples1[8]/loudestSampleAllBuffers),
                                    @(avgOfSamples1[9]/loudestSampleAllBuffers),
                                    @(avgOfSamples1[10]/loudestSampleAllBuffers),
                                    @(avgOfSamples1[11]/loudestSampleAllBuffers),
                                    @(avgOfSamples1[12]/loudestSampleAllBuffers),
                                    @(avgOfSamples1[13]/loudestSampleAllBuffers),
                                    ];
            
            if (_dualChannel)
                self.averageSamplesChannel2 = @[@(avgOfSamples2[0]/loudestSampleAllBuffers),
                                                @(avgOfSamples2[1]/loudestSampleAllBuffers),
                                                @(avgOfSamples2[2]/loudestSampleAllBuffers),
                                                @(avgOfSamples2[3]/loudestSampleAllBuffers),
                                                @(avgOfSamples2[4]/loudestSampleAllBuffers),
                                                @(avgOfSamples2[5]/loudestSampleAllBuffers),
                                                @(avgOfSamples2[6]/loudestSampleAllBuffers),
                                                @(avgOfSamples2[7]/loudestSampleAllBuffers),
                                                @(avgOfSamples2[8]/loudestSampleAllBuffers),
                                                @(avgOfSamples2[9]/loudestSampleAllBuffers),
                                                @(avgOfSamples2[10]/loudestSampleAllBuffers),
                                                @(avgOfSamples2[11]/loudestSampleAllBuffers),
                                                @(avgOfSamples2[12]/loudestSampleAllBuffers),
                                                @(avgOfSamples2[13]/loudestSampleAllBuffers),
                                                ];
        }

        
    }
    
    // EIGHTEEN
    
    else if (_sampleSize == SSampleSize18) {
        self.samples = @[@(loudestSamples1[0]/loudestSampleAllBuffers),
                         @(loudestSamples1[1]/loudestSampleAllBuffers),
                         @(loudestSamples1[2]/loudestSampleAllBuffers),
                         @(loudestSamples1[3]/loudestSampleAllBuffers),
                         @(loudestSamples1[4]/loudestSampleAllBuffers),
                         @(loudestSamples1[5]/loudestSampleAllBuffers),
                         @(loudestSamples1[6]/loudestSampleAllBuffers),
                         @(loudestSamples1[7]/loudestSampleAllBuffers),
                         @(loudestSamples1[8]/loudestSampleAllBuffers),
                         @(loudestSamples1[9]/loudestSampleAllBuffers),
                         @(loudestSamples1[10]/loudestSampleAllBuffers),
                         @(loudestSamples1[11]/loudestSampleAllBuffers),
                         @(loudestSamples1[12]/loudestSampleAllBuffers),
                         @(loudestSamples1[13]/loudestSampleAllBuffers),
                         @(loudestSamples1[14]/loudestSampleAllBuffers),
                         @(loudestSamples1[15]/loudestSampleAllBuffers),
                         @(loudestSamples1[16]/loudestSampleAllBuffers),
                         @(loudestSamples1[17]/loudestSampleAllBuffers)
                         ];

        if (_dualChannel)
            self.samplesChannel2 = @[@(loudestSamples2[0]/loudestSampleAllBuffers),
                                     @(loudestSamples2[1]/loudestSampleAllBuffers),
                                     @(loudestSamples2[2]/loudestSampleAllBuffers),
                                     @(loudestSamples2[3]/loudestSampleAllBuffers),
                                     @(loudestSamples2[4]/loudestSampleAllBuffers),
                                     @(loudestSamples2[5]/loudestSampleAllBuffers),
                                     @(loudestSamples2[6]/loudestSampleAllBuffers),
                                     @(loudestSamples2[7]/loudestSampleAllBuffers),
                                     @(loudestSamples2[8]/loudestSampleAllBuffers),
                                     @(loudestSamples2[9]/loudestSampleAllBuffers),
                                     @(loudestSamples2[10]/loudestSampleAllBuffers),
                                     @(loudestSamples2[11]/loudestSampleAllBuffers),
                                     @(loudestSamples2[12]/loudestSampleAllBuffers),
                                     @(loudestSamples2[13]/loudestSampleAllBuffers),
                                     @(loudestSamples2[14]/loudestSampleAllBuffers),
                                     @(loudestSamples2[15]/loudestSampleAllBuffers),
                                     @(loudestSamples2[16]/loudestSampleAllBuffers),
                                     @(loudestSamples2[17]/loudestSampleAllBuffers)
                                     ];
        
        
        if (averages) {
            self.averageSamples = @[@(avgOfSamples1[0]/loudestSampleAllBuffers),
                                    @(avgOfSamples1[1]/loudestSampleAllBuffers),
                                    @(avgOfSamples1[2]/loudestSampleAllBuffers),
                                    @(avgOfSamples1[3]/loudestSampleAllBuffers),
                                    @(avgOfSamples1[4]/loudestSampleAllBuffers),
                                    @(avgOfSamples1[5]/loudestSampleAllBuffers),
                                    @(avgOfSamples1[6]/loudestSampleAllBuffers),
                                    @(avgOfSamples1[7]/loudestSampleAllBuffers),
                                    @(avgOfSamples1[8]/loudestSampleAllBuffers),
                                    @(avgOfSamples1[9]/loudestSampleAllBuffers),
                                    @(avgOfSamples1[10]/loudestSampleAllBuffers),
                                    @(avgOfSamples1[11]/loudestSampleAllBuffers),
                                    @(avgOfSamples1[12]/loudestSampleAllBuffers),
                                    @(avgOfSamples1[13]/loudestSampleAllBuffers),
                                    @(avgOfSamples1[14]/loudestSampleAllBuffers),
                                    @(avgOfSamples1[15]/loudestSampleAllBuffers),
                                    @(avgOfSamples1[16]/loudestSampleAllBuffers),
                                    @(avgOfSamples1[17]/loudestSampleAllBuffers),
                                    ];
            
            if (_dualChannel)
                self.averageSamplesChannel2 = @[@(avgOfSamples2[0]/loudestSampleAllBuffers),
                                                @(avgOfSamples2[1]/loudestSampleAllBuffers),
                                                @(avgOfSamples2[2]/loudestSampleAllBuffers),
                                                @(avgOfSamples2[3]/loudestSampleAllBuffers),
                                                @(avgOfSamples2[4]/loudestSampleAllBuffers),
                                                @(avgOfSamples2[5]/loudestSampleAllBuffers),
                                                @(avgOfSamples2[6]/loudestSampleAllBuffers),
                                                @(avgOfSamples2[7]/loudestSampleAllBuffers),
                                                @(avgOfSamples2[8]/loudestSampleAllBuffers),
                                                @(avgOfSamples2[9]/loudestSampleAllBuffers),
                                                @(avgOfSamples2[10]/loudestSampleAllBuffers),
                                                @(avgOfSamples2[11]/loudestSampleAllBuffers),
                                                @(avgOfSamples2[12]/loudestSampleAllBuffers),
                                                @(avgOfSamples2[13]/loudestSampleAllBuffers),
                                                @(avgOfSamples2[14]/loudestSampleAllBuffers),
                                                @(avgOfSamples2[15]/loudestSampleAllBuffers),
                                                @(avgOfSamples2[16]/loudestSampleAllBuffers),
                                                @(avgOfSamples2[17]/loudestSampleAllBuffers),
                                                ];
            
        }

    }
    
}



//- (void)bufferReceived:(AVAudioPCMBuffer *)buffer atReadPosition:(AVAudioFramePosition)readPosition loudestSample:(float)loudestSampleAllBuffers {


// RECORDING buffer received

- (void)bufferReceived:(AVAudioPCMBuffer *)buffer atReadPosition:(AVAudioFramePosition)readPosition {
    
    //NSLog(@"%s %lld framLen %d ",__func__,readPosition, buffer.frameLength);
    if (buffer.frameLength == 0) {
        NSLog(@"%s empty buffer ",__func__);
        return;
    }

    BOOL averages=_computeAverages;
    NSUInteger sampleSize = 4;
//    NSUInteger sampleSize = 18;
    if (_sampleSize == SSampleSize4)
        sampleSize = 4;
    else if (_sampleSize == SSampleSize8)
        sampleSize = 8;
    else if (_sampleSize == SSampleSize10)
        sampleSize = 10;
    else if (_sampleSize == SSampleSize14)
        sampleSize = 14;
    else if (_sampleSize == SSampleSize18)
        sampleSize = 18;

    // local defnitions of stats
    float loudestSample = 0.000f;
    AVAudioFrameCount frameIndexes1[sampleSize];
    AVAudioFrameCount frameIndexes2[sampleSize];
    
    float loudestSamples1[sampleSize];
    float loudestSamples2[sampleSize];
    int nSamplesInSectionSet1[sampleSize];
    int nSamplesInSectionSet2[sampleSize];
    float sumOfSamples1[sampleSize];
    float sumOfSamples2[sampleSize];
    float avgOfSamples1[sampleSize];
    float avgOfSamples2[sampleSize];
    
    for (int frameSampleIndex = 0; frameSampleIndex < sampleSize; frameSampleIndex++) {
        frameIndexes1[frameSampleIndex] = (frameSampleIndex + 1) / (float)sampleSize  * buffer.frameLength; // dividing sections values
        frameIndexes2[frameSampleIndex] = frameIndexes1[frameSampleIndex];
        loudestSamples1[frameSampleIndex] = 0.0f;
        loudestSamples2[frameSampleIndex] = 0.0f;
        nSamplesInSectionSet1[frameSampleIndex] = 0;
        nSamplesInSectionSet2[frameSampleIndex] = 0;
        sumOfSamples1[frameSampleIndex] = 0.0f;
        sumOfSamples2[frameSampleIndex] = 0.0f;
        avgOfSamples1[frameSampleIndex] = 0.0f;
        avgOfSamples2[frameSampleIndex]= 0.0f;
    }
    
    //duration = (1 / mSampleRate) * mFramesPerPacket
    
    Float64 mSampleRate = buffer.format.streamDescription->mSampleRate;
    Float64 duration =  (1.0 / mSampleRate) * buffer.format.streamDescription->mFramesPerPacket;
    //    CGFloat nsecs  = duration * readPosition ;
    float durThisBuffer = duration * buffer.frameLength;
    self.durationThisBuffer = durThisBuffer;
   
    for (AVAudioChannelCount channelIndex = 0; channelIndex < buffer.format.channelCount; ++channelIndex)
    {
        if (_dualChannel == NO) {
            if (channelIndex > 0) {
                break;
            }
        }
        float *channelData = buffer.floatChannelData[channelIndex];
        for (AVAudioFrameCount frameIndex = 0; frameIndex < buffer.frameLength; ++frameIndex)
        {
            float sampleAbsLevel = fabs(channelData[frameIndex]);
            
//            NSLog(@"=== > sampleAbsLevel %.7f",sampleAbsLevel);

            // CHANNEL 1
            if (channelIndex == 0) {
                
                for (int i=0; i < sampleSize; i++) {
                    if (frameIndex < frameIndexes1[i]) {
                        
                        if  (i > 0) {
                            if (frameIndex > frameIndexes1[i-1]) {
                                
                                if (averages) {
                                    nSamplesInSectionSet1[i]++;
                                    sumOfSamples1[i] += sampleAbsLevel;
                                }
                                
                                if (sampleAbsLevel > loudestSamples1[i]){
                                    loudestSamples1[i] = sampleAbsLevel;
                                    if (loudestSamples1[i]  > loudestSample)
                                        loudestSample = loudestSamples1[i];
                                }

                                
                            } else {
                                break;
                            }
                        } else {
                            
                            if (averages) {
                                nSamplesInSectionSet1[i]++;
                                sumOfSamples1[i] += sampleAbsLevel;
                            }
                            
                            if (sampleAbsLevel > loudestSamples1[i]){
                                loudestSamples1[i] = sampleAbsLevel;
                                if (loudestSamples1[i]  > loudestSample)
                                    loudestSample = loudestSamples1[i];
                            }
                        }
                    }
                } // frameindex in range
            } // channel
            
            // CHANNEL 2
            
            else if (channelIndex == 1) {
                
                for (int i=0; i < sampleSize; ++i) {
                    if (frameIndex < frameIndexes2[i]) {
                        
                        if  (i > 0) {
                            if (frameIndex > frameIndexes2[i-1]) {
                                
                                if (averages) {
                                    nSamplesInSectionSet2[i]++;
                                    sumOfSamples2[i] += sampleAbsLevel;
                                }
                                
                                if (sampleAbsLevel > loudestSamples2[i]){
                                    loudestSamples2[i] = sampleAbsLevel;
                                    if (loudestSamples2[i]  > loudestSample)
                                        loudestSample = loudestSamples2[i];
                                }
                            } else {
                                i = (int)sampleSize;//break;
                            }
                        } else {
                            
                            if (averages) {
                                nSamplesInSectionSet2[i]++;
                                sumOfSamples2[i] += sampleAbsLevel;
                            }
                            
                            if (sampleAbsLevel > loudestSamples2[i]) {
                                loudestSamples2[i] = sampleAbsLevel;
                                if (loudestSamples2[i]  > loudestSample)
                                    loudestSample = loudestSamples2[i];
                            }
                            

                        }
                    } // frameindex in range
                }
                
            }  // channelindex = 1
            
        } // End FOR frame index
        
        // stats for fram at index
        
        // RECORDING
        if (channelIndex == 0) {
            
            // compute the stats
            for (int frameSampleIndex = 0; frameSampleIndex < sampleSize; frameSampleIndex++) {
                avgOfSamples1[frameSampleIndex] = sumOfSamples1[frameSampleIndex] / nSamplesInSectionSet1[frameSampleIndex];
                // clear the stats
                nSamplesInSectionSet1[frameSampleIndex] = 0;
                sumOfSamples1[frameSampleIndex] = 0.0f;
            }
            
        } else if (_dualChannel && channelIndex == 1 ) {
            
            // compute the stats
            for (int frameSampleIndex = 0; frameSampleIndex < sampleSize; frameSampleIndex++) {
                avgOfSamples2[frameSampleIndex] = sumOfSamples2[frameSampleIndex] / nSamplesInSectionSet2[frameSampleIndex];
                // clear the stats
                nSamplesInSectionSet2[frameSampleIndex] = 0;
                sumOfSamples2[frameSampleIndex] = 0.0f;
            }
            
        }  // for frame
        
    }  // for channel index count
    
    
    if (loudestSample > _loudestSampleSoFar)
        _loudestSampleSoFar = loudestSample;
    
    if (loudestSample > _loudestSample)
        _loudestSample = loudestSample;

    //               NSLog(@"ch %d loudest %.3f",channelIndex,loudestSample);
    
    
    // RECORDING SAMPLES
    
    // FOUR
    if (_sampleSize == SSampleSize4) {
        self.samples = @[@(loudestSamples1[0]/_loudestSampleSoFar),
                         @(loudestSamples1[1]/_loudestSampleSoFar),
                         @(loudestSamples1[2]/_loudestSampleSoFar),
                         @(loudestSamples1[3]/_loudestSampleSoFar)
                         ];
        if (_dualChannel)
            self.samplesChannel2 = @[
                                     @(loudestSamples2[0]/_loudestSampleSoFar),
                                     @(loudestSamples2[1]/_loudestSampleSoFar),
                                     @(loudestSamples2[2]/_loudestSampleSoFar),
                                     @(loudestSamples2[3]/_loudestSampleSoFar)
                                     ];
    }

    // SIX
    
    else if (_sampleSize == SSampleSize6) {
        self.samples = @[@(loudestSamples1[0]/_loudestSampleSoFar),
                         @(loudestSamples1[1]/_loudestSampleSoFar),
                         @(loudestSamples1[2]/_loudestSampleSoFar),
                         @(loudestSamples1[3]/_loudestSampleSoFar),
                         @(loudestSamples1[4]/_loudestSampleSoFar),
                         @(loudestSamples1[5]/_loudestSampleSoFar)
                         ];
        if (_dualChannel)
            self.samplesChannel2 = @[@(loudestSamples2[0]/_loudestSampleSoFar),
                                     @(loudestSamples2[1]/_loudestSampleSoFar),
                                     @(loudestSamples2[2]/_loudestSampleSoFar),
                                     @(loudestSamples2[3]/_loudestSampleSoFar),
                                     @(loudestSamples2[4]/_loudestSampleSoFar),
                                     @(loudestSamples2[5]/_loudestSampleSoFar)
                                     ];
        
        if (averages) {
            self.averageSamples = @[
                                    @(avgOfSamples1[0]/_loudestSampleSoFar),
                                    @(avgOfSamples1[1]/_loudestSampleSoFar),
                                    @(avgOfSamples1[2]/_loudestSampleSoFar),
                                    @(avgOfSamples1[3]/_loudestSampleSoFar),
                                    @(avgOfSamples1[4]/_loudestSampleSoFar),
                                    @(avgOfSamples1[5]/_loudestSampleSoFar),
                                    ];
            if (_dualChannel)
                self.averageSamplesChannel2 = @[
                                                @(avgOfSamples2[0]/_loudestSampleSoFar),
                                                @(avgOfSamples2[1]/_loudestSampleSoFar),
                                                @(avgOfSamples2[2]/_loudestSampleSoFar),
                                                @(avgOfSamples2[3]/_loudestSampleSoFar),
                                                @(avgOfSamples2[4]/_loudestSampleSoFar),
                                                @(avgOfSamples2[5]/_loudestSampleSoFar),
                                                ];
        } // averages

    }

    // EIGHT

    else if (_sampleSize == SSampleSize8) {
        self.samples = @[@(loudestSamples1[0]/_loudestSampleSoFar),
                         @(loudestSamples1[1]/_loudestSampleSoFar),
                         @(loudestSamples1[2]/_loudestSampleSoFar),
                         @(loudestSamples1[3]/_loudestSampleSoFar),
                         @(loudestSamples1[4]/_loudestSampleSoFar),
                         @(loudestSamples1[5]/_loudestSampleSoFar),
                         @(loudestSamples1[6]/_loudestSampleSoFar),
                         @(loudestSamples1[7]/_loudestSampleSoFar)
                         ];
        if (_dualChannel)
            self.samplesChannel2 = @[@(loudestSamples2[0]/_loudestSampleSoFar),
                                     @(loudestSamples2[1]/_loudestSampleSoFar),
                                     @(loudestSamples2[2]/_loudestSampleSoFar),
                                     @(loudestSamples2[3]/_loudestSampleSoFar),
                                     @(loudestSamples2[4]/_loudestSampleSoFar),
                                     @(loudestSamples2[5]/_loudestSampleSoFar),
                                     @(loudestSamples2[6]/_loudestSampleSoFar),
                                     @(loudestSamples2[7]/_loudestSampleSoFar)
                                     ];
        
        if (averages) {
            self.averageSamples = @[
                                    @(avgOfSamples1[0]/_loudestSampleSoFar),
                                    @(avgOfSamples1[1]/_loudestSampleSoFar),
                                    @(avgOfSamples1[2]/_loudestSampleSoFar),
                                    @(avgOfSamples1[3]/_loudestSampleSoFar),
                                    @(avgOfSamples1[4]/_loudestSampleSoFar),
                                    @(avgOfSamples1[5]/_loudestSampleSoFar),
                                    @(avgOfSamples1[6]/_loudestSampleSoFar),
                                    @(avgOfSamples1[7]/_loudestSampleSoFar),
                                    ];
            if (_dualChannel)
                self.averageSamplesChannel2 = @[
                                                @(avgOfSamples2[0]/_loudestSampleSoFar),
                                                @(avgOfSamples2[1]/_loudestSampleSoFar),
                                                @(avgOfSamples2[2]/_loudestSampleSoFar),
                                                @(avgOfSamples2[3]/_loudestSampleSoFar),
                                                @(avgOfSamples2[4]/_loudestSampleSoFar),
                                                @(avgOfSamples2[5]/_loudestSampleSoFar),
                                                @(avgOfSamples2[6]/_loudestSampleSoFar),
                                                @(avgOfSamples2[7]/_loudestSampleSoFar),
                                                ];
        } // averages
        
    }
    
    // TEN

    else if (_sampleSize == SSampleSize10) {
        self.samples = @[@(loudestSamples1[0]/_loudestSampleSoFar),
                         @(loudestSamples1[1]/_loudestSampleSoFar),
                         @(loudestSamples1[2]/_loudestSampleSoFar),
                         @(loudestSamples1[3]/_loudestSampleSoFar),
                         @(loudestSamples1[4]/_loudestSampleSoFar),
                         @(loudestSamples1[5]/_loudestSampleSoFar),
                         @(loudestSamples1[6]/_loudestSampleSoFar),
                         @(loudestSamples1[7]/_loudestSampleSoFar),
                         @(loudestSamples1[8]/_loudestSampleSoFar),
                         @(loudestSamples1[9]/_loudestSampleSoFar)
                         ];
        if (_dualChannel)
            self.samplesChannel2 = @[@(loudestSamples2[0]/_loudestSampleSoFar),
                                     @(loudestSamples2[1]/_loudestSampleSoFar),
                                     @(loudestSamples2[2]/_loudestSampleSoFar),
                                     @(loudestSamples2[3]/_loudestSampleSoFar),
                                     @(loudestSamples2[4]/_loudestSampleSoFar),
                                     @(loudestSamples2[5]/_loudestSampleSoFar),
                                     @(loudestSamples2[6]/_loudestSampleSoFar),
                                     @(loudestSamples2[7]/_loudestSampleSoFar),
                                     @(loudestSamples2[8]/_loudestSampleSoFar),
                                     @(loudestSamples2[9]/_loudestSampleSoFar)
                                     ];
        
        
        if (averages) {
            self.averageSamples = @[
                                    @(avgOfSamples1[0]/_loudestSampleSoFar),
                                    @(avgOfSamples1[1]/_loudestSampleSoFar),
                                    @(avgOfSamples1[2]/_loudestSampleSoFar),
                                    @(avgOfSamples1[3]/_loudestSampleSoFar),
                                    @(avgOfSamples1[4]/_loudestSampleSoFar),
                                    @(avgOfSamples1[5]/_loudestSampleSoFar),
                                    @(avgOfSamples1[6]/_loudestSampleSoFar),
                                    @(avgOfSamples1[7]/_loudestSampleSoFar),
                                    @(avgOfSamples1[8]/_loudestSampleSoFar),
                                    @(avgOfSamples1[9]/_loudestSampleSoFar),
                                    ];
            
            if (_dualChannel)
                self.averageSamplesChannel2 = @[
                                                @(avgOfSamples2[0]/_loudestSampleSoFar),
                                                @(avgOfSamples2[1]/_loudestSampleSoFar),
                                                @(avgOfSamples2[2]/_loudestSampleSoFar),
                                                @(avgOfSamples2[3]/_loudestSampleSoFar),
                                                @(avgOfSamples2[4]/_loudestSampleSoFar),
                                                @(avgOfSamples2[5]/_loudestSampleSoFar),
                                                @(avgOfSamples2[6]/_loudestSampleSoFar),
                                                @(avgOfSamples2[7]/_loudestSampleSoFar),
                                                @(avgOfSamples2[8]/_loudestSampleSoFar),
                                                @(avgOfSamples2[9]/_loudestSampleSoFar)
                                                ];
        }

    }
    
    else if (_sampleSize == SSampleSize14) {
        self.samples = @[@(loudestSamples1[0]/_loudestSampleSoFar),
                         @(loudestSamples1[1]/_loudestSampleSoFar),
                         @(loudestSamples1[2]/_loudestSampleSoFar),
                         @(loudestSamples1[3]/_loudestSampleSoFar),
                         @(loudestSamples1[4]/_loudestSampleSoFar),
                         @(loudestSamples1[5]/_loudestSampleSoFar),
                         @(loudestSamples1[6]/_loudestSampleSoFar),
                         @(loudestSamples1[7]/_loudestSampleSoFar),
                         @(loudestSamples1[8]/_loudestSampleSoFar),
                         @(loudestSamples1[9]/_loudestSampleSoFar),
                         @(loudestSamples1[10]/_loudestSampleSoFar),
                         @(loudestSamples1[11]/_loudestSampleSoFar),
                         @(loudestSamples1[12]/_loudestSampleSoFar),
                         @(loudestSamples1[13]/_loudestSampleSoFar)
                         ];
        if (_dualChannel)
            self.samplesChannel2 = @[@(loudestSamples2[0]/_loudestSampleSoFar),
                                     @(loudestSamples2[1]/_loudestSampleSoFar),
                                     @(loudestSamples2[2]/_loudestSampleSoFar),
                                     @(loudestSamples2[3]/_loudestSampleSoFar),
                                     @(loudestSamples2[4]/_loudestSampleSoFar),
                                     @(loudestSamples2[5]/_loudestSampleSoFar),
                                     @(loudestSamples2[6]/_loudestSampleSoFar),
                                     @(loudestSamples2[7]/_loudestSampleSoFar),
                                     @(loudestSamples2[8]/_loudestSampleSoFar),
                                     @(loudestSamples2[9]/_loudestSampleSoFar),
                                     @(loudestSamples2[10]/_loudestSampleSoFar),
                                     @(loudestSamples2[11]/_loudestSampleSoFar),
                                     @(loudestSamples2[12]/_loudestSampleSoFar),
                                     @(loudestSamples2[13]/_loudestSampleSoFar)
                                     ];
        
        
        if (averages) {
            self.averageSamples = @[
                                    @(avgOfSamples1[0]/_loudestSampleSoFar),
                                    @(avgOfSamples1[1]/_loudestSampleSoFar),
                                    @(avgOfSamples1[2]/_loudestSampleSoFar),
                                    @(avgOfSamples1[3]/_loudestSampleSoFar),
                                    @(avgOfSamples1[4]/_loudestSampleSoFar),
                                    @(avgOfSamples1[5]/_loudestSampleSoFar),
                                    @(avgOfSamples1[6]/_loudestSampleSoFar),
                                    @(avgOfSamples1[7]/_loudestSampleSoFar),
                                    @(avgOfSamples1[8]/_loudestSampleSoFar),
                                    @(avgOfSamples1[9]/_loudestSampleSoFar),
                                    @(avgOfSamples1[10]/_loudestSampleSoFar),
                                    @(avgOfSamples1[11]/_loudestSampleSoFar),
                                    @(avgOfSamples1[12]/_loudestSampleSoFar),
                                    @(avgOfSamples1[13]/_loudestSampleSoFar),
                                    ];
            
            if (_dualChannel)
                self.averageSamplesChannel2 = @[
                                                @(avgOfSamples2[0]/_loudestSampleSoFar),
                                                @(avgOfSamples2[1]/_loudestSampleSoFar),
                                                @(avgOfSamples2[2]/_loudestSampleSoFar),
                                                @(avgOfSamples2[3]/_loudestSampleSoFar),
                                                @(avgOfSamples2[4]/_loudestSampleSoFar),
                                                @(avgOfSamples2[5]/_loudestSampleSoFar),
                                                @(avgOfSamples2[6]/_loudestSampleSoFar),
                                                @(avgOfSamples2[7]/_loudestSampleSoFar),
                                                @(avgOfSamples2[8]/_loudestSampleSoFar),
                                                @(avgOfSamples2[9]/_loudestSampleSoFar),
                                                @(avgOfSamples2[10]/_loudestSampleSoFar),
                                                @(avgOfSamples2[11]/_loudestSampleSoFar),
                                                @(avgOfSamples2[12]/_loudestSampleSoFar),
                                                @(avgOfSamples2[13]/_loudestSampleSoFar),
                                                ];
            
        }

    }
    
}


@end



// ------------------------------------
// CODE SNIPPETS
// ------------------------------------
//                    NSLog(@"%s %@ %@",__func__,NSStringFromCGPoint(startp),NSStringFromCGPoint(endp));
//                    NSLog(@"avg %.4f peak %.4f",avgSampleValue,sampleValue);
//                    NSLog(@"%s %@ %@",__func__,NSStringFromCGPoint(startp),NSStringFromCGPoint(endp));
//                    NSLog(@"%s %@ %@",__func__,NSStringFromCGPoint(startp),NSStringFromCGPoint(endp));


// ------------------------------------
// CODE SNIPPETS Logging the FIRST method - channel 1
// ------------------------------------
//                NSLog(@"1 average %.5f largest  %.5f  =  a %.5f   L %.5f  nsamples %d",
//                      avgOfSamples1[frameSampleIndex],
//                      loudestSamples1[frameSampleIndex] ,
//                      avgOfSamples1[frameSampleIndex]/loudestSampleAllBuffers,
//                      loudestSamples1[frameSampleIndex ]/loudestSampleAllBuffers,
//                      nSamplesInSectionSet1[frameSampleIndex]);


//                for (int frameSampleIndex = 0; frameSampleIndex < sampleSize; frameSampleIndex++) {
//                    NSLog(@"[%d]max%.3f nsamples %d sumofnsamples %.3f  ==> avg %.4f ",
//                          channelIndex,loudestSampleAllBuffers,
//                          nSamplesInSectionSet1[frameSampleIndex],sumOfSamples1[frameSampleIndex],
//                          sumOfSamples1[frameSampleIndex]/nSamplesInSectionSet1[frameSampleIndex]
//                          );
//                }
//                for (int frameSampleIndex = 0; frameSampleIndex < sampleSize; frameSampleIndex++) {
//                    nSamplesInSectionSet1[frameSampleIndex] = 0;
//                    sumOfSamples1[frameSampleIndex] = 0.0f;
//                }
//            } else {
//        NSString *sep = (channelIndex == 0) ? @"║" : @"╜";
//            NSString *sep = (channelIndex == 0) ? @"|" : @"|";
//
//                //            NSLog(@"[%d]max%.3f %@%5d%@%5d%@%5d%@%5d%@%5d%@%5d%@%5d%@%5d%@%5d%@%5d%@%5d%@%5d%@%5d%@%5d%@%5d%@%5d%@%5d%@",
//                NSLog(@"[%d]max%.3f %@%5d%@%5d%@%5d%@%5d%@%5d%@%5d%@%5d%@%5d%@%5d%@%5d%@ %5d%@%5d%@%5d%@",
//
//                      channelIndex,loudestSampleAllBuffers,sep,
//                      (unsigned int)floorf(loudestSamples1[0]/loudestSampleAllBuffers*1000.0000f),sep,
//                      (unsigned int)floorf(loudestSamples1[1]/loudestSampleAllBuffers*1000.0000f),sep,
//                      (unsigned int)floorf(loudestSamples1[2]/loudestSampleAllBuffers*1000.0000f),sep,
//                      (unsigned int)floorf(loudestSamples1[3]/loudestSampleAllBuffers*1000.0000f),sep,
//                      (unsigned int)floorf(loudestSamples1[4]/loudestSampleAllBuffers*1000.0000f),sep,
//                      (unsigned int)floorf(loudestSamples1[5]/loudestSampleAllBuffers*1000.0000f),sep,
//                      (unsigned int)floor(loudestSamples1[6]/loudestSampleAllBuffers*1000.0000f),sep,
//                      (unsigned int)floor(loudestSamples1[7]/loudestSampleAllBuffers*1000.0000f),sep,
//                      (unsigned int)floor(loudestSamples1[8]/loudestSampleAllBuffers*1000.0000f),sep,
//                      (unsigned int)floor(loudestSamples1[9]/loudestSampleAllBuffers*1000.0000f),sep,
//                      (unsigned int)floor(loudestSamples1[10]/loudestSampleAllBuffers*1000.0000f),sep,
//                      (unsigned int)floor(loudestSamples1[11]/loudestSampleAllBuffers*1000.0000f),sep,
//                      (unsigned int)floor(loudestSamples1[12]/loudestSampleAllBuffers*1000.0000f),sep
//
//                      );
//                //            (unsigned int)floor(loudestSamples1[10]/loudestSampleAllBuffers*1000.0f),sep,
//                //            (unsigned int)floor(loudestSamples1[11]/loudestSampleAllBuffers*1000.0f),sep,
//                //            (unsigned int)floor(loudestSamples1[12]/loudestSampleAllBuffers*1000.0f),sep,
//                //            (unsigned int)floor(loudestSamples1[13]/loudestSampleAllBuffers*1000.0f),sep,
//                //            (unsigned int)floor(loudestSamples1[14]/loudestSampleAllBuffers*1000.0f),sep,
//                //            (unsigned int)floor(loudestSamples1[15]/loudestSampleAllBuffers*1000.0f),sep,
//                //            (unsigned int)floor(loudestSamples1[16]/loudestSampleAllBuffers*1000.0f),sep
////            }


// ------------------------------------
// CODE SNIPPETS Logging the FIRST method - channel 2
// ------------------------------------
//                NSLog(@"2 average %.5f largest  %.5f  =  a %.5f   L %.5f",
//                      avgOfSamples2[frameSampleIndex],
//                      loudestSamples2[frameSampleIndex] ,
//                      avgOfSamples2[frameSampleIndex]/loudestSampleAllBuffers,
//                      loudestSamples2[frameSampleIndex ]/loudestSampleAllBuffers);

//                for (int frameSampleIndex = 0; frameSampleIndex < sampleSize; frameSampleIndex++) {
//                    NSLog(@"[%d]max%.3f nsamples %d sumofnsamples %.3f  ==> avg %.4f ",
//                          channelIndex,loudestSampleAllBuffers,nSamplesInSectionSet2[frameSampleIndex],sumOfSamples2[frameSampleIndex],
//                          sumOfSamples2[frameSampleIndex]/nSamplesInSectionSet2[frameSampleIndex]
//                          );
//                }
//
//                //                for (int frameSampleIndex = 0; frameSampleIndex < sampleSize; frameSampleIndex++) {
//                //                    nSamplesInSectionSet2[frameSampleIndex] = 0;
//                //                    sumOfSamples2[frameSampleIndex] = 0.0f;
//                //                }
//            NSString *sep = (channelIndex == 0) ? @"|" : @"|";
//            NSLog(@"[%d]max%.3f %@%5d%@%5d%@%5d%@%5d%@%5d%@%5d%@%5d%@%5d%@%5d%@%5d%@ %5d%@%5d%@%5d%@",
//                  channelIndex,loudestSampleAllBuffers,sep,
//                  (unsigned int)floorf(loudestSamples2[0]/loudestSampleAllBuffers*1000.0000f),sep,
//                  (unsigned int)floorf(loudestSamples2[1]/loudestSampleAllBuffers*1000.0000f),sep,
//                  (unsigned int)floorf(loudestSamples2[2]/loudestSampleAllBuffers*1000.0000f),sep,
//                  (unsigned int)floor(loudestSamples2[3]/loudestSampleAllBuffers*1000.0000f),sep,
//                  (unsigned int)floor(loudestSamples2[4]/loudestSampleAllBuffers*1000.0000f),sep,
//                  (unsigned int)floor(loudestSamples2[5]/loudestSampleAllBuffers*1000.0000f),sep,
//                  (unsigned int)floor(loudestSamples2[6]/loudestSampleAllBuffers*1000.0000f),sep,
//                  (unsigned int)floor(loudestSamples2[7]/loudestSampleAllBuffers*1000.0000f),sep,
//                  (unsigned int)floor(loudestSamples2[8]/loudestSampleAllBuffers*1000.0000f),sep,
//                  (unsigned int)floorf(loudestSamples2[9]/loudestSampleAllBuffers*1000.0000f),sep,
//                  (unsigned int)floorf(loudestSamples2[10]/loudestSampleAllBuffers*1000.0000f),sep,
//                  (unsigned int)floorf(loudestSamples2[11]/loudestSampleAllBuffers*1000.0000f),sep,
//                  (unsigned int)floorf(loudestSamples2[12]/loudestSampleAllBuffers*1000.0000f),sep
//
//                  );

// ------------------------------------
// CODE SNIPPETS Logging the seconfd method - channel 1
// ------------------------------------
//                NSLog(@"1 average %.5f largest  %.5f  =  a %.5f   L %.5f  nsamples %d   sofar %.7f",
//                      avgOfSamples1[frameSampleIndex],
//                      loudestSamples1[frameSampleIndex] ,
//                      avgOfSamples1[frameSampleIndex]/_loudestSampleSoFar,
//                      loudestSamples1[frameSampleIndex ]/_loudestSampleSoFar,
//                      nSamplesInSectionSet1[frameSampleIndex],
//                      _loudestSampleSoFar
//                      );
//
//            NSString *sep = (channelIndex == 0) ? @"|" : @"|";
//            NSLog(@"RAWDTA [%d] dur(%.3f)thisbuffermax(%.3f) max%.7f %@%.5f%@%.5f%@%.5f%@%.5f%@",
//                  channelIndex,durThisBuffer,loudestSample,_loudestSampleSoFar,sep,
//                  loudestSamples1[0],sep,
//                  loudestSamples1[1],sep,
//                  loudestSamples1[2],sep,
//                  loudestSamples1[3],sep
//                  );
//
//            NSLog(@"XLATED [%d] dur(%.3f)thisbuffermax(%.3f) max%.7f %@%.5f%@%.5f%@%.5f%@%.5f%@\n\n",
//                  channelIndex,durThisBuffer,loudestSample,_loudestSampleSoFar,sep,
//                  loudestSamples1[0]/_loudestSampleSoFar,sep,
//                  loudestSamples1[1]/_loudestSampleSoFar,sep,
//                  loudestSamples1[2]/_loudestSampleSoFar,sep,
//                  loudestSamples2[3]/_loudestSampleSoFar,sep
//                  );
//            //            NSLog(@" %.3f durthisbuffer ch %d loudest %.3f sofar %.3f",durThisBuffer,channelIndex,loudestSample,_loudestSampleSoFar);
//            NSString *sep = (channelIndex == 0) ? @"|" : @"/";
//            NSLog(@"[%d] dur(%.3f)thisbuffermax(%.3f) max%.3f %@%5d%@%5d%@%5d%@%5d%@",
//                  channelIndex,durThisBuffer,loudestSample,_loudestSampleSoFar,sep,
//                  (unsigned int)floor(loudestSamples1[0]/_loudestSampleSoFar*1000.0f),sep,
//                  (unsigned int)floor(loudestSamples1[1]/_loudestSampleSoFar*1000.0f),sep,
//                  (unsigned int)floor(loudestSamples1[2]/_loudestSampleSoFar*1000.0f),sep,
//                  (unsigned int)floor(loudestSamples1[3]/_loudestSampleSoFar*1000.0f),sep
//                  );

// ------------------------------------
// CODE SNIPPETS Logging the seconfd method channel2
// ------------------------------------
//                NSLog(@"2 average %.5f largest  %.5f  =  a %.5f   L %.5f",
//                      avgOfSamples2[frameSampleIndex],
//                      loudestSamples2[frameSampleIndex] ,
//                      avgOfSamples2[frameSampleIndex]/_loudestSampleSoFar,
//                      loudestSamples2[frameSampleIndex ]/_loudestSampleSoFar);
//
//            NSString *sep = (channelIndex == 0) ? @"|" : @"|";
//            NSLog(@"RAWDTA [%d] dur(%.3f)thisbuffermax(%.3f) max%.7f %@%.5f%@%.5f%@%.5f%@%.5f%@",
//                  channelIndex,durThisBuffer,loudestSample,_loudestSampleSoFar,sep,
//                  loudestSamples2[0],sep,
//                  loudestSamples2[1],sep,
//                  loudestSamples2[2],sep,
//                  loudestSamples2[3],sep
//                  );
//
//            NSLog(@"XLATED [%d] dur(%.3f)thisbuffermax(%.3f) max%.7f %@%.5f%@%.5f%@%.5f%@%.5f%@\n\n",
//                  channelIndex,durThisBuffer,loudestSample,_loudestSampleSoFar,sep,
//                  loudestSamples2[0]/_loudestSampleSoFar,sep,
//                  loudestSamples2[1]/_loudestSampleSoFar,sep,
//                  loudestSamples2[2]/_loudestSampleSoFar,sep,
//                  loudestSamples2[3]/_loudestSampleSoFar,sep
//                  );

// LOG Stats
//            for (int frameSampleIndex = 0; frameSampleIndex < sampleSize; frameSampleIndex++) {
//                NSLog(@"[%d]max%.3f nsamples %d sumofnsamples %.3f  ==> avg %.4f ",
//                      channelIndex, _loudestSampleSoFar,
//                      nSamplesInSectionSet2[frameSampleIndex],sumOfSamples2[frameSampleIndex],
//                      sumOfSamples2[frameSampleIndex]/nSamplesInSectionSet2[frameSampleIndex]
//                      );
//            }

// LOG CHANNEL VALUES
//            NSString *sep = (channelIndex == 0) ? @"|" : @"/";
//            NSLog(@"[%d] dur(%.3f)thisbuffermax(%.3f) max%.3f %@%5d%@%5d%@%5d%@%5d%@",
//                  channelIndex,durThisBuffer,loudestSample,_loudestSampleSoFar,sep,
//                  (unsigned int)floor(loudestSamples2[0]/_loudestSampleSoFar*1000.0f),sep,
//                  (unsigned int)floor(loudestSamples2[1]/_loudestSampleSoFar*1000.0f),sep,
//                  (unsigned int)floor(loudestSamples2[2]/_loudestSampleSoFar*1000.0f),sep,
//                  (unsigned int)floor(loudestSamples2[3]/_loudestSampleSoFar*1000.0f),sep
//                  );




// ------------------------------------
// FOR REFERENCE AND REMOVAL
// ------------------------------------


