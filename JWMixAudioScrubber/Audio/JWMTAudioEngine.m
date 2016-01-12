//
//  ClipAudioEngine.m
//  JamWIthT
//
//  Created by JOSEPH KERR on 9/26/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

// from JWRecordJamViewController all audio engine stuff

#import "JWMTAudioEngine.h"
@import AVFoundation;
#import "JWAudioRecorderController.h"
#import "JWPlayerFileInfo.h"

@interface JWMTAudioEngine () {
    NSURL* _finalRecordingOutputURL;
    AVAudioFile* _finalRecordingOutputFile;
    BOOL _suspendPlayAlll;
    dispatch_queue_t _bufferReceivedQueue;
}
@property (nonatomic) NSURL *trimmedURL;
@property (nonatomic) NSURL *fiveSecondURL;
@property (strong, nonatomic) NSArray *mixerplayerNodeList; // saves playerNode list while play mix
@property (nonatomic,strong)  NSMutableDictionary *scrubberTrackIds;
@property (nonatomic,strong) id <JWScrubberBufferControllerDelegate> scrubberBufferController;
@property (nonatomic) NSMutableIndexSet *activePlayersIndex;
@property (nonatomic) NSMutableIndexSet *activeRecorderIndex;
@property (nonatomic) AVAudioPCMBuffer *fiveSecondBuffer;
@property (nonatomic) BOOL needMakeConnections;
@end


@implementation JWMTAudioEngine

-(instancetype)init {
    if (self = [super init]) {
        _activePlayersIndex = [NSMutableIndexSet new];
        _activeRecorderIndex = [NSMutableIndexSet new];
        _scrubberTrackIds = [@{} mutableCopy];
    }
    return self;
}

-(instancetype)initWithPrimaryFileURL:(NSURL*)primaryFileURL fadeInURL:(NSURL*)fadeInFileURL delegate:(id <JWMTAudioEngineDelgegate>) engineDelegate {
    if (self = [super init]) {
        self.trimmedURL = primaryFileURL;
        self.fiveSecondURL = fadeInFileURL;
        self.engineDelegate = engineDelegate;

        [self initializeAudioConfig];
    }
    return self;
}

-(void)initializeAudioConfig {
    _activePlayersIndex = [NSMutableIndexSet new];
    _activeRecorderIndex = [NSMutableIndexSet new];
    _scrubberTrackIds = [@{} mutableCopy];
    [self loadPlayerNodeData];
}

-(void)initializeAudio {
    [self initAVAudioSession];
    [self setupAVEngine];
}

/*
 stopPlayersForInterruption
 
 stop all players and remove taps
 */

- (void)stopPlayersForInterruption
{
    [super stopPlayersForInterruption];
    NSLog(@"%s",__func__);
    // leave it to subclasses
    for (JWPlayerNode* pn in self.activePlayerNodes)
    {
        [pn stop];
        NSLog(@"%s audioPlayerNode STOP",__func__);
    }
    
    if (_scrubberTrackIds[@"mixer"]) {
        // remove VAB TAP on mixer
        AVAudioMixerNode* mainMixer = [self.audioEngine mainMixerNode];
        [mainMixer removeTapOnBus:0];
        NSLog(@"REMOVED AudioVidual Tap");
    }
    
}


#pragma mark - player node data

-(void)loadPlayerNodeData {
    [self readPlayerNodeList];
    if (_playerNodeList == nil) {
        NSLog(@"%s no list creating new one ",__func__ );
//        [self defaultPlayerNodeList];
        [self defaultPlayerNodeListOnePlayerOneRecorder];
    }
}

-(void)defaultPlayerNodeList {
    _playerNodeList =
    [@[
       [@{@"title":@"Player node 1",
          @"type":@(JWMixerNodeTypePlayer),
          @"name":@"playernode1",
          @"volumevalue":@(0.50),
          @"panvalue":@(0.50),
          } mutableCopy],
       [@{@"title":@"Player Recorder node 2",
          @"type":@(JWMixerNodeTypePlayerRecorder),
          @"name":@"playerrecordernode1",
          @"volumevalue":@(0.50),
          @"panvalue":@(0.50),
          } mutableCopy],
       [@{@"title":@"Mixer Player node3",
          @"type":@(JWMixerNodeTypeMixerPlayerRecorder),
          @"name":@"mixerplayerrecordere3",
          @"volumevalue":@(0.50),
          @"panvalue":@(0.50),
          } mutableCopy]
       ] mutableCopy];
}
-(void)defaultPlayerNodeListPlayMix {
    _playerNodeList =
    [@[
       [@{@"title":@"mixerplayernode1",
          @"type":@(JWMixerNodeTypeMixerPlayer),
          @"loops":@(NO),
          @"volumevalue":@(0.50),
          @"panvalue":@(0.50),
          } mutableCopy]
       ] mutableCopy];
}
-(void)defaultPlayerNodeListTwoPlayer {
    _playerNodeList =
    [@[
       [@{@"title":@"playernode1",
          @"type":@(JWMixerNodeTypePlayer),
          @"volumevalue":@(0.50),
          @"panvalue":@(0.50),
          } mutableCopy],
       [@{@"title":@"playernode2",
          @"type":@(JWMixerNodeTypePlayer),
          @"volumevalue":@(0.50),
          @"panvalue":@(0.50),
          } mutableCopy]
       ] mutableCopy];
}
-(void)defaultPlayerNodeListOnePlayer {
    _playerNodeList =
    [@[
       [@{@"title":@"playernode1",
          @"type":@(JWMixerNodeTypePlayer),
          @"volumevalue":@(0.50),
          @"panvalue":@(0.50),
          } mutableCopy],
       ] mutableCopy];
}
-(void)defaultPlayerNodeListOnePlayerOneRecorder {
    _playerNodeList =
    [@[
       [@{@"title":@"playernode1",
          @"type":@(JWMixerNodeTypePlayer),
          @"volumevalue":@(0.50),
          @"panvalue":@(0.50),
          } mutableCopy],
       [@{@"title":@"Player Recorder node 2",
          @"type":@(JWMixerNodeTypePlayerRecorder),
          @"name":@"playerrecordernode1",
          @"volumevalue":@(0.50),
          @"panvalue":@(0.50),
          } mutableCopy],
       ] mutableCopy];
}


#pragma mark - VAB listeners

-(void)registerController:(id <JWScrubberBufferControllerDelegate> )myScrubberContoller withTrackId:(NSString*)trackId
 forPlayerRecorderAtIndex:(NSUInteger)index
{
    if ([_playerNodeList count] > index) {
        NSDictionary *playerNodeInfo = _playerNodeList[index];
        JWMixerNodeTypes nodeType = [self typeForNodeAtIndex:index];

        // PLAYER RECORDER
        if (nodeType == JWMixerNodeTypePlayerRecorder) {
            JWAudioRecorderController *rc = playerNodeInfo[@"recorderController"];
            [rc registerController:myScrubberContoller withTrackId:trackId forPlayerRecorder:@"recorder"];
        }
        
        // PLAYER
        else if (nodeType == JWMixerNodeTypePlayer) {
            
        }
        
        // MIXER PLAYER
        else if (nodeType == JWMixerNodeTypeMixerPlayerRecorder) {
            id nodename = playerNodeInfo[@"name"];
            if (nodename){
                _scrubberTrackIds[nodename] = trackId;
            }
            // last register called uses tha controller by all
            _scrubberBufferController = myScrubberContoller;
        }
    }

    [self initBufferReceiveQueue];
}

-(void)registerController:(id <JWScrubberBufferControllerDelegate> )myScrubberContoller withTrackId:(NSString*)trackId
        forPlayerRecorder:(NSString*)player
{
    if ([player isEqualToString:@"player1"]) {
        
        [self registerController:myScrubberContoller withTrackId:trackId forPlayerRecorderAtIndex:0];

    } else if ([player isEqualToString:@"player2"]) {
    } else if ([player isEqualToString:@"mixer"]) {
        // LOCAL used mainly for mixer as it does not have a playerNode to register forPlayerRecorderAtIndex
        // last register called uses tha controller by all
        _scrubberBufferController = myScrubberContoller;
        _scrubberTrackIds[player] = trackId;
        // Is a local controller

    } else if ([player isEqualToString:@"tap1"]) {
    } else if ([player isEqualToString:@"tap2"]) {
    } else if ([player isEqualToString:@"recorder"]) {
        // THIS would be used if a recorder was implemented as a Install TAP on INPUT node
        // Here, will set the first Player recorder playernode now
        for (int index = 0; index < [_playerNodeList count]; index++) {
            if ([self typeForNodeAtIndex:index] == JWMixerNodeTypePlayerRecorder) {
                [self registerController:myScrubberContoller withTrackId:trackId forPlayerRecorderAtIndex:index];
                _scrubberTrackIds[player] = trackId;
                break;
            }
        }
    }
    
    [self initBufferReceiveQueue];
}

-(void)initBufferReceiveQueue {
    if (_bufferReceivedQueue == nil) {
        _bufferReceivedQueue =
        dispatch_queue_create("bufferReceivedAE",
                              dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL,QOS_CLASS_USER_INTERACTIVE, 0));
    }
}


#pragma mark player node file data: urls,buffers and files

-(void) setPlayerNodeFileURL:(NSURL*)fileURL atIndex:(NSUInteger)index  {
    
    [self setPlayerNodeFileURLString:[fileURL path] atIndex:index];
}

-(void) setPlayerNodeFileURLString:(NSString*)stringURL atIndex:(NSUInteger)index {
    if (stringURL && [_playerNodeList count] > index) {
        NSMutableDictionary *playerNodeInfo =  _playerNodeList[index];
        playerNodeInfo[@"fileURLString"] = stringURL ;
    }
}

-(NSURL*) playerNodeFileURLAtIndex:(NSUInteger)index {
    NSURL *result = nil;
    if ([_playerNodeList count] > index) {
        id fileURLString = _playerNodeList[index][@"fileURLString"];
        if (fileURLString)
            result = [NSURL fileURLWithPath:fileURLString];
    }
    return result;
}

-(AVAudioPCMBuffer*) audioBufferForPlayerNodeAtIndex:(NSUInteger)index {
    AVAudioPCMBuffer *result = nil;
    if ([_playerNodeList count] > index) {
        id buffer = _playerNodeList[index][@"audiobuffer"];
        if (buffer && buffer != [NSNull null])
            result = buffer;
    }
    return result;
}

-(AVAudioFile*) audioFileForPlayerNodeAtIndex:(NSUInteger)index {
    AVAudioFile *result = nil;
    if ([_playerNodeList count] > index) {
        id file = _playerNodeList[index][@"audiofile"];
        if (file && file != [NSNull null])
            result = file;
    }
    return result;
}


#pragma mark public setters getters

