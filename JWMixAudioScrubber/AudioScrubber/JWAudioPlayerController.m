//
//  JWAudioPlayerController.m
//  JWAudioScrubber
//
//  Created by brendan kerr on 12/27/15.
//  Copyright © 2015 b3k3r. All rights reserved.
//

#import "JWAudioPlayerController.h"
#import "JWScrubber.h"
#import "JWScrubberController.h"
#import "JWMTEffectsAudioEngine.h"
#import "JWPlayerControlsViewController.h"
#import "JWMixEditTableViewController.h"
#import "JWMixNodes.h"

@interface JWAudioPlayerController () <
JWScrubberControllerDelegate,
JWMTAudioEngineDelgegate,
JWScrubberInfoDelegate,
JWMixEditDelegate
> {
    BOOL _colorizedTracks;
    BOOL _rewound;
    BOOL _listenToPositionChanges;
    BOOL _wasPlaying;
    BOOL _isRecording;

    UIColor *iosColor2;
    UIColor *iosColor1;
    UIColor *iosColor3;
    UIColor *iosColor4;
    UIColor *iosColor5;
    UIColor *iosColor6;
    UIColor *iosColor7;
    UIColor *iosColor8;
}
@property (nonatomic) JWScrubberController *sc;
@property (nonatomic) JWPlayerControlsViewController* pcvc;
@property (nonatomic) JWMixEditTableViewController *metvc;
@property (strong, nonatomic) JWMTEffectsAudioEngine *audioEngine;
@property (strong, nonatomic) NSDictionary *scrubberTrackColors;
@property (strong, nonatomic) NSDictionary *scrubberColors;
@property (strong, nonatomic) NSDate *editChangeTimeStamp;
@property (strong, nonatomic) NSDate *editChangeUpdateTimeStamp;
@property (strong, nonatomic) NSDate *positionChangeUpdateTimeStamp;
@property (strong, nonatomic) id currentEditTrackInfo;
@property (nonatomic) CGFloat currentPositionChange;
@property (nonatomic, readwrite) PlayerControllerState state;
@property (nonatomic) CGFloat backLightValue;;
@end


@implementation JWAudioPlayerController

-(instancetype)init {
    if (self = [super init]) {
        [self iosColors];
    }
    return self;
}

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

#pragma mark -

