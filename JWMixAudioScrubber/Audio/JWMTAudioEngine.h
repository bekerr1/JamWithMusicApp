//
//  ClipAudioEngine.h
//  JamWIthT
//
//  co-created by joe and brendan kerr on 9/26/15.
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
@property (nonatomic) NSArray *activeRecorderNodes;

@property (nonatomic,weak) id <JWMTAudioEngineDelgegate> engineDelegate;

-(instancetype)initWithPrimaryFileURL:(NSURL*)primaryFileURL fadeInURL:(NSURL*)fadeInFileURL
                             delegate:(id <JWMTAudioEngineDelgegate>) engineDelegate;

@property (nonatomic) NSArray *playerNodes;
@property (nonatomic,readonly) NSURL* mixOutputFileURL;
@property (nonatomic,readwrite) float mixerVolume;
@property (nonatomic) BOOL scheduledFiveSecondClip;
@property (nonatomic) BOOL hasFiveSecondClip;


-(void)initializeAudio;
-(void)initializeAudioConfig;
-(BOOL)addFiveSecondNodeToListForKey:(NSString *)dbKey;
-(void)setupAVEngine;
-(void)stopPlayersForReset;

-(void) setPlayerNodeFileURL:(NSURL*)fileURL atIndex:(NSUInteger)index;
-(NSURL*) playerNodeFileURLAtIndex:(NSUInteger)index;

-(JWPlayerNode*) playerForNodeAtIndex:(NSUInteger)index;
-(JWPlayerNode*) playerForNodeNamed:(NSString*)name;

-(void)setTrimmedAudioPathWith:(NSString *)trimmedFilePath And5SecondPathWith:(NSString* )fiveSeconds;
-(void)setTrimmedAudioURL:(NSURL *)trimmedFileURL andFiveSecondURL:(NSURL* )fiveSecondURL;


// commands
-(void)playFiveSecondNode;
-(BOOL)playAllActivePlayerNodes;
-(BOOL)pauseAllActivePlayerNodes;
-(BOOL)stopAllActivePlayerNodes;
-(void)refresh; // makeconnections if needed
-(void)pausePlayingAll;
-(void)playAlll;
-(void)playMix;
-(void)playAllAndRecordIt;
-(void)pauseAlll;
-(void)resumeAlll;
-(void)revertToMixing;
-(void)reMix;
-(void)prepareToPlayMix;
-(void)prepareToRecord;
-(BOOL)prepareToRecordFirstAvailable;
-(void)scheduleAllStartSeconds:(NSTimeInterval)secondsIn;
-(void)scheduleAllStartSeconds:(NSTimeInterval)secondsIn duration:(NSTimeInterval)duration;
-(void)prepareToRecordFromBeginningAtPlayerRecorderNodeIndex:(NSUInteger)index;
-(void)recordWithPlayerRecorderAtNodeIndex:(NSUInteger)prIndex;
-(void)recordOnlyWithPlayerRecorderAtNodeIndex:(NSUInteger)prIndex;
-(void)stopRecordOnlyWithPlayerRecorderAtNodeIndex:(NSUInteger)prIndex;


// getter
-(NSUInteger)countOfNodesWithAudio;
-(NSInteger)indexOfFirstRecorderNodeWithNoAudio;
-(NSTimeInterval)recordingTimeRecorderAtNodeIndex:(NSUInteger)prIndex;
-(NSURL*)recordingFileURLPlayerRecorderAtNodeIndex:(NSUInteger)prIndex;
-(JWMixerNodeTypes)typeForNodeAtIndex:(NSUInteger)index;
-(AVAudioPCMBuffer*)audioBufferForPlayerNodeAtIndex:(NSUInteger)index;
-(CGFloat)progressOfAudioFileForPlayerAtIndex:(NSUInteger)index;
-(CGFloat)durationInSecondsOfAudioFileForPlayerAtIndex:(NSUInteger)index;
-(CGFloat)remainingDurationInSecondsOfAudioFileForPlayerAtIndex:(NSUInteger)index;
-(CGFloat)currentPositionInSecondsOfAudioFileForPlayerAtIndex:(NSUInteger)index;
-(NSString*)processingFormatStrForPlayerAtIndex:(NSUInteger)index;

// scrubber support
-(void)registerController:(id <JWScrubberBufferControllerDelegate> )myScrubberContoller
              withTrackId:(NSString*)trackId
 forPlayerRecorderAtIndex:(NSUInteger)index;

-(void)registerController:(id <JWScrubberBufferControllerDelegate> )myScrubberContoller
              withTrackId:(NSString*)trackId
        forPlayerRecorder:(NSString*)player;

// others maybe not necessarily used
-(void)changeProgressOfSeekingAudioFile:(CGFloat)progress;
-(void)stopPlayingTrack1;
-(void)pausePlayingTrack1;
@property (nonatomic) AVAudioFramePosition micPlayerFramePostion;
@property (nonatomic,assign) CGFloat progressSeekingAudioFile;
@property (nonatomic) CGFloat currentPositionInAudio;
@property (nonatomic) JWPlayerNode* playerNode1;
@property (nonatomic) JWPlayerNode* playerNode2;

@end



// Protocol builds on JWAudioEngineDelegate with additional clip specific methods
@protocol JWMTAudioEngineDelgegate  <JWAudioEngineDelegate>
@optional
-(void) completedPlayingAtPlayerIndex:(NSUInteger)index;
-(void) fiveSecondBufferCompletion;
-(void) userAudioObtained;
-(void) userAudioObtainedAtIndex:(NSUInteger)index recordingId:(NSString*)rid;
-(void) mixRecordingCompleted;
// TODO: not used
-(void) mixInCountDownFired;
-(void) playingCompleted;
-(void) playMixCompleted;
@end






