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

@interface JWAudioPlayerController () <JWScrubberControllerDelegate, JWMTAudioEngineDelgegate, JWScrubberInfoDelegate, JWMixEditDelegate> {
    
    BOOL _colorizedTracks;
    BOOL _rewound;
    BOOL _listenToPositionChanges;
    UIColor *iosColor2;
    UIColor *iosColor1;
    UIColor *iosColor3;
    UIColor *iosColor4;
}

@property (strong, nonatomic) JWScrubberController *sc;
@property (strong, nonatomic) JWPlayerControlsViewController* pcvc;
@property (strong, nonatomic) JWMixEditTableViewController *metvc;
@property (strong, nonatomic) JWMTEffectsAudioEngine *audioEngine;
@property (strong, nonatomic) NSDictionary *scrubberTrackColors;
@property (strong, nonatomic) NSDictionary *scrubberColors;
@property (strong, nonatomic) NSDate *editChangeTimeStamp;
@property (strong, nonatomic) NSDate *editChangeUpdateTimeStamp;
@property (strong, nonatomic) NSDate *positionChangeUpdateTimeStamp;
@property (strong, nonatomic) id currentEditTrackInfo;
@property (nonatomic) CGFloat currentPositionChange;
@property (nonatomic, readwrite) PlayerControllerState state;

@end

@implementation JWAudioPlayerController


-(void) initializePlayerControllerWithScrubber:(id)svc playerControls:(id)pvc mixEdit:(id)me {
    
    //SCRUBBER COLORS
    iosColor1 = [UIColor colorWithRed:128/255.0 green:128/255.0 blue:0/255.0 alpha:1.0]; // asparagus
    iosColor2 = [UIColor colorWithRed:0/255.0 green:64/255.0 blue:128/255.0 alpha:1.0]; // ocean
    iosColor3 = [UIColor colorWithRed:0/255.0 green:128/255.0 blue:255/255.0 alpha:1.0]; // aqua
    iosColor4 = [UIColor colorWithRed:102/255.0 green:204/255.0 blue:255/255.0 alpha:1.0]; // sky

    _listenToPositionChanges = NO;

    //INITIALIZE ENGINE
    self.audioEngine = [[JWMTEffectsAudioEngine alloc] init];
    self.audioEngine.engineDelegate = self;
    
    self.metvc = me;
    self.metvc.delegateMixEdit = self;
    self.metvc.effectsHandler = self.audioEngine;
    
    self.sc = [[JWScrubberController alloc] initWithScrubber:(JWScrubberViewController*)svc];
    self.sc.delegate = self;
    
    self.pcvc = (JWPlayerControlsViewController *)pvc;
    self.pcvc.delegate = self;
    
    self.pcvc = pvc;
    [self.pcvc initializeWithState:_state withLightBackround:NO];
    
}


#pragma mark -

-(void)setTrackItems:(id)trackItems {
    
    _trackItems = trackItems;
    
    if (trackItems) {
        
        self.trackItem = nil;
        
        _state = JWPlayerStateSetToBeg;
        
        // BUILD A PLAYER NODE LIST
        NSMutableArray *nodeList = [NSMutableArray new];
        
        for (id item in (NSArray *)trackItems) {
            NSMutableDictionary *playerNode = [self newEnginePlayerNodeForItem:item];
            if (playerNode)
                [nodeList addObject:playerNode];
        }
        
        _audioEngine.playerNodeList = nodeList;
        
        [_audioEngine initializeAudio];
        [_audioEngine playerForNodeAtIndex:0].volume = 0.50;
        
        [self configureScrubbers:NO];
        
        self.state = JWPlayerStatePlayFromBeg;
    }
    
}

-(void)setTrackItem:(id)trackItem {
    
    _trackItem = trackItem;
    
    if (trackItem) {
        NSArray *trackItems = @[trackItem];
        self.trackItems = trackItems;
    }
    
}


