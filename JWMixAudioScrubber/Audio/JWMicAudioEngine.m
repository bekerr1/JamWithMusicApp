/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
*/

#import "JWMicAudioEngine.h"
@import Accelerate;

#define USE_AVRECORDER

#pragma mark AudioEngine class extensions

@interface JWMicAudioEngine() {
    
    AVAudioEngine       *_engine;
    AVAudioPlayerNode   *_micPlayer;
    AVAudioPCMBuffer    *_micLoopBuffer;
    NSURL               *_micOutputFileURL;
    NSURL               *_micOutputPrepareFileURL;

    AVAudioFile * _micOutputFile;
    BOOL _loops;
    BOOL                _isRecording;
    BOOL                _micPlayerIsPaused;
    BOOL                _useMetering;
    BOOL                _hasContent;
}
@property (strong, nonatomic) AVAudioRecorder *audioRecorder;
@property (nonatomic,strong)  NSTimer *meteringTimer;
@property (nonatomic,strong)  NSMutableArray *meterSamples; // array of two arrays each channel
@property (nonatomic,strong)  NSMutableArray *meterPeakSamples; // array of two arrays each channel

@property (nonatomic,strong)  NSDate *lastMeterTimeStamp;

@property (nonatomic,strong) id <JWScrubberBufferControllerDelegate> scrubberBufferController;
@property (nonatomic,strong) NSString *scrubberTrackId;

@end


#pragma mark AudioEngine implementation

@implementation JWMicAudioEngine

- (instancetype)init
{
    if (self = [super init]) {

        _useMetering = YES;
        
        _micPlayer = [[AVAudioPlayerNode alloc] init];
        _micOutputFileURL = nil;
        _micPlayerIsPaused = NO;
        _isRecording = NO;
        
        // create an instance of the engine and attach the nodes
        [self createEngineAndAttachNodes];
        
        // sign up for notifications from the engine if there's a hardware config change
        [[NSNotificationCenter defaultCenter] addObserverForName:AVAudioEngineConfigurationChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            
            // if we've received this notification, something has changed and the engine has been stopped
            // re-wire all the connections and start the engine
            NSLog(@"Received a %@ notification!", AVAudioEngineConfigurationChangeNotification);
            NSLog(@"Re-wiring connections and starting once again");
            [self makeEngineConnections];
            [self startEngine];
            
            // post notification
            if ([self.delegate respondsToSelector:@selector(engineConfigurationHasChanged)]) {
                [self.delegate engineConfigurationHasChanged];
            }
        }];
        
        // AVAudioSession setup
        [self initAVAudioSession];
        
        // make engine connections
        [self makeEngineConnections];
        
        // start the engine
        [self startEngine];
        
        
    }
    return self;
}


-(void)registerController:(id <JWScrubberBufferControllerDelegate> )myScrubberContoller
              withTrackId:(NSString*)trackId forPlayerRecorder:(NSString*)playerRecorder
{
    _scrubberBufferController = myScrubberContoller;
    _scrubberTrackId = trackId;
}

-(NSURL*)outputFileUrl
{
    return _micOutputFileURL;
}



- (void) setAudioEngineDelegate:(id<JWMicAudioEngineDelegate>)audioEngineDelegate
{
    _audioEngineDelegate = audioEngineDelegate;
    
    self.delegate = _audioEngineDelegate;  // for super
}

- (void) setCurrentCacheItem:(NSString *)currentCacheItem {
    
    if (_currentCacheItem != currentCacheItem) {
        _currentCacheItem = currentCacheItem;
    }
    
    if (_currentCacheItem == nil)
        _micOutputFileURL = nil;
    else {
        _micOutputFileURL = [self fileURLForCacheItem:_currentCacheItem];
        BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:[_micOutputFileURL path]];
        if (exists) {
            _hasContent = YES;
        } else {
            _hasContent = NO;
        }
    }

}

- (BOOL) micOutputExists {
    
    if (!_micOutputFileURL) {
        return NO;
    }
    if (!_hasContent) {
        return NO;
    }
    
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:[_micOutputFileURL path]];
    
    return exists;
}


#pragma mark - nodes and connections