-(void) initializePlayerControllerWithScrubber:(id)svc playerControls:(id)pvc mixEdit:(id)me {
    
    [self iosColors];
    _listenToPositionChanges = NO;
    id savedBackLightValue = [[NSUserDefaults standardUserDefaults] valueForKey:@"backlightvalue"];
    _backLightValue = savedBackLightValue ? [savedBackLightValue floatValue] : 0.22;
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

// initialize
-(void) initializePlayerControllerWithScrubberWithAutoplayOn:(BOOL)autoplay
                                               usingScrubberView:(id)svc playerControls:(id)pvc mixEdit:(id)me
                                              withCompletion:(JWPlayerCompletionHandler)completion
{
    id savedBackLightValue = [[NSUserDefaults standardUserDefaults] valueForKey:@"backlightvalue"];
    _backLightValue = savedBackLightValue ? [savedBackLightValue floatValue] : 0.22;
    _autoPlay = autoplay;
//    _listenToPositionChanges = _autoPlay ? NO : YES;
    
    _listenToPositionChanges = NO;
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
            if (completion) {
                completion();
            }
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

-(void)iosColors {
    iosColor1 = [UIColor colorWithRed:128/255.0 green:128/255.0 blue:0/255.0 alpha:1.0]; // asparagus
    iosColor2 = [UIColor colorWithRed:0/255.0 green:64/255.0 blue:128/255.0 alpha:1.0]; // ocean
    iosColor3 = [UIColor colorWithRed:0/255.0 green:128/255.0 blue:255/255.0 alpha:1.0]; // aqua
    iosColor4 = [UIColor colorWithRed:102/255.0 green:204/255.0 blue:255/255.0 alpha:1.0]; // sky
    iosColor5 = [UIColor colorWithRed:153/255.0 green:153/255.0 blue:153/255.0 alpha:1.0]; // aluminum
    iosColor6 = [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1.0]; // mercury
    iosColor7 = [UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1.0]; // tungsten
    iosColor8 = [UIColor colorWithRed:102/255.0 green:102/255.0 blue:102/255.0 alpha:1.0]; // steel
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
    
    for (id item in _trackItems) {
        NSMutableDictionary *playerNode = [self newEnginePlayerNodeForTrackSetItem:item];
        if (playerNode)
            [nodeList addObject:playerNode];
    }

    _audioEngine.playerNodeList = nodeList;

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

    NSLog(@"node type %ld title %@  fname %@  ",[playerNode[@"type"] unsignedIntegerValue],
          titleValue?titleValue:@"notitle",
          fileURL?[fileURL lastPathComponent]:@"nofilurl");
    
    return playerNode;
}


// SAMPLE EFFECTS CONFIG
//    @{@"type" : @(JWEffectNodeTypeReverb),
//      @"title" : @"Reverb",
//      @"factorypreset" : @(AVAudioUnitReverbPresetMediumRoom),
//      },
//    @{@"type" : @(JWEffectNodeTypeDelay),
//      @"title" : @"Delay",
//      @"feedback" : @(0.0),
//      @"lowpasscutoff" : @(15000.0)
//      },
//    @"delaytime" : @(0.0)
//@"lowpasscutoff" : @(15000.0),
//    @{@"type" : @(JWEffectNodeTypeReverb),
//      @"title" : @"Reverb",
//      @"factorypreset" : @(AVAudioUnitReverbPresetSmallRoom),
//      },
//    @{@"type" : @(JWEffectNodeTypeDelay),
//      @"title" : @"Delay",
//      @"feedback" : @(0.0),
//      @"lowpasscutoff" : @(0.0),
//      @"delaytime" : @(0.0)
//      },
//    @{@"type" : @(JWEffectNodeTypeDistortion),
//      @"title" : @"Distortion",
//      @"factorypreset" : @(AVAudioUnitDistortionPresetMultiDistortedFunk),
//      @"pregain" : @(0.0)
//      }


#pragma mark  old setTracks
// -----------------------------------
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


//DEFAULT COLORS FOR SCRUBBER
-(NSDictionary*)defaultWhiteColors {
    return @{
             JWColorScrubberTopPeak : [[UIColor whiteColor] colorWithAlphaComponent:0.6],
             JWColorScrubberTopAvg : [UIColor colorWithWhite:0.9 alpha:0.5] ,
             JWColorScrubberBottomAvg : [UIColor colorWithWhite:0.9 alpha:0.5],
             JWColorScrubberBottomPeak : [[UIColor whiteColor] colorWithAlphaComponent:0.6],
             JWColorScrubberTopPeakNoAvg : [[UIColor whiteColor] colorWithAlphaComponent:0.8],
             JWColorScrubberBottomPeakNoAvg : [[UIColor whiteColor] colorWithAlphaComponent:0.8],
             };
}


-(BOOL)recordingWithoutPlayers {
    
    BOOL result = NO;
    NSArray *playerNodeList = [self.audioEngine playerNodeList];
    
    if ([playerNodeList count] > 0) {
        id item = playerNodeList[0];
        
        if (item) {
            JWMixerNodeTypes nodeType = [item[@"type"] integerValue];
            
            if (nodeType == JWMixerNodeTypePlayerRecorder)
                result = YES;
        }
    }
    return result;
}



#pragma mark - BUTTON PRESSED PROTOCOL

-(void)play
{
    self.state = JWPlayerStatePlayFromPos;
}

-(void)rewind
{
    self.state = JWPlayerStateSetToBeg;
}

-(void)pause
{
    if (_state == JWPlayerStateRecFromPos) {
        //Ask the user if they want to keep the audio or re-record
        self.state = JWPlayerStateSetToBeg;
    } else {
        self.state = JWPlayerStateSetToPos;
    }
}

//    if (_state != JWPlayerStateRecFromPos) {
//        self.state = JWPlayerStateSetToPos;
//    } else {
//        //Ask the user if they want to keep the audio or re-record
//        self.state = JWPlayerStateSetToBeg;
////        if (_isRecording) {
////            _isRecording = NO;
////            self.state = JWPlayerStatePlayFromBeg;
////            [self configureScrubbers:NO];
////        }
//    }

-(void)record
{
    self.state = JWPlayerStateRecFromPos;
}

//TODO: added this
-(BOOL) canRecordAudio {
    
    return [[_audioEngine activeRecorderNodes] count] > 0 ? YES : NO;
}


-(void)setState:(PlayerControllerState)state {
    
    _state = state;
    //TODO: added this
    
    switch (state) {
        case JWPlayerStatePlayFromBeg:
            
            _listenToPositionChanges = NO;
            [_sc stopPlaying:nil rewind:YES];
            [_audioEngine stopAllActivePlayerNodes];
            [_audioEngine scheduleAllStartSeconds:0.0];
            
            break;
            
        case JWPlayerStatePlayFromPos:
            
            if ([_audioEngine playAllActivePlayerNodes])
                [_sc play:nil];
            
            break;

        case JWPlayerStateSetToPos:
            
            [_audioEngine pauseAllActivePlayerNodes];
            [_sc stopPlaying:nil];
            
            break;

        case JWPlayerStateSetToBeg:
            
            _listenToPositionChanges = NO;
            [_sc stopPlaying:nil rewind:YES];
            [_audioEngine stopAllActivePlayerNodes];
            
            break;
            
        case JWPlayerStateRecFromPos:
            
            if ([self recordingWithoutPlayers]) {

                _isRecording = YES;
                
                NSURL *fileURL = [_audioEngine recordOnlyWithPlayerRecorderAtNodeIndex:0];

                [_sc recordAt:[self trackIdForPlayerNodeAtIndex:0] usingFileURL:fileURL];
                
            } else {
                
                [_audioEngine prepareToRecord];
                [_sc playRecord:nil];
            }

        default:
            break;
    }
    
    [_pcvc setState:_state withRecording:[self canRecordAudio]];
}


-(NSUInteger)numberOfTracks
{
    return _sc.numberOfTracks;
}


#pragma mark - CONDIFURE SCRUBBER

-(void)startListening {
    
    _listenToPositionChanges = YES;
}

-(void)scrubberConfigurePlayer:(id)playerNode withFileURL:(NSURL*)fileURL {
    
    float delay = 0.0;
    id delayItem = playerNode[@"starttime"];
    if (delayItem)
        delay = [delayItem floatValue];
    
    NSDictionary * fileReference;
    id referenceFileItem = playerNode[@"referencefile"];
    if (referenceFileItem)
        fileReference = referenceFileItem;
    
    SampleSize ssz =  SampleSize18;
    VABKindOptions kind =  VABOptionCenter;
    VABLayoutOptions layout = VABLayoutOptionOverlayAverages | VABLayoutOptionShowAverageSamples | VABLayoutOptionShowCenterLine;
    
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
                                  JWColorScrubberTopPeak : [ iosColor4 colorWithAlphaComponent:0.5],
//                                  JWColorScrubberTopAvg : [UIColor colorWithWhite:0.88 alpha:0.8],
//                                  JWColorScrubberBottomAvg : [UIColor colorWithWhite:0.88 alpha:0.8],
                                  JWColorScrubberBottomPeak : [ iosColor3 colorWithAlphaComponent:0.5],
                                  }
     
                  referenceFile:fileReference
                      startTime:delay
                   onCompletion:nil];
    
    [playerNode setValue:sid forKey:@"trackid"];
    
}

