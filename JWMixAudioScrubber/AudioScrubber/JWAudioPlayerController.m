 //
//  JWAudioPlayerController.m
//  JWAudioScrubber
//
//  Created by brendan kerr on 12/27/15.
//  Copyright © 2015 b3k3r. All rights reserved.
//

#import "JWAudioPlayerController.h"
#import "JWScrubber.h"

#import "JWMixEditTableViewController.h"
#import "JWMixNodes.h"
#import "UIColor+JW.h"

@interface JWAudioPlayerController ()
<
JWScrubberControllerDelegate,
JWMTAudioEngineDelgegate,
JWScrubberInfoDelegate,
JWMixEditDelegate
>
{
    BOOL _colorizedTracks;
    BOOL _rewound;

    BOOL _wasPlaying;
    BOOL _editing;
    BOOL _scrubbAudioEnabled;
    BOOL _scrubbAudioContinuesPlaying;
    CGFloat _momentTime;
    CGFloat _momentPreviewTime;
    CGFloat _momentDefaultTime;
}


@property (nonatomic) JWMixEditTableViewController *metvc;
@property (strong, nonatomic) NSDictionary *scrubberTrackColors;
@property (strong, nonatomic) NSDictionary *scrubberColors;
@property (strong, nonatomic) NSDate *editChangeTimeStamp;
@property (strong, nonatomic) NSDate *editChangeUpdateTimeStamp;
@property (strong, nonatomic) NSDate *positionChangeUpdateTimeStamp;
@property (strong, nonatomic) id currentEditTrackInfo;
@property (nonatomic) CGFloat currentPositionChange;
@property (nonatomic) CGFloat lastPlayPosition;
@property (nonatomic, readwrite) PlayerControllerState state;
@property (nonatomic) CGFloat backLightValue;;
@property (nonatomic) NSString *previewMomentId;

@end


@implementation JWAudioPlayerController

-(instancetype)init {
    if (self = [super init]) {
    }
    return self;
}

#pragma mark -

-(void) startupInits {
    id savedBackLightValue = [[NSUserDefaults standardUserDefaults] valueForKey:@"backlightvalue"];
    _backLightValue = savedBackLightValue ? [savedBackLightValue floatValue] : 0.22;
    _momentDefaultTime = 1.1;
    _momentTime = _momentDefaultTime; // secs
    _momentPreviewTime = 1.25 * _momentDefaultTime; // secs
    _scrubbAudioEnabled = YES;
    _scrubbAudioContinuesPlaying = NO;
    _currentPositionChange = 0.0;
    _lastPlayPosition = 0.0;
    _listenToPositionChanges = NO;
}

-(void) initializePlayerControllerWithScrubber:(id)svc playerControls:(id)pvc mixEdit:(id)me {
    _autoPlay = NO;
    [self startupInits];
    //INITIALIZE ENGINE AND COMPONENTS
    self.audioEngine = [[JWMTEffectsAudioEngine alloc] init];
    self.audioEngine.engineDelegate = self;
    self.metvc = me;
    self.metvc.delegateMixEdit = self;
    self.metvc.effectsHandler = self.audioEngine;
    self.sc = [[JWScrubberController alloc] initWithScrubber:(JWScrubberViewController*)svc andBackLightValue:_backLightValue];
    self.sc.delegate = self;
    self.pcvc = (JWPlayerControlsViewController *)pvc;
    self.pcvc.delegate = self;
    self.pcvc = pvc;
    [self.pcvc initializeWithState:_state withLightBackround:NO];
}

// initialize wrapper
-(void) initializePlayerControllerWithScrubber:(id)svc playerControls:(id)pvc mixEdit:(id)me
                                withCompletion:(JWPlayerCompletionHandler)completion
{
    [self initializePlayerControllerWithScrubberWithAutoplayOn:NO
                                             usingScrubberView:svc playerControls:pvc mixEdit:me
                                                withCompletion:completion];
}


// designated initialize
-(void) initializePlayerControllerWithScrubberWithAutoplayOn:(BOOL)autoplay
                                               usingScrubberView:(id)svc playerControls:(id)pvc mixEdit:(id)me
                                              withCompletion:(JWPlayerCompletionHandler)completion
{
    _autoPlay = autoplay;
    [self startupInits];
    self.metvc = me;
    self.pcvc = (JWPlayerControlsViewController *)pvc;
    [self.pcvc initializeWithState:_state withLightBackround:NO];
    //INITIALIZE ENGINE IN BACKGROUND
    dispatch_async (dispatch_get_global_queue( QOS_CLASS_USER_INITIATED,0),^{
        self.audioEngine = [[JWMTEffectsAudioEngine alloc] init];
        self.audioEngine.engineDelegate = self;
        self.metvc.delegateMixEdit = self;
        self.metvc.effectsHandler = self.audioEngine;
        self.pcvc.delegate = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            self.sc = [[JWScrubberController alloc]
                       initWithScrubber:(JWScrubberViewController*)svc andBackLightValue:_backLightValue];
            self.sc.delegate = self;
            if (completion)
                completion();
        });
    });
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillBackground:)
                                                 name:@"AppWillBackground" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillForeground:)
                                                 name:@"AppWillForeground" object:nil];
    
    // AND RETURN

}


/*
 stop and kill to shutdown the player controller
 */
-(void)stop {
    _listenToPositionChanges = NO;
    [_sc stopPlaying:nil rewind:NO];
    [_audioEngine stopAllActivePlayerNodes];
    [[NSUserDefaults standardUserDefaults] setValue:@(_sc.backlightValue) forKey:@"backlightvalue"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSLog(@"%s STOP player controller",__func__);
}

-(void)stopKill {
    NSLog(@"%s",__func__);
    [self stop];
    self.audioEngine = nil;
    self.metvc = nil;
    self.pcvc = nil;
    self.sc = nil;
}


-(void)appWillBackground:(id)noti {
    NSLog(@"%s",__func__);
    _wasPlaying = [_sc isPlaying];
    [_sc stopPlaying:nil rewind:NO];
}

-(void)appWillForeground:(id)noti {
    NSLog(@"%s",__func__);
    if (_wasPlaying)
        [_sc resumePlaying];
}

#pragma mark -

-(void)setTrackSet:(id)trackSet {
    
    NSLog(@"%s",__func__);
    _trackItems = trackSet;
    if (_trackItems) {
        _state = JWPlayerStateSetToBeg;
        [self rebuildPlayerNodeListAndPlayIfAutoplay];
    }
}

// PLAYER NODE LIST AND PLAY IF AUTOPLAY

-(void)rebuildPlayerNodeListAndPlayIfAutoplay {
    
    NSMutableArray *nodeList = [NSMutableArray new];
    NSString *keyToIdFiveSecondNode = nil;
    
    for (id item in _trackItems) {
        NSMutableDictionary *playerNode = [self newEnginePlayerNodeForTrackSetItem:item];
        
        if (item[@"audiofilekey"]) {
            keyToIdFiveSecondNode = item[@"audiofilekey"];
        }
        
        if (playerNode)
            [nodeList addObject:playerNode];
    }

    _audioEngine.playerNodeList = nodeList;
    _hasFiveSecondClip = [_audioEngine addFiveSecondNodeToListForKey:keyToIdFiveSecondNode];
    
    [_audioEngine initializeAudioConfig];
    [_audioEngine initializeAudio];
    [self configureScrubbers:NO];
    [_audioEngine playerForNodeAtIndex:0].volume = 0.750;
    self.state = JWPlayerStatePlayFromBeg;
    if (_autoPlay) {
        double delayInSecs = 0.20;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSecs * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self play];
        });
    }
}