/*  An AVAudioEngine contains a group of connected AVAudioNodes ("nodes"), each of which performs
 an audio signal generation, processing, or input/output task.
 
 Nodes are created separately and attached to the engine.
 
 The engine supports dynamic connection, disconnection and removal of nodes while running,
 with only minor limitations:
 - all dynamic reconnections must occur upstream of a mixer
 - while removals of effects will normally result in the automatic connection of the adjacent
 nodes, removal of a node which has differing input vs. output channel counts, or which
 is a mixer, is likely to result in a broken graph. */

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

- (void)createEngineAndAttachNodes
{
    _engine = [AVAudioEngine new];
    
    /*  To support the instantiation of arbitrary AVAudioNode subclasses, instances are created
		externally to the engine, but are not usable until they are attached to the engine via
		the attachNode method. */

    [_engine attachNode:_micPlayer];
}

- (void)makeEngineConnections
{
    /*  The engine will construct a singleton main mixer and connect it to the outputNode on demand,
		when this property is first accessed. You can then connect additional nodes to the mixer.
		
		By default, the mixer's output format (sample rate and channel count) will track the format 
		of the output node. You may however make the connection explicitly with a different format. */
    
    // get the engine's optional singleton main mixer node
    
    AVAudioMixerNode *mainMixer = [_engine mainMixerNode];
    //    AVAudioFormat* micFormat = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100. channels:2];
    AVAudioChannelLayout *layout = [[AVAudioChannelLayout alloc] initWithLayoutTag:kAudioChannelLayoutTag_Stereo];
    //    AVAudioFormat* micFormat = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100. channelLayout:layout];
    AVAudioFormat* micFormat = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatFloat32 sampleRate:44100. interleaved:NO channelLayout:layout];
    
    [_engine connect: _micPlayer to:mainMixer format:micFormat];

//    [self micInit];
}


#pragma mark - engine toggles

// start the engine

/*  startAndReturnError: calls prepare if it has not already been called since stop.
	
 Starts the audio hardware via the AVAudioInputNode and/or AVAudioOutputNode instances in
 the engine. Audio begins flowing through the engine.
	
 This method will return YES for sucess.
 
 Reasons for potential failure include:
 
 1. There is problem in the structure of the graph. Input can't be routed to output or to a
 recording tap through converter type nodes.
 2. An AVAudioSession error.
 3. The driver failed to start the hardware. */

- (void)startEngine
{
    if (!_engine.isRunning) {
        NSError *error;
        NSAssert([_engine startAndReturnError:&error], @"couldn't start engine, %@", [error localizedDescription]);
    }
}

- (void)resetRecording {
    NSLog(@"%s",__func__);

    [self micOff];
    _micOutputFileURL = nil;
    _hasContent=NO;
    [_micPlayer stop];
    [_micPlayer reset];
}

- (BOOL)toggleLoop {
    _loops = ! _loops;
    
//    [_micPlayer stop];
//    [self playMicRecordedFile];

    return _loops;
}


- (BOOL)isLoop
{
    return _loops;
}

- (void)startMicRecording
{
    // install a tap on the input node
    [self startEngine];
    [self micOn];
    _isRecording = YES;
}

// stop recording really means remove the tap on the main mixer that was created in startRecordingMixerOutput

- (void)stopMicRecording
{
    if (_isRecording) {
        [self micOff];
        _isRecording = NO;
    }
}

- (void)playMicRecordedFile
{
    [self playMicRecordingUsingBuffer];
}

// using buffer allows looping

- (void)playMicRecordingUsingBuffer
{
    
    if (_micPlayerIsPaused) {
        [_micPlayer play];
    }
    else {
        
        // start playing
        if (_micOutputFileURL && _hasContent){
            
            AVAudioChannelLayout *layout = [[AVAudioChannelLayout alloc] initWithLayoutTag:kAudioChannelLayoutTag_Stereo];
            AVAudioFormat* micFormat = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatFloat32 sampleRate:44100. interleaved:NO channelLayout:layout];

            NSError *error;
            _micOutputFile = [[AVAudioFile alloc] initForReading:_micOutputFileURL error:&error];
            
            _micLoopBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:micFormat frameCapacity:(AVAudioFrameCount)[_micOutputFile length]];

            NSAssert([_micOutputFile readIntoBuffer:_micLoopBuffer error:&error], @"couldn't read LoopFile into buffer, %@", [error localizedDescription]);

            [self startEngine];

            if (_loops == NO) { // play the optional way
                // Play ONCE
                
                [_micPlayer scheduleBuffer:_micLoopBuffer atTime:nil options:AVAudioPlayerNodeBufferInterrupts completionHandler:^{
                    
                    NSLog(@"mic buffer play completed");
                    // reminder: we're not on the main thread in here
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSLog(@"done playing, as expected!");
                        if ([self.audioEngineDelegate respondsToSelector:@selector(playMicRecordingHasStopped)])
                            [self.audioEngineDelegate playMicRecordingHasStopped];
                    });
                    
                    _micPlayerIsPaused = NO;
                    [_micPlayer stop];
                }];
                
            } else {
                [_micPlayer scheduleBuffer:_micLoopBuffer atTime:nil options:AVAudioPlayerNodeBufferLoops completionHandler:^{
                    NSLog(@"mic buffer loop completed");
                }];
            }
            
            [_micPlayer play];
        }
        
        _micPlayerIsPaused = NO;

    }
}