//        iosColor5 = [UIColor colorWithRed:153/255.0 green:153/255.0 blue:153/255.0 alpha:1.0]; // aluminum
//        iosColor6 = [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1.0]; // mercury
//        iosColor7 = [UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1.0]; // tungsten
//        iosColor8 = [UIColor colorWithRed:102/255.0 green:102/255.0 blue:102/255.0 alpha:1.0]; // steel

-(void)scrubberConfigurePlayerRecorder:(id)playerNode atIndex:(NSUInteger)index withFileURL:(NSURL*)fileURL playerOnly:(BOOL)playerOnly {
    
    float delay = 0.0;
    id delayItem = playerNode[@"starttime"];
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
                             colors:nil
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
                                    colors:
         @{
           JWColorScrubberTopPeak : [[UIColor redColor] colorWithAlphaComponent:0.3],
           JWColorScrubberTopAvg : [UIColor colorWithWhite:0.88 alpha:0.8],
           JWColorScrubberBottomAvg : [UIColor colorWithWhite:0.88 alpha:0.8],
           JWColorScrubberBottomPeak : [[UIColor redColor] colorWithAlphaComponent:0.3],
           }
                              onCompletion:nil];
        
        
        [_audioEngine registerController:_sc withTrackId:recorderTrackId forPlayerRecorderAtIndex:index];
        
        [playerNode setValue:recorderTrackId forKey:@"trackid"];
    }
}