- (NSMutableDictionary*) newEnginePlayerNodeForTrackSetItem:(NSDictionary*)item {
    
    NSMutableDictionary *playerNode;
    
    NSURL *fileURL = item[@"fileURL"];
    
    
    NSMutableDictionary * fileReference =
    [@{@"duration":@(0),
       @"startinset":@(1.0),
       @"endinset":@(0.0),
       } mutableCopy];
    
    JWMixerNodeTypes  nodeType = JWMixerNodeTypeNone;
    id typeValue = item[@"type"];
    if (typeValue) {
        nodeType = [typeValue unsignedIntegerValue];
        if (nodeType == JWMixerNodeTypePlayer) {
            playerNode =
            [@{@"title":@"playernode1",
               @"type":@(JWMixerNodeTypePlayer),
               } mutableCopy];
        } else if (nodeType == JWMixerNodeTypePlayerRecorder) {
            
            playerNode =
            [@{@"title":@"playerrecordernode1",
               @"type":@(JWMixerNodeTypePlayerRecorder),
               @"nodekey":item[@"key"],
               
//               @"referencefile": fileReference,

               } mutableCopy];
        }
        if (fileURL)
            playerNode[@"fileURLString"] = [fileURL path];
        
    } else { // NO TYPE VALUE
        NSLog(@"%s No Type SHOULD NEVER HAPPEN Value in node config",__func__);
        if (fileURL) {
            playerNode =
            [@{@"title":@"playernode",
               @"type":@(JWMixerNodeTypePlayer),
               @"fileURLString":[fileURL path],
               } mutableCopy];
        } else {
            playerNode =
            [@{@"title":@"player recorder node",
               @"type":@(JWMixerNodeTypePlayerRecorder),
               } mutableCopy];
        }
    }
    
    id titleValue = item[@"title"];
    if (titleValue)
        playerNode[@"title"] = titleValue;
    
    id delayItem = item[@"starttime"];
    float delay = 0.0;
    if (delayItem)
        delay = [delayItem floatValue];
    
    if (delay > 0.0)
        playerNode[@"delay"] = @(delay);
    
//    playerNode[@"delay"] = @(0.5);
    
    id referenceFileItem = item[@"referencefile"];
    if (referenceFileItem)
        playerNode[@"referencefile"] = referenceFileItem;
    
    id effects = item[@"effects"];
//#warning auto effcts
//    effects = [NSNull null];
    
    if (effects) {
        NSArray *effectsArray =
        @[
          @{@"type" : @(JWEffectNodeTypeReverb),
            @"title" : @"Reverb",
            @"factorypreset" : @(AVAudioUnitReverbPresetSmallRoom),
            },
          
          @{@"type" : @(JWEffectNodeTypeDistortion),
            @"title" : @"Distortion",
            @"factorypreset" : @(AVAudioUnitDistortionPresetMultiDistortedFunk),
            @"pregain" : @(0.0)
            }
          ];
        
        playerNode[@"effects"] = effectsArray;
    }
    
    id confignode = item[@"config"];
    if (confignode)
        playerNode[@"config"] = confignode; //  slider values

    NSLog(@"node type %u title %@  fname %@  ",[playerNode[@"type"] unsignedIntegerValue],
          titleValue?titleValue:@"notitle",
          fileURL?[fileURL lastPathComponent]:@"nofilurl");
    
    return playerNode;
}


#pragma mark  old setTracks
// old track itesms Did not contain JWPlayerNodeType
-(void)setTrackItems:(id)trackItems {
    NSLog(@"%s NO LONGER USED use trackSet",__func__);
    _trackItems = trackItems;
}


-(void)setTrackItem:(id)trackItem {
    _trackItem = trackItem;
    if (trackItem) {
        self.trackItems = @[_trackItem];  // 1 trackItem
    } else {
        NSLog(@"%s NO LONGER USED use trackSet",__func__);
}
}

- (NSMutableDictionary*) newEnginePlayerNodeForItem:(NSDictionary*)item {
    NSLog(@"%s NO LONGER USED use trackSet",__func__);
    NSMutableDictionary *playerNode;
    return playerNode;
}

-(void)addEffectToEngineNodelist:(NSString *)effect {
    
    [self.audioEngine stopAllActivePlayerNodes];
    
    NSString *selectedTrackID = _sc.selectedTrack;
    
    if ([effect isEqualToString:@"reverb"]) {
        [self.audioEngine addEffect:JWEffectNodeTypeReverb toPlayerNodeID:selectedTrackID];
    } else if ([effect isEqualToString:@"delay"]) {
        [self.audioEngine addEffect:JWEffectNodeTypeDelay toPlayerNodeID:selectedTrackID];
    } else if ([effect isEqualToString:@"distortion"]) {
        [self.audioEngine addEffect:JWEffectNodeTypeDistortion toPlayerNodeID:selectedTrackID];
    } else if ([effect isEqualToString:@"eq"]) {
        [self.audioEngine addEffect:JWEffectNodeTypeEQ toPlayerNodeID:selectedTrackID];
    }
    [_metvc refresh];
    self.state = JWPlayerStatePlayFromBeg;
    
    
}


#pragma mark - Controller

-(void)deSelectTrack
{
    _sc.selectedTrack = nil;
}

-(NSUInteger)firstValidTrackIndexForSelection {
    
    NSUInteger resultIndex = 0;
    NSUInteger index = 0;
    
    NSArray *playerNodeList = [self.audioEngine playerNodeList];
    
    for (NSMutableDictionary *item in playerNodeList) {
        NSURL *fileURL = [_audioEngine playerNodeFileURLAtIndex:index];
        JWMixerNodeTypes nodeType = [item[@"type"] integerValue];

        if (nodeType == JWMixerNodeTypePlayerRecorder) {
            if (fileURL) {
                resultIndex = index;
                break;
            }
        }
        index++;
    }
    
    return resultIndex;
}