- (void) setClipEngineDelegate:(id<JWMTAudioEngineDelgegate>)engineDelegate {
    _engineDelegate = engineDelegate;
    self.delegate = _engineDelegate;
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

-(NSArray*)activePlayerNodes {
    __block NSMutableArray *nodes = [[NSMutableArray alloc] initWithCapacity:[_playerNodeList count]];
    
//    [_activePlayersIndex enumerateIndexesUsingBlock:^(NSUInteger idx,BOOL *stop){
//        [nodes addObject:_playerNodes[idx]];
//    }];

    
    [_activePlayersIndex enumerateIndexesUsingBlock:^(NSUInteger idx,BOOL *stop){
        id pn = [self playerForNodeAtIndex:idx];
        if (pn) {
            [nodes addObject:pn];
        }
    }];

    
    if ([nodes count] == 0) {
        NSLog(@"%s %ld activeNodes",__func__,(unsigned long)[nodes count]);
    }
    return [NSArray arrayWithArray:nodes];
}


//TODO: added this
-(NSArray*)activeRecorderNodes {
    __block NSMutableArray *nodes = [[NSMutableArray alloc] initWithCapacity:[_playerNodeList count]];
    
    //    [_activePlayersIndex enumerateIndexesUsingBlock:^(NSUInteger idx,BOOL *stop){
    //        [nodes addObject:_playerNodes[idx]];
    //    }];
    
    
    [_activeRecorderIndex enumerateIndexesUsingBlock:^(NSUInteger idx,BOOL *stop){
        id pn = [self recorderForPlayerNodeAtIndex:idx];
        if (pn) {
            [nodes addObject:pn];
        }
    }];
    
    
    return [NSArray arrayWithArray:nodes];
}


-(JWMixerNodeTypes)typeForNodeAtIndex:(NSUInteger)index {
    
    JWMixerNodeTypes result = 0;
    if ([_playerNodeList count] > index) {
        NSDictionary *playerNodeInfo = _playerNodeList[index];
        
        id type = playerNodeInfo[@"type"];
        if (type)
            result = [(NSNumber*)type integerValue];
    }
    return result;
}

-(NSURL*)mixOutputFileURL {
    return _finalRecordingOutputURL;
}

// Old should use playerNode at index

-(NSURL*) playerNode1FileURL {
    return [self playerNodeFileURLAtIndex:0];
}

-(NSURL*) playerNode2FileURL {
    return [self playerNodeFileURLAtIndex:1];
}

-(JWPlayerNode*) playerNode1 {
    
    return [self playerForNodeAtIndex:0];
    
//    JWPlayerNode* result = nil;
//    NSUInteger index = 0;
//    if ([_playerNodeList count] > index) {
//        result = _playerNodeList[index][@"player"];
//    }
//    return result;
}

-(JWPlayerNode*) playerNode2 {
    return [self playerForNodeAtIndex:1];

//    JWPlayerNode* result = nil;
//    NSUInteger index = 1;
//    if ([_playerNodeList count] > index) {
//        result = _playerNodeList[index][@"player"];
//    }
//    return result;
}

-(JWPlayerNode*) playerNode3 {
    return [self playerForNodeAtIndex:2];
}

#pragma mark - helper

-(void)fileURLs {
    // .caf = CoreAudioFormat
    NSString *cacheKey = [[NSUUID UUID] UUIDString];
    NSString *thisfName = @"finalRecording";
    NSString *uniqueFname = [NSString stringWithFormat:@"%@_%@.caf",thisfName,cacheKey?cacheKey:@""];
    NSString *docsDir = [NSHomeDirectory() stringByAppendingPathComponent:  @"Documents"];
    
    _finalRecordingOutputURL =[NSURL URLWithString:[docsDir stringByAppendingPathComponent:uniqueFname]];
}

#pragma mark - Commands

- (void)startEngine {
    [super startEngine];
}


//-(void)stopAll {
//    
//    for (JWPlayerNode* pn in self.activePlayerNodes)
//    {
//        [pn stop];
//        NSLog(@"%s audioPlayerNode STOP",__func__);
//    }
//    
//    if (_scrubberTrackIds[@"mixer"]) {
//        // remove VAB TAP on mixer
//        AVAudioMixerNode* mainMixer = [self.audioEngine mainMixerNode];
//        [mainMixer removeTapOnBus:0];
//        NSLog(@"REMOVED AudioVidual Tap");
//    }
//    
//    [self refresh];
//}

- (void)pausePlayingAll {
    for (JWPlayerNode* pn in self.activePlayerNodes)
    {
        [pn pause];
        NSLog(@"%s audioPlayerNode PAUSE",__func__);
    }
}

-(void) reMix {
    [self initializeAudioConfig];
    [self setPlayerNodeFileURL:_finalRecordingOutputURL atIndex:0];
    [self setupAVEngine];
}

-(void)pauseAlll {
    _suspendPlayAlll = YES; // for VAB
}

-(void)resumeAlll {
    _suspendPlayAlll = NO; // for VAB
}

-(void) refresh {
    if (_needMakeConnections) {
        [self makeEngineConnections];
    }
}

/*
 stopPlayingTrack1 - older model, but adapted to new model
 pausePlayingTrack1 - older model, but adapted to new model
 
 */
- (void)stopPlayingTrack1 {
    [self.playerNode1 stop];
}

- (void)pausePlayingTrack1 {
    [self.playerNode1 pause];
}

#pragma mark - player nodes

/*
 createPlayerNodes
 creates players for those ha t need it
 caution: player and recorderController are added to dict )non serilaizaable objects
 */
-(void)createPlayerNodes {
    [_activePlayersIndex removeAllIndexes];
    self.playerNodes = nil;
    
    //NSMutableArray *mPlayerNodes = [NSMutableArray new];
    NSUInteger index = 0;
    
    for (NSMutableDictionary *playerNodeInfo in _playerNodeList) {
        JWMixerNodeTypes nodeType = [self typeForNodeAtIndex:index];
        if (nodeType == JWMixerNodeTypePlayer || nodeType == JWMixerNodeTypePlayerRecorder || nodeType == JWMixerNodeTypeMixerPlayer) {
            JWPlayerNode *pn = [JWPlayerNode new];
            pn.volume = 0.4f;
            //[mPlayerNodes addObject:pn];
            playerNodeInfo[@"player"] = pn;  
            if (nodeType == JWMixerNodeTypePlayerRecorder) {
                id recorder = playerNodeInfo[@"recorderController"];
                if (recorder == nil) {
                    JWAudioRecorderController *rc = [[JWAudioRecorderController alloc] initWithMetering:YES];
                    playerNodeInfo[@"recorderController"] = rc;
                }
            }
        } else {
            // [mPlayerNodes addObject:[NSNull null]];
        }
        index++;
    }
    
    //self.playerNodes = [NSArray arrayWithArray:mPlayerNodes];
}

-(void)teeUpAudioBuffers {
    // Player node list drives population of audiofiles and audiobuffers
    // self.playernodes will play them they will set outside of here
    // the loop handles  _audioBufferFromFile but not _fiveSecondBuffer
    NSUInteger index = 0;

    for (NSMutableDictionary *playerNodeInfo in _playerNodeList) {
        NSURL *fileURL = [self playerNodeFileURLAtIndex:index];
        if (fileURL) {
            NSError* error = nil;
            AVAudioFile *audioFile = [[AVAudioFile alloc] initForReading:fileURL error:&error];
            if (error) {
                NSLog(@"%@",[error description]);
                [playerNodeInfo removeObjectForKey:@"audiofile"];
                [playerNodeInfo removeObjectForKey:@"audiobuffer"];
            } else {
                
                // CREATE and READ buffer
                AVAudioPCMBuffer *audioBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:audioFile.processingFormat
                                                                              frameCapacity:(UInt32)audioFile.length];
                [audioFile readIntoBuffer:audioBuffer error:&error];
                
                // ASSIGN BUFFER
                if (audioBuffer)
                    //TODO: get rid of memory hog
                    playerNodeInfo[@"audiobuffer"] = audioBuffer;
                else
                    [playerNodeInfo removeObjectForKey:@"audiobuffer"];
                
                // ASSIGN FILE
                playerNodeInfo[@"audiofile"] = audioFile;

//                NSLog(@"%s file length %lld buffer length %u",__func__,audioFile.length,audioBuffer.frameLength);
            }
        } else {
            [playerNodeInfo removeObjectForKey:@"audiofile"];
            [playerNodeInfo removeObjectForKey:@"audiobuffer"];
        }
        
        index++;
    }
    
}

-(void)teeUpAudioBufferFadeIn {
    if (_fiveSecondURL) {
        
        NSError* error = nil;
        
        AVAudioFile* audioFile = [[AVAudioFile alloc] initForReading:_fiveSecondURL error:&error];
        if (error == nil) {
            _fiveSecondBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:audioFile.processingFormat
                                                              frameCapacity:(UInt32)audioFile.length];
            
            [audioFile readIntoBuffer:_fiveSecondBuffer error:&error];
        }
        
        if (error) {
            NSLog(@"%@",[error description]);
        }
    }

}


#pragma mark - engine setup

-(void)setupAVEngine {
    
    [self fileURLs];
    [self createPlayerNodes];
    [self createEngineAndAttachNodes];
    [self teeUpAudioBuffers];
    [self teeUpAudioBufferFadeIn];
    [self makeEngineConnections];
    [self startEngine];
}

- (void)createEngineAndAttachNodes {
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
    
    
    // Attach all available not just active ones
    
    for (int i = 0; i < [_playerNodeList count]; i++)
    {
        id pn = [self playerForNodeAtIndex:i];
        if (pn) {
            
            [self.audioEngine attachNode:pn];
            NSLog(@"%s audioPlayerNode ATTACH",__func__);
        }
        
    }

}

- (void)makeEngineConnections {
    /*  The engine will construct a singleton main mixer and connect it to the outputNode on demand,
     when this property is first accessed. You can then connect additional nodes to the mixer.
     
     By default, the mixer's output format (sample rate and channel count) will track the format
     of the output node. You may however make the connection explicitly with a different format. */
    
    // get the engine's optional singleton main mixer node
    AVAudioMixerNode *mainMixer = [self.audioEngine mainMixerNode];
    
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
    
    // ITERATE through player list looking for players
    
    NSUInteger nNodes = [self.playerNodeList count];
    for (int index = 0; index < nNodes; index++) {

        JWMixerNodeTypes nodeType = [self typeForNodeAtIndex:index];
        if (nodeType == JWMixerNodeTypePlayer || nodeType == JWMixerNodeTypePlayerRecorder || nodeType == JWMixerNodeTypeMixerPlayer) {
            // loops, delays and volume attrs not cosidered here
            
            AVAudioPCMBuffer *audioBuffer = [self audioBufferForPlayerNodeAtIndex:index];
            if (audioBuffer) {
                JWPlayerNode* playerNode = [self playerForNodeAtIndex:index];
                
                if (playerNode)
                    [self.audioEngine connect:playerNode to:mainMixer format:audioBuffer.format];
                
            } else {
                NSLog(@"%s NO audioBuffer player at index %d perhaps try using audioFile for format ",__func__,index);
            }
        }
    }
    
    self.needMakeConnections = NO;

}


#pragma mark - engine actions

/*
 playAlll
 
 play all available players
 */

-(void)playAlll {
    [self playAlll:NO];  // no, not recording
}


/*
 recording - whether recording mix
 */