// using buffer disallows looping

- (void)playMicRecordingUsingFile
{
    if (_micOutputFileURL && _hasContent) {
        
        NSError *error;
        AVAudioFile *recordedFile = [[AVAudioFile alloc] initForReading:_micOutputFileURL error:&error];
        
        NSAssert(recordedFile != nil, @"recordedFile is nil, %@", [error localizedDescription]);
        
        [_micPlayer scheduleFile:recordedFile atTime:nil completionHandler:^{
            _micPlayerIsPaused = NO;
            
            // the data in the file has been scheduled but the player isn't actually done playing yet
            // calculate the approximate time remaining for the player to finish playing and then dispatch the notification to the main thread
            AVAudioTime *playerTime = [_micPlayer playerTimeForNodeTime:_micPlayer.lastRenderTime];
            
            double delayInSecs = (recordedFile.length - playerTime.sampleTime) / recordedFile.processingFormat.sampleRate;
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSecs * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                if ([self.audioEngineDelegate respondsToSelector:@selector(playMicRecordingHasStopped)])
                    [self.audioEngineDelegate playMicRecordingHasStopped];
                
                [_micPlayer stop];
            });
        }];
        
        [_micPlayer  play];
        
        _micPlayerIsPaused = NO;
    }
    
}


- (void)stopPlayingMicRecordedFile
{
    [_micPlayer stop];
    _micPlayerIsPaused = NO;
}

- (void)pausePlayingMicRecordedFile
{
    [_micPlayer pause];
    _micPlayerIsPaused = YES;
}

-(BOOL)prepareToPlayAudio {

    BOOL result = NO;
    if (_micOutputFileURL && _hasContent) {
        [self audioFileAnalyzer];
        NSError *error;
        _micOutputFile = [[AVAudioFile alloc] initForReading:_micOutputFileURL error:&error];
        result = YES;
    }
    return result;
}


#pragma mark - helpers

-(void)audioFileAnalyzer
{
//    [self audioFileAnalyzerForFile:_micOutputFileURL];
}

-(void)newRecording {
    
    _hasContent = NO; // will set to yes when recording starts
    self.currentCacheItem = [[NSUUID UUID] UUIDString];
    // URL is set when setting cache item
    [[NSUserDefaults standardUserDefaults] setValue:_currentCacheItem forKey:@"recordingCurrentItem"];
    NSLog(@"%s %@",__func__,_currentCacheItem);
}

-(NSURL *)fileURLForCacheItem:(NSString*)cacheKey {
    NSString *thisfName = @"recording";
    NSString *uniqueFname = [NSString stringWithFormat:@"%@_%@.caf",thisfName,cacheKey?cacheKey:@""];
    NSString *docsDir = [NSHomeDirectory() stringByAppendingPathComponent:  @"Documents"];
    NSString *pathName = [docsDir stringByAppendingPathComponent:uniqueFname];
    return [NSURL fileURLWithPath:pathName];
}


#pragma mark progress
// currentPos
// sampleTime / sampleRate
// progress of playback

