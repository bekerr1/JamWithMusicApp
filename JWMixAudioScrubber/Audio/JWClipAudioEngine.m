//
//  ClipAudioEngine.m
//  JamWIthT
//
//  co-created by joe and brendan kerr on 9/26/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

// from JWRecordJamViewController all audio engine stuff

#import "JWClipAudioEngine.h"
@import AVFoundation;

#define JWPLAYERNODE

@interface JWClipAudioEngine () {
    NSURL* _micOutputFileURL;
    NSURL* _finalRecordingOutputURL;
    AVAudioFile* _micOutputFile;
    AVAudioFile* _finalRecordingOutputFile;
    AVAudioFile* _trimmedAudioFile;
    AVAudioFormat* _generalFormat;
    NSString* _trimmedMP3FilePath;
    NSString* _5SecondsBeforeStartMP3FilePath;
    NSString* _countDownLabelText;
    int _countDownLabelValue;
    BOOL _isRecording;
    BOOL _playerIsPaused;
    BOOL _loops;
    BOOL _useMetering;
    BOOL _suspendPlayAlll;
    dispatch_queue_t _bufferReceivedQueue;
}


#ifdef JWPLAYERNODE

#else
@property (nonatomic) AVAudioPlayerNode* playerNode1;
@property (nonatomic) AVAudioPlayerNode* playerNode2;
#endif
@property (nonatomic) NSURL* trimmedURL;
@property (nonatomic) NSURL* fiveSecondURL;
@property (strong, nonatomic) AVAudioRecorder *audioRecorder;
@property (nonatomic,strong)  NSTimer *meteringTimer;
@property (nonatomic,strong)  NSMutableArray *meterSamples;
@property (nonatomic,strong)  NSDate *lastMeterTimeStamp;
@property (nonatomic,strong)  NSMutableDictionary *scrubberTrackIds;
@property (nonatomic,strong) id <JWScrubberBufferControllerDelegate> scrubberBufferController;
@end


@implementation JWClipAudioEngine

-(void)registerController:(id <JWScrubberBufferControllerDelegate> )myScrubberContoller withTrackId:(NSString*)trackId
        forPlayerRecorder:(NSString*)player
{
    if ([player isEqualToString:@"player1"]) {
    } else if ([player isEqualToString:@"player2"]) {
    } else if ([player isEqualToString:@"mixer"]) {
        _scrubberTrackIds[player] = trackId;
    } else if ([player isEqualToString:@"tap1"]) {
    } else if ([player isEqualToString:@"tap2"]) {
    } else if ([player isEqualToString:@"recorder"]) {
        _scrubberTrackIds[player] = trackId;
    }
    // last register called uses tha controller by all
    _scrubberBufferController = myScrubberContoller;

    if (_bufferReceivedQueue == nil) {
        _bufferReceivedQueue =
        dispatch_queue_create("bufferReceivedAE",
                              dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL,QOS_CLASS_USER_INTERACTIVE, 0));
    }

}


-(NSURL*) playerNode1FileURL {
    return _trimmedURL;
}
-(NSURL*) playerNode2FileURL {
    return _micOutputFileURL;
}


- (void) setClipEngineDelegate:(id<ClipAudioEngineDelgegate>)clipEngineDelegate {
    _clipEngineDelegate = clipEngineDelegate;
    self.delegate = _clipEngineDelegate;
}

-(void)setTrimmedAudioPathWith:(NSString *)trimmedFilePath And5SecondPathWith:(NSString* )fiveSeconds {
    self.trimmedURL = [NSURL fileURLWithPath:trimmedFilePath];
    self.fiveSecondURL = [NSURL fileURLWithPath:fiveSeconds];;
}

-(void)setTrimmedAudioURL:(NSURL *)trimmedFileURL andFiveSecondURL:(NSURL* )fiveSecondURL {
    self.trimmedURL = trimmedFileURL;
    self.fiveSecondURL = fiveSecondURL;
}

-(float)mixerVolume {
    return [self.audioEngine mainMixerNode].outputVolume ;
}
-(void)setMixerVolume:(float)adjustedValume {
    [self.audioEngine mainMixerNode].outputVolume = adjustedValume ;
}


- (void)initializeAudio {
    _useMetering = YES;
    _scrubberTrackIds = [@{} mutableCopy];
    [self initAVAudioSession];
    [self setupAVEngine];
}


#pragma mark -

- (void)stopPlayersForInterruption
{
    [super stopPlayersForInterruption];
    
    [self.playerNode1 stop];
    [self.playerNode2 stop];
}

- (void)startEngine
{
    [super startEngine];
}

#pragma mark -