-(void)selectValidTrack {
    
    NSUInteger selectedIndex = [self firstValidTrackIndexForSelection];
    NSArray *playerNodeList = [self.audioEngine playerNodeList];
    NSString *sid = [(NSDictionary*)playerNodeList[selectedIndex] valueForKey:@"trackid"];

    _sc.selectedTrack = sid;
    [_metvc setSelectedNodeIndex:selectedIndex];
    [_metvc refresh];
}

-(NSUInteger)numberOfTracks {
    return _sc.numberOfTracks;
}

-(NSUInteger)numberOfTracksWithAudio {
    
    return [self.audioEngine countOfNodesWithAudio];
}

//DEFAULT COLORS FOR SCRUBBER
-(NSDictionary*)defaultWhiteColorsMoreAlpha {
    return @{
             JWColorScrubberTopPeak : [[UIColor whiteColor] colorWithAlphaComponent:0.6],
             JWColorScrubberTopAvg : [UIColor colorWithWhite:0.9 alpha:0.5] ,
             JWColorScrubberBottomAvg : [UIColor colorWithWhite:0.9 alpha:0.5],
             JWColorScrubberBottomPeak : [[UIColor whiteColor] colorWithAlphaComponent:0.6],
             JWColorScrubberTopPeakNoAvg : [[UIColor whiteColor] colorWithAlphaComponent:0.8],
             JWColorScrubberBottomPeakNoAvg : [[UIColor whiteColor] colorWithAlphaComponent:0.8],
             };
}
-(NSDictionary*)defaultWhiteColors {
    return @{
             JWColorScrubberTopPeak : [[UIColor whiteColor] colorWithAlphaComponent:0.8],
             JWColorScrubberTopAvg : [UIColor colorWithWhite:0.9 alpha:0.7] ,
             JWColorScrubberBottomAvg : [UIColor colorWithWhite:0.9 alpha:0.7],
             JWColorScrubberBottomPeak : [[UIColor whiteColor] colorWithAlphaComponent:0.8],
             
             JWColorScrubberTopPeakNoAvg : [[UIColor whiteColor] colorWithAlphaComponent:0.8],
             JWColorScrubberBottomPeakNoAvg : [[UIColor whiteColor] colorWithAlphaComponent:0.],
             };
}


-(BOOL)recordingWithoutPlayers {
    
    BOOL result = NO;
    NSArray *playerNodeList = [self.audioEngine playerNodeList];
    
    if ([playerNodeList count] > 0) {
        id item = playerNodeList[0];
        if (item) {
            JWMixerNodeTypes nodeType = [item[@"type"] integerValue];
            if (nodeType == JWMixerNodeTypePlayerRecorder) {
                id fileURL = item[@"fileURLString"];
                if (fileURL == nil)
                    result = YES;
            }
        }
    }
    return result;
}


#pragma mark - BUTTON PRESSED PROTOCOL

-(void)play
{
    if (self.state != JWPlayerStateScrubbAudioFromPosMoment && self.state != JWPlayerStateScrubbAudioPreviewMoment)
        self.state = JWPlayerStatePlayFromPos;
    else
        NSLog(@"cannot play in moment");

}

-(void)rewind
{
    if (self.state != JWPlayerStateScrubbAudioFromPosMoment && self.state != JWPlayerStateScrubbAudioPreviewMoment)
        self.state = JWPlayerStateSetToBeg;
}

-(void)pause
{
    if (self.state != JWPlayerStateScrubbAudioFromPosMoment && self.state != JWPlayerStateScrubbAudioPreviewMoment)
    {
        if (_state == JWPlayerStateRecFromPos) {
            //Ask the user if they want to keep the audio or re-record
            self.state = JWPlayerStateSetToBeg;
        } else {
            self.state = JWPlayerStateSetToPos;
        }
    }
}

-(void)record
{
    if (_hasFiveSecondClip)
        self.state = JWPlayerStatePlayFiveSecondAudio;
     else
    if (self.state != JWPlayerStateScrubbAudioFromPosMoment && self.state != JWPlayerStateScrubbAudioPreviewMoment)
        self.state = JWPlayerStateRecFromPos;
}




-(void)timerFireMethod:(NSTimer *)timer {
    
    NSLog(@"%s increase volume: %f",__func__, [_audioEngine mixerVolume]);
    
    float timerStep = 0.10; // timer interval
    float factorIncrement = timerStep / 5.0f;  // divide by 5 seconds
    float mvol = [_audioEngine mixerVolume] + factorIncrement;
    
    if (mvol > 1.00f) {
        [timer invalidate];
        _audioEngine.mixerVolume = 1.00f;
        
        
    } else {
        _audioEngine.mixerVolume = mvol;
    }
    
}




-(BOOL) canRecordAudio {
    
    return [[_audioEngine activeRecorderNodes] count] > 0 ? YES : NO;
}

//-(void)setState:(PlayerControllerState)state {
//    
//       PlayerControllerState fromState = _state;
//    
//    NSLog(@"state %ld to %ld",(long)fromState,(long)state);