-(CGFloat)progressOfAudioFile
{
    CGFloat result = 0.000f;
    if (_micOutputFile) {
        AVAudioFramePosition fileLength = _micOutputFile.length;
        AVAudioTime *audioTime = [_micPlayer lastRenderTime];
        AVAudioTime *playerTime = [_micPlayer playerTimeForNodeTime:audioTime];
        
        if (playerTime==nil) {
            NSLog(@"%s NO PLAYER TIME  playing %@",__func__,@([_micPlayer isPlaying]));
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
        
        //NSLog(@"%s %.3f cp %.2f secs len %.2f secs",__func__,result,currentPosInSecs,fileLenInSecs);

    }
    //NSLog(@"%s %.3f",__func__,result);
    return result;
}

-(CGFloat)durationInSecondsOfAudioFile
{
    CGFloat result = 0.000f;
    if (_micOutputFile) {
        AVAudioFramePosition fileLength = _micOutputFile.length;
        AVAudioTime *audioTime = [_micPlayer lastRenderTime];
        AVAudioTime *playerTime = [_micPlayer playerTimeForNodeTime:audioTime];
        
        double fileLenInSecs = 0.0f;
        if (playerTime) {
            fileLenInSecs = fileLength / [playerTime sampleRate];
        } else {
            Float64 mSampleRate = _micOutputFile.processingFormat.streamDescription->mSampleRate;
            Float64 duration =  (1.0 / mSampleRate) * _micOutputFile.processingFormat.streamDescription->mFramesPerPacket;
            fileLenInSecs = duration * fileLength;
        }
        
        result = (CGFloat)fileLenInSecs;
    }
//    NSLog(@"%s %.3f",__func__,result);
    return result;
}

-(CGFloat)remainingDurationInSecondsOfAudioFile
{
    CGFloat result = 0.000f;
    if (_micOutputFile) {
        AVAudioFramePosition fileLength = _micOutputFile.length;
        AVAudioTime *audioTime = [_micPlayer lastRenderTime];
        AVAudioTime *playerTime = [_micPlayer playerTimeForNodeTime:audioTime];
        
        if (playerTime==nil) {
            NSLog(@"%s NO PLAYER TIME  playing %@  audioTime %@",__func__,@([_micPlayer isPlaying]),[audioTime description]);

        } else {
            double fileLenInSecs = fileLength / [playerTime sampleRate];
            double currentPosInSecs = [playerTime sampleTime] / [playerTime sampleRate];
            if (currentPosInSecs > fileLenInSecs )
                result = 0.0;
            else
                result = (fileLenInSecs - currentPosInSecs);
        }
    }
//    NSLog(@"%s %.3f",__func__,result);
    return result;
}

-(CGFloat)currentPositionInSecondsOfAudioFile
{
    CGFloat result = 0.000f;
    if (_micOutputFile) {
        AVAudioFramePosition fileLength = _micOutputFile.length;
        AVAudioTime *audioTime = [_micPlayer lastRenderTime];
        AVAudioTime *playerTime = [_micPlayer playerTimeForNodeTime:audioTime];
        
        if (playerTime == nil) {
            NSLog(@"%s NO PLAYER TIME  playing %@",__func__,@([_micPlayer isPlaying]));

        } else {
            double fileLenInSecs = fileLength / [playerTime sampleRate];
            double currentPosInSecs = [playerTime sampleTime] / [playerTime sampleRate];
            if (currentPosInSecs > fileLenInSecs ) {
//                result = fileLenInSecs;
                result = [self durationInSecondsOfAudioFile];
            } else if (currentPosInSecs  < 0.0000f ) {
                result = 0.0000f;
                
            } else {
                result = currentPosInSecs;
            }
        }
    }
    
//    NSLog(@"%s %.3f",__func__,result);
    return result;
}

-(NSString*)processingFormatStr
{
    NSString *result = nil;

//    AVFormatIDKey = 1819304813;
//    AVLinearPCMBitDepthKey = 32;
//    AVLinearPCMIsBigEndianKey = 0;
//    AVLinearPCMIsFloatKey = 1;
//    AVLinearPCMIsNonInterleaved = 0;
//    AVNumberOfChannelsKey = 2;
//    AVSampleRateKey = 44100;

    if ([_audioRecorder isRecording]) {
        NSLog(@"%s %@",__func__,[_audioRecorder settings]);
        NSDictionary *format = [_audioRecorder settings];
        result = [NSString stringWithFormat:@"%@ %@ %@ %@",
                  format[@"AVNumberOfChannelsKey"],
                  format[@"AVSampleRateKey"],
                  format[@"AVLinearPCMBitDepthKey"],
                  format[@"AVLinearPCMIsNonInterleaved"]
                  ];
    }
    else {
        if (_micOutputFile) {
            
            AVAudioFormat *format = [_micOutputFile processingFormat];
            result = [NSString stringWithFormat:@"%d ch %.0f %d %@ %@",
                      (unsigned int)format.streamDescription->mChannelsPerFrame,
                      format.streamDescription->mSampleRate,
                      (unsigned int)format.streamDescription->mBitsPerChannel,
                      format.standard ? @"Float32-std" : @"std NO",
                      format.interleaved ? @"inter" : @"non-interleaved"
                      ];
            
        }
        
    }
    NSLog(@"%s %@",__func__,result);
    return result;
}


#pragma mark - microphone

-(void)micOn {
    
    [self micInit];
    [_audioRecorder record];
    _hasContent = YES;
    [self startMeteringTimer];
    _micIsRecording = YES;
}

-(void)micOff {
    [_audioRecorder stop];
    [self.meteringTimer invalidate];
    _micIsRecording = NO;
}


-(void)micInit {
    
    if (!_micOutputFileURL)
        [self newRecording];

    AVAudioChannelLayout *layout = [[AVAudioChannelLayout alloc] initWithLayoutTag:kAudioChannelLayoutTag_Stereo];
    AVAudioFormat* micFormat = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatFloat32 sampleRate:44100. interleaved:NO channelLayout:layout];
    
    NSError *error;
    self.audioRecorder = [[AVAudioRecorder alloc] initWithURL:_micOutputFileURL settings:[micFormat settings] error:&error];
    
    _audioRecorder.meteringEnabled = _useMetering;
    
    [_audioRecorder prepareToRecord];
    
    if (_useMetering)
    {
//        self.meterSamples = [NSMutableArray new];
        self.meterSamples = [@[[@[] mutableCopy],[@[] mutableCopy] ] mutableCopy];
        self.meterPeakSamples = [@[
                               [@[] mutableCopy],
                               [@[] mutableCopy] ] mutableCopy];

    }
}