-(void)fileURLs {
    // .caf = CoreAudioFormat
    NSString *cacheKey = [[NSUUID UUID] UUIDString];
    NSString *thisfName = @"clipRecording";
    NSString *uniqueFname = [NSString stringWithFormat:@"%@_%@.caf",thisfName,cacheKey?cacheKey:@""];
    NSString *docsDir = [NSHomeDirectory() stringByAppendingPathComponent:  @"Documents"];
    _micOutputFileURL = [NSURL URLWithString:[docsDir stringByAppendingPathComponent:uniqueFname]];
    cacheKey = [[NSUUID UUID] UUIDString];
    thisfName = @"finalRecording";
    uniqueFname = [NSString stringWithFormat:@"%@_%@.caf",thisfName,cacheKey?cacheKey:@""];
    _finalRecordingOutputURL =[NSURL URLWithString:[docsDir stringByAppendingPathComponent:uniqueFname]];
    
    //    NSLog(@"%s %@",__func__,[_micOutputFileURL absoluteString]);
    //    NSLog(@"%s %@",__func__,[_finalRecordingOutputURL absoluteString]);
}


#define USE_EFFECTS

-(void)setupAVEngine {
    
    [self fileURLs];
    
    // Create nodes
    self.playerNode1 = [JWPlayerNode new];
    self.playerNode2 = [JWPlayerNode new];

    self.playerNode1.volume = 0.25;
    //What effects are in here right now?!?! How am i supposed to know this....
    //i search effectnodes and there are 33 different hits....
    
    AVAudioChannelLayout *layout = [[AVAudioChannelLayout alloc] initWithLayoutTag:kAudioChannelLayoutTag_Stereo];
    AVAudioFormat* micFormat = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatFloat32 sampleRate:44100. interleaved:NO channelLayout:layout];
    
    NSError *error;
    self.audioRecorder = [[AVAudioRecorder alloc] initWithURL:_micOutputFileURL settings:[micFormat settings] error:&error];
    _audioRecorder.meteringEnabled = _useMetering;
    [_audioRecorder prepareToRecord];

    if (_useMetering)
        self.meterSamples = [NSMutableArray new];

    //    AVAudioInputNode* inputNode = [self.audioEngine inputNode];
//    [inputNode installTapOnBus:0 bufferSize:1024
//                        format:_generalFormat block:^(AVAudioPCMBuffer* buffer, AVAudioTime* when) {}];
//    [inputNode removeTapOnBus:0];
    
    
    // Make connections
    [self teeUpAudioBuffers];

    [self createEngineAndAttachNodes];
    [self makeEngineConnections];
    
    self.mixerVolume = 1.0;

    // START the engine

    [self startEngine];

}



-(void)teeUpAudioBuffers {
    
    NSError* error = nil;
    _trimmedAudioFile = [[AVAudioFile alloc] initForReading:_trimmedURL error:&error];

    if (error) {
        NSLog(@"%@",[error description]);
    }

    error = nil;
    AVAudioFile* fiveSecondFile = [[AVAudioFile alloc] initForReading:_fiveSecondURL error:&error];
    if (error) {
        NSLog(@"%@",[error description]);
    }
    
    _audioBufferFromFile = [[AVAudioPCMBuffer alloc] initWithPCMFormat:_trimmedAudioFile.processingFormat
                                                         frameCapacity:(UInt32)_trimmedAudioFile.length];
    
    _fiveSecondBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:fiveSecondFile.processingFormat
                                                      frameCapacity:(UInt32)fiveSecondFile.length];
    
    [_trimmedAudioFile readIntoBuffer:_audioBufferFromFile error:&error];
    [fiveSecondFile readIntoBuffer:_fiveSecondBuffer error:&error];
    
    if (error) {
        NSLog(@"There was an error");
    }
}


#pragma mark - Engine Setup

- (void)createEngineAndAttachNodes
{
    NSLog(@"%s",__func__);
    
    [super createEngineAndAttachNodes];

    /*  An AVAudioEngine contains a group of connected AVAudioNodes ("nodes"), each of which performs
     an audio signal generation, processing, or input/output task.
     
     Nodes are created separately and attached to the engine.
     
     The engine supports dynamic connection, disconnection and removal of nodes while running,
     with only minor limitations:
     - all dynamic reconnections must occur upstream of a mixer
     - while removals of effects will normally result in the automatic connection of the adjacent
     nodes, removal of a node which has differing input vs. output channel counts, or which
     is a mixer, is likely to result in a broken graph. */

    
    /*  To support the instantiation of arbitrary AVAudioNode subclasses, instances are created
     externally to the engine, but are not usable until they are attached to the engine via
     the attachNode method. */
    
    [self.audioEngine attachNode:self.playerNode1];
    [self.audioEngine attachNode:self.playerNode2];

    // leave it to subclasses
}