-(void)setState:(PlayerControllerState)state {
    
    _state = state;
    
    switch (state) {
        case JWPlayerStatePlayFromBeg: {
            _editing = NO;
            _listenToPositionChanges = NO;
            [_sc stopPlaying:nil rewind:YES];
            [_audioEngine stopAllActivePlayerNodes];
            [_audioEngine scheduleAllStartSeconds:0.0 duration:0.0];
            if (_scrubbAudioEnabled) {
                double delayInSecs = 0.25;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSecs * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    _listenToPositionChanges = YES;
                });
            }
        }
            // And await PLAY
            break;
            
        case JWPlayerStateScrubbAudioFromPosMoment:
            [_audioEngine stopAllActivePlayerNodes];
            [_audioEngine scheduleAllStartSeconds:_currentPositionChange duration:_momentTime];
            [_audioEngine playAllActivePlayerNodes];
            _lastPlayPosition = _currentPositionChange;
            [_sc readyForScrub];
            break;

        case JWPlayerStateScrubbAudioPreviewMoment: {
            
            _previewMomentId = [[NSUUID UUID] UUIDString];
            NSString *temporalId = [_previewMomentId copy];
            _listenToPositionChanges = NO;
            [_audioEngine stopAllActivePlayerNodes];
            [_audioEngine scheduleAllStartSeconds:_currentPositionChange duration:_momentTime];
            [_audioEngine playAllActivePlayerNodes];
            [_sc playMomentFromPos:_currentPositionChange toPosition:_currentPositionChange + _momentTime];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_momentTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (self.state == JWPlayerStateScrubbAudioPreviewMoment) {
                    if ([temporalId isEqualToString:_previewMomentId]) {
                        NSLog(@"SAME PREVIEW rewind to position %.3f secs",_currentPositionChange);
                        [_sc seekToPosition:_currentPositionChange animated:YES];
                        // Enough time for anim to pass
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            if ([temporalId isEqualToString:_previewMomentId])
                                self.state = JWPlayerStateSetPlayToPos;
                        });
                    } else {
                        NSLog(@"OLD PREVIEW discarded");
                    }
                }
            });
        }
            break;

        case JWPlayerStateSetPlayToPos:
            if (_scrubbAudioEnabled && _scrubbAudioContinuesPlaying) {
                // TODO: this doesnt work well
                // Continues play till the End
                [_audioEngine scheduleAllStartSeconds:_currentPositionChange + _momentTime duration:0.0];
                if ([_audioEngine playAllActivePlayerNodes]){
                    _listenToPositionChanges = NO;
                    [_sc play:nil];
                    [_sc readyForPlay:nil];
                } else {
                    [_sc stopPlaying:nil];
                    [_sc readyForPlay:nil];
                    if (_scrubbAudioEnabled)
                        _listenToPositionChanges = YES;
                }
            } else {
                [_audioEngine stopAllActivePlayerNodes];
                [_audioEngine scheduleAllStartSeconds:_currentPositionChange duration:0.0];
                [_sc readyForPlay:nil];
                if (_scrubbAudioEnabled)
                    _listenToPositionChanges = YES;
            }
            // And await PLAY
            break;
            
        case JWPlayerStatePlayFromPos:
            if ([_audioEngine playAllActivePlayerNodes]){
                _listenToPositionChanges = NO;
                [_sc play:nil];
            } else {
                [_sc stopPlaying:nil];
            }
            break;
            
        case JWPlayerStateSetToPos:
            [_audioEngine pauseAllActivePlayerNodes];
            [_sc stopPlaying:nil];
            if (_scrubbAudioEnabled)
                _listenToPositionChanges = YES;
            // And await PLAY
            break;

        case JWPlayerStateSetToBeg:
            _listenToPositionChanges = NO;
            [_sc stopPlaying:nil rewind:YES];
            [_audioEngine stopAllActivePlayerNodes];
            if (_scrubbAudioEnabled)
                _listenToPositionChanges = YES;
            break;
            
        case JWPlayerStateRecFromPos: {
            _listenToPositionChanges = NO;
            BOOL singleRecorder = [self recordingWithoutPlayers];
            [_audioEngine prepareToRecord];
            if (singleRecorder)
                [_sc recordAt:[self trackIdForPlayerNodeAtIndex:0]];
            else
                [_sc playRecord:nil];
        }
            break;
            
        case JWPlayerStatePlayFiveSecondAudio:
            
            [_audioEngine setMixerVolume:0.0];
            
            self.fiveSecondTimer =
            [NSTimer scheduledTimerWithTimeInterval:1.0 target:[_delegate countDownTarget] selector:@selector(countdownTimerFireMethod:)
                                           userInfo:nil repeats:YES];
            
            self.mixerValueFadeTimer =
            [NSTimer scheduledTimerWithTimeInterval:0.10 target:self selector:@selector(timerFireMethod:)
                                           userInfo:nil repeats:YES];

            [_audioEngine playFiveSecondNode];

        default:
            break;
    }
    
    [_pcvc setState:_state withRecording:[self canRecordAudio]];
}


#pragma mark - ENGINE DELEGATE

-(void)completedPlayingAtPlayerIndex:(NSUInteger)index {
    
    if (self.positionChangeUpdateTimeStamp) {
        
        // if scrubbing positionChange
        
    } else {
        if (self.state == JWPlayerStateSetPlayToPos) {
            // Ignore callbacks waiting for play
            
        } else {
            
            if (index == 0) {
                // Primary Player
                self.state = JWPlayerStatePlayFromBeg;
                [_delegate playTillEnd];
                [_sc playedTillEnd:nil];
            } else {
                // Other Players blink the track
                id trackId = [self trackIdForPlayerNodeAtIndex:index];
                if (trackId) {
                    [_sc modifyTrack:trackId alpha:0.5];
                    double delayInSecs = 0.25;
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSecs * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [_sc modifyTrack:trackId alpha:1.0];
                    });
                }
            }
        }
    }
}

-(void)userAudioObtained {
    [_delegate playTillEnd];
    [_sc playedTillEnd:nil];
    [self configureScrubbers:NO];
}

-(void)userAudioObtainedAtIndex:(NSUInteger)index recordingId:(NSString*)rid {
    // Pass it up the chain
    if ([_delegate respondsToSelector:@selector(userAudioObtainedAtIndex:recordingId:)])
        [_delegate userAudioObtainedAtIndex:index recordingId:rid];
}


#pragma mark - CONDIFURE SCRUBBER