// load loop buffer

-(void)micRecordingBuffer {
    
    if (_micOutputFileURL && _hasContent){
        
        NSError *error;
        AVAudioFile *micLoopFile = [[AVAudioFile alloc] initForReading:_micOutputFileURL error:&error];
        
        _micLoopBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:[micLoopFile processingFormat] frameCapacity:(AVAudioFrameCount)[micLoopFile length]];
        
        NSAssert([micLoopFile readIntoBuffer:_micLoopBuffer error:&error], @"couldn't read LoopFile into buffer, %@", [error localizedDescription]);
        
        [self logAudioFormat:[micLoopFile processingFormat]];
    }
}


#pragma mark - engine properties for players

- (BOOL)micPlayerIsPlaying {
    return _micPlayer.isPlaying;
}

- (void)setOutputVolume:(float)outputVolume {
    _engine.mainMixerNode.outputVolume = outputVolume;
}

- (float)outputVolume {
    return _engine.mainMixerNode.outputVolume;
}

-(void)setMicPlayerFramePosition:(AVAudioFramePosition)micPlayerFramePosition {
    _micPlayerFramePostion = micPlayerFramePosition;
//    [self playSeekingAudioFileAtFramPosition:_micPlayerFramePostion];
}

-(AVAudioFramePosition)micPlayerFramePostion {
    return [[_micPlayer lastRenderTime] sampleTime];
}

-(void)changeProgressOfSeekingAudioFile:(CGFloat)progress {
    
//    AVAudioFramePosition fileLength = seekingAudioFile.length;
//    AVAudioFramePosition readPosition = progress * fileLength;
//    if (_micPlayer.playing) {
//        [self playSeekingAudioFileAtFramPosition:readPosition];
//    }
    
}

#pragma mark - NOT USED BELOW
#pragma mark - Play Seeking methods
// progress of playback
//-(void)setProgressOfSeekingAudioFile:(CGFloat)progressSeekingAudioFile {
//    _progressSeekingAudioFile = progressSeekingAudioFile;

-(void)setProgressSeekingAudioFile:(CGFloat)progressSeekingAudioFile
{
    _progressSeekingAudioFile = progressSeekingAudioFile;
}


#pragma mark - connect disconnect

-(void)connectMicToMixer:(AVAudioMixerNode *)mixer
{
    //[self micRecordingBuffer];
    //    [self startEngine];
    [_engine connect: _micPlayer to:mixer format:_micLoopBuffer.format];
}
-(void)connectMicToMixer
{
    [self connectMicToMixer:[_engine mainMixerNode]];
}
-(void)disconnectToMixer
{
    
}
-(void)disconnectMicToMixer
{
    [_engine disconnectNodeInput: _micPlayer];
}