- (void)makeEngineConnections
{
    NSLog(@"%s",__func__);
    
    // nothing to connect here
    
    
    /*  The engine will construct a singleton main mixer and connect it to the outputNode on demand,
     when this property is first accessed. You can then connect additional nodes to the mixer.
     
     By default, the mixer's output format (sample rate and channel count) will track the format
     of the output node. You may however make the connection explicitly with a different format. */
    
    // get the engine's optional singleton main mixer node
    //    AVAudioMixerNode *mainMixer = [self.audioEngine mainMixerNode];
    
    // establish a connection between nodes
    
    /*  Nodes have input and output buses (AVAudioNodeBus). Use connect:to:fromBus:toBus:format: to
     establish connections betweeen nodes. Connections are always one-to-one, never one-to-many or
     many-to-one.
     
     Note that any pre-existing connection(s) involving the source's output bus or the
     destination's input bus will be broken.
     
     @method connect:to:fromBus:toBus:format:
     @param node1 the source node
     @param node2 the destination node
     @param bus1 the output bus on the source node
     @param bus2 the input bus on the destination node
     @param format if non-null, the format of the source node's output bus is set to this
     format. In all cases, the format of the destination node's input bus is set to
     match that of the source node's output bus. */
    
    AVAudioMixerNode* mainMixer = [self.audioEngine mainMixerNode];
    
    [self.audioEngine connect:self.playerNode1 to:mainMixer format:_audioBufferFromFile.format];
    [self.audioEngine connect:self.playerNode2 to:mainMixer format:_fiveSecondBuffer.format];
    
}


#pragma mark -

- (void)prepareToRecord {
    AVAudioMixerNode *mainMixer = [self.audioEngine mainMixerNode];
    mainMixer.outputVolume = 0.0;

    // Player 1 Schedule buffer
    
    [self.playerNode1 scheduleBuffer:_fiveSecondBuffer atTime:nil options:0 completionHandler:^() {

        NSLog(@"Five Second Audio Completed");
        // Turn ON microphone
        [_audioRecorder record];
        [self startMeteringTimer];
        // Notify delegate
        dispatch_sync(dispatch_get_main_queue(), ^() {
            
            if ([_clipEngineDelegate respondsToSelector:@selector(fiveSecondBufferCompletion)])
                [_clipEngineDelegate fiveSecondBufferCompletion];
            
        });
    }];
    

    // Player 1 Schedule buffer

    [self.playerNode1 scheduleBuffer:_audioBufferFromFile atTime:nil options:0 completionHandler:^() {

        NSLog(@"Main Audio Completed");

        [self.meteringTimer invalidate];
        [_audioRecorder stop];
//        // REMOVE Tap for microphone
//        [[self.audioEngine inputNode] removeTapOnBus:0];

        // READ File into buffer
        
        NSError* error = nil;
        _micOutputFile = [[AVAudioFile alloc] initForReading:_micOutputFileURL error:&error];

        _micOutputBuffer =
        [[AVAudioPCMBuffer alloc] initWithPCMFormat:_micOutputFile.processingFormat
                                      frameCapacity:(UInt32)_micOutputFile.length];
        
        NSAssert([_micOutputFile readIntoBuffer:_micOutputBuffer error:&error], @"error reading into new buffer, %@", [error localizedDescription]);
        
        dispatch_sync(dispatch_get_main_queue(), ^() {
            if ([_clipEngineDelegate respondsToSelector:@selector(userAudioObtained)])
                [_clipEngineDelegate userAudioObtained];
        });
        
    }];
    
    
    [self startEngine];
    
    [self.playerNode1 play];
}


- (void)prepareForPreview {
    
    NSError* error;
    AVAudioMixerNode* mainMixer = [self.audioEngine mainMixerNode];
    
    //[mainMixer installTapOnBus:0 bufferSize:4069 format:_generalFormat
    //[mainMixer installTapOnBus:0 bufferSize:4069 format:[mainMixer outputFormatForBus:0]
    
    _finalRecordingOutputFile =
    [[AVAudioFile alloc] initForWriting:_finalRecordingOutputURL
                               settings:[[mainMixer outputFormatForBus:0] settings]
                                  error:&error];
    
    NSAssert(_finalRecordingOutputFile != nil, @"_finalRecordingOutputFile is nil, %@", [error localizedDescription]);
    
}



- (BOOL) micOutputFileExists {
    if (!_micOutputFileURL) {
        return NO;
    }
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:[_micOutputFileURL path]];
    return exists;
}