-(void)configureScrubbers:(BOOL)tap {
    
    _listenToPositionChanges = NO;
    
    BOOL recordAudio = NO;
    BOOL recordMix = NO;
    BOOL tapMixer = tap;
    if (recordAudio)
        tapMixer = NO;
    if (recordMix)
        tapMixer = YES;
    
    // STEP 1 CONFIGURE SCRUBBER SETTINGS before reset
    
    _sc.useGradient      = YES;
    _sc.useTrackGradient = NO;
    _sc.pulseBackLight   = NO;
    
    [_sc reset];
    
    // STEP 2 SET OPTIONS FOR NEW SCRUBBERS
    
    NSArray *playerNodeList = [self.audioEngine playerNodeList];
    _sc.numberOfTracks = [playerNodeList count] + (tapMixer ? 1 : 0);
    
    [_sc setViewOptions:ScrubberViewOptionDisplayOnlyValueLabels];
    
    //_sc.trackLocations = @[@(0.70)];
    
    _sc.scrubberControllerSize = [_delegate updateScrubberHeight:self];
    
    [self configureScrubberColors];
    
    
    // STEP 3 CONFIGURE THE SCRUBBERS
    
    NSUInteger index = 0;
    
    for (NSMutableDictionary *item in playerNodeList) {
        JWMixerNodeTypes nodeType = [item[@"type"] integerValue];
        
        if (nodeType == JWMixerNodeTypePlayer) {
            // PLAYER
            NSURL *fileURL = [_audioEngine playerNodeFileURLAtIndex:index];
            if (fileURL) {
                
                [self scrubberConfigurePlayer:item withFileURL:fileURL];
                
            } else {
                // no file URL for player
                NSLog(@"%s NO file url for Player Node at index %ld",__func__,index);
            }
            
        } else if (nodeType == JWMixerNodeTypePlayerRecorder) {
            // PLAYER RECORDER
            //This recorder has no audio and is used to record user audio
            // While Exporting Dont show the Recorder
            // A Recorder uses a different config than a tap on The Mixer
            
            [self scrubberConfigurePlayerRecorder:item atIndex:index
                                      withFileURL:[_audioEngine playerNodeFileURLAtIndex:index]
                                       playerOnly:recordMix];
        }
        
        index++;  // increment playerNode index
        
    } // End iterating
    
    
    
    // Finally, optionally configure the tap on the Mixer
    
    if (tapMixer) {
        NSString *trackidMixerTap =
        [_sc prepareScrubberListenerSource:nil
                            withSampleSize:SampleSize14
                                   options:SamplingOptionDualChannel
                                      type:VABOptionNone
                                    layout:VABLayoutOptionStackAverages | VABLayoutOptionShowAverageSamples | VABLayoutOptionShowCenterLine
                                    colors:
         @{
           JWColorScrubberTopPeak : [[UIColor greenColor] colorWithAlphaComponent:0.5],
           JWColorScrubberBottomPeak : [[UIColor yellowColor] colorWithAlphaComponent:0.7],
           }
                              onCompletion:nil];
        
        [_audioEngine registerController:_sc withTrackId:trackidMixerTap forPlayerRecorder:@"mixer"];
    }
    
    
    // STEP 4 REFRESH THE MIXEDIT
    
    [_metvc refresh];
    
    //    double delayInSecs = 0.15;
    //    //    NSLog(@"%3f",delayInSecs);
    //    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSecs * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    //        _listenToPositionChanges = YES;
    //    });
    
}

-(void)scrubberConfigurePlayer:(id)playerNode withFileURL:(NSURL*)fileURL {
    
    float delay = 0.0;
//    id delayItem = playerNode[@"starttime"];
    id delayItem = playerNode[@"delay"];
    if (delayItem)
        delay = [delayItem floatValue];
    
    NSDictionary * fileReference;
    id referenceFileItem = playerNode[@"referencefile"];
    if (referenceFileItem)
        fileReference = referenceFileItem;
    
    SampleSize ssz =  SampleSize14;
    VABKindOptions kind =  VABOptionCenter;
    VABLayoutOptions layout = VABLayoutOptionOverlayAverages | VABLayoutOptionShowAverageSamples;
//    VABLayoutOptions layout = VABLayoutOptionOverlayAverages | VABLayoutOptionShowAverageSamples | VABLayoutOptionShowCenterLine;
    
    SamplingOptions so = SamplingOptionDualChannel;
    if (_sc.pulseBackLight)
        so |= SamplingOptionCollectPulseData;

//        so &= SamplingOptionCollectPulseData;
    
    //If its a player node that has a file url that buffer info can be recieved
    NSString *sid =
    [_sc prepareScrubberFileURL:fileURL
                 withSampleSize:ssz
                        options:so
                           type:kind
                         layout:layout
                         colors:@{
                                  JWColorScrubberTopPeak : [ [UIColor iosSkyColor] colorWithAlphaComponent:1.0],
                                  JWColorScrubberTopAvg : [UIColor colorWithWhite:0.92 alpha:0.9],
                                  JWColorScrubberBottomAvg : [UIColor colorWithWhite:0.82 alpha:0.9],
                                  JWColorScrubberBottomPeak : [ [UIColor iosAquaColor] colorWithAlphaComponent:1.0],
                                  }
                       referenceFile:fileReference
                      startTime:delay
                   onCompletion:nil];
    
    [playerNode setValue:sid forKey:@"trackid"];
    
}

-(void)scrubberConfigurePlayerRecorder:(id)playerNode atIndex:(NSUInteger)index withFileURL:(NSURL*)fileURL playerOnly:(BOOL)playerOnly {
    
    float delay = 0.0;
//    id delayItem = playerNode[@"starttime"];
    id delayItem = playerNode[@"delay"];
    if (delayItem)
        delay = [delayItem floatValue];
    
    NSDictionary * fileReference;
    id referenceFileItem = playerNode[@"referencefile"];
    if (referenceFileItem)
        fileReference = referenceFileItem;
    
    BOOL usePlayerScrubber = YES;  // determine whther to use player or recorder for scrubber
    //TODO: B resolve this.
    if (fileURL == nil)
        usePlayerScrubber = NO; // USE recorder There is no file, no audio
    
    NSLog(@"usePlayerScrubber for recorderplayer %@ at index %lu",usePlayerScrubber?@"YES":@"NO",index);
    //If recorder has audio file, dont need to listen to it, should just play its audio
    if (usePlayerScrubber) {
        
        NSString *sid =
        [_sc prepareScrubberFileURL:fileURL
                     withSampleSize:SampleSize14
                            options:SamplingOptionDualChannel
                               type:VABOptionNone
                             layout:VABLayoutOptionOverlayAverages | VABLayoutOptionShowAverageSamples | VABLayoutOptionShowCenterLine
                             colors:@{
                                      JWColorScrubberTopPeak : [[UIColor iosMercuryColor] colorWithAlphaComponent:0.6],
                                      JWColorScrubberTopAvg : [UIColor colorWithWhite:0.92 alpha:0.8],
                                      JWColorScrubberBottomAvg : [UIColor colorWithWhite:0.82 alpha:0.8],
                                      JWColorScrubberBottomPeak : [[UIColor iosAluminumColor] colorWithAlphaComponent:0.9],
                                      }

                      referenceFile:fileReference
                          startTime:delay
                       onCompletion:nil];
        
        [playerNode setValue:sid forKey:@"trackid"];
        
    } else if (playerOnly == NO) {

        // use recorder

        // This recorder has no audio and is used to record user audio
        // While Exporting Dont show the Recorder when playerOnly = YES
        // A Recorder uses a different config than a tap on The Mixer
        
        NSString *recorderTrackId =
        [_sc prepareScrubberListenerSource:nil
                            withSampleSize:SampleSize8
                                   options:SamplingOptionDualChannel
                                      type:VABOptionCenter
                                    layout:VABLayoutOptionOverlayAverages | VABLayoutOptionShowAverageSamples
                                    colors:@{
                                             JWColorScrubberTopPeak : [[UIColor iosStrawberryColor] colorWithAlphaComponent:0.8],
                                             JWColorScrubberTopAvg : [[UIColor iosSilverColor] colorWithAlphaComponent:0.8],
                                             JWColorScrubberBottomAvg : [UIColor colorWithWhite:0.88 alpha:0.8],
                                             JWColorScrubberBottomPeak : [[UIColor iosStrawberryColor] colorWithAlphaComponent:0.6],
                                             }
                              onCompletion:nil];
        
        
        [_audioEngine registerController:_sc withTrackId:recorderTrackId forPlayerRecorderAtIndex:index];
        
        [playerNode setValue:recorderTrackId forKey:@"trackid"];
    }
}