#pragma mark - metering

-(void)startMeteringTimer
{
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [_audioEngineDelegate meterSamples:@[@(0.2),@(0.14)] andDuration:0.15];  // get somethng onthe board
//    });
    self.lastMeterTimeStamp = [NSDate date];
    self.meteringTimer = [NSTimer timerWithTimeInterval:0.05 target:self selector:@selector(meteringTimerFired:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_meteringTimer forMode:NSRunLoopCommonModes];

}

-(void)meteringTimerFired:(NSTimer*)timer {
    if (timer.valid) {
        
        NSTimeInterval meteringInterval = 0.28;
        
//        The current peak power, in decibels, for the sound being recorded. A return value of 0 dB indicates full scale, or maximum power; a return value of -160 dB indicates minimum power (that is, near silence).
        // but am gonna limit to 130
        // The sampl
        
        [self.audioRecorder updateMeters];
        
//        NSLog(@" [%.3f] peak %.3f",peakNormalizedValue,peakSample);

        float maxDB = 160.0f;
        float avgNormalizedValue = 0.0;// ratio 0 - 1.0
        float avgSample = 0.0f;
        
        // Channel 1
        
        avgSample = [self.audioRecorder averagePowerForChannel:0];
        avgSample -= 68;
        if (avgSample > 0 )
            avgNormalizedValue = 1.00f;
        else {
            avgNormalizedValue = (maxDB + avgSample) / maxDB;
        }
        [_meterSamples[0] addObject:@(avgNormalizedValue)];
        
        avgSample = [self.audioRecorder peakPowerForChannel:0];
        avgSample -= 68;
        if (avgSample > 0 )
            avgNormalizedValue = 1.00f;
        else {
            avgNormalizedValue = (maxDB + avgSample) / maxDB;
        }
        [_meterPeakSamples[0] addObject:@(avgNormalizedValue)];

        
        // Channel 2
        avgSample = [self.audioRecorder averagePowerForChannel:1];
        avgSample -= 68;
        if (avgSample > 0 )
            avgNormalizedValue = 1.00f;
        else {
            avgNormalizedValue = (maxDB + avgSample) / maxDB;              // sample of (-45) + 160 = 115   160 + (-158) = 2/160 = 0.0125
        }
        [_meterSamples[1] addObject:@(avgNormalizedValue)];
        
        avgSample = [self.audioRecorder peakPowerForChannel:1];
        avgSample -= 68;
        if (avgSample > 0 )
            avgNormalizedValue = 1.00f;
        else {
            avgNormalizedValue = (maxDB + avgSample) / maxDB;
        }
        [_meterPeakSamples[1] addObject:@(avgNormalizedValue)];

        
        NSTimeInterval timedMeter =  [_lastMeterTimeStamp timeIntervalSinceNow];
        
        if (timedMeter <  - meteringInterval) {
            
//            [_scrubberBufferController meterChannelSamples:_meterSamples[0] samplesForSecondChannel:_meterSamples[1] andDuration:-timedMeter forTrackId:self.scrubberTrackId];
            
            
            [_scrubberBufferController  meterChannelSamplesWithAverages:_meterPeakSamples[0] averageSamples:_meterSamples[0]
                                                        channel2Samples:_meterPeakSamples[1] averageSamples2:_meterSamples[1]
                                                            andDuration:-timedMeter
                                                             forTrackId:_scrubberTrackId
             ];
             
            
            _meterSamples[0] = [@[] mutableCopy];
            _meterSamples[1] = [@[] mutableCopy];
            
            _meterPeakSamples[0] = [@[] mutableCopy];
            _meterPeakSamples[1] = [@[] mutableCopy];

            self.lastMeterTimeStamp = [NSDate date];
        }
    }
}

//        NSLog(@"time  %.3f",timedMeter);


//        float peakSample = [self.audioRecorder peakPowerForChannel:0];
//        float peakNormalizedValue = 0.0;// ratio 0 - 1.0
//        if (peakSample > 0 )
//            peakNormalizedValue = 1.00f;  // full power
//        else
//            peakNormalizedValue = (160.0 + peakSample) / 160.00f;  // sample of (-45) = 115   160 + (-158) = 2 = 0.0125
//        [_meterSamples addObject:@(peakNormalizedValue)];
//


@end