// Plays all nodes and records output from mixer
// use PlayAll and Recordit for recording

//-(void)playAll {
//    
//    BOOL loopWhileMixing = YES;
//    
//    _loops = loopWhileMixing;
//    self.playerNode1.loops = _loops;
//    self.playerNode2.loops = _loops;
//    _playerIsPaused = NO;
//    
//    if (_playerIsPaused) {
//        NSLog(@"%s PAUSED will resume play",__func__);
//        
//    } else {
//        
//        // start playing
//        
//        if (loopWhileMixing == NO) { // play the optional way
//            // Play ONCE
//            
//            [self.playerNode1 scheduleBuffer:_audioBufferFromFile atTime:nil
//                                     options:AVAudioPlayerNodeBufferInterrupts
//                           completionHandler:^{
//                               _playerIsPaused = NO;
//                               [_playerNode1 stop];
//                               
//                               dispatch_sync(dispatch_get_main_queue(), ^() {
//                                   if ([_clipEngineDelegate respondsToSelector:@selector(playingCompleted)])
//                                       [_clipEngineDelegate playingCompleted];
//                               });
//                           }];
//            
//            if (_micOutputBuffer) {
//                [self.playerNode2 scheduleBuffer:_micOutputBuffer atTime:nil
//                                         options:AVAudioPlayerNodeBufferInterrupts completionHandler:nil];
//            }
//            
//            
//        } else {
//
//            [self.playerNode1 scheduleBuffer:_audioBufferFromFile atTime:nil
//                                     options:AVAudioPlayerNodeBufferLoops
//                           completionHandler:^{
//                           }];
//
//            if (_micOutputBuffer) {
//                [self.playerNode2 scheduleBuffer:_micOutputBuffer atTime:nil
//                                         options:AVAudioPlayerNodeBufferLoops  completionHandler:^{
//                                             NSLog(@"mic buffer loop completed");
//                                         }];
//            }
//            
//        }
//    }
//    
//    [self.playerNode1 play];
//    if (_micOutputBuffer)
//        [self.playerNode2 play];
//    
//}

-(void)playAlll {
    
    //_loops = YES;
    //self.playerNode1.loops = YES;
    //self.playerNode2.loops = YES;
    
    [self.playerNode1 scheduleBuffer:_audioBufferFromFile atTime:nil
                             options:AVAudioPlayerNodeBufferLoops
                   completionHandler:^{
                   }];
    
    if (_micOutputBuffer) {
        [self.playerNode2 scheduleBuffer:_micOutputBuffer atTime:nil
                                 options:AVAudioPlayerNodeBufferLoops  completionHandler:^{
                                     NSLog(@"mic buffer loop completed");
                                 }];
    }
    
    if (_scrubberTrackIds[@"mixer"]) {
        // install TAP on mixer to provide visualAudio
        AVAudioMixerNode* mainMixer = [self.audioEngine mainMixerNode];
        
        NSLog(@"Installed visual Audio mixer tap");
        
        [mainMixer installTapOnBus:0 bufferSize:1024 format:[mainMixer outputFormatForBus:0]
                             block:^(AVAudioPCMBuffer* buffer, AVAudioTime* when) {
                                 // Write buffer to final recording
                                 // Get it out of here
                                 if (_suspendPlayAlll == NO) {
                                 dispatch_async(_bufferReceivedQueue, ^{
                                     dispatch_sync(dispatch_get_main_queue(), ^() {
                                         [_scrubberBufferController bufferReceivedForTrackId:_scrubberTrackIds[@"mixer"] buffer:buffer atReadPosition:(AVAudioFramePosition)[when sampleTime]];
                                     });
                                 }); //_bufferReceivedQueue
                                 }
                             }];
        
    }
    
    [self.playerNode1 play];
    if (_micOutputBuffer)
        [self.playerNode2 play];
    
}



-(void)pauseAlll {
    _suspendPlayAlll = YES;
}

-(void)resumeAlll {
    _suspendPlayAlll = NO;
}


-(void)stopAll {
    [self.playerNode1 stop];
    [self.playerNode2 stop];
    if (_scrubberTrackIds[@"mixer"]) {
        // install TAP on mixer to provide visualAudio
        AVAudioMixerNode* mainMixer = [self.audioEngine mainMixerNode];
        [mainMixer removeTapOnBus:0];
        
        NSLog(@"REMOVED AudioVidual Tap");
    }
}


