/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    AudioEngine is the main controller class that creates the following objects:
                    AVAudioEngine       *_engine;
                 It connects all the nodes, loads the buffers as well as controls the AVAudioEngine object itself.
*/

@import Foundation;
@import AVFoundation;

#import "JWAudioEngine.h"
#import "JWScrubberController.h"

@protocol JWMicAudioEngineDelegate;


@interface JWMicAudioEngine : JWAudioEngine

@property (nonatomic,assign) id <JWMicAudioEngineDelegate> audioEngineDelegate;

@property (nonatomic, readonly) NSURL *outputFileUrl;

// Give the audio engine an object that implements protocol
// audioEngine register: (id <JWScrubberBufferControllerDelegate> )myScrubberContoller  forPlayerRecorder:myPlayerRecorder
//-(void)registerController:(id <JWScrubberBufferControllerDelegate> )myScrubberContoller forPlayerRecorder:(NSString*)playerRecorder;
-(void)registerController:(id <JWScrubberBufferControllerDelegate> )myScrubberContoller withTrackId:(NSString*)trackId
        forPlayerRecorder:(NSString*)player;

@property (nonatomic, readonly) BOOL micPlayerIsPlaying;
@property (nonatomic, readonly) BOOL micIsRecording;
@property (nonatomic) float outputVolume;           // 0.0 - 1.0
@property (nonatomic) NSString *currentCacheItem;
@property (nonatomic) AVAudioFramePosition micPlayerFramePostion;

@property (nonatomic, readonly) BOOL isLoop;

- (void)startMicRecording;
- (void)stopMicRecording;
- (void)playMicRecordedFile;
- (void)pausePlayingMicRecordedFile;
- (void)stopPlayingMicRecordedFile;

-(BOOL)prepareToPlayAudio;

-(CGFloat)progressOfAudioFile;
-(CGFloat)durationInSecondsOfAudioFile;
-(CGFloat)remainingDurationInSecondsOfAudioFile;
-(CGFloat)currentPositionInSecondsOfAudioFile;
-(NSString*)processingFormatStr;

- (BOOL) micOutputExists;

-(void)connectMicToMixer;
-(void)disconnectMicToMixer;
- (void)resetRecording;
- (BOOL)toggleLoop;


// -------
// seeking
@property (nonatomic,assign) CGFloat progressSeekingAudioFile;
//-(CGFloat)progressOfSeekingAudioFile;
-(void)changeProgressOfSeekingAudioFile:(CGFloat)progress;
@end


// Protocol builds on JWAudioEngineDelegate with additional clip specific methods
@protocol JWMicAudioEngineDelegate  <JWAudioEngineDelegate>
@optional
- (void)playMicRecordingHasStopped;
- (void)meterSamples:(NSArray *)samples andDuration:(NSTimeInterval)duration;

@end