// Configure Track Colors for all Tracks
// configureColors is whole saled the dictionary is simply kept
//    configureColors
//    configureScrubberColors - needs to be called or crash

-(void)configureScrubberColors {
    
    if (_colorizedTracks == NO) {  // set the base to whites
        // Track colors whiteColor/ whiteColor - WHITE middle
        [_sc configureColors:[self defaultWhiteColors]];

        [_sc configureScrubberColors:
         @{
           JWColorBackgroundHueColor : [UIColor blackColor],
          JWColorBackgroundHeaderGradientColor2 : [UIColor blackColor],
          JWColorBackgroundHeaderGradientColor1 : [UIColor iosSteelColor]
            }
         ];
        
//        [_sc configureScrubberColors:
//         @{ JWColorBackgroundHueColor : [UIColor blackColor],
//            JWColorBackgroundTrackGradientColor1 : [UIColor blueColor],
//            JWColorBackgroundTrackGradientColor2 : [UIColor blueColor],
//            JWColorBackgroundTrackGradientColor3 : [UIColor clearColor],
//            }
//         ];

        
        // default blue ocean
        //         @{ JWColorBackgroundHueColor : iosColor2
        //            }

    } else {
        if ([_scrubberTrackColors count]) {
            [_sc configureColors:_scrubberTrackColors];
            
        } else {
            [_sc configureColors:[self defaultWhiteColors] ];
        }
        
        if ([_scrubberColors count]) {
            [_sc configureScrubberColors:_scrubberColors ];
            
        } else {
            [_sc configureScrubberColors:
             
             @{ JWColorBackgroundHueColor : [UIColor iosOceanColor]
                }
             
             ];  // default blue ocean
        }
    }
}


#pragma mark - SCRUBBER DELEGATE

//#define TRACEUPDATES

#pragma mark editingMade Changed

-(void)editingMadeChange:(JWScrubberController*)controller forScrubberId:(NSString*)sid withTrackInfo:(id)trackInfo {
    
    //    NSLog(@"%s %@",__func__,sid);
    self.editChangeTimeStamp = [NSDate date];
    @synchronized(self.currentEditTrackInfo) {
        self.currentEditTrackInfo = trackInfo;
    }
    
    if ([self editUpdateTask] == NO) {
        // DID not update will delay and try again
        double delayInSecs = 0.335;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSecs * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self editUpdateTask];
        });
    }
}

-(BOOL)editUpdateTask {
    
    NSDate *timeStamp = [NSDate date];
    BOOL doUpdate = NO;
    
    if (_editChangeUpdateTimeStamp == nil){
        doUpdate = YES;
    } else {
        NSTimeInterval timeSinceUpdate = [timeStamp timeIntervalSinceDate:_editChangeUpdateTimeStamp];
        if (timeSinceUpdate > .33)
            doUpdate = YES;
    }
    
    if (doUpdate) {
        self.editChangeUpdateTimeStamp = [NSDate date];
        
#ifdef TRACEUPDATES
        NSLog(@"%s\n=== DO EDIT UPDATE =======================================",__func__);
#endif
        id trackInfo;
        @synchronized(self.currentEditTrackInfo) {
            trackInfo = self.currentEditTrackInfo;
        }
        
        if (trackInfo) {
            if ([trackInfo isKindOfClass:[NSDictionary class]]) {
                // AS DICTIONARY
#ifdef TRACEUPDATES
                id startTimeValue = trackInfo[@"starttime"];
                float startTime = startTimeValue ? [startTimeValue floatValue] : 0.0;
                id refFile = trackInfo[@"referencefile"];
                if (refFile) {
                    id durationValue = refFile[@"duration"];
                    NSTimeInterval durationSeconds  = durationValue ? [durationValue doubleValue] : 0.0;
                    id startInsetValue = refFile[@"startinset"];
                    float startInset = startInsetValue ? [startInsetValue floatValue] : 0.0;
                    id endInsetValue = refFile[@"endinset"];
                    float endInset = endInsetValue ? [endInsetValue floatValue] : 0.0;
                    
                    NSLog(@"%s start %.4f si %.4f ei %.4f dur %.2f\n",__func__,startTime,startInset,endInset,durationSeconds);
                }
                
                // NSTimeInterval frameDurationSeconds =
                /*  0000 2267     1/44100
                 
                 */
#endif
            }
            
        } else {
            NSLog(@"%s no reference No change",__func__);
        }
        
    } else {
        // silently ignore
        //NSLog(@"%s IGNORE update",__func__);
    }
    
    return doUpdate;
    
}


#pragma mark position Changed


-(void)positionChanged:(JWScrubberController*)controller positionSeconds:(CGFloat)position {
    _momentTime = _momentDefaultTime;
    [self positionChanged:controller positionSeconds:position force:NO];
}

-(void)positionChanged:(JWScrubberController*)controller positionSeconds:(CGFloat)position force:(BOOL)force {
    
    if (_listenToPositionChanges) {
        // Check for significant change in position
        // Recognize when forced or nil (called internally) or chage is greater than preset

        float posChange = fabs(position - _currentPositionChange);
        
        BOOL recognizePositionChange =  ( force || (controller == nil) || (posChange > 0.009));

        if (recognizePositionChange) {
            
            self.currentPositionChange = position;
            
            // Force, for now, temporarily changes moment time to preview time
            if (force)
                _momentTime = _momentPreviewTime;

            if ([self positionUpdateTaskForce:force] == NO) {
                // DID not update, not enough time elapsed, will delay and try again
                double delayInSecs = 0.2200;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSecs * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self positionUpdateTaskForce:force];
                });
            }
            
            
            // As long as we are in Moment (scrubbing) call for a timeout to change state to ready for play
            if (force == NO)
            if (self.state == JWPlayerStateScrubbAudioFromPosMoment) {
                NSTimeInterval timeout = force ? _momentTime : 0.44;
                
                double delayInSecs = _momentTime + 0.02;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSecs * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if (_positionChangeUpdateTimeStamp){
                        NSTimeInterval timeSinceUpdate =  - [_positionChangeUpdateTimeStamp timeIntervalSinceNow];
                        if (timeSinceUpdate > timeout) {
                            NSLog(@"IDLE SET POS    <<======= timeSinceUpdate %.4f",timeSinceUpdate);
                            // Schedule from here to REMAINDER
                            //[_audioEngine scheduleAllStartSeconds:_currentPositionChange duration:0.0];
                            self.state = JWPlayerStateSetPlayToPos;
                            self.positionChangeUpdateTimeStamp= nil;
                        } else {
                            //NSLog(@"timeSinceUpdate %.4f",timeSinceUpdate);
                        }
                    }
                });
            }
            
        } // end recognize change
        
    } // listening
}

