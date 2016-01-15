//
//  JWScrubberController.h
//  JamWIthT
//
//  Created by JOSEPH KERR on 10/23/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import <Foundation/Foundation.h>
@import AVFoundation;
@import UIKit;
#import "JWScrubber.h"
#import "JWEffectsModifyingProtocol.h"


typedef void (^JWScrubberControllerCompletionHandler)(void);

// Give the audio engine an object that implements protocol
// audioEngine register: (id <JWScrubberBufferControllerDelegate> )myScrubberContoller  forPlayerRecorder:myPlayerRecorder
//
@protocol JWScrubberBufferControllerDelegate <NSObject>
@optional
- (void)bufferReceivedForTrackId:(NSString*)tid buffer:(AVAudioPCMBuffer *)buffer
                  atReadPosition:(AVAudioFramePosition)readPosition;

- (void)meterChannelSamplesWithAverages:(NSArray *)samples
                         averageSamples:(NSArray*)averageSamples
                        channel2Samples:(NSArray*)samples2 averageSamples2:(NSArray*)averageSamples2
                            andDuration:(NSTimeInterval)duration forTrackId:(NSString*)tid;

- (void)meterChannelSamples:(NSArray *)samples samplesForSecondChannel:(NSArray *)samples2 andDuration:(NSTimeInterval)duration forTrackId:(NSString*)tid;
@end


@class JWScrubberViewController;
@protocol JWScrubberControllerDelegate;


//  CLASS DEFINITION

@interface JWScrubberController : NSObject <JWScrubberBufferControllerDelegate,JWEffectsModifyingProtocol>

@property (weak,nonatomic) id <JWScrubberControllerDelegate> delegate;
@property (nonatomic) NSUInteger numberOfTracks;
@property (nonatomic) CGSize scrubberControllerSize;
@property (nonatomic) NSArray *trackLocations;
@property (nonatomic) ScrubberViewOptions viewOptions;
@property (nonatomic) BOOL useGradient;
@property (nonatomic) BOOL useTrackGradient;
@property (nonatomic) UIColor *backLightColor;  // use as hue layer
@property (nonatomic) BOOL darkBackground;
@property (nonatomic) BOOL pulseBackLight;
@property (nonatomic) NSString *selectedTrack;

- (void)deSelectTrack;
- (void)selectTrack:(NSString*)tid;
@property (nonatomic) NSString *selectedTrackId;

- (id <JWEffectsModifyingProtocol>) trackNodeControllerForTrackId:(NSString*)tid;

-(void)configureScrubberColors:(NSDictionary*)scrubberColors;

-(void)adjustBackLightValue:(float)value;  // always white black

-(instancetype)initWithScrubber:(JWScrubberViewController*)scrubberViewController;

// PLAY
// one method with Colors the other without

-(NSString*)prepareScrubberFileURL:(NSURL*)fileURL
                    withSampleSize:(SampleSize)ssz
                           options:(SamplingOptions)options
                              type:(VABKindOptions)typeOptions
                            layout:(VABLayoutOptions)layoutOptions
                      onCompletion:(JWScrubberControllerCompletionHandler)completion;

-(NSString*)prepareScrubberFileURL:(NSURL*)fileURL
                    withSampleSize:(SampleSize)ssz
                           options:(SamplingOptions)options
                              type:(VABKindOptions)typeOptions
                            layout:(VABLayoutOptions)layoutOptions
                            colors:(NSDictionary*)trackColors
                      onCompletion:(JWScrubberControllerCompletionHandler)completion;

-(NSString*)prepareScrubberFileURL:(NSURL*)fileURL
                    withSampleSize:(SampleSize)ssz
                           options:(SamplingOptions)options
                              type:(VABKindOptions)typeOptions
                            layout:(VABLayoutOptions)layoutOptions
                            colors:(NSDictionary*)trackColors
                     referenceFile:(NSDictionary*)refFile
                         startTime:(float)startTime
                      onCompletion:(JWScrubberControllerCompletionHandler)completion;


