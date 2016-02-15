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
    BOOL _isRecordingOnly;
    
}
@property (nonatomic) NSURL *trimmedURL;
@property (nonatomic) NSURL *fiveSecondURL;
@property (strong, nonatomic) NSArray *mixerplayerNodeList; // saves playerNode list while play mix
@property (nonatomic,strong)  NSMutableDictionary *scrubberTrackIds;
@property (nonatomic,strong) id <JWScrubberBufferControllerDelegate> scrubberBufferController;
@property (nonatomic) NSMutableIndexSet *activePlayersIndex;
@property (nonatomic) NSMutableIndexSet *activeRecorderIndex;
@property (nonatomic) NSMutableArray *playingNodes;
@property (nonatomic) AVAudioPCMBuffer *fiveSecondBuffer;
@property (nonatomic) JWPlayerNode *fiveSecondNode;
@property (nonatomic) NSString *fiveSecondString;
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
- (void)stopPlayersForInterruption {
    [super stopPlayersForInterruption];
    NSLog(@"%s",__func__);
    
    // leave it to subclasses
    for (JWPlayerNode* pn in self.activePlayerNodes) {
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

- (void)stopPlayersForReset {

    NSLog(@"%s",__func__);
    NSUInteger index = 0;
    for (NSMutableDictionary *playerNodeInfo in _playerNodeList) {
        
        id pn = playerNodeInfo[@"player"];
        if (pn) {
//            [pn stop];
//            [pn reset];
        }
        
        id rc = playerNodeInfo[@"recorderController"];
        if (rc) {
//            if ([(JWAudioRecorderController*)rc recording]) {
//                [rc stopRecording];
//            }
        }

//        NSLog(@"%@",[playerNodeInfo description]);
        
        [playerNodeInfo removeObjectForKey:@"recorderController"];
        [playerNodeInfo removeObjectForKey:@"player"];
        [playerNodeInfo removeObjectForKey:@"audiobuffer"];
        [playerNodeInfo removeObjectForKey:@"audiofile"];
        [playerNodeInfo removeObjectForKey:@"effectnodes"];

//        NSLog(@"%@",[playerNodeInfo description]);
        
        index++;
    }
    
}

#pragma mark - player node data

-(void)loadPlayerNodeData {
    
//    [self readPlayerNodeList];

    NSLog(@"%s %@",__func__,[_playerNodeList description]);

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

//TODO:Five Second stuff, not sure if mutable.  Added this for creation of five second node
//only needed if engine is active (so doesnt show up in table view as a valid node)
-(NSMutableDictionary *)createFiveSecondPlayerNodeWithDirectory:(NSString *)fileString fromKey:(NSString*)dbKey {
    
    if (dbKey == nil) {
        NSLog(@"No Key To Create File String.");
        return nil;
    }
    NSURL *validURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/fiveSecondsMP3_%@.m4a",fileString, dbKey]];
    NSLog(@"Valid URL? %@", [validURL absoluteString]);
    NSFileManager *quickManager = [NSFileManager defaultManager];
    
    if (![quickManager fileExistsAtPath:[validURL path]]) {
        NSLog(@"No Valid URL To Create File String URL.");
        return nil;
    }
    
    
    NSMutableDictionary *fiveSecondNode =
    [@{
      @"title" : @"fivesecondnode",
      @"type" : @(JWMixerNodeTypeFiveSecondPlayer),
      @"volumevalue" : @(0.0),
      @"fileURLString" : [NSString stringWithFormat:@"%@/fiveSecondsMP3_%@.m4a",fileString, dbKey]
      } mutableCopy];
    
    JWPlayerNode *pn = [JWPlayerNode new];
    pn.volume = 0.4f;
    fiveSecondNode[@"player"] = pn;
    self.fiveSecondNode = pn;
    
    NSError *error;
    AVAudioFile *audioFile = [[AVAudioFile alloc] initForReading:validURL error:&error];
    if (error)
        NSLog(@"%@",[error description]);
     else
        fiveSecondNode[@"audiofile"] = audioFile;

    
    return fiveSecondNode;
}


//TODO: added this for five second addition to node list
-(BOOL)addFiveSecondNodeToListForKey:(NSString *)dbKey {
    
//    NSString *keyForFiveSecondNode = nil;
    
    if (dbKey) {
        
        NSDictionary *fiveSecondNode = nil;
        
        //TODO:questionable methods to determining a five second node should be establishd
        for (NSMutableDictionary *node in _playerNodeList) {
            NSString* fileURLString = node[@"fileURLString"];
            
            if (fileURLString) {
                
                NSRange subStringRange = [fileURLString rangeOfString:@"Documents"];
                NSString *directoryOfPlayerNodeURL = [fileURLString substringWithRange:NSMakeRange(0, subStringRange.location + subStringRange.length)];
                fiveSecondNode = [self createFiveSecondPlayerNodeWithDirectory:directoryOfPlayerNodeURL
                                                                                     fromKey:dbKey];
                if (fiveSecondNode) {
                    node[@"fivesecondnode"] = fiveSecondNode;
                    NSLog(@"five second node added %s", __func__);
                    _hasFiveSecondClip = YES;
                    return YES;
                }

                
            }
        }
        
        
    }
    return NO;
}


#pragma mark - VAB listeners

-(void)registerController:(id <JWScrubberBufferControllerDelegate> )myScrubberContoller
              withTrackId:(NSString*)trackId
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
            if (nodename)
                _scrubberTrackIds[nodename] = trackId;

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
    
    if (_bufferReceivedQueue == nil)
        _bufferReceivedQueue =
        dispatch_queue_create("bufferReceivedAE",
                              dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL,QOS_CLASS_USER_INTERACTIVE, 0));
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

-(void)setClipEngineDelegate:(id<JWMTAudioEngineDelgegate>)engineDelegate {
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
    
    [_activePlayersIndex enumerateIndexesUsingBlock:^(NSUInteger idx,BOOL *stop){
        id pn = [self playerForNodeAtIndex:idx];
        if (pn)
            [nodes addObject:pn];
    }];
    
    if ([nodes count] == 0) {
//        NSLog(@"%s %ld activeNodes",__func__,(unsigned long)[nodes count]);
    }

    return [NSArray arrayWithArray:nodes];
}

-(NSArray*)activeRecorderNodes {
    __block NSMutableArray *nodes = [[NSMutableArray alloc] initWithCapacity:[_playerNodeList count]];
    
    [_activeRecorderIndex enumerateIndexesUsingBlock:^(NSUInteger idx,BOOL *stop){
        id pn = [self recorderForPlayerNodeAtIndex:idx];
        if (pn)
            [nodes addObject:pn];
    }];
    
    return [NSArray arrayWithArray:nodes];
}

-(NSUInteger)countOfNodesWithAudio {
    
    NSUInteger count = 0;
    for (int i = 0; i < [_playerNodeList count]; i++) {
        NSDictionary *node = _playerNodeList[i];
        if (node) {
            id fileUrl = node[@"fileURLString"];
            if (fileUrl) {
                count++;
            }
        }
    }
    return count;
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

-(NSURL*) playerNode1FileURL {
    return [self playerNodeFileURLAtIndex:0];
}

-(NSURL*) playerNode2FileURL {
    return [self playerNodeFileURLAtIndex:1];
}

-(JWPlayerNode*) playerNode1 {
    return [self playerForNodeAtIndex:0];
}

-(JWPlayerNode*) playerNode2 {
    return [self playerForNodeAtIndex:1];
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
-(void)stopPlayingTrack1 {
    [self.playerNode1 stop];
}

-(void)pausePlayingTrack1 {
    [self.playerNode1 pause];
}

//-(void)stopAll {
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
//    [self refresh];
//}


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
        
        if (nodeType == JWMixerNodeTypePlayer || nodeType == JWMixerNodeTypePlayerRecorder || nodeType == JWMixerNodeTypeMixerPlayer || nodeType == JWMixerNodeTypeFiveSecondPlayer) {
        
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

-(void)configFiveSecondNode {
    
    for (id node in _playerNodeList) {
        
        id fiveSecondNode = node[@"fivesecondnode"];
        AVAudioMixerNode *mainMixer = [self.audioEngine mainMixerNode];
        
        if (fiveSecondNode) {
            
            id playerNode = fiveSecondNode[@"player"];
            AVAudioFile *audioFile = fiveSecondNode[@"audiofile"];
            if (self.audioEngine && playerNode && audioFile) {
                
                [self.audioEngine attachNode:(JWPlayerNode *)playerNode];
                [self.audioEngine connect:playerNode to:mainMixer format:audioFile.processingFormat];
                
            }
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
    //TODO:added for five seconds;
    [self configFiveSecondNode];
    [self startEngine];
}


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


- (void)createEngineAndAttachNodes {
    
    if (self.audioEngine == nil) {
        [super createEngineAndAttachNodes];
    }
    
    // Attach all available not just active ones
    
    for (int i = 0; i < [_playerNodeList count]; i++) {
        id pn = [self playerForNodeAtIndex:i];
        if (pn) {
            [self.audioEngine attachNode:pn];
            NSLog(@"audioPlayerNode ATTACH");
        }
    }

}

/*  The engine will construct a singleton main mixer and connect it to the outputNode on demand,
 when this property is first accessed. You can then connect additional nodes to the mixer.
 
 By default, the mixer's output format (sample rate and channel count) will track the format
 of the output node. You may however make the connection explicitly with a different format. */


- (void)makeEngineConnections {
    
    
    
    // ITERATE through player list looking for players
    // get the engine's optional singleton main mixer node
    AVAudioMixerNode *mainMixer = [self.audioEngine mainMixerNode];
    
    NSUInteger nNodes = [self.playerNodeList count];
    
    for (int index = 0; index < nNodes; index++) {

        JWMixerNodeTypes nodeType = [self typeForNodeAtIndex:index];
        if (nodeType == JWMixerNodeTypePlayer || nodeType == JWMixerNodeTypePlayerRecorder || nodeType == JWMixerNodeTypeMixerPlayer || nodeType == JWMixerNodeTypeFiveSecondPlayer) {
            // loops, delays and volume attrs not cosidered here
            
            AVAudioPCMBuffer *audioBuffer = [self audioBufferForPlayerNodeAtIndex:index];
            if (audioBuffer) {
                JWPlayerNode* playerNode = [self playerForNodeAtIndex:index];
                
                if (playerNode)
                    [self.audioEngine connect:playerNode to:mainMixer format:audioBuffer.format];
                
            } else {
//                NSLog(@"%s ",__func__);
                NSLog(@"NO audioBuffer player at index %d perhaps try using audioFile for format ",index);
            }
        }
    }
    
    NSLog(@"mixer inputs %i", [mainMixer numberOfInputs]);
    self.needMakeConnections = NO;
}

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

#pragma mark -
// deprecate
-(void)playMicRecordedFile { }
-(void)setMicPlayerFramePosition:(AVAudioFramePosition)micPlayerFramePosition { }
-(void)changeProgressOfSeekingAudioFile:(CGFloat)progress { }
// deprecate to here


//=======================
//  P L A Y I N G
//=======================
#pragma mark - PLAYING

#pragma mark convenience methods

/*
 playAlll
 
 play all available players
 */

-(void)playAlll {
    [self playAlll:NO];  // no, not recording
}

-(void)playAlllStartSeconds:(NSTimeInterval)secondsIn  {
    
    //[self playAlllWithOptions:0 insetSeconds:secondsIn recording:NO];
}

-(void)scheduleAllStartSeconds:(NSTimeInterval)secondsIn  {
    
    [self scheduleAllWithOptions:0 insetSeconds:secondsIn duration:0.0 recording:NO];
}

-(void)scheduleAllStartSeconds:(NSTimeInterval)secondsIn duration:(NSTimeInterval)duration {
    
    [self scheduleAllWithOptions:0 insetSeconds:secondsIn duration:duration recording:NO];
}


//===========================================================================
//  NODE ITERATION AND PLAYER SCHEDULE scheduleAllWithOptions
//===========================================================================

/*
 uses scheduleAllPlayerNode
 
 Play all audio player nodes from beginning and record
 
 
 playAlllWithOptions
 
 - insetSeconds  start playing nSeconds In
 
 all players will read audiofiles nSeconds in from beginning
 nodes with delays will begin reading computed seconds in or have its delay shortened
 
 recording = YES not supported
 
 */

//    NSLog(@"%s %.3f secondsin  %@",__func__,secondsIn,[_playerNodeList description]);
//    NSLog(@"%s %.3f secondsin  node count %ld",__func__,secondsIn,[_playerNodeList count]);


-(void)scheduleAllPlayerNode:(id)playerNodeInfo audioFile:(AVAudioFile *)audioFile index:(NSUInteger)index
                insetSeconds:(NSTimeInterval)secondsIn
                    duration:(NSTimeInterval)duration
                   recording:(BOOL)recording {
    
    AVAudioFormat *processingFormat = [audioFile processingFormat];
    
    // PLAYNODE Config and Properties
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
        [[JWPlayerFileInfo alloc] initWithCurrentPosition:secondsIn duration:durationSeconds
                                            startPosition:secondsDelay
                                               startInset:startInset endInset:endInset];
    }

    // DETERMINE READ POSITION AND DELAY ANd WHETHER HAS AUDIO TO PLAY

    BOOL hasAudioToPlay = YES;
    AVAudioFramePosition readPosition = 0;
    if (secondsDelay > secondsIn) {
        // reduce delay
        delayAudioTime = [AVAudioTime timeWithSampleTime:((secondsDelay - secondsIn) * processingFormat.sampleRate)
                                                  atRate:processingFormat.sampleRate];
    }
    else {
        // delay Zero, and readIn required, delay < secondsIn , in progress
        // delay 5  seconds in 8 read 3 seconds in
        
        readPosition = (secondsIn - secondsDelay) * processingFormat.sampleRate;
    }
    
    if (fileReference) {
        /*
         The fileReference here has secondsDelay builtin will override readposition already established
         */
        if (fileReference.readPositionInReferencedTrack < 0.0) {
            if (fileReference.remainingInTrack > 0) {
                readPosition = fileReference.startPositionInset *  processingFormat.sampleRate;
                
            } else {
                NSLog(@"fileReference read position negative");
                hasAudioToPlay = NO;
            }
        } else {
            readPosition = fileReference.readPositionInReferencedTrack *  processingFormat.sampleRate;
            
            NSLog(@"fileReference dur %.2fs remaining %.2fs read %lld ",
                  fileReference.duration,
                  fileReference.remainingInTrack,
                  readPosition);
        }
    }
    
    //            NSLog(@"%s loops %@ secondsDelay %.3f secondsin %.3f read %lld ",__func__,@(loops),secondsDelay,secondsIn,readPosition);
    
    if (hasAudioToPlay) {
        
        JWMixerNodeTypes type = [playerNodeInfo[@"type"] integerValue];
        
        // GET The player for this audio
        JWPlayerNode* playerNode =  playerNodeInfo[@"player"];
        [_activePlayersIndex addIndex:index];
        
        playerNode.audioFile = audioFile;
        playerNode.fileReference = playerNodeInfo[@"referencefile"];
        playerNode.delayStart = secondsDelay;
        playerNode.startPlayingInset = secondsIn;

        // Final Player completion
        void (^playerCompletion)(void) = ^{
//            NSLog(@"Audio Completed for playerAtIndex %ld",(unsigned long)index);
            dispatch_sync(dispatch_get_main_queue(), ^() {
                if ([_engineDelegate respondsToSelector:@selector(completedPlayingAtPlayerIndex:)])
                    [_engineDelegate completedPlayingAtPlayerIndex:index];
            });
        };
        //TODO: added for five second completion
        void (^fiveSecondCompletion)(void) = ^{
            NSLog(@"Five second completed for playerAtIndex %ld", (unsigned long)index);
            dispatch_sync(dispatch_get_main_queue(), ^() {
                if ([_engineDelegate respondsToSelector:@selector(fiveSecondBufferCompletion)])
                    [_engineDelegate fiveSecondBufferCompletion];
            });
        };
        
        // Option one Buffer read
        // Play buffer One read at position if necessary
        AVAudioFramePosition fileLength = audioFile.length;
        AVAudioFrameCount remainingFrameCount = 0;
        AVAudioFrameCount durationFrameCount = duration * processingFormat.sampleRate;
        if (duration > 0) {
            remainingFrameCount = durationFrameCount;
            NSLog(@"AE USE_DURATION: dfrc %lld %.3f secs, rfrc %u,  %.3f scndsin %ld nds idx %ld",
                  (long long)durationFrameCount,duration,remainingFrameCount,secondsIn,[_playerNodeList count],index);
        } else {
            if (fileReference)
                remainingFrameCount =  fileReference.remainingInTrack * processingFormat.sampleRate;
            else
                remainingFrameCount =  (AVAudioFrameCount)(fileLength - readPosition);

            NSLog(@"AE TO_THE_END: rfrc %u,  %.3f scndsin %ld nds idx %ld",remainingFrameCount,secondsIn,[_playerNodeList count],index);
        }


        // CREATE and READ buffer and READ from the File at READ POSITION
        audioFile.framePosition = readPosition;

        AVAudioFrameCount bufferFrameCapacity = remainingFrameCount;
        AVAudioPCMBuffer *readBuffer =
        [[AVAudioPCMBuffer alloc] initWithPCMFormat: audioFile.processingFormat frameCapacity: bufferFrameCapacity];
        NSError *error = nil;
        if ([audioFile readIntoBuffer: readBuffer error: &error]) {
            
//            NSLog(@"AE FileLength: %lld  %.3f seconds. Buffer length %u",(long long)fileLength,
//                  fileLength / audioFile.fileFormat.sampleRate, readBuffer.frameLength );
            
            // SCHEDULE THE BUFFER
            //TODO: added a check on the type to make sure the right completion block is scheduled
            if (type == JWMixerNodeTypePlayer || type == JWMixerNodeTypeMixerPlayerRecorder) {
                [playerNode scheduleBuffer:readBuffer atTime:delayAudioTime
                                   options:AVAudioPlayerNodeBufferInterrupts
                         completionHandler:playerCompletion
                 ];
                
            } else if (type == JWMixerNodeTypeFiveSecondPlayer) {
                [playerNode scheduleBuffer:readBuffer atTime:delayAudioTime
                                   options:AVAudioPlayerNodeBufferInterrupts
                         completionHandler:fiveSecondCompletion
                 ];
                _scheduledFiveSecondClip = YES;
            }
            
        } else {
            NSLog(@"failed to read audio file: %@", [error description]);
        }
    }
}

/*
 Iteration method scheduleAll
 */

-(void)scheduleAllWithOptions:(NSUInteger)options insetSeconds:(NSTimeInterval)secondsIn
                     duration:(NSTimeInterval)duration
                    recording:(BOOL)recording {

//    NSLog(@"scheduleAllWithOptions %.3f secondsin, %ld nodes",secondsIn,[_playerNodeList count]);
    NSUInteger index = 0;
    
    for (NSDictionary *playerNodeInfo in _playerNodeList) {
        
        JWMixerNodeTypes nodeType = [self typeForNodeAtIndex:index];
        //TODO: fivesecond
        id fiveSecondNode = playerNodeInfo[@"fivesecondnode"];
        id fsAudioFile = fiveSecondNode[@"audiofile"];
        
        if (nodeType == JWMixerNodeTypePlayer || nodeType == JWMixerNodeTypePlayerRecorder || nodeType == JWMixerNodeTypeFiveSecondPlayer) {
            
            AVAudioFile *audioFile = [self audioFileForPlayerNodeAtIndex:index]; // AVAudioFile
            if (audioFile == nil) {
                if (nodeType == JWMixerNodeTypePlayerRecorder)
                    [_activeRecorderIndex addIndex:index];
                
                index++;
                continue; // not interested
            }
            
            // OTHERWISE we are ready to go with a buffer which is what we are scheduling
            // including obtaining delay time information

            [self scheduleAllPlayerNode:playerNodeInfo audioFile:audioFile index:index insetSeconds:secondsIn duration:duration recording:recording];
            //[self schedulePlayerNode:playerNodeInfo audioFile:audioFile index:index insetSeconds:secondsIn duration:duration recording:recording];
            
            if (fiveSecondNode && fsAudioFile) {
                [self scheduleAllPlayerNode:fiveSecondNode audioFile:fsAudioFile index:index insetSeconds:secondsIn duration:duration recording:recording];
            }
        }
        
        index++;
    }
    
    // do not add mixer vab if recording
    
    if (recording == NO  &&  _scrubberTrackIds[@"mixer"]) {
        // install TAP on mixer to provide visualAudio
        
        [self tapTheMixerForScrubberOnly];
    }
    
}


#pragma mark - engine commands


-(void)playFiveSecondNode {
    NSLog(@"%s", __func__);
    
    [self.fiveSecondNode play];
    
}

-(BOOL)playAllActivePlayerNodes {
//    NSLog(@"%s", __func__);
    
    if ([self.activePlayerNodes count] > 0) {
        
        self.mixerVolume = 1.0;
        for (JWPlayerNode* pn in self.activePlayerNodes)
        {
            [pn play];
            NSLog(@"audioPlayerNode PLAY");
        }
        return YES;
        
    } else {
        NSLog(@"No Active player nodes to play.");
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
            NSLog(@"audioPlayerNode PAUSE");
        }
        return YES;
        
    } else {
        NSLog(@"No Active player nodes to PAUSE.");
        return NO;
    }
}


-(BOOL)stopAllActivePlayerNodes {
    //    NSLog(@"%s", __func__);
    
    if (_isRecordingOnly) {
        
        _isRecordingOnly = NO;
        dispatch_async (dispatch_get_global_queue( QOS_CLASS_USER_INTERACTIVE,0),^{
            [self stopRecordOnlyWithPlayerRecorderAtNodeIndex:0];
            [self refresh];
        });

        return YES;
    } else {
        
        if ([self.activePlayerNodes count] > 0) {
            
            for (JWPlayerNode* pn in self.activePlayerNodes)
            {
                [pn stop];
                NSLog(@"audioPlayerNode STOP");
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
            NSLog(@"No Active player nodes to stop.");
            return NO;
        }
    }
}


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


#pragma mark -

//===========================================================================
//  NODE ITERATION AND PLAYER SCHEDULE playAlll
//===========================================================================

/*
 uses playAlllScheduleBufferForPlayerNode
 
 
 */

-(void)playAlllScheduleBufferForPlayerNode:(id)playerNodeInfo
                               audioBuffer:(AVAudioPCMBuffer *)audioBuffer
                                   atIndex:(NSUInteger)index recording:(BOOL)recording
{
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
    playerNode.audioFile = audioFile;
    
    // Build the completion handler
    
    void (^playerCompletion)(void) = ^{
        NSLog(@"Audio Completed for playerAtIndex %ld",index);
        dispatch_sync(dispatch_get_main_queue(), ^() {
            if ([_engineDelegate respondsToSelector:@selector(completedPlayingAtPlayerIndex:)])
                [_engineDelegate completedPlayingAtPlayerIndex:index];
            
        });
    };
    
    void (^playerCompletionMixRecording)(void) = ^{
        NSLog(@"Audio Completed for playerAtIndex %ld",index);
        AVAudioMixerNode* mainMixer = [self.audioEngine mainMixerNode];
        [mainMixer removeTapOnBus:0];
        dispatch_sync(dispatch_get_main_queue(), ^() {
            if ([_engineDelegate respondsToSelector:@selector(mixRecordingCompleted)])
                [_engineDelegate mixRecordingCompleted];
        });
    };

    
    // SCHEDULE THE BUFFER OR FILE
    
    NSUInteger option = 0;
    if (option == 0) {
        // schedule the file
        // doesnt loop
        if (recording  && index == 0)
            [playerNode scheduleFile:audioFile atTime:delayAudioTime  completionHandler:playerCompletionMixRecording];
        else
            [playerNode scheduleFile:audioFile atTime:delayAudioTime  completionHandler:playerCompletion];
        
    } else if (option == 1) {
        
        // SCHEDULE THE BUFFER
        
        AVAudioPlayerNodeBufferOptions boptions = loops? AVAudioPlayerNodeBufferLoops : 0;
        if (recording  && index == 0)
            [playerNode scheduleBuffer:audioBuffer atTime:delayAudioTime options:boptions completionHandler:playerCompletionMixRecording];
        else
            [playerNode scheduleBuffer:audioBuffer atTime:delayAudioTime options:boptions completionHandler:playerCompletion];
    }
}

/*
 Iteration method playAlll
 */

-(void)playAlll:(BOOL)recording {
    
    // recording - whether recording mix
    
    NSUInteger index = 0;
    
    for (NSDictionary *playerNodeInfo in _playerNodeList) {
        
        JWMixerNodeTypes nodeType = [self typeForNodeAtIndex:index];
        
        if (nodeType == JWMixerNodeTypePlayer || nodeType == JWMixerNodeTypePlayerRecorder || nodeType == JWMixerNodeTypeMixerPlayer) {
            
            AVAudioPCMBuffer *audioBuffer = [self audioBufferForPlayerNodeAtIndex:index];
            if (audioBuffer == nil)
                continue; // not interested
            
            // OTHERWISE we are ready to go with a buffer which is what we are scheduling
            // including obtaining delay time information
            
            [self playAlllScheduleBufferForPlayerNode:playerNodeInfo audioBuffer:audioBuffer atIndex:index recording:recording];
        }
        
        index++;
    }
    
    // do not add mixer vab if recording
    
    if (recording == NO  &&  _scrubberTrackIds[@"mixer"]) {
        
        // install TAP on mixer to provide visualAudio
        [self tapTheMixerForScrubberOnly];
    }
    
    self.mixerVolume = 1.0;
    
    for (JWPlayerNode* pn in self.activePlayerNodes)
    {
        [pn play];
        NSLog(@"%s audioPlayerNode PLAY",__func__);
    }
}





//=======================
//  R E C O R D I N G
//=======================
#pragma mark - RECORDING

// helper
-(NSUInteger)numberOfPlayerNodes {
    
    NSUInteger result = 0;
    NSInteger index = 0;
    NSUInteger nNodes = [self.playerNodeList count];
    for (index = 0; index < nNodes; index++) {
        if (JWMixerNodeTypePlayer == [self typeForNodeAtIndex:index] ){
            result++;
            break;
        }
    }
    
    return result;
}

// helper
-(NSInteger)firstAvailableRecorderIndex {
    
    NSUInteger result = NSNotFound;
    NSInteger index = 0;
    NSUInteger nNodes = [self.playerNodeList count];
    for (index = 0; index < nNodes; index++) {
        if (JWMixerNodeTypePlayerRecorder == [self typeForNodeAtIndex:index] ) {
            if ([self playerNodeFileURLAtIndex:index] == nil) {
                result = index; // found
                break;
            }
        }
    }
    
    return result;
}

-(BOOL)prepareToRecordFirstAvailable {
    
    BOOL result = NO;
    NSInteger index = [self firstAvailableRecorderIndex];
    if (index != NSNotFound) {
        [self recordWithPlayerRecorderAtNodeIndex:index];
        result = YES;
    }
    return result;
}

-(void)prepareToRecord {
    
    if ([self numberOfPlayerNodes] == 0 && [self.playerNodeList count] == 1){
        
        NSInteger index = [self firstAvailableRecorderIndex];
        if (index != NSNotFound)
            [self recordOnlyWithPlayerRecorderAtNodeIndex:index];
        
    } else {
        
        // first recorder playernode now
        
        if ([self prepareToRecordFirstAvailable]) {
            NSLog(@"%s RECORDING AT FIRST AVAILABLE RECORDER",__func__);
        } else {
            NSLog(@"%s NO AVAILABLE RECORDERS",__func__);
        }
    }
}

-(JWAudioRecorderController*)recorderForPlayerNodeAtIndex:(NSUInteger)pindex {

    JWAudioRecorderController* result;
    
    if (pindex < [self.playerNodeList count]) {
        NSDictionary *playerNodeInfo = self.playerNodeList[pindex];
        JWMixerNodeTypes nodeType = [self typeForNodeAtIndex:pindex];
        
        if (nodeType == JWMixerNodeTypePlayerRecorder) {
            id rc = playerNodeInfo[@"recorderController"];
            if (rc)
                result = (JWAudioRecorderController*)rc;
        }
    }
    
    return result;
}

-(NSInteger)indexOfFirstRecorderNodeWithNoAudio {
    
    //Want to put the url for the recording
    int returnIndex = 0;
    for (NSMutableDictionary *pn in _playerNodeList) {
        
        JWMixerNodeTypes nodeType = [pn[@"type"] integerValue];
        NSString *fileString = pn[@"fileURLString"];
        
        if (nodeType == JWMixerNodeTypeMixerPlayerRecorder) {
            
            if (!fileString) {
                //This is the top most recorder node with no fileURL
                return returnIndex;
            }
        }
        returnIndex++;
    }
    return -1;
    
}



// NO Playback simply start recording

- (NSURL*)recordingFileURLPlayerRecorderAtNodeIndex:(NSUInteger)prIndex {

    NSURL* result;
    JWAudioRecorderController* rc  =[self recorderForPlayerNodeAtIndex:prIndex];
    result = rc.micOutputFileURL;
    return result;
}

- (void)recordOnlyWithPlayerRecorderAtNodeIndex:(NSUInteger)prIndex {
    _isRecordingOnly = YES;
    JWAudioRecorderController* rc  =[self recorderForPlayerNodeAtIndex:prIndex];
    rc.metering = NO;
    [rc record];
}

- (NSTimeInterval)recordingTimeRecorderAtNodeIndex:(NSUInteger)prIndex {
    NSTimeInterval result = 0;
    JWAudioRecorderController* rc  =[self recorderForPlayerNodeAtIndex:prIndex];
    result = [rc currentTime];
    return result;
}

- (void)stopRecordOnlyWithPlayerRecorderAtNodeIndex:(NSUInteger)prIndex {

    JWAudioRecorderController* rc  =[self recorderForPlayerNodeAtIndex:prIndex];
    
    [rc stopRecording];
    
    // READ Recorded File into buffer
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
    
    [_activeRecorderIndex removeIndex:prIndex];

    dispatch_sync(dispatch_get_main_queue(), ^() {
        if ([_engineDelegate respondsToSelector:@selector(userAudioObtainedAtIndex:recordingId:)])
            [_engineDelegate userAudioObtainedAtIndex:prIndex recordingId:rc.recordingId];
        if ([_engineDelegate respondsToSelector:@selector(userAudioObtained)])
            [_engineDelegate userAudioObtained];
        if ([_engineDelegate respondsToSelector:@selector(completedPlayingAtPlayerIndex:)])
            [_engineDelegate completedPlayingAtPlayerIndex:0];  // Notify end, and to rewind
    });
    
}



//===========================================================================
//  NODE ITERATION AND PLAYER SCHEDULE playAllRecordingFromBeginnigAtIndex
//===========================================================================

/*
 uses playAllRecordingScheduleBufferForPlayerNode

 Play all audio player nodes from beginning and record
 
  play all with fade in from primary
 In order to play all and record with a fade, i need to get the current position the
 audio is at and i need to check if any crops have been done.  This is so if they are recording
 from the middle of audio it can start there, or if they are recording from the beggining
 of a clipped track, i can use seconds before the clips to fade in.

 */

/*
 prepareToRecordFromBeginningAtPlayerRecorderNodeIndex
 record from beginning with fade in
 */

// convenience

-(void)prepareToRecordFromBeginningAtPlayerRecorderNodeIndex:(NSUInteger)index {
    
    //TODO: changed fade
    [self playAllRecordingFromBeginnigAtIndex:index fadeIn:YES];
}

-(void)playAllRecordingScheduleBufferForPlayerNode:(id)playerNodeInfo audioBuffer:(AVAudioPCMBuffer *)audioBuffer
                                           atIndex:(NSUInteger)index
                                   atRecorderIndex:(NSUInteger)prIndex
                                              fade:(BOOL)fade
{
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
    
    JWPlayerNode* playerNode = [self playerForNodeAtIndex:index];
    [_activePlayersIndex addIndex:index];
    
    playerNode.audioFile = [self audioFileForPlayerNodeAtIndex:index]; // AVAudioFile
    
    
    JWAudioRecorderController *rc = [self recorderForPlayerNodeAtIndex:prIndex];
    
    // Build the completion handlers
    
    void (^playerCompletion)(void) = ^{
        NSLog(@"Audio Completed for playerAtIndex %ld",(unsigned long)index);
        dispatch_sync(dispatch_get_main_queue(), ^() {
            if ([_engineDelegate respondsToSelector:@selector(completedPlayingAtPlayerIndex:)])
                [_engineDelegate completedPlayingAtPlayerIndex:index];
        });
    };
    
    void (^playerCompletionFiveSecond)(void) = ^{
        // Turn ON microphone
        [rc record];
        NSLog(@"Five Second Audio Completed");
        // Notify delegate
        dispatch_sync(dispatch_get_main_queue(), ^() {
            if ([_engineDelegate respondsToSelector:@selector(fiveSecondBufferCompletion)])
                [_engineDelegate fiveSecondBufferCompletion];
        });
    };

    void (^playerCompletionRecording)(void) = ^{
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

        [_activeRecorderIndex removeIndex:prIndex];

        self.needMakeConnections = YES;  // need to make engine connections as this has now become a player
        
        dispatch_sync(dispatch_get_main_queue(), ^() {
            if ([_engineDelegate respondsToSelector:@selector(userAudioObtainedAtIndex:recordingId:)])
                [_engineDelegate userAudioObtainedAtIndex:prIndex recordingId:rc.recordingId];
            if ([_engineDelegate respondsToSelector:@selector(userAudioObtained)])
                [_engineDelegate userAudioObtained];
        });
    };
    
    
    if (fade && index == 0) {
        
        NSLog(@"%s _fiveSecondBuffer %u audioBuffer %u",__func__,_fiveSecondBuffer.frameLength,audioBuffer.frameLength );
        // use the volume, ignore delay and loops for the fade scheduling and loop options
        
        self.mixerVolume = 0.0;
        
        //only schedule if framelength of five second buffer is > 0.0
        if (_fiveSecondBuffer.frameLength > 0.0) {
            
            // SCHEDULE THE BUFFER
            // Schedule fade in buffer playing buffer immediatelyfollowing
            
            [playerNode scheduleBuffer:_fiveSecondBuffer atTime:nil options:0 completionHandler:playerCompletionFiveSecond];
            
        } else {
            // Turn ON microphone
            [rc record];
        }
        
        // SCHEDULE THE BUFFER
        // Schedule full playing buffer
        
        [playerNode scheduleBuffer:audioBuffer atTime:nil options:0 completionHandler:playerCompletionRecording];
        
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

        // SCHEDULE THE BUFFER

        if (isRecording)
            [playerNode scheduleBuffer:audioBuffer atTime:delayAudioTime options:boptions completionHandler:playerCompletionRecording];
        else
            [playerNode scheduleBuffer:audioBuffer atTime:delayAudioTime options:boptions completionHandler:playerCompletion];

    }
    
}

/*
 Iteration method playAllRecordingFromBeginnig
 */

-(void)playAllRecordingFromBeginnigAtIndex:(NSUInteger)prIndex fadeIn:(BOOL)fade{
    
    NSUInteger index = 0;  // index to playerNodeList
    
    for (NSDictionary *playerNodeInfo in _playerNodeList) {
        
        if (index == prIndex)
            continue;  // skip the one recording

        JWMixerNodeTypes nodeType = [self typeForNodeAtIndex:index];
        
        if (nodeType == JWMixerNodeTypePlayer || nodeType == JWMixerNodeTypePlayerRecorder) {
            
            AVAudioPCMBuffer *audioBuffer = [self audioBufferForPlayerNodeAtIndex:index];
            if (audioBuffer == nil)
                continue; // not interested

            // OTHERWISE we are ready to go with a buffer which is what we are scheduling
            // including obtaining delay time information
            
            [self playAllRecordingScheduleBufferForPlayerNode:playerNodeInfo audioBuffer:audioBuffer
                                                      atIndex:index atRecorderIndex:prIndex
                                                         fade:fade];
            
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



//===========================================================================
//  NODE ITERATION AND PLAYER SCHEDULE recordWithPlayerRecorderAtNodeIndex
//===========================================================================

/*
 uses recordWithScheduleBufferForPlayerNode
 
 
 similar to playALL but skips the JWMixerNodeTypePlayerRecorder that is recording
 from beginnig
 
*/
-(void)recordWithScheduleBufferForPlayerNode:(id)playerNodeInfo audioBuffer:(AVAudioPCMBuffer *)audioBuffer
                                     atIndex:(NSUInteger)index
                             atRecorderIndex:(NSUInteger)prIndex
{
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
    
    // RECONCILE Audiofile
    
    JWPlayerNode* playerNode = [self playerForNodeAtIndex:index];
    [_activePlayersIndex addIndex:index];
    
    playerNode.audioFile = [self audioFileForPlayerNodeAtIndex:index]; // AVAudioFile
    
    AVAudioPlayerNodeBufferOptions boptions = loops? AVAudioPlayerNodeBufferLoops : 0;

    
    JWAudioRecorderController* rc  =[self recorderForPlayerNodeAtIndex:prIndex];
    
    // Build the completion handlers
    void (^playerCompletion)(void) = ^{
        NSLog(@"Audio Completed for playerAtIndex %ld",(unsigned long)index);
        dispatch_sync(dispatch_get_main_queue(), ^() {
            if ([_engineDelegate respondsToSelector:@selector(completedPlayingAtPlayerIndex:)])
                [_engineDelegate completedPlayingAtPlayerIndex:index];
        });
    };

    void (^playerCompletionRecording)(void) = ^{
        NSLog(@"Audio Completed for playerAtIndex %ld",(unsigned long)index);
        
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
        
        [_activeRecorderIndex removeIndex:prIndex];
        
        self.needMakeConnections = YES;
        
        dispatch_sync(dispatch_get_main_queue(), ^() {
            if ([_engineDelegate respondsToSelector:@selector(userAudioObtainedAtIndex:recordingId:)])
                [_engineDelegate userAudioObtainedAtIndex:prIndex recordingId:rc.recordingId];
            if ([_engineDelegate respondsToSelector:@selector(userAudioObtained)])
                [_engineDelegate userAudioObtained];
        });
    };
    
    // SCHEDULE THE BUFFER

    if (index == 0) // primary player
        [playerNode scheduleBuffer:audioBuffer atTime:delayAudioTime options:boptions completionHandler:playerCompletionRecording];
    else
        [playerNode scheduleBuffer:audioBuffer atTime:delayAudioTime options:boptions completionHandler:playerCompletion];

}

/*
 Iteration method recordWithPlayerRecorder
 */

- (void)recordWithPlayerRecorderAtNodeIndex:(NSUInteger)prIndex {
    
    NSUInteger index = 0;
    
    for (NSDictionary *playerNodeInfo in _playerNodeList) {
        
        if (index == prIndex)
            continue;  // skip the one recording
        
        JWMixerNodeTypes nodeType = [self typeForNodeAtIndex:index];
        
        if (nodeType == JWMixerNodeTypePlayer || nodeType == JWMixerNodeTypePlayerRecorder ) {
            
            AVAudioPCMBuffer *audioBuffer = [self audioBufferForPlayerNodeAtIndex:index];
            if (audioBuffer == nil)
                continue; // not interested

            // OTHERWISE we are ready to go with a buffer which is what we are scheduling
            // including obtaining delay time information
            
            [self recordWithScheduleBufferForPlayerNode:playerNodeInfo audioBuffer:audioBuffer atIndex:index atRecorderIndex:prIndex];
        }
        
        index++;
    }
    
    // do not add mixer vab if recording
    // RECORD AND PLAY
    
    JWAudioRecorderController* rc  =[self recorderForPlayerNodeAtIndex:prIndex];

    [rc record];
    
    for (JWPlayerNode* pn in self.activePlayerNodes)
    {
        [pn play];
        NSLog(@"%s audioPlayerNode PLAY",__func__);
    }
    
}


#pragma mark -

-(void)tapTheMixerForScrubberOnly {
    
    // install TAP on mixer to provide visualAudio
    AVAudioMixerNode* mainMixer = [self.audioEngine mainMixerNode];
    
    NSLog(@"%s Installed visual Audio mixer tap",__func__);
    [mainMixer installTapOnBus:0 bufferSize:2024 format:[mainMixer outputFormatForBus:0]
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

#pragma mark - Scrubber support

// This allows the scrubber to move the playhead on the player

-(AVAudioFramePosition)playerFramePostion {
    return [[_playerNode1 lastRenderTime] sampleTime];
}

-(void)setProgressSeekingAudioFile:(CGFloat)progressSeekingAudioFile {
    _progressSeekingAudioFile = progressSeekingAudioFile;
}


@end





//===========================================================================
//  KEEPME - option buffer reads
//
//===========================================================================

//// Option Buffer by buffer
//else if (option==2) {
//
//    // Play buffer by buffer starting at read pos  read a portion and play the rest
//    const AVAudioFrameCount kBufferFrameCapacity = 8 * 1024L;  // 8k .1857 seconds at 44100
//    AVAudioPCMBuffer *readBuffer =
//    [[AVAudioPCMBuffer alloc] initWithPCMFormat:audioFile.processingFormat frameCapacity: kBufferFrameCapacity];
//
//    audioFile.framePosition = readPosition;
//
//    //    NSLog(@"FileLength: %lld  %.3f seconds ",
//    //          (long long)fileLength, fileLength / seekingAudioFile.fileFormat.sampleRate);
//
//    NSError *error = nil;
//
//    if ([audioFile readIntoBuffer: readBuffer error: &error]) {
//        [playerNode scheduleBuffer:readBuffer
//                            atTime:delayAudioTime
//                           options:AVAudioPlayerNodeBufferInterrupts
//                 completionHandler:^{
//                     NSError *error;
//                     AVAudioPCMBuffer *buffer =
//                     [[AVAudioPCMBuffer alloc] initWithPCMFormat:audioFile.processingFormat
//                                                   frameCapacity:(AVAudioFrameCount)audioFile.length];
//
//                     if ([audioFile readIntoBuffer: buffer error: &error]) {
//                         [playerNode scheduleBuffer:buffer
//                                             atTime:nil
//                                            options:AVAudioPlayerNodeBufferInterrupts
//                                  completionHandler:finalPlayerCompletion
//                          ];
//
//                     } else {
//                         NSLog(@"failed to read audio file: %@", error);
//                     }
//                 }];
//
//    } else {
//        NSLog(@"failed to read audio file: %@", [error description]);
//    }
//}
//// Option Schedule segment
//else if (option==3) {
//
//    // Simply schedule some sound to play while seeking
//    // Need a way to continue playing to end
//    AVAudioFramePosition fileLength = audioFile.length;
//    AVAudioFrameCount framesToread = 22050; // half second at 44100
//    if ((readPosition + framesToread) > fileLength) {
//        framesToread = (AVAudioFrameCount) (fileLength - readPosition);
//    }
//
//    // TODO: needs to read the rest
//    [playerNode scheduleSegment:playerNode.audioFile
//                  startingFrame:readPosition
//                     frameCount:framesToread
//                         atTime:delayAudioTime
//              completionHandler:^{
//                  NSLog(@"seeking played segment");
//                  // Now play here until end
//
//              }];
//}
//
//// NO OPtion normal play all
//else {
//    AVAudioPCMBuffer *audioBuffer = [self audioBufferForPlayerNodeAtIndex:index];
//    if (audioBuffer == nil)
//    {
//        //continue; // not interested
//        return;
//    }
//    AVAudioPlayerNodeBufferOptions boptions = loops? AVAudioPlayerNodeBufferLoops : 0;
//    [playerNode scheduleBuffer:audioBuffer atTime:delayAudioTime options:boptions completionHandler:finalPlayerCompletion];
//}


//===========================================================================
//  for ref to be tossed
//===========================================================================