- (NSMutableDictionary*) newEnginePlayerNodeForItem:(NSDictionary*)item {
    
    NSURL *fileURL = item[@"fileURL"];

    NSMutableDictionary *playerNode;
    
    if (fileURL) {
        playerNode =
        [@{@"title":@"playernode1",
           @"type":@(JWMixerNodeTypePlayer),
           @"fileURLString":[fileURL path],
           } mutableCopy];
    } else {
        playerNode =
        [@{@"title":@"playerrecordernode1",
           @"type":@(JWMixerNodeTypePlayerRecorder),
           } mutableCopy];
    }
    
    id delayItem = item[@"starttime"];
    float delay = 0.0;
    if (delayItem)
        delay = [delayItem floatValue];
    
    if (delay > 0.0)
        playerNode[@"delay"] = @(delay);
    
    id referenceFileItem = item[@"referencefile"];
    if (referenceFileItem)
        playerNode[@"referencefile"] = referenceFileItem;
    
    //TODO: fill this in
    
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
    
    if (effectsArray) {
        //    playerNode[@"effects"] = effectsArray;
    }
    
    return playerNode;

}

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


//TODO: added this
- (NSMutableDictionary*) newEnginePlayerRecorderNodeForItem:(NSDictionary*)item {
    
    //NSURL *fileURL = item[@"fileURL"];
    
    NSMutableDictionary *playerNode =
    [@{@"title":@"playerrecordernode1",
       @"type":@(JWMixerNodeTypePlayerRecorder),
       } mutableCopy];
    
    id delayItem = item[@"starttime"];
    float delay = 0.0;
    if (delayItem)
        delay = [delayItem floatValue];
    
    if (delay > 0.0)
        playerNode[@"delay"] = @(delay);
    
    id referenceFileItem = item[@"referencefile"];
    if (referenceFileItem)
        playerNode[@"referencefile"] = referenceFileItem;
    
    return playerNode;
    
}


#pragma mark -

-(void)deSelectTrack
{
    _sc.selectedTrack = nil;
}


-(NSUInteger)firstValidTrackIndexForSelection {
    
    NSUInteger resultIndex = 0;

    NSArray *playerNodeList = [self.audioEngine playerNodeList];

    NSUInteger index = 0;
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
    if (_state != JWPlayerStateRecFromPos) {
        self.state = JWPlayerStateSetToPos;
    } else {
        //Ask the user if they want to keep the audio or re-record
        self.state = JWPlayerStateSetToBeg;
    }
}

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
            
        case JWPlayerStateSetToBeg:
            
            _listenToPositionChanges = NO;
            [_sc stopPlaying:nil rewind:YES];
            [_audioEngine stopAllActivePlayerNodes];
            
            break;
            
        case JWPlayerStateSetToPos:
            
            [_audioEngine pauseAllActivePlayerNodes];
            [_sc stopPlaying:nil];
            
            break;
            
        case JWPlayerStateRecFromPos:
            
            [_audioEngine prepareToRecord];
            [_sc play:nil];

        default:
            break;
    }
    
    [_pcvc setState:_state withRecording:[self canRecordAudio]];
}


-(NSUInteger)numberOfTracks
{
    return _sc.numberOfTracks;
}


#pragma mark - SCRUBBER

-(void)startListening {
    
    _listenToPositionChanges = YES;
}


//    SampleSize ssz =  [[_scrubberOptions valueForKey:@"size"] unsignedIntegerValue];
//    VABKindOptions kind =  [[_scrubberOptions valueForKey:@"kind"] unsignedIntegerValue];
//    VABLayoutOptions layout =  [[_scrubberOptions valueForKey:@"layout"] unsignedIntegerValue];
// Update the user interface for the detail item.