- (void)configureScrubbers:(BOOL)tap {

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
    
    //    [self performSelector:@selector(startListening) withObject:nil afterDelay:0.25];
    
}


// PLAYER

// Configure Track Colors for all Tracks
// configureColors is whole saled the dictionary is simply kept

//    configureColors
//    configureScrubberColors - needs to be called or crash

//        iosColor5 = [UIColor colorWithRed:153/255.0 green:153/255.0 blue:153/255.0 alpha:1.0]; // aluminum
//        iosColor6 = [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1.0]; // mercury
//        iosColor7 = [UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1.0]; // tungsten
//        iosColor8 = [UIColor colorWithRed:102/255.0 green:102/255.0 blue:102/255.0 alpha:1.0]; // steel

-(void)configureScrubberColors {
    
    if (_colorizedTracks == NO) {  // set the base to whites
        // Track colors whiteColor/ whiteColor - WHITE middle
        [_sc configureColors:[self defaultWhiteColors]];

        [_sc configureScrubberColors:
         @{
           JWColorBackgroundHueColor : [UIColor blackColor],
          JWColorBackgroundHeaderGradientColor2 : [UIColor blackColor],
          JWColorBackgroundHeaderGradientColor1 : iosColor8
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
             
             @{ JWColorBackgroundHueColor : iosColor2
                }
             
             ];  // default blue ocean
        }
    }
}


#pragma mark scrubber commands

-(BOOL) editSelectedTrackBeginInset {
    if (_sc.selectedTrack) {
        [_sc editTrackBeginInset:_sc.selectedTrack];
        return YES;
    }
    return NO;
}
-(BOOL) editSelectedTrackEndInset {
    if (_sc.selectedTrack) {
        [_sc editTrackEndInset:_sc.selectedTrack];
        return YES;
    }
    return NO;
}
-(BOOL) editSelectedTrackStartPosition {
    if (_sc.selectedTrack) {
        [_sc editTrackStartPosition:_sc.selectedTrack];
        return YES;
    }
    return NO;
}

-(BOOL) stopEditingSelectedTrackSave {
    if (_sc.selectedTrack) {
        [_sc stopEditingTrackSave:_sc.selectedTrack];
        return YES;
    }
    return NO;
}
-(BOOL) stopEditingSelectedTrackCancel {
    if (_sc.selectedTrack) {
        [_sc stopEditingTrackCancel:_sc.selectedTrack];
        return YES;
    }
    return NO;
}


#pragma mark - SCRUBBER DELEGATE

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
    
    if (_isRecording) {
        NSUInteger index = [self playerNodeIndexForTrackId:sid];
        result = [_audioEngine recordingTimeRecorderAtNodeIndex:index];
    } else {
        result = [_audioEngine currentPositionInSecondsOfAudioFileForPlayerAtIndex:0];
    }
    
    return result;
}

-(NSString*)processingFormatStr:(JWScrubberController*)controller forScrubberId:(NSString*)sid{

    return [_delegate playerControllerTitleForTrackSetContainingKey:self];
    
//    return [_audioEngine processingFormatStr];
    
}


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


#pragma mark edit scrubber delegate

-(void)editingCompleted:(JWScrubberController*)controller forScrubberId:(NSString*)sid {
    
    [self editingCompleted:controller forScrubberId:sid withTrackInfo:nil];
}

-(void)editingCompleted:(JWScrubberController*)controller forScrubberId:(NSString*)sid withTrackInfo:(id)trackInfo {
    
    if (trackInfo) {
        NSLog(@"%s %@ %@",__func__,sid,[trackInfo description]);
        
        if ([trackInfo isKindOfClass:[NSDictionary class]]) {
            id startTimeValue = trackInfo[@"starttime"];
            if (startTimeValue)
                _trackItem[@"starttime"] = startTimeValue;
            id refFile = trackInfo[@"referencefile"];
            if (refFile)
                _trackItem[@"referencefile"] = refFile;
            
            [_delegate save:self];
        }
        
    } else {
        NSLog(@"%s no reference No change %@",__func__,sid);
    }
}


