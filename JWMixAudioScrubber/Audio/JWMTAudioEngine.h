//
//  ClipAudioEngine.h
//  JamWIthT
//
//  Created by JOSEPH KERR on 9/26/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

/*
 JWMTAudioEngine is a JWAudioEngine
 
 Multi-Track audio engine uses a playerNodeList to determine how many players and what each
 player should play
 
 InitAVAudioSession and AVAudioEngine are used from Super
 
 */
#import <Foundation/Foundation.h>
#import "JWAudioEngine.h"
#import "JWMixNodes.h"
#import "JWPlayerNode.h"
#import "JWScrubberController.h"

@protocol JWMTAudioEngineDelgegate;


@interface JWMTAudioEngine : JWAudioEngine

@property (strong, nonatomic) NSMutableArray *playerNodeList;
@property (nonatomic) NSArray *activePlayerNodes;
//TODO: added this
@property (nonatomic) NSArray *activeRecorderNodes;
@property (nonatomic) NSArray *playerNodes;
@property (nonatomic,readonly) NSURL* mixOutputFileURL;

@property (nonatomic,assign) id <JWMTAudioEngineDelgegate> engineDelegate;

-(instancetype)initWithPrimaryFileURL:(NSURL*)primaryFileURL fadeInURL:(NSURL*)fadeInFileURL delegate:(id <JWMTAudioEngineDelgegate>) engineDelegate;

-(void)initializeAudio;
-(void)setupAVEngine;

@property (nonatomic,readwrite) float mixerVolume;

-(void) setPlayerNodeFileURL:(NSURL*)fileURL atIndex:(NSUInteger)index;
-(NSURL*) playerNodeFileURLAtIndex:(NSUInteger)index;

-(JWPlayerNode*) playerForNodeAtIndex:(NSUInteger)index;
-(JWPlayerNode*) playerForNodeNamed:(NSString*)name;

-(void)setTrimmedAudioPathWith:(NSString *)trimmedFilePath And5SecondPathWith:(NSString* )fiveSeconds;
-(void)setTrimmedAudioURL:(NSURL *)trimmedFileURL andFiveSecondURL:(NSURL* )fiveSecondURL;

// commands
-(void)prepareToRecord;
-(void)prepareToRecordFromBeginningAtPlayerRecorderNodeIndex:(NSUInteger)index;
-(void)recordWithPlayerRecorderAtNodeIndex:(NSUInteger)prIndex;
-(void)prepareToPlayMix;
-(void)refresh; // makeconnections if needed
-(void)pausePlayingAll;
-(void)playAlll;
//TODO: added this
-(BOOL)playAllActivePlayerNodes;
-(BOOL)pauseAllActivePlayerNodes;
-(BOOL)stopAllActivePlayerNodes;

-(void)playMix;
-(void)playAllAndRecordIt;
//-(void)stopAll;
-(void)pauseAlll;
-(void)resumeAlll;
-(void)revertToMixing;
-(void)reMix;
//TODO: changed this
-(void)scheduleAllStartSeconds:(NSTimeInterval)secondsIn;
//-(void)playAlllStartSeconds:(NSTimeInterval)secondsIn;


// scrubber support
-(void)registerController:(id <JWScrubberBufferControllerDelegate> )myScrubberContoller
              withTrackId:(NSString*)trackId
 forPlayerRecorderAtIndex:(NSUInteger)index;

-(void)registerController:(id <JWScrubberBufferControllerDelegate> )myScrubberContoller
              withTrackId:(NSString*)trackId
        forPlayerRecorder:(NSString*)player;


-(JWMixerNodeTypes)typeForNodeAtIndex:(NSUInteger)index;
-(AVAudioPCMBuffer*)audioBufferForPlayerNodeAtIndex:(NSUInteger)index;

-(CGFloat)progressOfSeekingAudioFile;
-(CGFloat)durationInSecondsOfSeekingAudioFile;
-(CGFloat)remainingDurationInSecondsOfSeekingAudioFile;
-(CGFloat)currentPositionInSecondsOfSeekingAudioFile;
-(NSString*)processingFormatStr;

-(CGFloat)progressOfAudioFileForPlayerAtIndex:(NSUInteger)index;
-(CGFloat)durationInSecondsOfAudioFileForPlayerAtIndex:(NSUInteger)index;
-(CGFloat)remainingDurationInSecondsOfAudioFileForPlayerAtIndex:(NSUInteger)index;
-(CGFloat)currentPositionInSecondsOfAudioFileForPlayerAtIndex:(NSUInteger)index;
-(NSString*)processingFormatStrForPlayerAtIndex:(NSUInteger)index;

-(void)changeProgressOfSeekingAudioFile:(CGFloat)progress;
-(void)stopPlayingTrack1;
-(void)pausePlayingTrack1;

// Scrubber stuff
@property (nonatomic) AVAudioFramePosition micPlayerFramePostion;
@property (nonatomic,assign) CGFloat progressSeekingAudioFile;
// end scrubber stuff
// older model
@property (nonatomic) JWPlayerNode* playerNode1;
@property (nonatomic) JWPlayerNode* playerNode2;
@end



// Protocol builds on JWAudioEngineDelegate with additional clip specific methods
@protocol JWMTAudioEngineDelgegate  <JWAudioEngineDelegate>
@optional
-(void) completedPlayingAtPlayerIndex:(NSUInteger)index;
-(void) fiveSecondBufferCompletion;
-(void) userAudioObtained;
-(void) mixRecordingCompleted;
// TODO: not used
-(void) mixInCountDownFired;
-(void) playingCompleted;
-(void) playMixCompleted;
@end