- (void)configureScrubbers:(BOOL)tap {
    
    BOOL recordAudio = NO;
    BOOL recordMix = NO;
    
    BOOL tapMixer = tap;
    if (recordAudio)
        tapMixer = NO;
    if (recordMix)
        tapMixer = YES;

    
    _listenToPositionChanges = NO;
    // STEP 2 CONFIGURE SCRUBBER SETTINGS
    [_sc reset];
    
    [self performSelector:@selector(startListening) withObject:nil afterDelay:0.25];
    
    _sc.useGradient = YES;
    _sc.useTrackGradient = NO;
    _sc.pulseBackLight = NO;

    NSArray *playerNodeList = [self.audioEngine playerNodeList];
    
    [self configureScrubberColors];
    [_sc setViewOptions:ScrubberViewOptionDisplayLabels];
    
    _sc.numberOfTracks = [playerNodeList count] + (tapMixer ? 1 : 0);
    
    _sc.scrubberControllerSize = [_delegate updateScrubberHeight:self];
    
    SampleSize ssz =  SampleSize14;
    VABKindOptions kind =  VABOptionCenter;
    VABLayoutOptions layout = VABLayoutOptionOverlayAverages | VABLayoutOptionShowAverageSamples | VABLayoutOptionShowCenterLine;
    NSDictionary * fileReference;
    NSURL * fileURL;

    int index = 0;
    for (NSMutableDictionary *item in playerNodeList) {
        
        float delay = 0.0;
        id delayItem = item[@"starttime"];
        if (delayItem)
            delay = [delayItem floatValue];
        
        id referenceFileItem = item[@"referencefile"];
        if (referenceFileItem)
            fileReference = referenceFileItem;
        
       
        fileURL = [_audioEngine playerNodeFileURLAtIndex:index];
        
        JWMixerNodeTypes nodeType = [item[@"type"] integerValue];
        
        if (nodeType == JWMixerNodeTypePlayer) {
            
            SamplingOptions so = SamplingOptionDualChannel ;
            if (_sc.pulseBackLight) {
                so = SamplingOptionDualChannel | SamplingOptionCollectPulseData;
            }
            
            //If its a player node that has a file url that buffer info can be recieved
            if (fileURL) {
                NSLog(@"%s file at index %d\n%@",__func__,index,[fileURL lastPathComponent]);
                
                NSString *sid =
                [_sc prepareScrubberFileURL:fileURL
                             withSampleSize:ssz
                                    options:so
                                       type:kind
                                     layout:layout
                                     colors:nil
                              referenceFile:fileReference
                                  startTime:delay
                               onCompletion:nil];
                
                
                [item setValue:sid forKey:@"trackid"];
                
            } else {
                // no file URL for player
                NSLog(@"%s NO file url at index %d",__func__,index);
            }
            
            //        colorizedTracks
            //        ? @{
            //            JWColorScrubberTopAvg : [[UIColor blueColor] colorWithAlphaComponent:0.8] ,
            //            JWColorScrubberBottomAvg : [[UIColor blueColor] colorWithAlphaComponent:0.5],
            //            }:nil
        }
        
        
        // PLAYER RECORDER
        else if (nodeType == JWMixerNodeTypePlayerRecorder) {
            
            BOOL usePlayerScrubber = YES;  // determine whther to use player or recorder for scrubber
            //TODO: resolve this
            if (fileURL == nil) {
                // USE recorder
                usePlayerScrubber = NO;
            }
            
            NSLog(@"%s use player %@ at index %d",__func__,usePlayerScrubber?@"YES":@"NO",index);
            //If recorder has audio file, dont need to listen to it, should just play its audio
            if (usePlayerScrubber) {
                // PLAYER - YELLOW / YELLOW
                
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
                
                [item setValue:sid forKey:@"trackid"];

                
            } else {
                //This recorder has no audio and is used to record user audio
                if (recordMix == NO) {
                    // use recorder
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
                   
                    
                    [item setValue:recorderTrackId forKey:@"trackid"];

                  //This recorder doesnt have audio and is used to record a mix
                }
                
                
                
                
            }
        }
        
     
        index++;
    }

    
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
    
    [_metvc refresh];
    
}


// PLAYER

// Configure Track Colors for all Tracks
// configureColors is whole saled the dictionary is simply kept