-(void)playAllAndRecordIt {
    
    _loops = NO;

    [self.playerNode1 stop];
    [self.playerNode2 stop];
    
    [self.playerNode1 reset];
    [self.playerNode2 reset];
    
    _playerIsPaused = NO;
    
    [self.playerNode1 scheduleBuffer:_audioBufferFromFile atTime:nil options:0
                   completionHandler:^{
                       
                       AVAudioMixerNode* mainMixer = [self.audioEngine mainMixerNode];
                       [mainMixer removeTapOnBus:0];
                       
                       dispatch_sync(dispatch_get_main_queue(), ^() {
                           if ([_clipEngineDelegate respondsToSelector:@selector(mixRecordingCompleted)])
                               [_clipEngineDelegate mixRecordingCompleted];
                       });
                       
                   }];
    
    [self.playerNode2 scheduleBuffer:_micOutputBuffer atTime:nil options:0 completionHandler:^() {
        }];
    
    // Install TAP
    
    AVAudioMixerNode* mainMixer = [self.audioEngine mainMixerNode];
    
    //[mainMixer installTapOnBus:0 bufferSize:4069 format:_generalFormat
    
    NSLog(@"Installed recording mix tap");
    
    [mainMixer installTapOnBus:0 bufferSize:4069 format:[mainMixer outputFormatForBus:0]
                         block:^(AVAudioPCMBuffer* buffer, AVAudioTime* when) {
                             // Write buffer to final recording
                             NSError *error;
                             NSAssert([_finalRecordingOutputFile writeFromBuffer:buffer error:&error],
                                      @"error writing buffer data to file, %@", [error localizedDescription]);
                         }];
    
    [self.playerNode1 play];
    [self.playerNode2 play];
}


-(void)playMix {

    _loops = NO;
    
    [self.playerNode2 stop];

    [_playerNode1 reset];

    // Plas the mix result _finalRecordingOutputURL
    
    NSError* error = nil;
    _finalRecordingOutputFile = [[AVAudioFile alloc] initForReading:_finalRecordingOutputURL error:&error];

    if (error) {
        NSLog(@"%@",[error description]);
    }
    
    AVAudioPCMBuffer *audioBuffer =
    [[AVAudioPCMBuffer alloc] initWithPCMFormat:_finalRecordingOutputFile.processingFormat
                                  frameCapacity:(UInt32)_finalRecordingOutputFile.length];
    
    error = nil;
    
    [_finalRecordingOutputFile readIntoBuffer:audioBuffer error:&error];
    
    if (error) {
        NSLog(@"There was an error");
    }
    
    [self.playerNode1 scheduleBuffer:audioBuffer atTime:nil options:0
                   completionHandler:^{
                       
                       dispatch_async(dispatch_get_main_queue(), ^{
                           if ([_clipEngineDelegate respondsToSelector:@selector(playMixCompleted)])
                               [_clipEngineDelegate playMixCompleted];
                       });
                   }];
    
    [self.playerNode1 play];
}


#pragma mark - Scrubber support

-(AVAudioFramePosition)playerFramePostion
{
    return [[_playerNode1 lastRenderTime] sampleTime];
}

-(void)changeProgressOfSeekingAudioFile:(CGFloat)progress {
    
//    AVAudioFramePosition fileLength = seekingAudioFile.length;
//    AVAudioFramePosition readPosition = progress * fileLength;
//    
//    if (_micPlayer.playing) {
//        [self playSeekingAudioFileAtFramPosition:readPosition];
//    }
    
}

// currentPos
// sampleTime / sampleRate
// progress of playback

-(CGFloat)progressOfSeekingAudioFile {
        return _isRecording ? [self.playerNode2 progressOfAudioFile] : [self.playerNode1 progressOfAudioFile];
}
-(CGFloat)durationInSecondsOfSeekingAudioFile {
    return _isRecording ? [self.playerNode2 durationInSecondsOfAudioFile] : [self.playerNode1 durationInSecondsOfAudioFile];
}
-(CGFloat)remainingDurationInSecondsOfSeekingAudioFile {
    return _isRecording ? [self.playerNode2 remainingDurationInSecondsOfAudioFile] :
    [self.playerNode1 remainingDurationInSecondsOfAudioFile];
}
-(CGFloat)currentPositionInSecondsOfSeekingAudioFile {
    return _isRecording ? [self.playerNode2 currentPositionInSecondsOfAudioFile] :
    [self.playerNode1 currentPositionInSecondsOfAudioFile];  // trimmed
}
-(NSString*)processingFormatStr{
//    return _isRecording ? [self processingMicFormatStr] : [self processingTrimmedFormatStr];
    return nil;
}

// generic