// Recorder and Taps
// use listener methods to activate the JWScrubberBufferControllerDelegate
// this is for recording where the caller registers

// one method with Colors the other without

-(NSString*)prepareScrubberListenerSource:(id <JWScrubberBufferControllerDelegate>)scrubberSource
                           withSampleSize:(SampleSize)ssz
                                  options:(SamplingOptions)options
                                     type:(VABKindOptions)typeOptions
                                   layout:(VABLayoutOptions)layoutOptions
                             onCompletion:(JWScrubberControllerCompletionHandler)completion;

-(NSString*)prepareScrubberListenerSource:(id <JWScrubberBufferControllerDelegate>)scrubberSource
                           withSampleSize:(SampleSize)ssz
                                  options:(SamplingOptions)options
                                     type:(VABKindOptions)typeOptions
                                   layout:(VABLayoutOptions)layoutOptions
                                   colors:(NSDictionary*)trackColors
                             onCompletion:(JWScrubberControllerCompletionHandler)completion;


-(void)configureColors:(NSDictionary*)trackColors;
-(void)configureColors:(NSDictionary*)trackColors forTackId:(NSString*)trackId;
-(void)configureTrackColors:(NSDictionary*)trackColors;
-(void)configureTrackColors:(NSDictionary*)trackColors forTackId:(NSString*)trackId;

//-(void)setSampleSize:(SampleSize)sampleSize forTrackWithId:(NSString*)stid;
//-(SampleSize)sampleSizeForTrackWithId:(NSString*)stid;
//-(void)setSamplingOptions:(SamplingOptions)options forTrack:(NSString*)stid;
//-(SamplingOptions)SamplingOptionsForTrack:(NSString*)stid;

// suppprts autoplay
-(void)play:(NSString*)sid;
-(void)playRecord:(NSString*)sid;

-(void)stopPlaying:(NSString*)sid;
-(void)stopPlaying:(NSString*)sid rewind:(BOOL)rewind;

-(void)playedTillEnd:(NSString*)sid;

-(void)seekToPosition:(NSString*)sid;
-(void)seekToPosition:(NSString*)sid animated:(BOOL)animated;
-(void)rewind:(NSString*)sid;
-(void)rewind:(NSString*)sid animated:(BOOL)animated;
-(void)reset;
-(void)refresh;

-(void)editTrackBeginInset:(NSString*)trackId;
-(void)editTrackStartPosition:(NSString*)trackId;
-(void)editTrackEndInset:(NSString*)trackId;
-(void)saveEditingTrack:(NSString*)trackId;
-(void)stopEditingTrackCancel:(NSString*)trackId;
-(void)stopEditingTrackSave:(NSString*)trackId;

-(void)modifyTrack:(NSString*)trackId alpha:(CGFloat)alpha;
-(void)modifyTrack:(NSString*)trackId colors:(NSDictionary*)trackColors;
-(void)modifyTrack:(NSString*)trackId colors:(NSDictionary*)trackColors alpha:(CGFloat)alpha;
-(void)modifyTrack:(NSString*)trackId pan:(CGFloat)panValue;
-(void)modifyTrack:(NSString*)trackId volume:(CGFloat)volumeValue;
-(void)modifyTrack:(NSString*)trackId allTracksHeight:(CGFloat)allTracksHeight;
-(void)modifyTrack:(NSString*)trackId withAlpha:(CGFloat)alpha allTracksHeight:(CGFloat)allTracksHeight;
-(void)modifyTrack:(NSString*)trackId withColors:(NSDictionary*)trackColors allTracksHeight:(CGFloat)allTracksHeight;
-(void)modifyTrack:(NSString*)trackId withColors:(NSDictionary*)trackColors alpha:(CGFloat)alpha allTracksHeight:(CGFloat)allTracksHeight;
-(void)modifyTrack:(NSString*)trackId
            layout:(VABLayoutOptions)layoutOptions
              kind:(VABKindOptions)kindOptions
   allTracksHeight:(CGFloat)allTracksHeight;