//    configureColors
//    configureScrubberColors - needs to be called or crash

-(void)configureScrubberColors {
    
    if (_colorizedTracks == NO) {  // set the base to whites
        // Track colors whiteColor/ whiteColor - WHITE middle
        [_sc configureColors:[self defaultWhiteColors]];
        [_sc configureScrubberColors:
         @{ JWColorBackgroundHueColor : [UIColor blackColor]}
         ]; // default blue ocean

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



#pragma mark scrubber controler Delegate for buffers

-(CGFloat)progressOfAudioFile:(JWScrubberController*)self forScrubberId:(NSString*)sid{
    return [_audioEngine progressOfAudioFileForPlayerAtIndex:0];
}
-(CGFloat)durationInSecondsOfAudioFile:(JWScrubberController*)self forScrubberId:(NSString*)sid{
    return [_audioEngine durationInSecondsOfAudioFileForPlayerAtIndex:0];
}
-(CGFloat)remainingDurationInSecondsOfAudioFile:(JWScrubberController*)self forScrubberId:(NSString*)sid{
    return [_audioEngine remainingDurationInSecondsOfAudioFileForPlayerAtIndex:0];
}
-(CGFloat)currentPositionInSecondsOfAudioFile:(JWScrubberController*)self forScrubberId:(NSString*)sid{

    return [_audioEngine currentPositionInSecondsOfAudioFileForPlayerAtIndex:0];
}
-(NSString*)processingFormatStr:(JWScrubberController*)self forScrubberId:(NSString*)sid{
    //    return [_audioEngine processingFormatStr];
    return nil;
}







#pragma mark - edit scrubber delegate

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


#pragma mark - Position Changed

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
//            
//        }
        
        
        
    } else {
        // silently ignore
        //NSLog(@"%s IGNORE update",__func__);
    }
    
    return doUpdate;
}

-(void)scrubber:(JWScrubberController *)controller selectedTrack:(NSString *)sid {
    NSLog(@"%s %@", __func__,sid);
    [_delegate trackSelected:self];
    
    NSArray *playerNodeList = [self.audioEngine playerNodeList];
    NSUInteger index = 0;
    for (NSMutableDictionary *item in playerNodeList) {
        
        NSString *trackId = item[@"trackid"];
        if ([sid isEqualToString:trackId]) {
            // This one
            break;
        }
        index++;
    }
    
    [_metvc setSelectedNodeIndex:index];
    [_metvc refresh];

}

-(void)scrubberTrackNotSelected:(JWScrubberController *)controller {
    NSLog(@"%s", __func__);
    [_delegate noTrackSelected:self];
}


-(void)scrubberDidLongPress:(JWScrubberController*)controller forScrubberId:(NSString*)sid {
    
    NSArray *playerNodeList = [self.audioEngine playerNodeList];
    BOOL found = NO;
    NSUInteger index = 0;
    for (NSMutableDictionary *item in playerNodeList) {
        
        NSString *trackId = item[@"trackid"];
        if ([sid isEqualToString:trackId]) {
            // This one
            found = YES;
            break;
        }
        index++;
    }
    
    if (found) {
        [_delegate playerController:self didLongPressForTrackAtIndex:index];
    }
    
}


#pragma mark - ENGINE DELEGATE

-(void)completedPlayingAtPlayerIndex:(NSUInteger)index {
    
    if (index == 0) {
        self.state = JWPlayerStatePlayFromBeg;
    }
    
    [_delegate playTillEnd];

}

-(void)userAudioObtained {
    
    [self configureScrubbers:NO];
    [_delegate playTillEnd];
    
}

#pragma mark - MIXEDIT DELEGATE

- (id <JWEffectsModifyingProtocol>) mixNodeControllerForScrubber {
    NSLog(@"%s", __func__);
    
    return _sc;
}
- (void)recordAtNodeIndex:(NSUInteger)index {
    NSLog(@"%s", __func__);
    
}


@end