-(NSString*)processingFormatStrOfAudioFile:(AVAudioFile*)audioFile
{
    NSString *result = nil;
    if (audioFile) {
        AVAudioFormat *format = [_trimmedAudioFile processingFormat];
        result = [NSString stringWithFormat:@"%d ch %.0f %d %@ %@",
                  format.streamDescription->mChannelsPerFrame,
                  format.streamDescription->mSampleRate,
                  format.streamDescription->mBitsPerChannel,
                  format.standard ? @"Float32-std" : @"std NO",
                  format.interleaved ? @"inter" : @"non-interleaved"
                  ];
    }
    NSLog(@"%s %@",__func__,result);
    return result;
}

// MIC

-(NSString*)processingMicFormatStr{
    return [self processingFormatStrOfAudioFile:_micOutputFile];
}

// TRIMMED

-(NSString*)processingTrimmedFormatStr {
    return [self processingFormatStrOfAudioFile:_trimmedAudioFile];
}

// MIX file
-(CGFloat)progressOfMixAudioFile{
    return [self.playerNode1 progressOfAudioFile];
}
-(CGFloat)durationInSecondsOfMixFile {
    return [self.playerNode1 durationInSecondsOfAudioFile];
}
-(CGFloat)remainingDurationInSecondsOfMixFile {
    return [self.playerNode1 remainingDurationInSecondsOfAudioFile];
}
-(CGFloat)currentPositionInSecondsOfMixFile{
    return [self.playerNode1 currentPositionInSecondsOfAudioFile];
}
-(NSString*)mixFileProcessingFormatStr{
//    return [self processingFormatStrOfAudioFile:_finalRecordingOutputFile];
    return nil;
}

// other
-(void)setProgressSeekingAudioFile:(CGFloat)progressSeekingAudioFile {
    _progressSeekingAudioFile = progressSeekingAudioFile;
}

#ifndef JWPLAYERNODE

-(CGFloat)progressOfMicAudioFile {
    return [self progressOfAudioFile:_micOutputFile forPlayerNode:_playerNode2];
}

-(CGFloat)durationInSecondsOfMicAudioFile {
    return [self durationInSecondsOfAudioFile:_micOutputFile forPlayerNode:_playerNode2];
}

-(CGFloat)remainingDurationInSecondsOfMicAudioFile {
    return [self remainingDurationInSecondsOfAudioFile:_micOutputFile forPlayerNode:_playerNode2];
}
-(CGFloat)currentPositionInSecondsOfMicAudioFile {
    return [self currentPositionInSecondsOfAudioFile:_micOutputFile forPlayerNode:_playerNode2];
}

-(CGFloat)remainingDurationInSecondsOfTrimmedAudioFile{
    return [self remainingDurationInSecondsOfAudioFile:_trimmedAudioFile forPlayerNode:_playerNode1];
}
-(CGFloat)currentPositionInSecondsOfTrimmedAudioFile{
    return [self currentPositionInSecondsOfAudioFile:_trimmedAudioFile forPlayerNode:_playerNode1];
}


-(CGFloat)progressOfTrimmedAudioFile{
    return [self progressOfAudioFile:_trimmedAudioFile forPlayerNode:_playerNode1];
}

-(CGFloat)durationInSecondsOfTrimmedAudioFile{
    return [self durationInSecondsOfAudioFile:_trimmedAudioFile forPlayerNode:_playerNode1];
}


