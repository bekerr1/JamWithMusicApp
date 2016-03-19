//
//  ClipAudioEngine.h
//  JamWIthT
//
//  co-created by joe and brendan kerr on 9/26/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JWAudioEngine.h"
#import "JWPlayerNode.h"
#import "JWScrubberController.h"

@protocol ClipAudioEngineDelgegate;

@interface JWClipAudioEngine : JWAudioEngine

@property (nonatomic,assign) id <ClipAudioEngineDelgegate> clipEngineDelegate;

@property (nonatomic) JWPlayerNode* playerNode1;
@property (nonatomic) JWPlayerNode* playerNode2;

@property (nonatomic) AVAudioPCMBuffer* fiveSecondBuffer;
@property (nonatomic) AVAudioPCMBuffer* audioBufferFromFile; // needed by subclass
@property (nonatomic) AVAudioPCMBuffer* micOutputBuffer;

@property (nonatomic) NSURL* playerNode1FileURL;
@property (nonatomic) NSURL* playerNode2FileURL;
@property (nonatomic) NSURL* playerNode3FileURL;

-(void)registerController:(id <JWScrubberBufferControllerDelegate> )myScrubberContoller
              withTrackId:(NSString*)trackId
        forPlayerRecorder:(NSString*)player;

-(void)initializeAudio;
-(void)setTrimmedAudioPathWith:(NSString *)trimmedFilePath And5SecondPathWith:(NSString* )fiveSeconds;
-(void)setTrimmedAudioURL:(NSURL *)trimmedFileURL andFiveSecondURL:(NSURL* )fiveSecondURL;
-(void)prepareToRecord;
-(void)prepareForPreview;
//-(void)playAll;
-(void)playAlll;
-(void)playMix;
-(void)playAllAndRecordIt;
-(BOOL)micOutputFileExists;
-(void)stopPlayingTrack1;
-(void)pausePlayingTrack1;
-(BOOL)prepareToPlayTrack1;
-(void)stopAll;

-(void)pauseAlll;
-(void)resumeAlll;


@property (nonatomic,readwrite) float mixerVolume;
@property (nonatomic,readwrite) float volumePlayBackTrack;
@property (nonatomic,readwrite) float panValuePlayer1;
@property (nonatomic,readwrite) float panValuePlayer2;
@property (nonatomic,readwrite) float volumeValuePlayer1;
@property (nonatomic,readwrite) float volumeValuePlayer2;

// Scrubber stuff
@property (nonatomic) AVAudioFramePosition micPlayerFramePostion;
@property (nonatomic,assign) CGFloat progressSeekingAudioFile;

-(void)prepareToPlaySeekingAudio;
-(void)prepareMasterMixSampling;
-(void)prepareToPlayPrimaryTrack;
-(void)prepareToPlayMicRecording;
-(void)changeProgressOfSeekingAudioFile:(CGFloat)progress;

// Recorded file
-(CGFloat)progressOfSeekingAudioFile;
-(CGFloat)durationInSecondsOfSeekingAudioFile;
-(CGFloat)remainingDurationInSecondsOfSeekingAudioFile;
-(CGFloat)currentPositionInSecondsOfSeekingAudioFile;
-(NSString*)processingFormatStr;

// MIX file
-(CGFloat)progressOfMixAudioFile;
-(CGFloat)durationInSecondsOfMixFile;
-(CGFloat)currentPositionInSecondsOfMixFile;
-(CGFloat)remainingDurationInSecondsOfMixFile;
-(NSString*)mixFileProcessingFormatStr;

// end scrubber stuff

- (void)pausePlayingAll;

-(void)setupAVEngine;


@end


// Protocol builds on JWAudioEngineDelegate with additional clip specific methods
@protocol ClipAudioEngineDelgegate  <JWAudioEngineDelegate>
@optional
-(void) fiveSecondBufferCompletion;
-(void) userAudioObtained;
-(void) playMixCompleted;
-(void) mixRecordingCompleted;
-(void) playingCompleted;
-(void) meterSamples:(NSArray *)samples andDuration:(NSTimeInterval)duration;

// TODO: not used
-(void) mixInCountDownFired;
@end