-(void)playAlll:(BOOL)recording {
   
    NSLog(@"%s %@",__func__,[_playerNodeList description]);
    
    NSUInteger index = 0;
    for (NSDictionary *playerNodeInfo in _playerNodeList) {
        JWMixerNodeTypes nodeType = [self typeForNodeAtIndex:index];
        
        if (nodeType == JWMixerNodeTypePlayer || nodeType == JWMixerNodeTypePlayerRecorder || nodeType == JWMixerNodeTypeMixerPlayer) {
            
            AVAudioPCMBuffer *audioBuffer = [self audioBufferForPlayerNodeAtIndex:index];
            if (audioBuffer == nil)
            {
                continue; // not interested
            }
            // OTHERWISE we are ready to go with a buffer which is what we are scheduling
            // including obtaining delay time information
            
            // PLAYNODE Config
            BOOL loops = NO;
            NSTimeInterval secondsDelay = 0;
            AVAudioTime *delayAudioTime = nil;
            float volume = 0.25;
            id obj = nil;
            if (recording  && index == 0) {
                // override loops on recording and track 0
                loops = NO;
            } else {
                obj = playerNodeInfo[@"loops"];
                if (obj)
                    loops = [obj boolValue];
            }
            obj = playerNodeInfo[@"volumevalue"];
            if (obj)
                volume = [obj floatValue];
            obj = playerNodeInfo[@"delay"];
            if (obj) {
                secondsDelay = [obj doubleValue];
                // Create AVAudioTime to pass to atTime
                AVAudioFormat *format = [audioBuffer format];
                delayAudioTime = [AVAudioTime timeWithSampleTime:(secondsDelay * format.sampleRate) atRate:format.sampleRate];
            }
            
            NSLog(@"%s loops %@ secondsDelay %.3f",__func__,@(loops),secondsDelay);
            
           // RECONCILE Audiofile and Audio Buffer

            AVAudioFile *audioFile = [self audioFileForPlayerNodeAtIndex:index]; // AVAudioFile

            JWPlayerNode* playerNode = [self playerForNodeAtIndex:index];
            [_activePlayersIndex addIndex:index];
            
//            JWPlayerNode* playerNode =  (JWPlayerNode*)_playerNodes[playerNodeIndex];
//            [_activePlayersIndex addIndex:playerNodeIndex];
//            playerNodeIndex++;
            
            playerNode.audioFile = audioFile;
            
            //playerNode.volume = volume;  //volume already set on player by user

            
            // Build the completion handler
            
            void (^playerCompletion)(void) = ^{
                
                NSLog(@"Audio Completed for playerAtIndex %ld",index);
                if (recording  && index == 0) {
                    AVAudioMixerNode* mainMixer = [self.audioEngine mainMixerNode];
                    [mainMixer removeTapOnBus:0];
                    
                    // Notify delegate
                    dispatch_sync(dispatch_get_main_queue(), ^() {
                        if ([_engineDelegate respondsToSelector:@selector(mixRecordingCompleted)])
                            [_engineDelegate mixRecordingCompleted];
                    });
                    
                } else {
                    // Try not to notify both
                    // Notify delegate
                    dispatch_sync(dispatch_get_main_queue(), ^() {
                        if ([_engineDelegate respondsToSelector:@selector(completedPlayingAtPlayerIndex:)])
                            [_engineDelegate completedPlayingAtPlayerIndex:index];
                        
                    });
                }
            };
        
        
            NSUInteger option = 0;

            if (option == 0) {
                // schedule the file
                // doesnt loop
                
                [playerNode scheduleFile:audioFile atTime:delayAudioTime  completionHandler:playerCompletion];
                
            } else if (option == 1) {
                
                // SCHEDULE THE BUFFER
                
                AVAudioPlayerNodeBufferOptions boptions = loops? AVAudioPlayerNodeBufferLoops : 0;
                
                [playerNode scheduleBuffer:audioBuffer atTime:delayAudioTime options:boptions completionHandler:playerCompletion];
            }
        }
        
        index++;
        
    }
    
    // do not add mixer vab if recording
    
    if (recording == NO  &&  _scrubberTrackIds[@"mixer"]) {
        
        // install TAP on mixer to provide visualAudio
        AVAudioMixerNode* mainMixer = [self.audioEngine mainMixerNode];
        
        NSLog(@"%s Installed visual Audio mixer tap",__func__);
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
    
    self.mixerVolume = 1.0;

    for (JWPlayerNode* pn in self.activePlayerNodes)
    {
        [pn play];
        NSLog(@"%s audioPlayerNode PLAY",__func__);
    }
    
}


- (void)playMicRecordedFile
{
    
}

-(void)setMicPlayerFramePosition:(AVAudioFramePosition)micPlayerFramePosition
{
}


-(void)changeProgressOfSeekingAudioFile:(CGFloat)progress {
    
//    AVAudioFramePosition fileLength = seekingAudioFile.length;
//    AVAudioFramePosition readPosition = progress * fileLength;
//    
//    if (_micPlayer.playing) {
//        [self playSeekingAudioFileAtFramPosition:readPosition];
//    }
    
}


-(void)playAlllStartSeconds:(NSTimeInterval)secondsIn  {

    //[self playAlllWithOptions:0 insetSeconds:secondsIn recording:NO];
}
//TODO: added this
-(void)scheduleAllStartSeconds:(NSTimeInterval)secondsIn  {
    
    [self scheduleAllWithOptions:0 insetSeconds:secondsIn recording:NO];
}

-(void)scheduleAllStartSeconds:(NSTimeInterval)secondsIn duration:(NSTimeInterval)duration {
    
    [self scheduleAllWithOptions:0 insetSeconds:secondsIn recording:NO];
}

/*
 playAlllWithOptions

 - insetSeconds  start playing nSeconds In 
 
 all players will read audiofiles nSeconds in from beginning
 nodes with delays will begin reading computed seconds in or have its delay shortened
 
 recording = YES not supported
 
 */
//TODO: changed this

-(void)scheduleAllWithOptions:(NSUInteger)options insetSeconds:(NSTimeInterval)secondsIn recording:(BOOL)recording {
    
//    NSLog(@"%s %.3f secondsin  %@",__func__,secondsIn,[_playerNodeList description]);
    NSLog(@"%s %.3f secondsin  node count %ld",__func__,secondsIn,[_playerNodeList count]);
    
    NSUInteger index = 0;
    for (NSDictionary *playerNodeInfo in _playerNodeList) {
        JWMixerNodeTypes nodeType = [self typeForNodeAtIndex:index];
        
        if (nodeType == JWMixerNodeTypePlayer || nodeType == JWMixerNodeTypePlayerRecorder || nodeType == JWMixerNodeTypeMixerPlayer) {
            
            AVAudioFile *audioFile = [self audioFileForPlayerNodeAtIndex:index]; // AVAudioFile
            if (audioFile == nil)
            {
                if (nodeType == JWMixerNodeTypePlayerRecorder) {
                    [_activeRecorderIndex addIndex:index];
                }
                
                continue; // not interested
            }

            AVAudioFormat *processingFormat = [audioFile processingFormat];
            
            // OTHERWISE we are ready to go with a buffer which is what we are scheduling
            // including obtaining delay time information
            
            // PLAYNODE Config
            BOOL loops = NO;
            NSTimeInterval secondsDelay = 0;
            AVAudioTime *delayAudioTime = nil;
            JWPlayerFileInfo *fileReference = nil;
            float volume = 0.25;
            
            id obj = nil;
            if (recording  && index == 0) {
                // override loops on recording and track 0
                loops = NO;
            } else {
                obj = playerNodeInfo[@"loops"];
                if (obj)
                    loops = [obj boolValue];
            }
            
            obj = playerNodeInfo[@"volumevalue"];
            if (obj)
                volume = [obj floatValue];
            
            obj = playerNodeInfo[@"delay"];
            if (obj) {
                secondsDelay = [obj doubleValue];
                // Create AVAudioTime to pass to atTime
                delayAudioTime = [AVAudioTime timeWithSampleTime:(secondsDelay * processingFormat.sampleRate)
                                                          atRate:processingFormat.sampleRate];
            }

            obj = playerNodeInfo[@"referencefile"];
            if (obj) {
                NSTimeInterval durationSeconds = audioFile.length / processingFormat.sampleRate;
                
                //how far in you want to start playing
                id startInsetValue = obj[@"startinset"];
                float startInset = startInsetValue ? [startInsetValue floatValue] : 0.0;
                
                //how far in you want the track to stop playing
                id endInsetValue = obj[@"endinset"];
                float endInset = endInsetValue ? [endInsetValue floatValue] : 0.0;
                
                fileReference =
                [[JWPlayerFileInfo alloc] initWithCurrentPosition:secondsIn
                                                         duration:durationSeconds
                                                    startPosition:secondsDelay
                                                       startInset:startInset
                                                         endInset:endInset];
            }
            
            BOOL hasAudioToPlay = YES;
            
            // DETERMINE READ POSITION
            AVAudioFramePosition readPosition = 0;
            
            if (secondsDelay > secondsIn) {
                // reduce delay
                delayAudioTime = [AVAudioTime timeWithSampleTime:((secondsDelay - secondsIn) * processingFormat.sampleRate)
                                                          atRate:processingFormat.sampleRate];
            } else {
                
                if (fileReference) {
                    
                    if (fileReference.readPositionInReferencedTrack < 0.0) {
                        NSLog(@"%s fileReference read position negative",__func__);
                        hasAudioToPlay = NO;
                    } else {
                        readPosition = fileReference.readPositionInReferencedTrack *  processingFormat.sampleRate;
                        
                        NSLog(@"%s fileReference dur %.2fs remaining %.2fs read %lld ",__func__,
                              fileReference.duration,
                              fileReference.remainingInTrack,
                              readPosition);
                    }
                    
                } else {
                    
                    // delay Zero, and readIn required, delay < secondsIn , in progress
                    readPosition = (secondsIn - secondsDelay) * processingFormat.sampleRate;
                    
                    // delay 5  seconds in 8 read 3 seconds in
                }
            }
            
            
//            NSLog(@"%s loops %@ secondsDelay %.3f secondsin %.3f read %lld ",__func__,@(loops),secondsDelay,secondsIn,readPosition);
            
            if (hasAudioToPlay) {
                // GET The player for this audio
//                JWPlayerNode* playerNode =  (JWPlayerNode*)_playerNodes[playerNodeIndex];
//                [_activePlayersIndex addIndex:playerNodeIndex];
//                playerNodeIndex++;
                
                
                JWPlayerNode* playerNode =  playerNodeInfo[@"player"];
                [_activePlayersIndex addIndex:index];
                
                playerNode.audioFile = audioFile;
                
                // Final Player completion
                void (^finalPlayerCompletion)(void) = ^{
                    NSLog(@"Audio Completed for playerAtIndex %ld",(unsigned long)index);
                    // Notify delegate
                    dispatch_sync(dispatch_get_main_queue(), ^() {
                        if ([_engineDelegate respondsToSelector:@selector(completedPlayingAtPlayerIndex:)])
                            [_engineDelegate completedPlayingAtPlayerIndex:index];
                    });
                };
                
                //playerNode.volume = volume;  //volume already set on player by user
                
                // SCHEDULE THE BUFFER
                
                int option = 1;
                
                // Option one Buffer read
                if (option==1) {
                    // Play buffer One read at position if necessary
                    AVAudioFramePosition fileLength = audioFile.length;
                    AVAudioFrameCount remainingFrameCount = 0;
                    if (fileReference) {
                        remainingFrameCount =  fileReference.remainingInTrack * processingFormat.sampleRate;
                    } else {
                        remainingFrameCount =  (AVAudioFrameCount)(fileLength - readPosition);
                    }
                    AVAudioFrameCount bufferFrameCapacity = remainingFrameCount;
                    
                    // CREATE and READ buffer
                    AVAudioPCMBuffer *readBuffer =
                    [[AVAudioPCMBuffer alloc] initWithPCMFormat: audioFile.processingFormat frameCapacity: bufferFrameCapacity];
                    
                    // READ from the File
                    NSError *error = nil;
                    audioFile.framePosition = readPosition;
                    
                    if ([audioFile readIntoBuffer: readBuffer error: &error]) {
                        
                        NSLog(@"FileLength: %lld  %.3f seconds. Buffer length %u",(long long)fileLength,
                              fileLength / audioFile.fileFormat.sampleRate, readBuffer.frameLength );
                        
                        [playerNode scheduleBuffer:readBuffer
                                            atTime:delayAudioTime
                                           options:AVAudioPlayerNodeBufferInterrupts
                                 completionHandler:finalPlayerCompletion
                         ];
                        
                    } else {
                        NSLog(@"failed to read audio file: %@", [error description]);
                    }
                }
                
                // Option Buffer by buffer
                else if (option==2) {
                    
                    // Play buffer by buffer starting at read pos  read a portion and play the rest
                    const AVAudioFrameCount kBufferFrameCapacity = 8 * 1024L;  // 8k .1857 seconds at 44100
                    AVAudioPCMBuffer *readBuffer =
                    [[AVAudioPCMBuffer alloc] initWithPCMFormat:audioFile.processingFormat frameCapacity: kBufferFrameCapacity];
                    
                    audioFile.framePosition = readPosition;
                    
                    //    NSLog(@"FileLength: %lld  %.3f seconds ",
                    //          (long long)fileLength, fileLength / seekingAudioFile.fileFormat.sampleRate);
                    
                    NSError *error = nil;
                    
                    if ([audioFile readIntoBuffer: readBuffer error: &error]) {
                        [playerNode scheduleBuffer:readBuffer
                                            atTime:delayAudioTime
                                           options:AVAudioPlayerNodeBufferInterrupts
                                 completionHandler:^{
                                     NSError *error;
                                     AVAudioPCMBuffer *buffer =
                                     [[AVAudioPCMBuffer alloc] initWithPCMFormat:audioFile.processingFormat
                                                                   frameCapacity:(AVAudioFrameCount)audioFile.length];
                                     
                                     if ([audioFile readIntoBuffer: buffer error: &error]) {
                                         [playerNode scheduleBuffer:buffer
                                                             atTime:nil
                                                            options:AVAudioPlayerNodeBufferInterrupts
                                                  completionHandler:finalPlayerCompletion
                                          ];
                                         
                                     } else {
                                         NSLog(@"failed to read audio file: %@", error);
                                     }
                                 }];
                        
                    } else {
                        NSLog(@"failed to read audio file: %@", [error description]);
                    }
                }
                
                // Option Schedule segment
                else if (option==3) {
                    
                    // Simply schedule some sound to play while seeking
                    // Need a way to continue playing to end
                    AVAudioFramePosition fileLength = audioFile.length;
                    AVAudioFrameCount framesToread = 22050; // half second at 44100
                    if ((readPosition + framesToread) > fileLength) {
                        framesToread = (AVAudioFrameCount) (fileLength - readPosition);
                    }
                    
                    // TODO: needs to read the rest
                    [playerNode scheduleSegment:playerNode.audioFile
                                  startingFrame:readPosition
                                     frameCount:framesToread
                                         atTime:delayAudioTime
                              completionHandler:^{
                                  NSLog(@"seeking played segment");
                                  // Now play here until end
                                  
                              }];

                }
                
                // NO OPtion normal play all
                else {
                    
                    AVAudioPCMBuffer *audioBuffer = [self audioBufferForPlayerNodeAtIndex:index];
                    if (audioBuffer == nil)
                    {
                        continue; // not interested
                    }
                    
                    AVAudioPlayerNodeBufferOptions boptions = loops? AVAudioPlayerNodeBufferLoops : 0;
                    
                    [playerNode scheduleBuffer:audioBuffer atTime:delayAudioTime options:boptions completionHandler:finalPlayerCompletion];
                }
            }
        }
        
        index++;
        
    }
    
    // do not add mixer vab if recording
    
    if (recording == NO  &&  _scrubberTrackIds[@"mixer"]) {
        
        // install TAP on mixer to provide visualAudio
        AVAudioMixerNode* mainMixer = [self.audioEngine mainMixerNode];
        
        NSLog(@"%s Installed visual Audio mixer tap",__func__);
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
    
    
}

//TODO: added this
-(BOOL)playAllActivePlayerNodes {
//    NSLog(@"%s", __func__);
    
    if ([self.activePlayerNodes count] > 0) {
        
        self.mixerVolume = 1.0;
        for (JWPlayerNode* pn in self.activePlayerNodes)
        {
            [pn play];
            NSLog(@"%s audioPlayerNode PLAY",__func__);
        }
        
        return YES;
        
    } else {
        NSLog(@"No Active palyer nodes to play.");
        return NO;        
    }
}

-(BOOL)pauseAllActivePlayerNodes {
//    NSLog(@"%s", __func__);
    
    if ([self.activePlayerNodes count] > 0) {
        
        self.mixerVolume = 1.0;
        for (JWPlayerNode* pn in self.activePlayerNodes)
        {
            [pn pause];
            NSLog(@"%s audioPlayerNode PAUSE",__func__);
        }
        
        return YES;
        
    } else {
        NSLog(@"No Active palyer nodes to PAUSE.");
        return NO;
    }
}


-(BOOL)stopAllActivePlayerNodes {
//    NSLog(@"%s", __func__);
    
    if ([self.activePlayerNodes count] > 0) {
        
        for (JWPlayerNode* pn in self.activePlayerNodes)
        {
            [pn stop];
            NSLog(@"%s audioPlayerNode STOP",__func__);
        }
        
        if (_scrubberTrackIds[@"mixer"]) {
            // remove VAB TAP on mixer
            AVAudioMixerNode* mainMixer = [self.audioEngine mainMixerNode];
            [mainMixer removeTapOnBus:0];
            NSLog(@"REMOVED AudioVidual Tap");
        }
        
        [self refresh];
        
        return YES;
        
    } else {
        NSLog(@"No Active palyer nodes to play.");
        return NO;
    }
}


//                @property (nonatomic,readonly) float duration;  // duration playback
//                @property (nonatomic,readonly) float remainingInTrack;
//                @property (nonatomic,readonly) float currentPositionIntrack;
//                @property (nonatomic,readonly) float startPositionInReferencedTrack;
//                @property (nonatomic,readonly) float readPositionInReferencedTrack;


#pragma mark -

/*
 playAllAndRecordIt - will install recordng tap on MIXER
 
 then call playALLL recording YES
 */

-(void)playAllAndRecordIt {
    
    for (JWPlayerNode* pn in self.activePlayerNodes)
    {
        [pn stop];
        [pn reset];
        NSLog(@"%s audioPlayerNode STOP/RESET",__func__);
    }
    
    /*
     Install ONE tap on mixer,  VAB tap and Record to file, in one tap
     VAB tap is ignored in PlayALLL when recording
     */
    
    BOOL useVABTap =  NO;
    id scrubberTrackId = _scrubberTrackIds[@"mixer"];
    if (scrubberTrackId)
        useVABTap =  YES;
    
    // SETP 1 - READY FILE FOR WRITING
    AVAudioMixerNode* mainMixer = [self.audioEngine mainMixerNode];

    NSError *error = nil;
    AVAudioFile *mixerOutputFile =
    [[AVAudioFile alloc] initForWriting:_finalRecordingOutputURL
                               settings:[[mainMixer outputFormatForBus:0] settings]
                                  error:&error];
    
    // SETP 2 - Install TAP
    if (error) {
        NSLog(@"%@",[error description]);
        
    } else {
        [mainMixer installTapOnBus:0 bufferSize:2048 format:[mainMixer outputFormatForBus:0]
                             block:^(AVAudioPCMBuffer* buffer, AVAudioTime* when) {
                                 
                                 if (useVABTap && _suspendPlayAlll == NO) {
                                     dispatch_async(_bufferReceivedQueue, ^{
                                         dispatch_sync(dispatch_get_main_queue(), ^() {
                                             [_scrubberBufferController bufferReceivedForTrackId:_scrubberTrackIds[@"mixer"]
                                                                                          buffer:buffer
                                                                                  atReadPosition:[when sampleTime]];
                                         });
                                     }); //_bufferReceivedQueue
                                 }
                                 
                                 // Write buffer to file
                                 NSError *error;
                                 NSAssert([mixerOutputFile writeFromBuffer:buffer error:&error],
                                          @"error writing buffer data to file, %@", [error localizedDescription]);
                                 
                             }];
        
        NSLog(@"Installed tap to record mix, useVAB %@",useVABTap?@"YES":@"NO");
    }
    
    // SETP 3 - PlayALLL
    
    [self playAlll:YES];  // yes am recording
    
}

/*
 prepareToRecord
 
 */

-(void)prepareToRecord {
    NSInteger index = 0;
    // first recorder playernode now
    NSUInteger nNodes = [self.playerNodeList count];
    for (index = 0; index < nNodes; index++) {
        if (JWMixerNodeTypePlayerRecorder == [self typeForNodeAtIndex:index] ) {
            //TODO: add test for Filr URL (some audio player recorders have audio)
            if ([self playerNodeFileURLAtIndex:index] == nil) {
                // found
                break;
            }
            
        }
    }
    //[self prepareToRecordFromBeginningAtPlayerRecorderNodeIndex:index];
    [self recordWithPlayerRecorderAtNodeIndex:index];
}


-(JWAudioRecorderController*)recorderForPlayerNodeAtIndex:(NSUInteger)pindex {
    JWAudioRecorderController* result;
    if (pindex < [self.playerNodeList count]) {
        NSDictionary *playerNodeInfo = self.playerNodeList[pindex];
        JWMixerNodeTypes nodeType = [self typeForNodeAtIndex:pindex];
        
        // PLAYER RECORDER
        if (nodeType == JWMixerNodeTypePlayerRecorder) {
            id rc = playerNodeInfo[@"recorderController"];
            if (rc) {
                result = (JWAudioRecorderController*)rc;
            }
        }
    }
    return result;
}


/*
 prepareToRecordFromBeginningAtPlayerRecorderNodeIndex
 
 record from beginning with fade in
 
 */

-(void)prepareToRecordFromBeginningAtPlayerRecorderNodeIndex:(NSUInteger)index {
    
    //TODO: changed fade
    [self playAllRecordingFromBeginnigAtIndex:index fadeIn:YES];
}

// play all with fade in from primary
//TODO: get this to work
//In order to play all and record with a fade, i need to get the current position the
//audio is at and i need to check if any crops have been done.  This is so if they are recording
//from the middle of audio it can start there, or if they are recording from the beggining
//of a clipped track, i can use seconds before the clips to fade in.

-(void)playAllRecordingFromBeginnigAtIndex:(NSUInteger)prIndex fadeIn:(BOOL)fade{
    
    NSUInteger index = 0;  // index to playerNodeList
    JWAudioRecorderController *rc = [self recorderForPlayerNodeAtIndex:prIndex];
    
    for (NSDictionary *playerNodeInfo in _playerNodeList) {
        
        if (index == prIndex)
        {
            continue;  // skip the one recording
        }

        JWMixerNodeTypes nodeType = [self typeForNodeAtIndex:index];
        if (nodeType == JWMixerNodeTypePlayer ||
            nodeType == JWMixerNodeTypePlayerRecorder ||
            nodeType == JWMixerNodeTypeMixerPlayer) {
            
            AVAudioPCMBuffer *audioBuffer = [self audioBufferForPlayerNodeAtIndex:index];
            if (audioBuffer == nil)
            {
                continue; // not interested
            }
            // OTHERWISE we are ready to go with a buffer which is what we are scheduling
            // including obtaining delay time information
            
            // PLAYNODE Config
            BOOL loops = NO;
            NSTimeInterval secondsDelay = 0;
            AVAudioTime *delayAudioTime = nil;
            float volume = 0.25;
            id obj = nil;
            if (index == 0) {
                // override loops on recording and track 0
                loops = NO;
            } else {
                obj = playerNodeInfo[@"loops"];
                if (obj) {
                    loops = [obj boolValue];
                }
            }
            obj = playerNodeInfo[@"volumevalue"];
            if (obj) {
                volume = [obj floatValue];
            }
            obj = playerNodeInfo[@"delay"];
            if (obj) {
                secondsDelay = [obj doubleValue];
                // Create AVAudioTime to pass to atTime
                AVAudioFormat *format = [audioBuffer format];
                delayAudioTime = [AVAudioTime timeWithSampleTime:(secondsDelay * format.sampleRate) atRate:format.sampleRate];
            }
            
            NSLog(@"%s loops %@ secondsDelay %.3f",__func__,@(loops),secondsDelay);

            // RECONCILE Audiofile and Audio Buffer

            JWPlayerNode* playerNode = [self playerForNodeAtIndex:index];
            [_activePlayersIndex addIndex:index];
            
//            JWPlayerNode* playerNode =  (JWPlayerNode*)_playerNodes[playerNodeIndex];
//            [_activePlayersIndex addIndex:playerNodeIndex];
//            playerNodeIndex++;

            playerNode.audioFile = [self audioFileForPlayerNodeAtIndex:index]; // AVAudioFile

            
            // SCHEDULE THE BUFFER
            
            if (fade && index == 0) {
                
                NSLog(@"%s _fiveSecondBuffer %u audioBuffer %u",__func__,_fiveSecondBuffer.frameLength,audioBuffer.frameLength );
                // use the volume, ignore delay and loops for the fade scheduling and loop options
                
                self.mixerVolume = 0.0;
                
                //only schedule if framelength of five second buffer is > 0.0
                if (_fiveSecondBuffer.frameLength > 0.0) {
                    
                    // Schedule fade in buffer playing buffer immediatelyfollowing
                    [playerNode scheduleBuffer:_fiveSecondBuffer atTime:nil options:0 completionHandler:^() {
                        // Turn ON microphone
                        [rc record];
                        
                        NSLog(@"Five Second Audio Completed");
                        // Notify delegate
                        dispatch_sync(dispatch_get_main_queue(), ^() {
                            if ([_engineDelegate respondsToSelector:@selector(fiveSecondBufferCompletion)])
                                [_engineDelegate fiveSecondBufferCompletion];
                        });
                    }];

                }
                
                // Schedule full playing buffer
                
                [playerNode scheduleBuffer:audioBuffer atTime:nil options:0 completionHandler:^() {

                    NSLog(@"Audio Completed for playerAtIndex %ld",(unsigned long)index);
                    // Turn OFF microphone
                    [rc stopRecording];
                    
                    // READ File into buffer
                    NSError* error = nil;
                    AVAudioFile *micOutputFile =
                    [[AVAudioFile alloc] initForReading:[rc micOutputFileURL] error:&error];
                    AVAudioPCMBuffer *micOutputBuffer =
                    [[AVAudioPCMBuffer alloc] initWithPCMFormat:micOutputFile.processingFormat
                                                  frameCapacity:(UInt32)micOutputFile.length];
                    NSAssert([micOutputFile readIntoBuffer:micOutputBuffer error:&error],
                             @"error reading into new buffer, %@",[error localizedDescription]);
                    
                    // USER AUDIO obtained read into a buffer teedUP and ready to play
                    NSMutableDictionary *playerNodeInfo = _playerNodeList[prIndex];
                    playerNodeInfo [@"fileURLString"] = [[rc micOutputFileURL] path];
                    playerNodeInfo [@"audiobuffer"] = micOutputBuffer;
                    playerNodeInfo [@"audiofile"] = micOutputFile;
                    self.needMakeConnections = YES;  // need to make engine connections as this has now become a player

                    dispatch_sync(dispatch_get_main_queue(), ^() {
                        if ([_engineDelegate respondsToSelector:@selector(userAudioObtained)])
                            [_engineDelegate userAudioObtained];
                        // MAY Confuse to act on both completions
//                        if ([_clipEngineDelegate respondsToSelector:@selector(completedPlayingAtPlayerIndex:)])
//                            [_clipEngineDelegate completedPlayingAtPlayerIndex:index];
                    });
                }];
                
                // SCHEDULED back to back buffers FADE and PLAY
            }
            
            // normal play all
            
            else {

                BOOL isRecording = NO;
                if (fade == NO && index == 0) {
                    // Turn ON microphone
                    [rc record];
                    isRecording = YES;
                }

                // use all the volume, delay and loops options

                AVAudioPlayerNodeBufferOptions boptions = loops? AVAudioPlayerNodeBufferLoops : 0;
                
                [playerNode scheduleBuffer:audioBuffer atTime:delayAudioTime options:boptions completionHandler:^() {

                    NSLog(@"Audio Completed for playerAtIndex %ld",(unsigned long)index);
                    if (isRecording) {
                        // Turn OFF microphone
                        [rc stopRecording];
                        
                        // READ File into buffer
                        NSError* error = nil;
                        AVAudioFile *micOutputFile =
                        [[AVAudioFile alloc] initForReading:[rc micOutputFileURL] error:&error];
                        AVAudioPCMBuffer *micOutputBuffer =
                        [[AVAudioPCMBuffer alloc] initWithPCMFormat:micOutputFile.processingFormat
                                                      frameCapacity:(UInt32)micOutputFile.length];
                        NSAssert([micOutputFile readIntoBuffer:micOutputBuffer error:&error],
                                 @"error reading into new buffer, %@", [error localizedDescription]);
                        
                        // USER AUDIO obtained read into a buffer teedUP and ready to play
                        NSMutableDictionary *playerNodeInfo = _playerNodeList[prIndex];
                        playerNodeInfo [@"fileURLString"] = [[rc micOutputFileURL] path];
                        playerNodeInfo [@"audiobuffer"] = micOutputBuffer;
                        playerNodeInfo [@"audiofile"] = micOutputFile;
                        self.needMakeConnections = YES;
                        
                        dispatch_sync(dispatch_get_main_queue(), ^() {
                            if ([_engineDelegate respondsToSelector:@selector(userAudioObtained)])
                                [_engineDelegate userAudioObtained];
                        });
                        
                    } else {
                        
                        // Notify delegate
                        dispatch_sync(dispatch_get_main_queue(), ^() {
                            if ([_engineDelegate respondsToSelector:@selector(completedPlayingAtPlayerIndex:)])
                                [_engineDelegate completedPlayingAtPlayerIndex:index];
                        });
                    }
                }];
            }
            
            
        } // player playerrecorder
        
        index++;
        
    } // for
    
    // do not add mixer vab while recording
    
    if (fade == NO)
    {
        self.mixerVolume = 1.0;
    }
    
    for (JWPlayerNode* pn in self.activePlayerNodes)
    {
        [pn play];
        NSLog(@"%s audioPlayerNode PLAY",__func__);
    }
    
}


/*
 recordAtPlayerRecorderNodeIndex
 
 similar to playALL but skips the JWMixerNodeTypePlayerRecorder that is recording
 from beginnig
 */

- (void)recordWithPlayerRecorderAtNodeIndex:(NSUInteger)prIndex {
    
    JWAudioRecorderController* rc  =[self recorderForPlayerNodeAtIndex:prIndex];
    NSUInteger index = 0;
    for (NSDictionary *playerNodeInfo in _playerNodeList) {
        
        if (index == prIndex)
        {
            continue;  // skip the one recording
        }
        
        JWMixerNodeTypes nodeType = [self typeForNodeAtIndex:index];
        if (nodeType == JWMixerNodeTypePlayer || nodeType == JWMixerNodeTypePlayerRecorder || nodeType == JWMixerNodeTypeMixerPlayer) {
            
            AVAudioPCMBuffer *audioBuffer = [self audioBufferForPlayerNodeAtIndex:index];
            if (audioBuffer == nil)
            {
                continue; // not interested
            }
            // OTHERWISE we are ready to go with a buffer which is what we are scheduling
            // including obtaining delay time information
            
            // PLAYNODE Config
            BOOL loops = NO;
            NSTimeInterval secondsDelay = 0;
            AVAudioTime *delayAudioTime = nil;
            float volume = 0.25;
            
            id obj = nil;
            obj = playerNodeInfo[@"loops"];
            if (obj) {
                loops = [obj boolValue];
            }
            obj = playerNodeInfo[@"volumevalue"];
            if (obj) {
                volume = [obj floatValue];
            }
            obj = playerNodeInfo[@"delay"];
            if (obj) {
                secondsDelay = [obj doubleValue];
                // Create AVAudioTime to pass to atTime
                AVAudioFormat *format = [audioBuffer format];
                delayAudioTime = [AVAudioTime timeWithSampleTime:(secondsDelay * format.sampleRate) atRate:format.sampleRate];
            }
            
            NSLog(@"%s loops %@ secondsDelay %.3f",__func__,@(loops),secondsDelay);
            
            // RECONCILE Audiofile and Audio Buffer

            JWPlayerNode* playerNode = [self playerForNodeAtIndex:index];
            [_activePlayersIndex addIndex:index];
            
//            JWPlayerNode* playerNode =  (JWPlayerNode*)_playerNodes[playerNodeIndex];
//            [_activePlayersIndex addIndex:playerNodeIndex];
//            playerNodeIndex++;
            
            playerNode.audioFile = [self audioFileForPlayerNodeAtIndex:index]; // AVAudioFile


            // SCHEDULE THE BUFFER

            AVAudioPlayerNodeBufferOptions boptions = loops? AVAudioPlayerNodeBufferLoops : 0;
            
            [playerNode scheduleBuffer:audioBuffer atTime:delayAudioTime options:boptions completionHandler:^() {

                NSLog(@"Audio Completed for playerAtIndex %ld",(unsigned long)index);
                if (index == 0) { // primary player
                    [rc stopRecording];
                    
                    // READ File into buffer
                    NSError* error = nil;
                    AVAudioFile *micOutputFile =
                    [[AVAudioFile alloc] initForReading:[rc micOutputFileURL] error:&error];
                    AVAudioPCMBuffer *micOutputBuffer =
                    [[AVAudioPCMBuffer alloc] initWithPCMFormat:micOutputFile.processingFormat
                                                  frameCapacity:(UInt32)micOutputFile.length];
                    NSAssert([micOutputFile readIntoBuffer:micOutputBuffer error:&error],
                             @"error reading into new buffer, %@", [error localizedDescription]);
                    
                    // USER AUDIO obtained read into a buffer teedUP and ready to play
                    NSMutableDictionary *playerNodeInfo = _playerNodeList[prIndex];
                    playerNodeInfo [@"fileURLString"] = [[rc micOutputFileURL] path];
                    playerNodeInfo [@"audiobuffer"] = micOutputBuffer;
                    playerNodeInfo [@"audiofile"] = micOutputFile;
                    
                    NSString *recordingId = rc.recordingId;
                    [_activeRecorderIndex removeIndex:prIndex];
                    
                    self.needMakeConnections = YES;
                    
                    dispatch_sync(dispatch_get_main_queue(), ^() {
                        if ([_engineDelegate respondsToSelector:@selector(userAudioObtainedAtIndex:recordingId:)])
                            [_engineDelegate userAudioObtainedAtIndex:prIndex recordingId:rc.recordingId];

                        if ([_engineDelegate respondsToSelector:@selector(userAudioObtained)])
                            [_engineDelegate userAudioObtained];
                    });
                    

                    

                } else {
                // Notify delegate
                dispatch_sync(dispatch_get_main_queue(), ^() {
                    if ([_engineDelegate respondsToSelector:@selector(completedPlayingAtPlayerIndex:)])
                        [_engineDelegate completedPlayingAtPlayerIndex:index];
                });
                }
            }];
        }
        
        index++;
    }
    
    // do not add mixer vab if recording
    
    // RECORD AND PLAY
    
    [rc record];
    
    for (JWPlayerNode* pn in self.activePlayerNodes)
    {
        [pn play];
        NSLog(@"%s audioPlayerNode PLAY",__func__);
    }
    
}


/*
 recordCurrentForPlayerRecorderAtNodeIndex
 
 begin recording at current position
 */

- (void)recordAtCurrentPositionWithRecorderAtNodeIndex:(NSUInteger)prIndex {
    JWAudioRecorderController* rc  =[self recorderForPlayerNodeAtIndex:prIndex];
    [rc record];
}

/*
 prepareToPlayMix
 allows subclasses to take any action after list has been modified
 */

-(void)prepareToPlayMix {
//    [self makeEngineConnections];
    for (JWPlayerNode* pn in self.activePlayerNodes)
    {
        [pn stop];
        [pn reset];
        NSLog(@"%s audioPlayerNode STOP/RESET",__func__);
    }
    
    if (_mixerplayerNodeList == nil) {
        // this should have effects removed

        [self createPlayMixPlayerNodeList];
//        [self createPlayerNodes]; // calls [self.activePlayersIndex removeAllIndexes];
        [self.activePlayersIndex removeAllIndexes];
        [self createEngineAndAttachNodes];
        [self makeEngineConnections];
        [self startEngine];
    }
}

-(void)playMix {
    // hopefully prepareToPlayMix was called
    [self playAlll:NO];  // NO not recording
}

/*
 revertToMixing - will exchange the playerNodeList back to the mixing version
 
 typically is used after a prepare to playMix
 when a version of mixerplayerNodeList is saved
 */
-(void)revertToMixing {
    
    // REVERT from SAVED mixing playerNodeList

    if (_mixerplayerNodeList) {
        self.playerNodeList = [_mixerplayerNodeList mutableCopy];
        self.mixerplayerNodeList = nil;
        [self createPlayerNodes]; // calls [self.activePlayersIndex removeAllIndexes];
        [self createEngineAndAttachNodes];
        [self makeEngineConnections];
        [self startEngine];
    }
}

-(void)createPlayMixPlayerNodeList {

    // SAVE the current mixing playerNodeList

    self.mixerplayerNodeList = [NSArray arrayWithArray:_playerNodeList];
    
    // RESET _playerNodeList for play back of mixer output
    
    [self defaultPlayerNodeListPlayMix];
    // ONE node
    
    // Update the file URL with _finalRecordingOutputURL
    // READ File into buffer
    NSError* error = nil;
    AVAudioFile *mixerOutputFile =
    [[AVAudioFile alloc] initForReading:_finalRecordingOutputURL error:&error];
    
    if (error) {
        NSLog(@"%@",[error description]);
    } else {
        // NO Error - proceed with playback
        
        AVAudioPCMBuffer *mixerOutputBuffer =
        [[AVAudioPCMBuffer alloc] initWithPCMFormat:mixerOutputFile.processingFormat
                                      frameCapacity:(UInt32)mixerOutputFile.length];
        
        NSAssert([mixerOutputFile readIntoBuffer:mixerOutputBuffer error:&error], @"error reading into new buffer, %@", [error localizedDescription]);
        
        if (error) {
            NSLog(@"There was an error");
        }
        
        // USER AUDIO obtained read into a buffer and ready to play
        
        NSUInteger playerNodeIndex = 0;
        NSMutableDictionary *playerNodeInfo = _playerNodeList[playerNodeIndex];
        playerNodeInfo [@"fileURLString"] = [_finalRecordingOutputURL path];
        playerNodeInfo [@"audiobuffer"] = mixerOutputBuffer;
    }
    
    NSLog(@"%s %@",__func__,[_playerNodeList description]);
}

#pragma mark - support the scrubber to determine current pos

-(JWPlayerNode*) playerForNodeAtIndex:(NSUInteger)index {
    JWPlayerNode *result = nil;
    if ([_playerNodeList count] > index) {
        result = _playerNodeList[index][@"player"];
    }
    
    return result;
}

-(JWPlayerNode*) recorderForNodeAtIndex:(NSUInteger)index {
    JWPlayerNode *result = nil;
    if ([_playerNodeList count] > index) {
        result = _playerNodeList[index][@"recorder"];
    }
    
    return result;
}

-(JWPlayerNode*) playerForNodeNamed:(NSString*)name {
    JWPlayerNode *result = nil;
    NSUInteger index = 0;
    for (NSDictionary *playerNodeInfo in _playerNodeList) {
        id nodename = playerNodeInfo[@"name"];
        if (nodename){
            if ([name isEqualToString:nodename]) {
                // found
                result = [self playerForNodeAtIndex:index];
                break;
            }
        }
        index++;
    }
    return result;
}

// Player status and progress
// currentPos
// sampleTime / sampleRate
// progress of playback

//-(void)changeProgressOfSeekingAudioFile:(CGFloat)progress {
//    //    AVAudioFramePosition fileLength = seekingAudioFile.length;
//    //    AVAudioFramePosition readPosition = progress * fileLength;
//    //    if (_micPlayer.playing) {
//    //        [self playSeekingAudioFileAtFramPosition:readPosition];
//}


-(CGFloat)progressOfSeekingAudioFile {
    return [self.playerNode1 progressOfAudioFile];
}
-(CGFloat)durationInSecondsOfSeekingAudioFile {
    return [self.playerNode1 durationInSecondsOfAudioFile];
}
-(CGFloat)remainingDurationInSecondsOfSeekingAudioFile {
    return [self.playerNode1 remainingDurationInSecondsOfAudioFile];
}
-(CGFloat)currentPositionInSecondsOfSeekingAudioFile {
    return [self.playerNode1 currentPositionInSecondsOfAudioFile];
}
-(NSString*)processingFormatStr{
    return nil;
    //    return [self.playerNode1 processingFormatStr];
}


-(CGFloat)progressOfAudioFileForPlayerAtIndex:(NSUInteger)index {
    
    //JWPlayerNode *pn = [self playerForNodeAtIndex:index];
    JWPlayerNode *pn = [[self activePlayerNodes] objectAtIndex:0];
    return [pn progressOfAudioFile];
}
-(CGFloat)durationInSecondsOfAudioFileForPlayerAtIndex:(NSUInteger)index {
    JWPlayerNode *pn = [self playerForNodeAtIndex:index];
    return [pn durationInSecondsOfAudioFile];
}
-(CGFloat)remainingDurationInSecondsOfAudioFileForPlayerAtIndex:(NSUInteger)index {
    JWPlayerNode *pn = [self playerForNodeAtIndex:index];
    return [pn remainingDurationInSecondsOfAudioFile];
}
-(CGFloat)currentPositionInSecondsOfAudioFileForPlayerAtIndex:(NSUInteger)index {
    JWPlayerNode *pn = [self playerForNodeAtIndex:index];
    return [pn currentPositionInSecondsOfAudioFile];
}
-(NSString*)processingFormatStrForPlayerAtIndex:(NSUInteger)index {
//    JWPlayerNode *pn = [self playerForNodeAtIndex:index];
//    return [pn processingFormatStr];
    return nil;
}

-(CGFloat)progressOfAudioFileForPlayerNamed:(NSString*)name {
    JWPlayerNode *pn = [self playerForNodeNamed:name];
    return [pn progressOfAudioFile];
}
-(CGFloat)durationInSecondsOfAudioFileForPlayerNamed:(NSString*)name {
    JWPlayerNode *pn = [self playerForNodeNamed:name];
    return [pn durationInSecondsOfAudioFile];
}
-(CGFloat)remainingDurationInSecondsOfAudioFileForPlayerNamed:(NSString*)name {
    JWPlayerNode *pn = [self playerForNodeNamed:name];
    return [pn remainingDurationInSecondsOfAudioFile];
}
-(CGFloat)currentPositionInSecondsOfAudioFileForPlayerNamed:(NSString*)name {
    JWPlayerNode *pn = [self playerForNodeNamed:name];
    return [pn currentPositionInSecondsOfAudioFile];
}
-(NSString*)processingFormatStrForPlayerNamed:(NSString*)name {
//    JWPlayerNode *pn = [self playerForNodeNamed:name];
    //    return [pn processingFormatStr];
    return nil;
}


#pragma mark - Scrubber support

// This allows the scrubber to move the playhead on the player

-(AVAudioFramePosition)playerFramePostion {
    return [[_playerNode1 lastRenderTime] sampleTime];
}

#pragma mark - support the scrubber older model
// OLD modelgeneric
//-(NSString*)processingFormatStrOfAudioFile:(AVAudioFile*)audioFile {
//    NSString *result = nil;
//    if (audioFile) {
//        AVAudioFormat *format = [_trimmedAudioFile processingFormat];
//        result = [NSString stringWithFormat:@"%d ch %.0f %d %@ %@",
//                  format.streamDescription->mChannelsPerFrame,
//                  format.streamDescription->mSampleRate,
//                  format.streamDescription->mBitsPerChannel,
//                  format.standard ? @"Float32-std" : @"std NO",
//                  format.interleaved ? @"inter" : @"non-interleaved"
//                  ];
//    }
//    NSLog(@"%s %@",__func__,result);
//    return result;
//}
// other
-(void)setProgressSeekingAudioFile:(CGFloat)progressSeekingAudioFile {
    _progressSeekingAudioFile = progressSeekingAudioFile;
}


#pragma mark - file methods

-(NSString*)documentsDirectoryPath {
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [searchPaths objectAtIndex:0];
}

-(void)savePlayerNodeList{
    NSString *fpath = [[self documentsDirectoryPath] stringByAppendingPathComponent:@"playernodes.dat"];
    // Remove non serilizableobjects
    for (NSMutableDictionary *playerNodeInfo in _playerNodeList) {
        [playerNodeInfo removeObjectForKey:@"player"];
        [playerNodeInfo removeObjectForKey:@"recorderController"];
        [playerNodeInfo removeObjectForKey:@"audiofile"];
        [playerNodeInfo removeObjectForKey:@"audiobuffer"];
        [playerNodeInfo removeObjectForKey:@"fileURL"];
    }
    [_playerNodeList writeToURL:[NSURL fileURLWithPath:fpath] atomically:YES];
    
    NSLog(@"\n%s\nplayernodes.dat\n%@",__func__,[_playerNodeList description]);
}

-(void)readPlayerNodeList{
    NSString *fpath = [[self documentsDirectoryPath] stringByAppendingPathComponent:@"playernodes.dat"];
    NSArray *playerNodeListFromFile = [[NSArray alloc] initWithContentsOfURL:[NSURL fileURLWithPath:fpath]];
    //    _playerNodeList = [[NSMutableArray alloc] initWithContentsOfURL:[NSURL fileURLWithPath:fpath]];
    if (playerNodeListFromFile) {
        self.playerNodeList = [@[] mutableCopy];
        for (NSDictionary* playerNodeInfo in playerNodeListFromFile) {
            [_playerNodeList addObject:[playerNodeInfo mutableCopy]];
        }
    }
    NSLog(@"\n%s\nplayernodes.dat\n%@",__func__,[_playerNodeList description]);
}


@end





//===========================================================================
//
//
//===========================================================================

//@property (nonatomic) AVAudioPCMBuffer* audioBufferFromFile;
//@property (nonatomic) AVAudioPCMBuffer* micOutputBuffer;
//@property (nonatomic) NSURL* playerNode1FileURL;
//@property (nonatomic) NSURL* playerNode2FileURL;
//@property (nonatomic) NSURL* playerNode3FileURL;

//#ifndef JWPLAYERNODE
//-(CGFloat)progressOfMicAudioFile {
//    return [self progressOfAudioFile:_micOutputFile forPlayerNode:_playerNode2];
//}
//
//-(CGFloat)durationInSecondsOfMicAudioFile {
//    return [self durationInSecondsOfAudioFile:_micOutputFile forPlayerNode:_playerNode2];
//}
//
//-(CGFloat)remainingDurationInSecondsOfMicAudioFile {
//    return [self remainingDurationInSecondsOfAudioFile:_micOutputFile forPlayerNode:_playerNode2];
//}
//-(CGFloat)currentPositionInSecondsOfMicAudioFile {
//    return [self currentPositionInSecondsOfAudioFile:_micOutputFile forPlayerNode:_playerNode2];
//}
//
//-(CGFloat)remainingDurationInSecondsOfTrimmedAudioFile{
//    return [self remainingDurationInSecondsOfAudioFile:_trimmedAudioFile forPlayerNode:_playerNode1];
//}
//-(CGFloat)currentPositionInSecondsOfTrimmedAudioFile{
//    return [self currentPositionInSecondsOfAudioFile:_trimmedAudioFile forPlayerNode:_playerNode1];
//}
//-(CGFloat)progressOfTrimmedAudioFile{
//    return [self progressOfAudioFile:_trimmedAudioFile forPlayerNode:_playerNode1];
//}
//-(CGFloat)durationInSecondsOfTrimmedAudioFile{
//    return [self durationInSecondsOfAudioFile:_trimmedAudioFile forPlayerNode:_playerNode1];
//}
//-(CGFloat)progressOfAudioFile:(AVAudioFile*)audioFile forPlayerNode:(AVAudioPlayerNode*)playerNode
//{
//    CGFloat result = 0.000f;
//    if (audioFile) {
//        AVAudioFramePosition fileLength = audioFile.length;
//        AVAudioTime *audioTime = [playerNode lastRenderTime];
//        AVAudioTime *playerTime = [playerNode playerTimeForNodeTime:audioTime];
//        if (playerTime==nil) {
//            NSLog(@"%s NO PLAYER TIME  playing %@",__func__,@([playerNode isPlaying]));
//            result = 1.00f;
//        } else {
//            double fileLenInSecs = fileLength / [playerTime sampleRate];
//            double currentPosInSecs = [playerTime sampleTime] / [playerTime sampleRate];
//            if (currentPosInSecs > fileLenInSecs ) {
//                if (_loops) {
//                    double normalizedPos = currentPosInSecs/fileLenInSecs - floorf(currentPosInSecs/fileLenInSecs);
//                    result = normalizedPos;
//                } else {
//                    result = 1.0;
//                }
//                
//            } else {
//                result = currentPosInSecs/fileLenInSecs;
//            }
//        }
//    }
//    
//    //    NSLog(@"%s %.3f",__func__,result);
//    return result;

//-(CGFloat)durationInSecondsOfAudioFile:(AVAudioFile*)audioFile forPlayerNode:(AVAudioPlayerNode*)playerNode
//    CGFloat result = 0.000f;
//    if (audioFile) {
//        AVAudioFramePosition fileLength = audioFile.length;
//        AVAudioTime *audioTime = [playerNode lastRenderTime];
//        AVAudioTime *playerTime = [playerNode playerTimeForNodeTime:audioTime];
//        
//        double fileLenInSecs = 0.0f;
//        
//        if (playerTime) {
//            fileLenInSecs = fileLength / [playerTime sampleRate];
//        } else {
//            Float64 mSampleRate = audioFile.processingFormat.streamDescription->mSampleRate;
//            Float64 duration =  (1.0 / mSampleRate) * audioFile.processingFormat.streamDescription->mFramesPerPacket;
//            fileLenInSecs = duration * fileLength;
//        }
//        result = (CGFloat)fileLenInSecs;
//    }
//    //    NSLog(@"%s %.3f",__func__,result);
//    return result;

//-(CGFloat)remainingDurationInSecondsOfAudioFile:(AVAudioFile*)audioFile forPlayerNode:(AVAudioPlayerNode*)playerNode
//    CGFloat result = 0.000f;
//    if (audioFile) {
//        AVAudioTime *audioTime = [playerNode lastRenderTime];
//        AVAudioFramePosition fileLength = audioFile.length;
//        AVAudioTime *playerTime = [playerNode playerTimeForNodeTime:audioTime];
//        
//        double fileLenInSecs = fileLength / [playerTime sampleRate];
//        double currentPosInSecs = [playerTime sampleTime] / [playerTime sampleRate];
//        
//        if (currentPosInSecs > fileLenInSecs ) {
//            result = 0.0;
//        } else {
//            result = (fileLenInSecs - currentPosInSecs);
//    }
//    //    NSLog(@"%s %.3f",__func__,result);
//    return result;

//-(CGFloat)currentPositionInSecondsOfAudioFile:(AVAudioFile*)audioFile forPlayerNode:(AVAudioPlayerNode*)playerNode
//    CGFloat result = 0.000f;
//    if (audioFile) {
//        AVAudioFramePosition fileLength = audioFile.length;
//        AVAudioTime *audioTime = [playerNode lastRenderTime];
//        AVAudioTime *playerTime = [playerNode playerTimeForNodeTime:audioTime];
//        
//        double fileLenInSecs = fileLength / [playerTime sampleRate];
//        double currentPosInSecs = [playerTime sampleTime] / [playerTime sampleRate];
//        
//        if (currentPosInSecs > fileLenInSecs ) {
//            result = fileLenInSecs;
//        } else {
//            result = currentPosInSecs;
//        }
//    }
//    //    NSLog(@"%s %.3f",__func__,result);
//    return result;
//}

// MIX file
//-(CGFloat)progressOfMixAudioFile{
//    return [self.playerNode1 progressOfAudioFile:_finalRecordingOutputFile];
//}
//-(CGFloat)durationInSecondsOfMixFile {
//    return [self.playerNode1 durationInSecondsOfAudioFile:_finalRecordingOutputFile];
//}
//-(CGFloat)remainingDurationInSecondsOfMixFile {
//    return [self.playerNode1 remainingDurationInSecondsOfAudioFile:_finalRecordingOutputFile];
//}
//-(CGFloat)currentPositionInSecondsOfMixFile{
//    return [self.playerNode1 currentPositionInSecondsOfAudioFile:_finalRecordingOutputFile];
//}


//-(float)volumeValuePlayer1 {
//    return [_playerNode1 volume];
//}
//-(float)volumeValuePlayer2 {
//    return [_playerNode2 volume];
//}
//-(void)setVolumeValuePlayer1:(float)volumeValuePlayer1  {
//    //_volumeValuePlayer1 = volumeValuePlayer1;
//    _playerNode1.volume = volumeValuePlayer1;
//}
//-(void)setVolumeValuePlayer2:(float)volumeValuePlayer2  {
//    //    _volumeValuePlayer2 =volumeValuePlayer2;
//    _playerNode2.volume = volumeValuePlayer2;
//}

//-(float)panValuePlayer1 {
//    return [_playerNode1 pan];
//}
//-(float)panValuePlayer2 {
//    return [_playerNode2 pan];
//}
//-(void)setPanValuePlayer1:(float)panValue  {
//    _playerNode1.pan = panValue;
//    //    NSLog(@"%s %.2f",__func__,panValue);
//}
//-(void)setPanValuePlayer2:(float)panValue  {
//    _playerNode2.pan = panValue;
//}
//-(float)volumePlaybackTarck {
//    return _playerNode1.volume;
//}
//-(void)setVolumePlayBackTrack:(float)volumePlayBackTrack {
//    _volumePlayBackTrack = volumePlayBackTrack;
//    _playerNode1.volume = _volumePlayBackTrack;
//}
//
//#endif

//-(CGFloat)progressOfSeekingAudioFile {
//        return _isRecording ? [self.playerNode2 progressOfAudioFile:_micOutputFile] : [self.playerNode1 progressOfAudioFile:_trimmedAudioFile];
//}
//-(CGFloat)durationInSecondsOfSeekingAudioFile {
//    return _isRecording ? [self.playerNode2 durationInSecondsOfAudioFile:_micOutputFile] : [self.playerNode1 durationInSecondsOfAudioFile:_trimmedAudioFile];
//}
//-(CGFloat)remainingDurationInSecondsOfSeekingAudioFile {
//    return _isRecording ? [self.playerNode2 remainingDurationInSecondsOfAudioFile:_micOutputFile] : [self.playerNode1 remainingDurationInSecondsOfAudioFile:_trimmedAudioFile];
//}
//-(CGFloat)currentPositionInSecondsOfSeekingAudioFile {
//    return _isRecording ? [self.playerNode2 currentPositionInSecondsOfAudioFile:_micOutputFile] : [self.playerNode1 currentPositionInSecondsOfAudioFile:_trimmedAudioFile];
//}
//-(NSString*)processingFormatStr{
//    return _isRecording ? [self processingMicFormatStr] : [self processingTrimmedFormatStr];
//}


//===============================
// REFACTOR ENGINES
//===============================

//- (void)prepareForPreview {
//    NSError* error;
//    AVAudioMixerNode* mainMixer = [self.audioEngine mainMixerNode];
//    //[mainMixer installTapOnBus:0 bufferSize:4069 format:_generalFormat
//    //[mainMixer installTapOnBus:0 bufferSize:4069 format:[mainMixer outputFormatForBus:0]
//    _finalRecordingOutputFile =
//    [[AVAudioFile alloc] initForWriting:_finalRecordingOutputURL
//                               settings:[[mainMixer outputFormatForBus:0] settings]
//                                  error:&error];
//
//    NSAssert(_finalRecordingOutputFile != nil, @"_finalRecordingOutputFile is nil, %@", [error localizedDescription]);
//}


// setupAVEngine

// joe: move to makeconnections method
//    AVAudioMixerNode* mainMixer = [self.audioEngine mainMixerNode];
//    [self.audioEngine connect:self.playerNode1 to:mainMixer format:_audioBufferFromFile.format];
//    [self.audioEngine connect:self.playerNode2 to:mainMixer format:_fiveSecondBuffer.format];
//    mainMixer.outputVolume = 1.0;
//
// START the engine

//    [self startEngine];

// Create nodes
//    self.playerNode1 = [[AVAudioPlayerNode alloc] init];
//    self.playerNode2 = [[AVAudioPlayerNode alloc] init];

//    self.playerNode1 = [JWPlayerNode new];
//    self.playerNode2 = [JWPlayerNode new];
//    self.playerNode1.volume = 0.25;

// joe: moved to createEngineAndAttachNodes
// Create Engine and Attach nodes
//    self.audioEngine = [[AVAudioEngine alloc] init];
//
//    [self.audioEngine attachNode:self.playerNode1];
//    [self.audioEngine attachNode:self.playerNode2];

// JOE: move recorder to recorder controller
//    AVAudioChannelLayout *layout = [[AVAudioChannelLayout alloc] initWithLayoutTag:kAudioChannelLayoutTag_Stereo];
//    AVAudioFormat* micFormat = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatFloat32 sampleRate:44100. interleaved:NO channelLayout:layout];
//    NSError *error;
//    self.audioRecorder = [[AVAudioRecorder alloc] initWithURL:_micOutputFileURL settings:[micFormat settings] error:&error];
//    _audioRecorder.meteringEnabled = _useMetering;
//    [_audioRecorder prepareToRecord];
//    if (_useMetering)
//        self.meterSamples = [NSMutableArray new];


//    AVAudioInputNode* inputNode = [self.audioEngine inputNode];
//    [inputNode installTapOnBus:0 bufferSize:1024
//                        format:_generalFormat block:^(AVAudioPCMBuffer* buffer, AVAudioTime* when) {}];
//    [inputNode removeTapOnBus:0];

//-(void)teeUpAudioBuffersxx {
//    NSError* error = nil;
//    _trimmedAudioFile = [[AVAudioFile alloc] initForReading:_trimmedURL error:&error];
//    if (error) {
//        NSLog(@"%@",[error description]);
//    }
//    error = nil;
//    AVAudioFile* fiveSecondFile = [[AVAudioFile alloc] initForReading:_fiveSecondURL error:&error];
//    if (error) {
//        NSLog(@"%@",[error description]);
//    }
//    _audioBufferFromFile = [[AVAudioPCMBuffer alloc] initWithPCMFormat:_trimmedAudioFile.processingFormat
//                                                         frameCapacity:(UInt32)_trimmedAudioFile.length];
//
//    _fiveSecondBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:fiveSecondFile.processingFormat
//                                                      frameCapacity:(UInt32)fiveSecondFile.length];
//
//    [_trimmedAudioFile readIntoBuffer:_audioBufferFromFile error:&error];
//    [fiveSecondFile readIntoBuffer:_fiveSecondBuffer error:&error];
//    if (error) {
//        NSLog(@"There was an error");
//    }
//}

//prepareToRecord
//    // Player 1 Schedule buffer
//
//    [self.playerNode1 scheduleBuffer:_fiveSecondBuffer atTime:nil options:0 completionHandler:^() {
//        NSLog(@"Five Second Audio Completed");
//        // Turn ON microphone
//        [_recorderController record];
//        // joe: done by controller
////        [self startMeteringTimer];
//        // Notify delegate
//        dispatch_sync(dispatch_get_main_queue(), ^() {
//            if ([_clipEngineDelegate respondsToSelector:@selector(fiveSecondBufferCompletion)])
//                [_clipEngineDelegate fiveSecondBufferCompletion];
//        });
//    }];
//
//
//    // Player 1 Schedule buffer
//
//    [self.playerNode1 scheduleBuffer:_audioBufferFromFile atTime:nil options:0 completionHandler:^() {
//
//        NSLog(@"Main Audio Completed");
//
//        // joe: moved to controller
////        [self.meteringTimer invalidate];
////        [_audioRecorder stop];
////        // REMOVE Tap for microphone
////        [[self.audioEngine inputNode] removeTapOnBus:0];
//
//        [_recorderController stopRecording];
//
//        // READ File into buffer
//
//
//        // TODO: get from recorder controller
////        NSError* error = nil;
////        _micOutputFile = [[AVAudioFile alloc] initForReading:_micOutputFileURL error:&error];
////
////        _micOutputBuffer =
////        [[AVAudioPCMBuffer alloc] initWithPCMFormat:_micOutputFile.processingFormat
////                                      frameCapacity:(UInt32)_micOutputFile.length];
////
////        NSAssert([_micOutputFile readIntoBuffer:_micOutputBuffer error:&error], @"error reading into new buffer, %@", [error localizedDescription]);
//
//        dispatch_sync(dispatch_get_main_queue(), ^() {
//            if ([_clipEngineDelegate respondsToSelector:@selector(userAudioObtained)])
//                [_clipEngineDelegate userAudioObtained];
//        });
//    }];
//    [self startEngine];
//    [self.playerNode1 play];

//    [self.playerNode1 scheduleBuffer:_audioBufferFromFile atTime:nil
//                             options:AVAudioPlayerNodeBufferLoops
//                   completionHandler:^{
//                   }];
//
//    if (_micOutputBuffer) {
//        [self.playerNode2 scheduleBuffer:_micOutputBuffer atTime:nil
//                                 options:AVAudioPlayerNodeBufferLoops  completionHandler:^{
//                                     NSLog(@"mic buffer loop completed");
//                                 }];
//    }


// Plays all nodes and records output from mixer
// use PlayAll and Recordit for recording

//-(void)playAll {
//    BOOL loopWhileMixing = YES;
//    _loops = loopWhileMixing;
//    self.playerNode1.loops = _loops;
//    self.playerNode2.loops = _loops;
//    _playerIsPaused = NO;
//    if (_playerIsPaused) {
//        NSLog(@"%s PAUSED will resume play",__func__);
//    } else {
//        // start playing
//        if (loopWhileMixing == NO) { // play the optional way
//            // Play ONCE
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
//        } else {
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
//        }
//    }
//    [self.playerNode1 play];
//    if (_micOutputBuffer)
//        [self.playerNode2 play];


//playMix
//    [self.playerNode2 stop];
//
//    [_playerNode1 reset];
//
//    // Plas the mix result _finalRecordingOutputURL
//
//    NSError* error = nil;
//    _finalRecordingOutputFile = [[AVAudioFile alloc] initForReading:_finalRecordingOutputURL error:&error];
//    AVAudioPCMBuffer *audioBuffer =
//    [[AVAudioPCMBuffer alloc] initWithPCMFormat:_finalRecordingOutputFile.processingFormat
//                                  frameCapacity:(UInt32)_finalRecordingOutputFile.length];
//    error = nil;
//    [_finalRecordingOutputFile readIntoBuffer:audioBuffer error:&error];
//    if (error) {
//        NSLog(@"There was an error");
//    [self.playerNode1 scheduleBuffer:audioBuffer atTime:nil options:0
//                   completionHandler:^{
//                       dispatch_async(dispatch_get_main_queue(), ^{
//                           if ([_clipEngineDelegate respondsToSelector:@selector(playMixCompleted)])
//                               [_clipEngineDelegate playMixCompleted];
//                       });
//                   }];
//
//    [self.playerNode1 play];



//-(void)prepareToPlaySeekingAudio {
//    [self audioFileAnalyzerForFile:_micOutputFileURL];
//}
//-(void)prepareToPlayPrimaryTrack {
//    [self audioFileAnalyzerForFile:_trimmedURL andTrack:1];
//}
//-(void)prepareToPlayMicRecording {
//    [self audioFileAnalyzerForFile:_micOutputFileURL andTrack:2];
//}
//-(void)prepareMasterMixSampling {
//    [self audioFileAnalyzerForFile:_finalRecordingOutputURL];
//}


//scrubber stuff
//-(BOOL)prepareToPlayTrack1 {
//    [self audioFileAnalyzerForFile:_trimmedURL];
//    return YES;
//}
//-(void)audioFileAnalyzer {
//    [self audioFileAnalyzerForFile:_micOutputFileURL];
//}


//#pragma mark - metering
//
//-(void)startMeteringTimer
//    self.lastMeterTimeStamp = [NSDate date];
//    self.meteringTimer = [NSTimer timerWithTimeInterval:0.10 target:self selector:@selector(meteringTimerFired:) userInfo:nil repeats:YES];
//    [[NSRunLoop mainRunLoop] addTimer:_meteringTimer forMode:NSRunLoopCommonModes];
//-(void)meteringTimerFired:(NSTimer*)timer {
//    if (timer.valid) {
//        //        The current peak power, in decibels, for the sound being recorded. A return value of 0 dB indicates full scale, or maximum power; a return value of -160 dB indicates minimum power (that is, near silence).
//        // but am gonna limit to 130
//        // The sampl
//        [self.audioRecorder updateMeters];
//        //        float peakSample = [self.audioRecorder peakPowerForChannel:0];
//        //        float peakNormalizedValue = 0.0;// ratio 0 - 1.0
//        //        if (peakSample > 0 )
//        //            peakNormalizedValue = 1.00f;  // full power
//        //        else
//        //            peakNormalizedValue = (160.0 + peakSample) / 160.00f;  // sample of (-45) = 115   160 + (-158) = 2 = 0.0125
//        //        [_meterSamples addObject:@(peakNormalizedValue)];
//        //
//        //        NSLog(@" [%.3f] peak %.3f",peakNormalizedValue,peakSample);
//        float avgSample = [self.audioRecorder averagePowerForChannel:0];
//        float avgNormalizedValue = 0.0;// ratio 0 - 1.0
//        float maxDB = 160.0f;
//        if (avgSample > 0 )
//            avgNormalizedValue = 1.00f;
//        else {
//            avgNormalizedValue = (maxDB + avgSample) / (maxDB + 20);  // sample of (-45) = 115   160 + (-158) = 2 = 0.0125
//        }
//        //        NSLog(@" [%.3f] avg %.3f",avgNormalizedValue,avgSample);
//        [_meterSamples addObject:@(avgNormalizedValue)];
//        NSTimeInterval timedMeter =  [_lastMeterTimeStamp timeIntervalSinceNow];
//        //        NSLog(@"time  %.3f",timedMeter);
//        NSTimeInterval meteringInterval = 0.28;
//        if (timedMeter <  - meteringInterval) {
//            //            [_audioEngineDelegate meterSamples:[NSArray arrayWithArray:_meterSamples] andDuration:-timedMeter];
//            [_scrubberBufferController meterSamples:[NSArray arrayWithArray:_meterSamples] andDuration:-timedMeter
//                                         forTrackId:_scrubberTrackIds[@"recorder"]];
//            [_meterSamples removeAllObjects];
//            self.lastMeterTimeStamp = [NSDate date];
//        }

//===============================
// REFERENCES
//===============================


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