-(BOOL)positionUpdateTask {
    return [self positionUpdateTaskForce:NO]; // dont force
}

// Force will ignore checks whther to update
-(BOOL)positionUpdateTaskForce:(BOOL)force {
    
    NSDate *timeStamp = [NSDate date];
    BOOL doUpdate = NO;
    if (force) {
        doUpdate = YES;
        NSLog(@"doUpdate <<< force %@",@(doUpdate));
    } else {
        if (_positionChangeUpdateTimeStamp == nil){
            // starting new
            _lastPlayPosition = 0.0;
            doUpdate = YES;
            NSLog(@"doUpdate <<< new %@",@(doUpdate));
        } else  if (fabs(_lastPlayPosition - _currentPositionChange) < 0.00001) {
            doUpdate = NO; // try to eliminate too soon repeats
            NSLog(@"doUpdate <<< too soon %@",@(doUpdate));
        } else {
            NSTimeInterval timeSinceUpdate = [timeStamp timeIntervalSinceDate:_positionChangeUpdateTimeStamp];
            if (timeSinceUpdate > .20){
                doUpdate = YES;
                NSLog(@"doUpdate <<< timeSinceUpdate %.4f,  currentPosition %.3f secs",timeSinceUpdate,_currentPositionChange);
            }
        }
    }
    
    if (doUpdate) {
        self.positionChangeUpdateTimeStamp = [NSDate date];
#ifdef TRACEUPDATES
        NSLog(@"%s postion %.4f secs",__func__,_currentPositionChange);
#endif
        _lastPlayPosition = _currentPositionChange;
        if (force) {
            self.state = JWPlayerStateScrubbAudioPreviewMoment;
        } else {
            self.state = JWPlayerStateScrubbAudioFromPosMoment;
        }
    }
    // else silently ignore
    //NSLog(@"%s IGNORE update",__func__);
    
    return doUpdate;
}


#pragma mark track interaction

-(void)scrubber:(JWScrubberController *)controller selectedTrack:(NSString *)sid {
    NSLog(@"%s %@", __func__,sid);

    [_delegate trackSelected:self];
    
    NSInteger index = [self playerNodeIndexForTrackId:sid];
    if (index != NSNotFound)
        [_metvc setSelectedNodeIndex:index];

    [_metvc refresh];
}

-(void)scrubberTrackNotSelected:(JWScrubberController *)controller {
    NSLog(@"%s", __func__);
    [_delegate noTrackSelected:self];
}

-(void)scrubberDidLongPress:(JWScrubberController*)controller forScrubberId:(NSString*)sid {
    NSInteger index = [self playerNodeIndexForTrackId:sid];
    if (index != NSNotFound)
        [_delegate playerController:self didLongPressForTrackAtIndex:index];
}

-(void)scrubberPlayHeadTapped:(JWScrubberController*)controller {
    
    NSLog(@"%s %ld",__func__,self.state );
    
    if (self.state == JWPlayerStateScrubbAudioFromPosMoment) {
        
        NSLog(@"PREVIEW MOMENT mom");

    } else if (self.state == JWPlayerStateScrubbAudioPreviewMoment) {
        
        NSLog(@"PREVIEW MOMENT again %.3f ",_lastPlayPosition);
        
        self.state = JWPlayerStateScrubbAudioPreviewMoment;
        
    } else {
    
        // NORMAL Play Pause
        if (self.state == JWPlayerStateSetToBeg || self.state == JWPlayerStatePlayFromBeg || self.state == JWPlayerStateSetToPos) {
            self.state = JWPlayerStatePlayFromPos;
        }
        // Ready to play at Position transitioned from momemnt
        else if (self.state == JWPlayerStateSetPlayToPos) {
            if (_scrubbAudioEnabled && _scrubbAudioContinuesPlaying) {
                [_sc stopPlaying:nil];
                _listenToPositionChanges = YES;
                _currentPositionChange = [_audioEngine currentPositionInSecondsOfAudioFileForPlayerAtIndex:0];
                [self positionChanged:nil positionSeconds:_currentPositionChange - _momentTime - 0.09];

            } else {
                NSLog(@"PREVIEW MOMENT alt");
                self.positionChangeUpdateTimeStamp = [NSDate date];
                _momentTime = _momentPreviewTime;
                _currentPositionChange = _lastPlayPosition;
                self.state = JWPlayerStateScrubbAudioPreviewMoment;
                _listenToPositionChanges = NO;
            }
        }
        // We are not playing so Play
        else if (self.state != JWPlayerStatePlayFromPos) {
            self.state = JWPlayerStatePlayFromPos;

        }
        // Otherwise Pause, ready to play
        else {
            self.state = JWPlayerStateSetToPos;
        }
    }
}