-(CGFloat)progressOfAudioFile:(AVAudioFile*)audioFile forPlayerNode:(AVAudioPlayerNode*)playerNode
{
    CGFloat result = 0.000f;
    if (audioFile) {
        AVAudioFramePosition fileLength = audioFile.length;
        AVAudioTime *audioTime = [playerNode lastRenderTime];
        AVAudioTime *playerTime = [playerNode playerTimeForNodeTime:audioTime];
        
        if (playerTime==nil) {
            NSLog(@"%s NO PLAYER TIME  playing %@",__func__,@([playerNode isPlaying]));
            result = 1.00f;
            
        } else {
            double fileLenInSecs = fileLength / [playerTime sampleRate];
            double currentPosInSecs = [playerTime sampleTime] / [playerTime sampleRate];
            
            if (currentPosInSecs > fileLenInSecs ) {
                if (_loops) {
                    double normalizedPos = currentPosInSecs/fileLenInSecs - floorf(currentPosInSecs/fileLenInSecs);
                    result = normalizedPos;
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

-(CGFloat)durationInSecondsOfAudioFile:(AVAudioFile*)audioFile forPlayerNode:(AVAudioPlayerNode*)playerNode
{
    CGFloat result = 0.000f;
    
    if (audioFile) {
        AVAudioFramePosition fileLength = audioFile.length;
        AVAudioTime *audioTime = [playerNode lastRenderTime];
        AVAudioTime *playerTime = [playerNode playerTimeForNodeTime:audioTime];
        
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

-(CGFloat)remainingDurationInSecondsOfAudioFile:(AVAudioFile*)audioFile forPlayerNode:(AVAudioPlayerNode*)playerNode
{
    CGFloat result = 0.000f;
    if (audioFile) {
        AVAudioTime *audioTime = [playerNode lastRenderTime];
        AVAudioFramePosition fileLength = audioFile.length;
        AVAudioTime *playerTime = [playerNode playerTimeForNodeTime:audioTime];
        
        double fileLenInSecs = fileLength / [playerTime sampleRate];
        double currentPosInSecs = [playerTime sampleTime] / [playerTime sampleRate];
        
        if (currentPosInSecs > fileLenInSecs ) {
            result = 0.0;
        } else {
            result = (fileLenInSecs - currentPosInSecs);
        }
    }
    //    NSLog(@"%s %.3f",__func__,result);
    return result;
}

-(CGFloat)currentPositionInSecondsOfAudioFile:(AVAudioFile*)audioFile forPlayerNode:(AVAudioPlayerNode*)playerNode
{
    CGFloat result = 0.000f;
    if (audioFile) {
        AVAudioFramePosition fileLength = audioFile.length;
        AVAudioTime *audioTime = [playerNode lastRenderTime];
        AVAudioTime *playerTime = [playerNode playerTimeForNodeTime:audioTime];
        
        double fileLenInSecs = fileLength / [playerTime sampleRate];
        double currentPosInSecs = [playerTime sampleTime] / [playerTime sampleRate];
        
        if (currentPosInSecs > fileLenInSecs ) {
            result = fileLenInSecs;
        } else {
            result = currentPosInSecs;
        }
    }
    //    NSLog(@"%s %.3f",__func__,result);
    return result;
}


-(float)volumeValuePlayer1 {
    return [_playerNode1 volume];
}
-(float)volumeValuePlayer2 {
    return [_playerNode2 volume];
}
-(void)setVolumeValuePlayer1:(float)volumeValuePlayer1  {
    //_volumeValuePlayer1 = volumeValuePlayer1;
    _playerNode1.volume = volumeValuePlayer1;
}
-(void)setVolumeValuePlayer2:(float)volumeValuePlayer2  {
    //    _volumeValuePlayer2 =volumeValuePlayer2;
    _playerNode2.volume = volumeValuePlayer2;
}


-(float)panValuePlayer1 {
    return [_playerNode1 pan];
}
-(float)panValuePlayer2 {
    return [_playerNode2 pan];
}

-(void)setPanValuePlayer1:(float)panValue  {
    _playerNode1.pan = panValue;
    //    NSLog(@"%s %.2f",__func__,panValue);
}
-(void)setPanValuePlayer2:(float)panValue  {
    _playerNode2.pan = panValue;
}


-(float)volumePlaybackTarck {
    return _playerNode1.volume;
}
-(void)setVolumePlayBackTrack:(float)volumePlayBackTrack {
    _volumePlayBackTrack = volumePlayBackTrack;
    _playerNode1.volume = _volumePlayBackTrack;
}

#endif


#pragma mark -

- (void)stopPlayingTrack1
{
    [_playerNode1 stop];
    _playerIsPaused = NO;
}

- (void)pausePlayingTrack1
{
    [_playerNode1 pause];
    _playerIsPaused = YES;
}

- (void)pausePlayingAll
{
    [_playerNode1 pause];
    [_playerNode2 pause];

    _playerIsPaused = YES;
}

-(BOOL)prepareToPlayTrack1 {
//    [self audioFileAnalyzerForFile:_trimmedURL];
    return YES;
}

//-(void)audioFileAnalyzer {
////    [self audioFileAnalyzerForFile:_micOutputFileURL];
//}


#pragma mark - metering

-(void)startMeteringTimer
{
    self.lastMeterTimeStamp = [NSDate date];
    self.meteringTimer = [NSTimer timerWithTimeInterval:0.10 target:self selector:@selector(meteringTimerFired:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_meteringTimer forMode:NSRunLoopCommonModes];
}

-(void)meteringTimerFired:(NSTimer*)timer {
    
    if (timer.valid) {
        //        The current peak power, in decibels, for the sound being recorded. A return value of 0 dB indicates full scale, or maximum power; a return value of -160 dB indicates minimum power (that is, near silence).
        // but am gonna limit to 130
        // The sampl
        [self.audioRecorder updateMeters];
        
        //        float peakSample = [self.audioRecorder peakPowerForChannel:0];
        //        float peakNormalizedValue = 0.0;// ratio 0 - 1.0
        //        if (peakSample > 0 )
        //            peakNormalizedValue = 1.00f;  // full power
        //        else
        //            peakNormalizedValue = (160.0 + peakSample) / 160.00f;  // sample of (-45) = 115   160 + (-158) = 2 = 0.0125
        //        [_meterSamples addObject:@(peakNormalizedValue)];
        //
        //        NSLog(@" [%.3f] peak %.3f",peakNormalizedValue,peakSample);
        
        float avgSample = [self.audioRecorder averagePowerForChannel:0];
        float avgNormalizedValue = 0.0;// ratio 0 - 1.0
        float maxDB = 160.0f;
        if (avgSample > 0 )
            avgNormalizedValue = 1.00f;
        else {
            avgNormalizedValue = (maxDB + avgSample) / (maxDB + 20);  // sample of (-45) = 115   160 + (-158) = 2 = 0.0125
        }
        
        //        NSLog(@" [%.3f] avg %.3f",avgNormalizedValue,avgSample);
        
        [_meterSamples addObject:@(avgNormalizedValue)];
        
        NSTimeInterval timedMeter =  [_lastMeterTimeStamp timeIntervalSinceNow];
        //        NSLog(@"time  %.3f",timedMeter);
        
        NSTimeInterval meteringInterval = 0.28;
        if (timedMeter <  - meteringInterval) {
            
            //            [_audioEngineDelegate meterSamples:[NSArray arrayWithArray:_meterSamples] andDuration:-timedMeter];
            
//            [_scrubberBufferController meterSamples:[NSArray arrayWithArray:_meterSamples] andDuration:-timedMeter
//                                         forTrackId:_scrubberTrackIds[@"recorder"]];
            
            
            [_meterSamples removeAllObjects];
            self.lastMeterTimeStamp = [NSDate date];
        }
    }
}


//#pragma mark Prepare methods
//
-(void)prepareToPlaySeekingAudio {
    //    [self audioFileAnalyzerForFile:_micOutputFileURL];
}
-(void)prepareToPlayPrimaryTrack {
    //    [self audioFileAnalyzerForFile:_trimmedURL andTrack:1];
}
-(void)prepareToPlayMicRecording {
    //    [self audioFileAnalyzerForFile:_micOutputFileURL andTrack:2];
}
-(void)prepareMasterMixSampling {
    //    [self audioFileAnalyzerForFile:_finalRecordingOutputURL];
}

@end











////4. Connect player node to engine's main mixer
//NSDictionary *setting = @{
//                          AVFormatIDKey: @(AVAudioPCMFormatFloat32),
//                          AVSampleRateKey: @(1),
//                          AVNumberOfChannelsKey: @(1)
//                          };
//_audioFormat = [[AVAudioFormat alloc] initWithSettings:setting];

// Superclass has this

//- (void)initAVAudioSession
//    AVAudioSession *sessionInstance = [AVAudioSession sharedInstance];
//    bool success = [sessionInstance setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];


//data/Containers/Data/Application/0B0742C9-24B0-494B-B516-04B941BD4035/Documents/trimmedMP3
//2015-09-22 09:53:28.648 JamWithV1.0[59545:6526481] 09:53:28.648 ERROR:     AVAudioFile.mm:266: AVAudioFileImpl: error 1685348671
//2015-09-22 09:53:28.649 JamWithV1.0[59545:6526481] Error Domain=com.apple.coreaudio.avfaudio Code=1685348671 "The operation couldn’t be completed. (com.apple.coreaudio.avfaudio error 1685348671.)" UserInfo=0x7c167470 {failed call=ExtAudioFileOpenURL((CFURLRef)fileURL, &_extAudioFile)}
//(lldb)

//7down votefavorite
//I initialize my AVAudioPlayer instance like:
//
//[self.audioPlayer initWithContentsOfURL:url error:&err];
//url contains the path of an .m4a file
//
//The following error is displayed in the console when this line is called :"Error Domain=NSOSStatusErrorDomain Code=1685348671 "Operation could not be completed. (OSStatus error 1685348671.)"
// --------------------
//
//The error code is a four-char-code for "dta?" (you can use the Calculator app in programmer mode to convert the int values to ASCII). Check the "result codes" of the various Core Audio references and you'll find this is defined in both Audio File Services and Audio File Stream Services as kAudioFileInvalidFileError or kAudioFileStreamError_InvalidFile respectively, both of which have the same definition:
//
//The file is malformed, not a valid instance of an audio file of its type, or not recognized as an audio file. Available in iPhone OS 2.0 and later.
//Have you tried your code with different .m4a files?