-(void)modifyTrack:(NSString*)trackId
            colors:(NSDictionary*)trackColors
             alpha:(CGFloat)alpha
            layout:(VABLayoutOptions)layoutOptions
              kind:(VABKindOptions)kindOptions
   allTracksHeight:(CGFloat)allTracksHeight;

@end


// may not be needed may be local except for reording

@protocol JWScrubberBuffer2ControllerDelegate <NSObject>
- (void)bufferReceived:(AVAudioPCMBuffer *)buffer atReadPosition:(AVAudioFramePosition)readPosition loudestSample:(CGFloat)loudestSample;
- (void)bufferReceived:(AVAudioPCMBuffer *)buffer inTrack:(NSUInteger)track atReadPosition:(AVAudioFramePosition)readPosition loudestSample:(CGFloat)loudestSampleAllBuffers;
- (void)buffersReceivedCompleted;
- (void)buffersReceivedStarted;
- (void)buffersReceivedCompletedForTrack:(NSUInteger)track;
- (void)buffersReceivedStartedForTrack:(NSUInteger)track;
@end

@protocol JWScrubberInfoDelegate <NSObject>
@optional
// to allow the controller to support the play timer
-(CGFloat)progressOfAudioFile;
-(CGFloat)durationInSecondsOfAudioFile;
-(CGFloat)remainingDurationInSecondsOfAudioFile;
-(CGFloat)currentPositionInSecondsOfAudioFile;
-(NSString*)processingFormatStr;
@end


@protocol JWScrubberControllerDelegate <NSObject>
@optional
-(void)scrubberAvailable:(JWScrubberController*)controller;
-(void)scrubberAvailable:(JWScrubberController*)controller forTrack:(NSUInteger)track;
-(void)scrubber:(JWScrubberController*)controller selectedTrack:(NSString*)sid;
-(void)scrubberTrackNotSelected:(JWScrubberController*)controller;
-(void)scrubberDidLongPress:(JWScrubberController*)controller forScrubberId:(NSString*)sid;
-(void)scrubberPlayHeadTapped:(JWScrubberController*)controller;

// to allow the controller to support the play timer
-(CGFloat)progressOfAudioFile:(JWScrubberController*)controller forScrubberId:(NSString*)sid;
-(CGFloat)durationInSecondsOfAudioFile:(JWScrubberController*)controller forScrubberId:(NSString*)sid;
-(CGFloat)remainingDurationInSecondsOfAudioFile:(JWScrubberController*)controller forScrubberId:(NSString*)sid;
-(CGFloat)currentPositionInSecondsOfAudioFile:(JWScrubberController*)controller forScrubberId:(NSString*)sid;
-(NSString*)processingFormatStr:(JWScrubberController*)self forScrubberId:(NSString*)sid;

-(void)editingMadeChange:(JWScrubberController*)controller forScrubberId:(NSString*)sid;
-(void)editingCompleted:(JWScrubberController*)controller forScrubberId:(NSString*)sid;
-(void)editingMadeChange:(JWScrubberController*)controller forScrubberId:(NSString*)sid withTrackInfo:(id)fileReference;
-(void)editingCompleted:(JWScrubberController*)controller forScrubberId:(NSString*)sid withTrackInfo:(id)fileReference;
-(void)positionChanged:(JWScrubberController*)controller positionSeconds:(CGFloat)position;
@end



// VALID for mats for specifying block paramaters
//withCompletion:(void (^)())completion;
//- (void)something:(JWClipAudioCompletionHandler)completion;
//(void (^)(CMTime time))block
//typedef void (^AVAudioNodeCompletionHandler)(void);
//onCompletion:(void (^)(NSMutableArray* channelData,NSString *searchStr))completion;
//typedef void (^JWFileDowloadCompletionHandler)(void);