//NSLog(@"PREVIEW MOMENT mom");
//        _listenToPositionChanges = YES;
//        NSTimeInterval playPos = _lastPlayPosition;
//[self positionChanged:nil positionSeconds:playPos force:YES];
//        self.positionChangeUpdateTimeStamp = [NSDate date];
//        _momentTime = _momentPreviewTime;
//        self.state = JWPlayerStateScrubbAudioPreviewMoment;
//            _listenToPositionChanges = NO;
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((_momentTime ) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            [_sc readyForScrub];
//            if (self.state == JWPlayerStateScrubbAudioPreviewMoment) {
//                self.state = JWPlayerStateSetPlayToPos;
//                self.positionChangeUpdateTimeStamp= nil;
//            }
//        });

//                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((_momentTime) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                    [_sc readyForScrub];
//                    if (self.state == JWPlayerStateScrubbAudioPreviewMoment) {
//                        self.state = JWPlayerStateSetPlayToPos;
//                    }
//                });



-(NSURL*)recordingFileURL:(JWScrubberController*)controller {
    
    NSURL *fileURL = [_audioEngine recordingFileURLPlayerRecorderAtNodeIndex:0];
    
    return fileURL;
}


#pragma mark scrubber player status

-(CGFloat)progressOfAudioFile:(JWScrubberController*)controller forScrubberId:(NSString*)sid{
    return [_audioEngine progressOfAudioFileForPlayerAtIndex:0];
}

-(CGFloat)durationInSecondsOfAudioFile:(JWScrubberController*)controller forScrubberId:(NSString*)sid{
    return [_audioEngine durationInSecondsOfAudioFileForPlayerAtIndex:0];
}

-(CGFloat)remainingDurationInSecondsOfAudioFile:(JWScrubberController*)controller forScrubberId:(NSString*)sid{
    return [_audioEngine remainingDurationInSecondsOfAudioFileForPlayerAtIndex:0];
}

-(CGFloat)currentPositionInSecondsOfAudioFile:(JWScrubberController*)controller forScrubberId:(NSString*)sid{
    
    CGFloat result = 0.0;
    if (sid == nil) {
        // primary player
        result = [_audioEngine currentPositionInSecondsOfAudioFileForPlayerAtIndex:0];
    } else {
        // isRecording
        NSUInteger index = [self playerNodeIndexForTrackId:sid];
        result = [_audioEngine recordingTimeRecorderAtNodeIndex:index];
    }
    
    return result;
}

-(NSString*)processingFormatStr:(JWScrubberController*)controller forScrubberId:(NSString*)sid{
    
    return [_delegate playerControllerTitleForTrackSetContainingKey:self];
    
    //    return [_audioEngine processingFormatStr];
    
}


#pragma mark edit scrubber delegate

-(void)editingCompleted:(JWScrubberController*)controller forScrubberId:(NSString*)sid {
    
    [self editingCompleted:controller forScrubberId:sid withTrackInfo:nil];
}

-(void)editingCompleted:(JWScrubberController*)controller forScrubberId:(NSString*)sid withTrackInfo:(id)trackInfo {
    
    if (trackInfo) {
        NSLog(@"%s %@ %@",__func__,sid,[trackInfo description]);
        
        if ([trackInfo isKindOfClass:[NSDictionary class]]) {
            NSInteger index = [self playerNodeIndexForTrackId:sid];
            if (index != NSNotFound) {
                id trackItem = _trackItems[index];
                if (trackItem) {
                    id startTimeValue = trackInfo[@"starttime"];
                    if (startTimeValue)
                        trackItem[@"starttime"] = startTimeValue;
                    id refFile = trackInfo[@"referencefile"];
                    if (refFile)
                        trackItem[@"referencefile"] = refFile;
                }
                
                [_delegate save:self];
                
                [self rebuildPlayerNodeListAndPlayIfAutoplay];
                [_audioEngine stopAllActivePlayerNodes];
            }
        }
        
    } else {
        NSLog(@"%s no reference No change %@",__func__,sid);
    }
    
    //_editing = NO;
}

-(void)editingMadeChange:(JWScrubberController*)controller forScrubberId:(NSString*)sid {
    [self editingMadeChange:controller forScrubberId:sid withTrackInfo:nil];
}

#pragma mark - MIXEDIT DELEGATE

- (id <JWEffectsModifyingProtocol>) mixNodeControllerForScrubber {
    return _sc;
}

- (id <JWEffectsModifyingProtocol>) trackNodeControllerForNodeAtIndex:(NSUInteger)index {
    
    id <JWEffectsModifyingProtocol> result;
    
    id trackIdValue = [self trackIdForPlayerNodeAtIndex:index];
    if (trackIdValue)
        result = [_sc trackNodeControllerForTrackId:trackIdValue];

    return result;
}

- (void)recordAtNodeIndex:(NSUInteger)index {
    NSLog(@"%s NOT IMPLEMENTED %ld", __func__,index);
}


#pragma mark helper

-(id)playerNodeItemForTrackId:(NSString*)sid {
    id result;
    NSInteger index = [self playerNodeIndexForTrackId:sid];
    if (index != NSNotFound)
        result = [self.audioEngine playerNodeList][index];
    return result;
}

-(NSInteger)playerNodeIndexForTrackId:(NSString*)sid {
    NSInteger result = NSNotFound;
    NSUInteger index = 0;
    for (NSMutableDictionary *item in [self.audioEngine playerNodeList]) {
        NSString *trackId = item[@"trackid"];
        if ([sid isEqualToString:trackId]) {
            result = index;
            break;
        }
        index++;
    }
    return result;
}

-(id)trackIdForPlayerNodeAtIndex:(NSUInteger)index {
    id result;
    NSArray *playerNodeList = [self.audioEngine playerNodeList];
    if (index < [playerNodeList count]) {
        id trackIdValue = playerNodeList[index][@"trackid"];
        if (trackIdValue)
            result = trackIdValue;
    }
    return result;
}

#pragma mark scrubber commands

// All edit and stop edits will use the selectedTrack first and when not available use the first node
-(BOOL) editSelectedTrackBeginInset {
    [_sc editTrackBeginInset:_sc.selectedTrack ? _sc.selectedTrack :[self trackIdForPlayerNodeAtIndex:0]];
    return (_editing = YES);
}

-(BOOL) editSelectedTrackEndInset {
    [_sc editTrackEndInset:_sc.selectedTrack ? _sc.selectedTrack :[self trackIdForPlayerNodeAtIndex:0]];
    return (_editing = YES);
}

-(BOOL) editSelectedTrackStartPosition {
    [_sc editTrackStartPosition:_sc.selectedTrack ? _sc.selectedTrack :[self trackIdForPlayerNodeAtIndex:0]];
    return (_editing = YES);
}

-(BOOL) stopEditingSelectedTrackSave {
    [_sc stopEditingTrackSave:_sc.selectedTrack ? _sc.selectedTrack : [self trackIdForPlayerNodeAtIndex:0]];
    return (_editing = NO);
}

-(BOOL) stopEditingSelectedTrackCancel {
    [_sc stopEditingTrackCancel:[self trackIdForPlayerNodeAtIndex:0]];
    return (_editing = NO);
}


@end




//processingFormatStr

//    NSUInteger index = 0;
//    NSString *title;
//    BOOL found = false;
////    [_delegate trackSets:self titleForSection:section];
////    [_delegate trackSets:self titleDetailForSection:section];
//    if (sid) {
//        for (NSMutableDictionary *item in [self.audioEngine playerNodeList]) {
//            id trackId = item[@"trackid"];
//            if (trackId && [sid isEqualToString:trackId]) {
//                title = item[@"title"];
//                found = YES;
//                break; // This one
//            }
//            index++;
//        }
//    } else {
//        index = 0;
//    }
//
//    if (index < [_trackItems count]) {
//        id titleValue = _trackItems[index][@"usertitle"];
//        if (titleValue){
//            title =titleValue;
//        } else {
//            id titleValue = _trackItems[index][@"title"];
//            if (titleValue)
//                title =titleValue;
//        }
//    }
//    if (found == NO) {
//        title = [_audioEngine processingFormatStr];
//    }
//    return title;