-(void)editingMadeChange:(JWScrubberController*)controller forScrubberId:(NSString*)sid {
    
    [self editingMadeChange:controller forScrubberId:sid withTrackInfo:nil];
}

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

//#define TRACEUPDATES

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
    
    if (_listenToPositionChanges) {
        
        //TODO: THIS IS not WRONG
//        self.currentPositionChange = position;
//        _state = JWPlayerStateSetToPos;
//        [_pcvc setState:_state];
        
        [_audioEngine setCurrentPositionInAudio:position];
        
        if ([self positionUpdateTask] == NO) {
            // DID not update will delay and try again
            double delayInSecs = 0.48;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSecs * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self positionUpdateTask];
            });
        }
    }
}

-(BOOL)positionUpdateTask {
    
    NSDate *timeStamp = [NSDate date];
    BOOL doUpdate = NO;
    if (_positionChangeUpdateTimeStamp == nil){
        doUpdate = YES;
    } else {
        NSTimeInterval timeSinceUpdate = [timeStamp timeIntervalSinceDate:_positionChangeUpdateTimeStamp];
        if (timeSinceUpdate > .48)
            doUpdate = YES;
    }
    
    if (doUpdate) {
        self.positionChangeUpdateTimeStamp = [NSDate date];
        
#ifdef TRACEUPDATES
        NSLog(@"%s\n=== DO POSITION UPDATE =======================================",
              __func__);
        NSLog(@"%s postion %.4f secs",__func__,_currentPositionChange);
#endif
//        if (_state != JWPlayerStateSetToBeg) {
//            [_audioEngine scheduleAllStartSeconds:_currentPositionChange];
//            [_audioEngine playAllActivePlayerNodes];
//            _state = JWPlayerStateSetToPos;
        
    } else {
        // silently ignore
        //NSLog(@"%s IGNORE update",__func__);
    }
    
    return doUpdate;
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


#pragma mark scrubber track interaction

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
    
    if (self.state == JWPlayerStateSetToBeg || self.state == JWPlayerStatePlayFromBeg)
        
        self.state = JWPlayerStatePlayFromPos;
    
    else if (self.state != JWPlayerStatePlayFromPos)
        
        self.state = JWPlayerStatePlayFromPos;
    else
        self.state = JWPlayerStateSetToPos;
}

-(NSURL*)recordingFileURL:(JWScrubberController*)controller {
    
    NSURL *fileURL = [_audioEngine recordingFileURLPlayerRecorderAtNodeIndex:0];
    
    return fileURL;
}


#pragma mark - ENGINE DELEGATE

-(void)completedPlayingAtPlayerIndex:(NSUInteger)index {
    
    if (index == 0)
        self.state = JWPlayerStatePlayFromBeg;
    
    [_delegate playTillEnd];
    [_sc playedTillEnd:nil];
}

-(void)userAudioObtained {
    
    if (_isRecording) {
        _isRecording = NO;
        self.state = JWPlayerStatePlayFromBeg;
        [self configureScrubbers:NO];
        
    } else {
        [self configureScrubbers:NO];
        [_delegate playTillEnd];
        [_sc playedTillEnd:nil];
    }

}

-(void) userAudioObtainedAtIndex:(NSUInteger)index recordingId:(NSString*)rid {
    // Pass it up the chain
    if ([_delegate respondsToSelector:@selector(userAudioObtainedAtIndex:recordingId:)])
        [_delegate userAudioObtainedAtIndex:index recordingId:rid];
}

#pragma mark - MIXEDIT DELEGATE

- (id <JWEffectsModifyingProtocol>) mixNodeControllerForScrubber
{
    return _sc;
}

- (id <JWEffectsModifyingProtocol>) trackNodeControllerForNodeAtIndex:(NSUInteger)index {
    
    id <JWEffectsModifyingProtocol> result;
    
    id trackIdValue = [self trackIdForPlayerNodeAtIndex:index];
    if (trackIdValue)
        result = [_sc trackNodeControllerForTrackId:trackIdValue];

    return result;
}

- (void)recordAtNodeIndex:(NSUInteger)index
{
    NSLog(@"%s NOT IMPLEMENTED %ld", __func__,index);
}


@end




