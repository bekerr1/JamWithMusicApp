//
//  JWAudioPlayerCameraController.m
//  JamWDev
//
//  co-created by joe and brendan kerr on 1/16/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

#import "JWAudioPlayerCameraController.h"
#import "JWFileManager.h"

@interface JWAudioPlayerCameraController() <AVCaptureFileOutputRecordingDelegate>

@property (nonatomic) NSUInteger videoCameraPlayerNodeIndex;


@end

@implementation JWAudioPlayerCameraController 

-(void) initializePlayerControllerWithScrubber:(id)svc playerControles:(id)pvc withCompletion:(JWPlayerCompletionHandler)completion {
    
    if (self.videoSettings == nil) {
        NSLog(@"Video settings not recieved.  Potential Error in Video setup. %s", __func__);
    }
    
    [super initializePlayerControllerWithScrubber:svc playerControls:pvc mixEdit:nil withCompletion:completion];
    
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
    
    SampleSize ssz =  SampleSize14;
    VABKindOptions kind =  VABOptionCenter;
    VABLayoutOptions layout = VABLayoutOptionOverlayAverages | VABLayoutOptionShowAverageSamples | VABLayoutOptionShowCenterLine;
    
    SamplingOptions so = SamplingOptionDualChannel;
    if (self.sc.pulseBackLight)
        so &= SamplingOptionCollectPulseData;
    
    //If its a player node that has a file url that buffer info can be recieved
    NSString *sid =
    [self.sc prepareScrubberFileURL:fileURL
                 withSampleSize:ssz
                        options:so
                           type:kind
                         layout:layout
                         colors:nil
                  referenceFile:fileReference
                      startTime:delay
                   onCompletion:nil];
    
    [playerNode setValue:sid forKey:@"trackid"];
    
}


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
    
    NSLog(@"usePlayerScrubber for recorderplayer %@ at index %lu",usePlayerScrubber?@"YES":@"NO",(unsigned long)index);
    //If recorder has audio file, dont need to listen to it, should just play its audio
    if (usePlayerScrubber) {
        
        NSString *sid =
        [self.sc prepareScrubberFileURL:fileURL
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
        [self.sc prepareScrubberListenerSource:nil
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
        
        
        [self.audioEngine registerController:self.sc withTrackId:recorderTrackId forPlayerRecorderAtIndex:index];
        
        [playerNode setValue:recorderTrackId forKey:@"trackid"];
    }
}


- (void)configureScrubbers:(BOOL)tap {
    
    self.listenToPositionChanges = NO;
    
    BOOL recordAudio = NO;
    BOOL recordMix = NO;
    BOOL tapMixer = tap;
    if (recordAudio)
        tapMixer = NO;
    if (recordMix)
        tapMixer = YES;
    
    // STEP 1 CONFIGURE SCRUBBER SETTINGS before reset
    
    self.sc.useGradient      = NO;
    self.sc.useTrackGradient = NO;
    self.sc.pulseBackLight   = NO;
    
    [self.sc setDarkBackground:NO];
    [self.sc setBackLightColor:[UIColor clearColor]];
    
    [self.sc reset];
    
    // STEP 2 SET OPTIONS FOR NEW SCRUBBERS
    
    NSArray *playerNodeList = [self.audioEngine playerNodeList];
    self.sc.numberOfTracks = [playerNodeList count] + (tapMixer ? 1 : 0);
    
    [self.sc setViewOptions:ScrubberViewOptionsDisplayInCameraView];
    self.sc.scrubberControllerSize = [self.delegate updateScrubberHeight:self];
    
    [self configureScrubberColors];
    
    
    // STEP 3 CONFIGURE THE SCRUBBERS
    
    NSUInteger index = 0;
    
    for (NSMutableDictionary *item in playerNodeList) {
        
        JWMixerNodeTypes nodeType = [item[@"type"] integerValue];
        id fileURLString = item[@"fileURLString"];
        
        //Only want to configure scrubbers for player nodes with file urls
        if (fileURLString) {
            
            if (nodeType == JWMixerNodeTypePlayer) {
                
                // PLAYER
                NSURL *fileURL = [self.audioEngine playerNodeFileURLAtIndex:index];
                if (fileURL) {
                    
                    [self scrubberConfigurePlayer:item withFileURL:fileURL];
                    
                } else {
                    // no file URL for player
                    NSLog(@"%s NO file url for Player Node at index %ld",__func__,(unsigned long)index);
                }
                
            } else if (nodeType == JWMixerNodeTypePlayerRecorder) {
                
                // PLAYER RECORDER
                
                //This recorder has no audio and is used to record user audio
                // While Exporting Dont show the Recorder
                // A Recorder uses a different config than a tap on The Mixer
                
                [self scrubberConfigurePlayerRecorder:item atIndex:index
                                          withFileURL:[self.audioEngine playerNodeFileURLAtIndex:index]
                                           playerOnly:YES];
            }
            
            index++;  // increment playerNode index
            

        }
        
    } // End iterating
    
    
    
    // Finally, optionally configure the tap on the Mixer
    
    if (tapMixer) {
        NSString *trackidMixerTap =
        [self.sc prepareScrubberListenerSource:nil
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
        
        [self.audioEngine registerController:self.sc withTrackId:trackidMixerTap forPlayerRecorder:@"mixer"];
    }
    
    
    // STEP 4 REFRESH THE MIXEDIT
    
    
    //    [self performSelector:@selector(startListening) withObject:nil afterDelay:0.25];
    
}


// PLAYER

// Configure Track Colors for all Tracks
// configureColors is whole saled the dictionary is simply kept

//    configureColors
//    configureScrubberColors - needs to be called or crash

-(void)configureScrubberColors {
    
    // set the base to whites
    // Track colors whiteColor/ whiteColor - WHITE middle
    [self.sc configureColors:[self defaultWhiteColors]];
    [self.sc setBackgroundToClear];
    
    [self.sc configureScrubberColors:
     @{
       JWColorBackgroundHueColor : [UIColor clearColor],
       JWColorBackgroundHeaderGradientColor1 : [UIColor clearColor],
       JWColorBackgroundHeaderGradientColor2 : [UIColor clearColor],
       JWColorBackgroundTrackGradientColor1 : [UIColor clearColor],
       JWColorBackgroundTrackGradientColor2 : [UIColor clearColor],
       JWColorBackgroundTrackGradientColor3 : [UIColor clearColor],
       }
     ]; // default blue ocean
    
    //[self.sc configureScrubberColors:[self.sc scrubberColorsDefaultConfig1]];
    
}


//Start recording video feed,call super record
//super records audio and starts scrubber
-(void)record {
    NSLog(@"Hit Subclass Record First. %s", __func__);
    
    //Want to match the video with the right recorder node (maybe for reference later)
    self.videoCameraPlayerNodeIndex = [self.audioEngine indexOfFirstRecorderNodeWithNoAudio];
    
    NSString *movieFileName = @"moviefile";
    NSString *documentsPath = [[[[JWFileManager defaultManager] documentsDirectoryPath] stringByAppendingPathComponent:movieFileName] stringByAppendingPathExtension:@"mov"];
    NSURL *movieURL = [NSURL fileURLWithPath:documentsPath];
    
    NSLog(@"Movie File URL = %@", [movieURL absoluteString]);
    
    [self.videoMovie startRecordingToOutputFileURL:movieURL recordingDelegate:self];
    
    [super record];
    
}

-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections {
    NSLog(@"Recording Started. %s", __func__);
    
}

-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    NSLog(@"%s", __func__);
    
    BOOL recordedSuccessfully = YES;
    if ([error code] != noErr) {
        // A problem occurred: Find out if the recording was successful.
        id value = [[error userInfo] objectForKey:AVErrorRecordingSuccessfullyFinishedKey];
        if (value) {
            recordedSuccessfully = [value boolValue];
        }
    }
    
    if (recordedSuccessfully) {
        NSLog(@"Succesful Recording. %s", __func__);
        
        NSMutableDictionary *videoNode =
        [@{
          @"type" : [NSNumber numberWithInteger:JWMixerNodeTypeVideo],
          @"title" : @"Video Node",
          @"recordernodeindex" : [NSNumber numberWithInteger:self.videoCameraPlayerNodeIndex],
          @"fileURLString" : [outputFileURL absoluteString],
          @"videosettings" : self.videoSettings
          } mutableCopy];
        
        [self.audioEngine.playerNodeList addObject:videoNode];
        
        NSLog(@"Video node was just added with contents: %@ with settings %@", videoNode.description, _videoSettings.description);
        
    } else {
        NSLog(@"Potential error in recording or somewhere else.");
    }
//    
}



#pragma mark - PLAYER CONTROLS PROTOCOL

-(void)dismissCamera {

    [self.delegate userDismissCamera];
    [self.audioEngine startEngine];
    
}



@end
