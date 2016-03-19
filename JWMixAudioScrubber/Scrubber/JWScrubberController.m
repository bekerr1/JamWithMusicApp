//
//  JWScrubberController.m
//  JamWIthT
//
//  co-created by joe and brendan kerr on 10/23/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import "JWScrubberController.h"
#import "JWScrubberViewController.h"
#import "JWBufferSampler.h"
#import "JWPlayerFileInfo.h"
#import "JWScrubberTackModify.h"
#import "UIColor+JW.h"

const int scMaxTracks = 10;

@interface JWScrubberController () <ScrubberDelegate, JWScrubberTackModifyDelegate > {
    dispatch_queue_t _bufferReceivedQueue;
    dispatch_queue_t _bufferSampledQueue;
    dispatch_queue_t _bufferReceivedPerformanceQueue;
    dispatch_queue_t _bufferSampledPerformanceQueue;
    NSUInteger _buffersReceivedCount;
    NSUInteger _buffersSentCount;
    NSUInteger _trackCount;
    NSMutableDictionary * _tracks;
    NSUInteger _buffersReceivedCounts[scMaxTracks];
    NSUInteger _buffersSentCounts[scMaxTracks];

    float _loudestSamplesSofar[scMaxTracks]; // for listener implementation
    float _elapsedTimesSoFar[scMaxTracks];
    float _durationForTrack[scMaxTracks];
    BOOL _pulseOn;
}
@property (nonatomic) JWScrubberViewController *scrubber;
@property (nonatomic) JWPlayerFileInfo *restoreReferenceFileObject;
@property (nonatomic,strong)  NSTimer *playerTimer;
@property (nonatomic,strong)  NSTimer *recordingTimer;
@property (nonatomic,strong)  NSString *playerTrackId;
@property (nonatomic,strong)  NSMutableDictionary *trackColorsByTrackId;
@property (nonatomic,strong)  NSDictionary *trackColorsAllTracks;
@property (nonatomic,strong)  NSDictionary *scrubberColors;
@property (nonatomic,strong)  NSMutableArray *pulseSamples;
@property (nonatomic,strong)  NSMutableArray *pulseSamplesDurations;
@property (nonatomic,readwrite) BOOL isPlaying;
@property (nonatomic,strong)  NSString *playerProgressFormatString;
@property (nonatomic)  AVAudioFile *recordingAudioFile;
@property (nonatomic)  NSTimeInterval recordingLength;
@property (nonatomic)  NSDate *recordingStartTime;
@property (nonatomic)  AVAudioFramePosition recordingLastReadPosition;
@property (nonatomic)  NSURL *recordingURL;
@end


@implementation JWScrubberController

-(instancetype)initWithScrubber:(JWScrubberViewController*)scrubberViewController
{
    _backlightValue = 0.33f;
    return [self initWithScrubber:scrubberViewController andBackLightValue:_backlightValue];
}

-(instancetype)initWithScrubber:(JWScrubberViewController*)scrubberViewController andBackLightValue:(float)backLightValue {

    if (self = [super init]) {
        _scrubber = scrubberViewController;
        
        _viewOptions = ScrubberViewOptionNone;
        _scrubber.viewOptions = _viewOptions;
        _scrubber.delegate = self;
        
        _backlightValue = backLightValue;
        [_scrubber adjustWhiteBacklightValue:_backlightValue];
        
        [self reset];
        _pulseSamples = [@[] mutableCopy];
        _pulseSamplesDurations = [@[] mutableCopy];
        _playerProgressFormatString = @"%.0f";
//        _playerProgressFormatString = @"%00.2f";
    }
    return self;
}

-(void)initBufferQueues {
    if (_bufferReceivedQueue == nil)
        _bufferReceivedQueue =
        dispatch_queue_create("bufferReceived",
                              dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL,QOS_CLASS_USER_INTERACTIVE, -1));
    if (_bufferSampledQueue == nil)
        _bufferSampledQueue =
        dispatch_queue_create("bufferProcessing",
                              dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL,QOS_CLASS_USER_INTERACTIVE, -1));
    
    if (_bufferReceivedPerformanceQueue == nil)
        _bufferReceivedPerformanceQueue =
        dispatch_queue_create("bufferReceivedP",
                              dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL,QOS_CLASS_USER_INTERACTIVE, -1));
    if (_bufferSampledPerformanceQueue == nil)
        _bufferSampledPerformanceQueue =
        dispatch_queue_create("bufferProcessingP",
                              dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL,QOS_CLASS_USER_INTERACTIVE, -1));
}

-(void)dealloc {
    NSLog(@"%s",__func__);
    self.scrubber.delegate = nil;
//    self.scrubber = nil;
}

#pragma mark -

-(void)rewind:(NSString*)sid;
{
    [_scrubber rewindToBeginning];
}

- (void)refresh
{
    [self.scrubber refresh];
}

-(bool)hasRecording {
    for (id item in [_tracks allKeys]) {
        id source = _tracks[item][@"source"];
        if (source != nil) {
            return YES;
        }
    }
    return NO;
}

-(NSInteger)trackNumberForSource {
    NSInteger result = NSNotFound;
    for (id item in [_tracks allKeys]) {
        id source = _tracks[item][@"source"];
        if (source != nil) {
            NSUInteger track = [(NSNumber*)_tracks[item][@"tracknum"] unsignedIntegerValue];
            if (track > 0){
                result = track;
                break;
            }
        }
    }
    return result;
}


-(void)play:(NSString*)sid {
    
    if ([_playerTimer isValid])
        [_playerTimer invalidate];
    self.playerTimer = nil;
    
    if (sid == nil) {
//        [_scrubber prepareToPlay:1 atPosition:[_delegate currentPositionInSecondsOfAudioFile:self forScrubberId:nil]];
        NSLog(@"%s pos %.2f",__func__,[_delegate currentPositionInSecondsOfAudioFile:self forScrubberId:nil]);
        [_scrubber prepareToPlay:1];
        if ([_delegate respondsToSelector:@selector( progressOfAudioFile:forScrubberId:)])
            [self.scrubber trackScrubberToProgress:[_delegate progressOfAudioFile:self forScrubberId:sid] timeAnimated:NO];
    }
    
    [self startPlayTimer];
    [_scrubber transitionToPlay];
    
    // Reset position of taps
    NSInteger track = [self trackNumberForSource];
    if (track != NSNotFound) {
        _durationForTrack[track] = [_delegate currentPositionInSecondsOfAudioFile:self forScrubberId:nil];
    }

    if ( (_scrubber.viewOptions == ScrubberViewOptionDisplayLabels)
        || (_scrubber.viewOptions == ScrubberViewOptionDisplayOnlyValueLabels)) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([_delegate respondsToSelector:@selector( processingFormatStr:forScrubberId:)]) {
                _scrubber.formatValueStr = [_delegate processingFormatStr:self forScrubberId:sid];
            }
        });
    }
}

-(void)playMomentFromPos:(CGFloat)fromPos toPosition:(CGFloat)toPos {
    if ([_playerTimer isValid])
        [_playerTimer invalidate];
    self.playerTimer = nil;
    
    [_scrubber prepareToPlay:1];
    [_scrubber transitionToPlayPreview];  // turns of scrolllistening and interaction
    [_scrubber trackScrubberToPostion:fromPos timeAnimated:NO animated:NO];
    [_scrubber trackScrubberToPostion:toPos timeAnimated:YES animated:YES];
    [_scrubber readyForScrub];
}

-(void)readyForPlay:(NSString*)sid {
    [_scrubber readyForPlay];
    [_scrubber transitionToStopPlayPreview];
}

-(void)readyForScrub {
    [_scrubber readyForScrub];
    [_scrubber transitionToStopPlayPreview];
}

-(void)playRecord:(NSString*)sid {
    
    [self play:sid];
    
    [_scrubber transitionToRecording];
}

-(void)recordAt:(NSString*)sid  {
    
    NSURL *fileURL = [_delegate recordingFileURL:self];
    
    [self recordAt:sid usingFileURL:fileURL];
}

-(void)recordAt:(NSString*)sid usingFileURL:(NSURL*)fileURL {
    
    if ([_playerTimer isValid])
        [_playerTimer invalidate];

    [_scrubber prepareToPlay:1 atPosition:0.0];
    [_scrubber transitionToRecordingSingleRecorder:YES];
    
    _playerTrackId = sid;
    self.recordingURL = fileURL;
    _recordingLength = 0.0; //secs
    _recordingLastReadPosition = 0;
    
    [self audioFileAnalyzerForRecorderFile:fileURL forTrackId:sid];
    
    self.recordingStartTime = [NSDate date];
    [self startPlayTimer];
}


-(void)stopPlaying:(NSString*)sid {
    
    [_playerTimer invalidate];
    self.playerTimer = nil;
    
    if (_recordingStartTime != nil) {
        // we have been recording
      
        [_recordingTimer invalidate];
        NSTimeInterval recordTime = -([_recordingStartTime timeIntervalSinceNow]);
        self.recordingLength = recordTime;
        self.recordingStartTime = nil;
        
        NSLog(@"RECORDING TIME %.3f",_recordingLength);
    }

    [_scrubber transitionToStopPlaying];
}

-(void)stopPlaying:(NSString*)sid rewind:(BOOL)rewind {
    [self stopPlaying:sid];
    if (rewind)
    {
        [self rewind:sid];
    }
}

-(void)playedTillEnd:(NSString*)sid {
    [_scrubber transitionToPlayTillEnd];
}

-(void)resumePlaying {
//    [_playerTimer invalidate];
    [self play:nil];
}

-(void)reset {
    
    NSLog(@"%s",__func__);
    _bufferSampledQueue = nil;
    _bufferReceivedQueue = nil;
    _bufferSampledPerformanceQueue = nil;
    _bufferReceivedPerformanceQueue = nil;
    [self initBufferQueues];

    _trackCount = 0;
    _tracks = [@{} mutableCopy];
    _trackColorsByTrackId = [@{} mutableCopy];
    
    for (int i=0; i<scMaxTracks; i++) {
        _buffersReceivedCounts[i] = 0;
        _buffersSentCounts[i] = 0;

        _elapsedTimesSoFar[i] = 0.000f;
        _loudestSamplesSofar[i] = 0.000001f;
        _durationForTrack[i] = 0.000f;
    }
    
    [self.scrubber resetScrubber];
    
    [[NSUserDefaults standardUserDefaults] setValue:@(_backlightValue) forKey:@"backlightvalue"];
}

-(void)setPulseBackLight:(BOOL)pulseBackLight {
    _pulseBackLight = pulseBackLight;
    
    if (pulseBackLight) {
        _pulseOn = YES;
    }
}

-(void)setUseGradient:(BOOL)useGradient {
    _useGradient = useGradient;
    if (_scrubber) {
        [_scrubber setUseGradient: _useGradient];
    }
}
-(void)setUseTrackGradient:(BOOL)useTrackGradient {
    _useTrackGradient = useTrackGradient;
    if (_scrubber) {
        [_scrubber setUseTrackGradient: _useTrackGradient];
    }
}

-(void)setBackLightColor:(UIColor*)backLightColor {
    _backLightColor = backLightColor;
    if (_scrubber) {
        _scrubber.hueColor = _backLightColor;
        [_scrubber.view setNeedsLayout];
    }
}

-(void)setDarkBackground:(BOOL)darkBackground {
    _darkBackground = darkBackground;
    if (_scrubber) {
        _scrubber.darkBackground = _darkBackground;
    }
}

-(void)adjustBackLightValue:(float)value {
    self.backlightValue = value;
    [_scrubber adjustWhiteBacklightValue:_backlightValue];
}

-(void)setSelectedTrack:(NSString *)selectedTrack {
    _selectedTrack = selectedTrack;
    if (_selectedTrack) {
        NSUInteger track = [(NSNumber*)_tracks[_selectedTrack][@"tracknum"] unsignedIntegerValue];
        if (track > 0)
            [_scrubber selectTrack:track];
    } else {
        // nil
        [_scrubber deSelectTrack];
    }
}


// select deselect prefer to use property selectedTrack
- (void)selectTrack:(NSString*)tid {
    _selectedTrackId = tid;
    _selectedTrack = _selectedTrackId;
    if (tid){
        NSUInteger track = [(NSNumber*)_tracks[tid][@"tracknum"] unsignedIntegerValue];
        if (track > 0)
            [_scrubber selectTrack:track];
    }
}
- (void)deSelectTrack {
    self.selectedTrack = nil;
    self.selectedTrackId = nil;
    [_scrubber deSelectTrack];
}


- (id <JWEffectsModifyingProtocol>) trackNodeControllerForTrackId:(NSString*)tid {
   
    id <JWEffectsModifyingProtocol> result;
    
    if (tid){
        id trackmod = _tracks[tid][@"trackmod"];
        if (trackmod) {
            result = trackmod;
        } else {
            NSUInteger track = [(NSNumber*)_tracks[tid][@"tracknum"] unsignedIntegerValue];
            if (track > 0) {
                JWScrubberTackModify *trackModify = [JWScrubberTackModify new];
                trackModify.delegate = self;
                trackModify.track = track;
                _tracks[tid][@"trackmod"] = trackModify;
                result = trackModify;
            }
        }
    }
    
    return result;
}


#pragma mark -

-(void)seekToPosition:(CGFloat)pos scrubber:(NSString*)sid {
    [self seekToPosition:pos scrubber:sid animated:YES];
}

-(void)seekToPosition:(CGFloat)pos scrubber:(NSString*)sid animated:(BOOL)animated {
    NSLog(@"%s NOT IMPLEMENTED",__func__);
}

-(void)seekToPosition:(CGFloat)pos animated:(BOOL)animated {
    [_scrubber trackScrubberToPostion:pos timeAnimated:NO animated:animated];
}

-(void)rewind:(NSString*)sid animated:(BOOL)animated {
    NSLog(@"%s NOT IMPLEMENTED",__func__);
}

#pragma mark -

-(void)setViewOptions:(ScrubberViewOptions)viewOptions {
    _viewOptions = viewOptions;
    _scrubber.viewOptions = _viewOptions;
}

-(void)setNumberOfTracks:(NSUInteger)numberOfTracks {
    _numberOfTracks = numberOfTracks;
    _scrubber.numberOfTracks = _numberOfTracks;
}

-(void)setTrackLocations:(NSArray *)trackLocations {
    _scrubber.locations = trackLocations;
}

// setter/getter
-(void)setSampleSize:(SampleSize)sampleSize forTrackWithId:(NSString*)stid{
    _tracks[stid][@"samplesize"]= @(sampleSize);
}

-(SampleSize)sampleSizeForTrackWithId:(NSString*)stid {
    return [(NSNumber*)_tracks[stid][@"samplesize"] unsignedIntegerValue];
}

// setter/getter
-(void)setSamplingOptions:(SamplingOptions)options forTrack:(NSString*)stid{
    _tracks[stid][@"options"]= @(options);
}

-(SamplingOptions)configOptionsForTrack:(NSString*)stid {
    id options = _tracks[stid][@"options"];
    if (options)
        return [(NSNumber*)options unsignedIntegerValue];
    return 0; // not found
}

// setter/getter
-(void)setKindOptions:(VABKindOptions)options forTrack:(NSString*)stid{
    _tracks[stid][@"kind"]= @(options);
}

-(VABKindOptions)kindOptionsForTrack:(NSString*)stid {
    id options = _tracks[stid][@"kind"];
    if (options)
        return [(NSNumber*)options unsignedIntegerValue];
    return 0; // not found
}

// setter/getter
-(void)setLayoutOptions:(VABLayoutOptions)options forTrack:(NSString*)stid{
    _tracks[stid][@"layout"]= @(options);
}
-(VABLayoutOptions)layoutOptionsForTrack:(NSString*)stid {
    id options = _tracks[stid][@"layout"];
    if (options)
        return [(NSNumber*)options unsignedIntegerValue];
    return 0; // not found
}

#pragma mark - configure

-(void)configureTrackColors:(NSDictionary*)trackColors {
    _trackColorsAllTracks = trackColors;
    _scrubber.userProvidedColorsAllTracks = _trackColorsAllTracks;
}

-(void)configureTrackColors:(NSDictionary*)trackColors forTackId:(NSString*)trackId {
    if (trackColors) {
        if (trackId == nil)
            [self configureColors:trackColors];
        else
            _trackColorsByTrackId[trackId] = trackColors;
    }
}

-(void)configureColors:(NSDictionary*)trackColors {
    [self configureTrackColors:trackColors];
}

-(void)configureColors:(NSDictionary*)trackColors forTackId:(NSString*)trackId {
    [self configureTrackColors:trackColors forTackId:trackId];
}

-(void)configureScrubberColors:(NSDictionary*)scrubberColors {
    id color;
    color = scrubberColors[JWColorBackgroundHueColor];
    if (color)
        _scrubber.hueColor = color;
    color = scrubberColors[JWColorBackgroundHueGradientColor1];
    if (color)
        _scrubber.hueGradientColor1 = color;
    color = scrubberColors[JWColorBackgroundHueGradientColor2];
    if (color)
        _scrubber.hueGradientColor2 = color;
    color = scrubberColors[JWColorBackgroundTrackGradientColor1];
    if (color)
        _scrubber.trackGradientColor1 = color;
    color = scrubberColors[JWColorBackgroundTrackGradientColor2];
    if (color)
        _scrubber.trackGradientColor2 = color;
    color = scrubberColors[JWColorBackgroundTrackGradientColor3];
    if (color)
        _scrubber.trackGradientColor3 = color;
    color = scrubberColors[JWColorBackgroundHeaderGradientColor1];
    if (color)
        _scrubber.headerColor1 = color;
    color = scrubberColors[JWColorBackgroundHeaderGradientColor2];
    if (color)
        _scrubber.headerColor2 = color;

    _scrubberColors = scrubberColors;
    
    [_scrubber.view setNeedsLayout];  // to rebuild the gradients
}


-(NSDictionary*)scrubberColorsDefaultConfig1 {
    

    NSDictionary *scrubberColors =
    @{
      JWColorBackgroundHueColor : [UIColor iosOceanColor],
      JWColorBackgroundHeaderGradientColor1 : [UIColor blackColor],
      JWColorBackgroundHeaderGradientColor2 : [UIColor blackColor],
      JWColorBackgroundTrackGradientColor1 : [UIColor blackColor],
      JWColorBackgroundTrackGradientColor2 : [[UIColor blueColor] colorWithAlphaComponent:0.6],
      JWColorBackgroundTrackGradientColor3 : [UIColor clearColor],
      };

    //      JWColorBackgroundTrackGradientColor1 : [UIColor blackColor],
    //      JWColorBackgroundTrackGradientColor3 : [iosColor3 colorWithAlphaComponent:0.5],

    return scrubberColors;
}


/* ----------------------------------------------------
 BEGIN EDITING PROTOCOL
 ----------------------------------------------------
 */

#pragma mark - edit track

-(NSUInteger)trackNumberForTrackId:(NSString*)trackId  {
    NSUInteger track = 1;
    if (trackId)
        track = [(NSNumber*)_tracks[trackId][@"tracknum"] unsignedIntegerValue];
    return track;
}

/* ----------------------------------------------------
 
EDITING PROTOCOL PUBLIC API
 EDIT Track - Start, BeginInset, EndInset
 Each one will call editTrack and call back to trackInfoForTrack for the info
 ----------------------------------------------------
 */

-(void)editTrackStartPosition:(NSString*)trackId  {

    self.restoreReferenceFileObject = [self fileReferenceObjectForTrackId:trackId];
    
    [_restoreReferenceFileObject calculateAtCurrentPosition:0.0];

    id startTimeValue = _tracks[trackId][@"starttime"];
    float startTime = startTimeValue ? [startTimeValue floatValue] : 0.0;
    id refFile = _tracks[trackId][@"referencefile"];
    if (refFile) {
        id startInsetValue = refFile[@"startinset"];
        float startInset = startInsetValue ? [startInsetValue floatValue] : 0.0;
        id endInsetValue = refFile[@"endinset"];
        float endInset = endInsetValue ? [endInsetValue floatValue] : 0.0;
        NSLog(@"%s st %.2f si %.2f ei %.2f",__func__,startTime,startInset,endInset);
    } else {
        NSLog(@"%s st %.2f no referencefile",__func__,startTime);
    }

    NSUInteger track = [self trackNumberForTrackId:trackId];

    [_scrubber editTrack:track startTime:startTime];
    
    // RESET and REDRAW
    _durationForTrack[track] = startTime;
    [_scrubber setTrackStartPosition:startTime forTrack:track];
    _durationForTrack[0] = 0.0;
    [_scrubber setTrackStartPosition:0.0 forTrack:0];

    NSURL *fileURL = _tracks[trackId][@"fileurl"];

    [self audioFileAnalyzerForFile:fileURL forTrackId:trackId usingFileReference:nil edit:YES];
    
    // Current is editing position

}

-(void)editTrackBeginInset:(NSString*)trackId  {

    self.restoreReferenceFileObject = [self fileReferenceObjectForTrackId:trackId];

    [_restoreReferenceFileObject calculateAtCurrentPosition:0.0];
    
    CGFloat fullTrackStartPosition = _restoreReferenceFileObject.startPositionInReferencedTrack;
    
    float startInset = 0.0;
    id startTimeValue = _tracks[trackId][@"starttime"];
    float startTime = startTimeValue ? [startTimeValue floatValue] : 0.0;
    id refFile = _tracks[trackId][@"referencefile"];
    if (refFile) {
        id startInsetValue = refFile[@"startinset"];
        startInset = startInsetValue ? [startInsetValue floatValue] : 0.0;
        id endInsetValue = refFile[@"endinset"];
        float endInset = endInsetValue ? [endInsetValue floatValue] : 0.0;
        NSLog(@"%s st %.2f si %.2f ei %.2f",__func__,startTime,startInset,endInset);
    } else {
        NSLog(@"%s st %.2f no referencefile",__func__,startTime);
    }

    NSUInteger track = [self trackNumberForTrackId:trackId];

    [_scrubber editTrack:track startInset:startInset];
    
    NSLog(@"%s fullTrackStartPosition %.2f",__func__,fullTrackStartPosition);
    _durationForTrack[track] = fullTrackStartPosition;
    [_scrubber setTrackStartPosition:fullTrackStartPosition forTrack:track];
    _durationForTrack[0] = 0.0;
    [_scrubber setTrackStartPosition:0.0 forTrack:0];
    
    NSURL *fileURL = _tracks[trackId][@"fileurl"];

    [self audioFileAnalyzerForFile:fileURL forTrackId:trackId usingFileReference:nil edit:YES];

}

-(void)editTrackEndInset:(NSString*)trackId  {
    
    self.restoreReferenceFileObject = [self fileReferenceObjectForTrackId:trackId];
    
    [_restoreReferenceFileObject calculateAtCurrentPosition:0.0];
    
    CGFloat fullTrackStartPosition = _restoreReferenceFileObject.startPositionInReferencedTrack;

    float endInset  = 0.0;
    id startTimeValue = _tracks[trackId][@"starttime"];
    float startTime = startTimeValue ? [startTimeValue floatValue] : 0.0;
    id refFile = _tracks[trackId][@"referencefile"];
    if (refFile) {
        id endInsetValue = refFile[@"endinset"];
        endInset = endInsetValue ? [endInsetValue floatValue] : 0.0;
        id startInsetValue = refFile[@"startinset"];
        float startInset = startInsetValue ? [startInsetValue floatValue] : 0.0;
        NSLog(@"%s st %.2f si %.2f ei %.2f",__func__,startTime,startInset,endInset);
    } else {
        NSLog(@"%s st %.2f no referencefile",__func__,startTime);
    }
    
    NSUInteger track = [self trackNumberForTrackId:trackId];

    [_scrubber editTrack:track endInset:endInset];
    

    NSLog(@"%s fullTrackStartPosition %.2f",__func__,fullTrackStartPosition);

    // reset track duration to begin
    _durationForTrack[track] = fullTrackStartPosition;
    [_scrubber setTrackStartPosition:fullTrackStartPosition forTrack:track];
    _durationForTrack[0] = 0.0;
    [_scrubber setTrackStartPosition:0.0 forTrack:0];

    NSURL *fileURL = _tracks[trackId][@"fileurl"];

    [self audioFileAnalyzerForFile:fileURL forTrackId:trackId usingFileReference:nil edit:YES];
    
    // TODO: move to editing position
}

//    _durationForTrack[track] = startTime;
//    [_scrubber setTrackStartPosition:startTime forTrack:track];


/* ----------------------------------------------------
 EDITING STOP EDIT Track - Cancel and Save
 ----------------------------------------------------
 */

#pragma mark edit commands
// PUBLIC API
-(void)stopEditingTrackCancel:(NSString*)trackId {

    // RESTORE Current Values from backup
    if (_restoreReferenceFileObject) {
        _tracks[trackId][@"starttime"] = @(_restoreReferenceFileObject.trackStartPosition);
        _tracks[trackId][@"referencefile"] = [@{@"duration":@(_restoreReferenceFileObject.trackDuration),
                                                @"startinset":@(_restoreReferenceFileObject.startPositionInset),
                                                @"endinset":@(_restoreReferenceFileObject.endPositionInset),
                                                } mutableCopy];
        NSLog(@"%s restored track info %@",__func__,[_tracks[trackId] description]);
    }

    self.restoreReferenceFileObject = nil;

    // TELL The ScrubberView to stopEditing
    NSUInteger track = [self trackNumberForTrackId:trackId];
    
    [_scrubber stopEditingTrackCancel:track];
    
    [self redrawFromCurrentForTrack:trackId]; // USE Current Values
    
    if ([_delegate respondsToSelector:@selector(editingCompleted:forScrubberId:)])
        [_delegate editingCompleted:self forScrubberId:trackId];

}

-(void)stopEditingTrackSave:(NSString*)trackId {

    self.restoreReferenceFileObject = nil;

    NSUInteger track = [self trackNumberForTrackId:trackId];

    [_scrubber stopEditingTrackSave:track completion:^(id fileRef) {
        [self editCompletedForTrack:track withTrackInfo:fileRef];
    }];
    
//    id trackInfo = [_scrubber stopEditingTrackSave:track];
//    [self editCompletedForTrack:track withTrackInfo:trackInfo];
}


// PRIVATE API

-(void)redrawFromCurrentForTrack:(NSString*)trackId {
    
    NSUInteger track = [self trackNumberForTrackId:trackId];
    
    id startTimeValue = _tracks[trackId][@"starttime"];
    float startTime = startTimeValue ? [startTimeValue floatValue] : 0.0;
    // reset track duration to begin
    _durationForTrack[track] = startTime;
    [_scrubber setTrackStartPosition:startTime forTrack:track];

    JWPlayerFileInfo *fileReference = [self fileReferenceObjectForTrackId:trackId];

    NSURL *fileURL = _tracks[trackId][@"fileurl"];

    [self audioFileAnalyzerForFile:fileURL forTrackId:trackId usingFileReference:fileReference];
}

-(void)saveEditingTrack:(NSString*)trackId {
    NSUInteger track = [self trackNumberForTrackId:trackId];
    [_scrubber saveEditingTrack:track];
}


#pragma mark edit helper

/*
 fileReferenceObjectForTrack
 Creates a fileReference Object using current trackInfo
 */

-(JWPlayerFileInfo *)fileReferenceObjectForTrackId:(NSString*)trackId  {
    
    JWPlayerFileInfo *result = nil;

    id startTimeValue = _tracks[trackId][@"starttime"];
    float startTime = startTimeValue ? [startTimeValue floatValue] : 0.0;
    id refFile = _tracks[trackId][@"referencefile"];
    
    NSURL *fileURL = _tracks[trackId][@"fileurl"];
    NSTimeInterval durationSeconds = 0.0;
    if (fileURL) {
        NSError *error = nil;
        AVAudioFile *audioFile = [[AVAudioFile alloc] initForReading:fileURL error:&error];
        AVAudioFormat *processingFormat = [audioFile processingFormat];
        durationSeconds = audioFile.length / processingFormat.sampleRate;
    }

    if (refFile) {
        
        id startInsetValue = refFile[@"startinset"];
        float startInset = startInsetValue ? [startInsetValue floatValue] : 0.0;
        id endInsetValue = refFile[@"endinset"];
        float endInset = endInsetValue ? [endInsetValue floatValue] : 0.0;
        
        result =
        [[JWPlayerFileInfo alloc] initWithCurrentPosition:0.0 duration:durationSeconds
                                            startPosition:startTime
                                               startInset:startInset
                                                 endInset:endInset];
        
        NSLog(@"%s [%.2fs , %.2fs] %.2fs",__func__,startInset,endInset,durationSeconds);
    } else {
        NSLog(@"%s st %.2f no referencefile create new one",__func__,startTime);

        result =
        [[JWPlayerFileInfo alloc] initWithCurrentPosition:0.0 duration:durationSeconds
                                            startPosition:0.0
                                               startInset:0.0
                                                 endInset:0.0];
    }
    
    return result;
    
}

// delegate method
/*
 fileReferenceObjectForTrack
 
 returns JWPlayerFileInfo object populated or nil if
 referencefile is not available
 
 */

-(id)fileReferenceObjectForTrack:(NSUInteger)track {

    JWPlayerFileInfo *result = nil;

    NSDictionary *trackInfo = [self trackInfoForTrack:track];

    id refFile = trackInfo[@"referencefile"];
    if (refFile) {
        id startTimeValue = trackInfo[@"starttime"];
        float startTime = startTimeValue ? [startTimeValue floatValue] : 0.0;

        NSTimeInterval durationSeconds = 0.0;
        NSURL *fileURL = trackInfo[@"fileurl"];
        if (fileURL) {
            NSError *error = nil;
            AVAudioFile *audioFile = [[AVAudioFile alloc] initForReading:fileURL error:&error];
            AVAudioFormat *processingFormat = [audioFile processingFormat];
            durationSeconds = audioFile.length / processingFormat.sampleRate;
        }

        id startInsetValue = refFile[@"startinset"];
        float startInset = startInsetValue ? [startInsetValue floatValue] : 0.0;
        id endInsetValue = refFile[@"endinset"];
        float endInset = endInsetValue ? [endInsetValue floatValue] : 0.0;
        
        result =
        [[JWPlayerFileInfo alloc] initWithCurrentPosition:0.0 duration:durationSeconds
                                            startPosition:startTime
                                               startInset:startInset
                                                 endInset:endInset];
        
        NSLog(@"%s %.2f %.2f %.2f",__func__,startInset,endInset,durationSeconds);
    } else {
        NSLog(@"%s no referencefile",__func__);
    }
    
    return result;

}

// delegate method
/*
 lengthInSecondsForTrack
 
 returns length of track - duration in seconds
 reads the referencefile if available  or entire file length if it does not
 
 */

-(NSTimeInterval)lengthInSecondsForTrack:(NSUInteger)track {
    
    NSTimeInterval resultDuration = 0.0;
    
    NSDictionary *trackInfo = [self trackInfoForTrack:track];
    
    NSTimeInterval durationSeconds = 0.0;
    NSURL *fileURL = trackInfo[@"fileurl"];
    if (fileURL) {
        NSError *error = nil;
        AVAudioFile *audioFile = [[AVAudioFile alloc] initForReading:fileURL error:&error];
        AVAudioFormat *processingFormat = [audioFile processingFormat];
        durationSeconds = audioFile.length / processingFormat.sampleRate;
    }
    
    id refFile = trackInfo[@"referencefile"];
    if (refFile) {
        id startTimeValue = trackInfo[@"starttime"];
        float startTime = startTimeValue ? [startTimeValue floatValue] : 0.0;
        
        id startInsetValue = refFile[@"startinset"];
        float startInset = startInsetValue ? [startInsetValue floatValue] : 0.0;
        id endInsetValue = refFile[@"endinset"];
        float endInset = endInsetValue ? [endInsetValue floatValue] : 0.0;

        JWPlayerFileInfo *fileRefObject =
        [[JWPlayerFileInfo alloc] initWithCurrentPosition:0.0 duration:durationSeconds
                                            startPosition:startTime
                                               startInset:startInset
                                                 endInset:endInset];
        
        resultDuration = fileRefObject.duration;
        
        NSLog(@"%s %.2f %.2f %.2f",__func__,startInset,endInset,durationSeconds);
    } else {
        resultDuration = durationSeconds;
        NSLog(@"%s %.2fs no referencefile",__func__,durationSeconds);
    }
    
    return resultDuration;
}

-(NSMutableDictionary*)trackMutableInfoForTrack:(NSUInteger)track {
    NSLog(@"%s %lu",__func__,(unsigned long)track);
    NSMutableDictionary *result;
    for (id item in [_tracks allKeys]) {
        id trackNumberValue = _tracks[item][@"tracknum"];
        NSUInteger tn = [(NSNumber*)trackNumberValue unsignedIntegerValue];
        if (tn == track){
            result = _tracks[item];
            break;
        }
    }
    return result;
}

-(void)updateTrackInfo:(NSMutableDictionary*)trackInfo withFileReference:(id)fileReference {
    
    if (fileReference) {
        
        // AS OBJECT
        if ([fileReference isKindOfClass:[JWPlayerFileInfo class]]) {
            
            JWPlayerFileInfo *refFileObject = fileReference;
            
            // GET START TIME
            trackInfo[@"starttime"] = @(refFileObject.trackStartPosition);
            
            // UPDATE or CREATE NEW REFFILE
            id refFile = trackInfo[@"referencefile"];
            if (refFile) {
                refFile[@"duration"] = @(refFileObject.trackDuration);
                refFile[@"startinset"] = @(refFileObject.startPositionInset);
                refFile[@"endinset"] = @(refFileObject.endPositionInset);
            } else {
                refFile =[@{@"duration":@(refFileObject.trackDuration),
                            @"startinset":@(refFileObject.startPositionInset),
                            @"endinset":@(refFileObject.endPositionInset),
                            } mutableCopy];
            }
            
            trackInfo[@"referencefile"] = refFile;
            
//            NSLog(@"%s update referencefile from OBJECT ",__func__);
            
        }
        // AS DICTIONARY
        else if ([fileReference isKindOfClass:[NSDictionary class]]) {
            
            NSDictionary *refFileDict = fileReference;

            // GET START TIME
            id startTimeValue = refFileDict[@"starttime"];
            if (startTimeValue)
                trackInfo[@"starttime"] = startTimeValue;
            
            // UPDATE or CREATE NEW REFFILE
            id refFile = trackInfo[@"referencefile"];
            if (refFile) {
                id insetValue = refFileDict[@"startinset"];
                if  (insetValue)
                    refFile[@"startinset"] = insetValue;
                insetValue = refFileDict[@"endinset"];
                if  (insetValue)
                    refFile[@"endinset"] = insetValue;
                id durValue = refFileDict[@"duration"];
                if  (durValue)
                    refFile[@"duration"] = durValue;
                
            } else {
                NSURL *fileURL = trackInfo[@"fileurl"];
                NSTimeInterval durationSeconds = 0.0;
                if (fileURL){
                    NSError *error = nil;
                    AVAudioFile *audioFile = [[AVAudioFile alloc] initForReading:fileURL error:&error];
                    AVAudioFormat *processingFormat = [audioFile processingFormat];
                    durationSeconds = audioFile.length / processingFormat.sampleRate;
                }
                
                id startInsetValue = refFile[@"startinset"];
                float startInset = startInsetValue ? [startInsetValue floatValue] : 0.0;
                id endInsetValue = refFile[@"endinset"];
                float endInset = endInsetValue ? [endInsetValue floatValue] : 0.0;
                
                refFile =[@{@"duration":@(durationSeconds),
                            @"startinset":@(startInset),
                            @"endinset":@(endInset),
                            } mutableCopy];
            }
            
            trackInfo[@"referencefile"] = refFile;
            
//            NSLog(@"%s update referencefile from DICT ",__func__);
            
        }
        // fileReferenceObjectForTrack can now be used
    }
    else {
        // nil file reference - no changes made
        NSLog(@"%s nil track info no change",__func__);
    }
}


/* ----------------------------------------------------
 DELEGATE EDITING PROTOCOL
 
 editCompleted nil-fileReference
 editChange    nil-fileReference
 editCompletedForTrack withTrackInfo: (id)fileReference
 editChangeForTrack withTrackInfo:    (id)fileReference

 ----------------------------------------------------
 */

#pragma mark - Scrubber View delegate

-(CGSize)viewSize {
    return _scrubberControllerSize;
}

//NSLog(@"%s %@",__func__,NSStringFromCGSize(_scrubberControllerSize));
//NSLog(@"%s %ld",__func__,track);

-(void)trackSelected:(NSUInteger)track {
    _selectedTrack = [self trackIdForTrack:track];
    if ([_delegate respondsToSelector:@selector(scrubber:selectedTrack:)])
        [_delegate scrubber:self selectedTrack:_selectedTrack];
}

-(void)trackNotSelected {
    if ([_delegate respondsToSelector:@selector(scrubberTrackNotSelected:)])
        [_delegate scrubberTrackNotSelected:self];
}

-(void)longPressOnTrack:(NSUInteger)track {
    _selectedTrack = [self trackIdForTrack:track];
    [_delegate scrubberDidLongPress:self forScrubberId:_selectedTrack];
}

-(void)playHeadTapped {
    [_delegate scrubberPlayHeadTapped:self];
}


-(NSDictionary*)trackColorsForTrack:(NSUInteger)track {

    id trackId = [self trackIdForTrack:track];
    id trackColors = _trackColorsByTrackId[trackId];
    if (trackColors == nil)
        trackColors = _trackColorsAllTracks;
    return trackColors;
}


#pragma mark edit delegate

-(NSString*)trackIdForTrack:(NSUInteger)track {
//    NSLog(@"%s %ld",__func__,track);
    NSString *result;
    for (id item in [_tracks allKeys]) {
        id trackNumberValue = _tracks[item][@"tracknum"];
        NSUInteger tn = [(NSNumber*)trackNumberValue unsignedIntegerValue];
        if (tn == track){
            result = item;
            break;
        }
    }
    return result;
}

-(NSDictionary*)trackInfoForTrack:(NSUInteger)track {
    NSLog(@"%s %lu",__func__,(unsigned long)track);
    NSDictionary *result;
    for (id item in [_tracks allKeys]) {
        id trackNumberValue = _tracks[item][@"tracknum"];
        NSUInteger tn = [(NSNumber*)trackNumberValue unsignedIntegerValue];
        if (tn == track){
            result = _tracks[item];
            break;
        }
    }
    return result;
}

-(void)editCompleted:(NSUInteger)track {
    
    [self editCompletedForTrack:track withTrackInfo:nil];
}

-(void)editChange:(NSUInteger)track {
    
    [self editChangeForTrack:track withTrackInfo:nil];
}


// nil fileReference no change
-(void)editCompletedForTrack:(NSUInteger)track withTrackInfo:(id)fileReference {
    
    NSString *trackId;
    NSMutableDictionary *trackInfo;
    // GET THE track info and trackId
    for (id item in [_tracks allKeys]) {
        id trackNumberValue = _tracks[item][@"tracknum"];
        NSUInteger tn = [(NSNumber*)trackNumberValue unsignedIntegerValue];
        if (tn == track){
            trackInfo = _tracks[item];
            trackId = item;
            break;
        }
    }

    [self updateTrackInfo:trackInfo withFileReference:fileReference];
    
    [self redrawFromCurrentForTrack:trackId];
    
    // SEND MESSAGE to Delegate with our without data
    id trackInfoData = nil;
    if (fileReference) {
        id startTimeValue = trackInfo[@"starttime"];
        float startTime = startTimeValue ? [startTimeValue floatValue] : 0.0;
        id refFile = trackInfo[@"referencefile"];
        trackInfoData = @{@"starttime" : @(startTime),
                          @"referencefile" : refFile ? refFile : [NSNull null]
                          };
    }

    if ([_delegate respondsToSelector:@selector(editingCompleted:forScrubberId:withTrackInfo:)])
        [_delegate editingCompleted:self forScrubberId:trackId withTrackInfo:trackInfoData];

}


-(void)editChangeForTrack:(NSUInteger)track withTrackInfo:(id)fileReference{
    
    // GET THE track info and trackId
    NSString *trackId;
    NSMutableDictionary *trackInfo ;
    
    for (id item in [_tracks allKeys]) {
        id trackNumberValue = _tracks[item][@"tracknum"];
        NSUInteger tn = [(NSNumber*)trackNumberValue unsignedIntegerValue];
        if (tn == track){
            trackInfo = _tracks[item];
            trackId = item;
            break;
        }
    }
    
    [self updateTrackInfo:trackInfo withFileReference:fileReference];
    
    
    // SEND MESSAGE to Delegate With Data
    id startTimeValue = trackInfo[@"starttime"];
    float startTime = startTimeValue ? [startTimeValue floatValue] : 0.0;
    id refFile = trackInfo[@"referencefile"];
    id trackInfoData = @{@"starttime" : @(startTime),
                         @"referencefile" : refFile ? refFile : [NSNull null]
                         };
    
    if ([_delegate respondsToSelector:@selector(editingMadeChange:forScrubberId:withTrackInfo:)])
        [_delegate editingMadeChange:self forScrubberId:trackId withTrackInfo:trackInfoData];

}


-(void)positionInTrackChangedPosition:(CGFloat)positionSeconds {
    
    NSInteger track = [self trackNumberForSource];
    if (track != NSNotFound) {
        _durationForTrack[track] = positionSeconds;
        NSLog(@"PC StartDur %.3f in track %ld",_durationForTrack[track],(long)track);
    }
    
    [_delegate positionChanged:self positionSeconds:positionSeconds];
}

/* ----------------------------------------------------
 END EDITING PROTOCOL
 ----------------------------------------------------
 */


#pragma mark - Scrubber track delegate

-(void)volumeAdjusted:(JWScrubberTackModify*)controller forTrack:(NSUInteger)track withValue:(float)value {
    [_scrubber modifyTrack:track volume:value];
}
-(void)panAdjusted:(JWScrubberTackModify*)controller forTrack:(NSUInteger)track withValue:(float)value {
    [_scrubber modifyTrack:track pan:value];
}

#pragma mark - modify

-(void)modifyTrack:(NSString*)trackId alpha:(CGFloat)alpha  {
    NSUInteger track = 1;
    if (trackId)
        track = [(NSNumber*)_tracks[trackId][@"tracknum"] unsignedIntegerValue];
    [_scrubber modifyTrack:track alpha:alpha];
}
-(void)modifyTrack:(NSString*)trackId colors:(NSDictionary*)trackColors  {
    NSUInteger track = 1;
    if (trackId)
        track = [(NSNumber*)_tracks[trackId][@"tracknum"] unsignedIntegerValue];
    [_scrubber modifyTrack:track colors:trackColors];
}
-(void)modifyTrack:(NSString*)trackId colors:(NSDictionary*)trackColors alpha:(CGFloat)alpha  {
    NSUInteger track = 1;
    if (trackId)
        track = [(NSNumber*)_tracks[trackId][@"tracknum"] unsignedIntegerValue];
    [_scrubber modifyTrack:track colors:trackColors alpha:alpha];
}
-(void)modifyTrack:(NSString*)trackId pan:(CGFloat)panValue  {
    NSUInteger track = 1;
    if (trackId)
        track = [(NSNumber*)_tracks[trackId][@"tracknum"] unsignedIntegerValue];
    [_scrubber modifyTrack:track pan:panValue];
}
-(void)modifyTrack:(NSString*)trackId volume:(CGFloat)volumeValue {
    NSUInteger track = 1;
    if (trackId)
        track = [(NSNumber*)_tracks[trackId][@"tracknum"] unsignedIntegerValue];
    [_scrubber modifyTrack:track volume:volumeValue];
}

#pragma mark -

// prepareScrubberFileURL

/*
  There two types of prepare , prepareScrubberFileURL and prepareScrubberListenerSource
 
  auto generated ids
  
  prepareScrubberFileURL - is for playing
  audioAnalyzer for a file
 
  prepareScrubberListenerSource - is for recording from mic and install Tap
  registers the sids to scrubbers
  use this method to activate the JWScrubberBufferControllerDelegate
  this is for recording where the caller registers
 
*/

-(NSString*)prepareScrubberFileURL:(NSURL*)fileURL
                      onCompletion:(JWScrubberControllerCompletionHandler)completion
{
    return [self prepareScrubberFileURL:fileURL withSampleSize:SampleSize14
                                options:SamplingOptionDualChannel
                                   type:VABOptionNone
                                 layout:VABLayoutOptionShowAverageSamples
                                 colors:nil
                           onCompletion:completion];
}

-(NSString*)prepareScrubberFileURL:(NSURL*)fileURL
                    withSampleSize:(SampleSize)ssz
                           options:(SamplingOptions)options
                              type:(VABKindOptions)typeOptions
                            layout:(VABLayoutOptions)layoutOptions
                      onCompletion:(JWScrubberControllerCompletionHandler)completion
{
    return [self prepareScrubberFileURL:fileURL withSampleSize:ssz
                                options:options type:typeOptions layout:layoutOptions
                                 colors:nil
                           onCompletion:completion];
}

-(NSString*)prepareScrubberFileURL:(NSURL*)fileURL
                    withSampleSize:(SampleSize)ssz
                           options:(SamplingOptions)options
                              type:(VABKindOptions)typeOptions
                            layout:(VABLayoutOptions)layoutOptions
                            colors:(NSDictionary*)trackColors
                      onCompletion:(JWScrubberControllerCompletionHandler)completion
{
    return [self prepareScrubberFileURL:fileURL withSampleSize:ssz options:options type:typeOptions layout:layoutOptions
                                 colors:nil
                          referenceFile:nil
                              startTime:0.0
                           onCompletion:completion];
}

-(NSString*)prepareScrubberFileURL:(NSURL*)fileURL
                    withSampleSize:(SampleSize)ssz
                           options:(SamplingOptions)options
                              type:(VABKindOptions)typeOptions
                            layout:(VABLayoutOptions)layoutOptions
                            colors:(NSDictionary*)trackColors
                     referenceFile:(NSDictionary*)refFile
                         startTime:(float)startTime
                      onCompletion:(JWScrubberControllerCompletionHandler)completion
{
    [self.scrubber refresh];
    
    NSString *sid = [[NSUUID UUID] UUIDString];
    _trackCount++;
    NSUInteger track  = _trackCount;
    
    NSMutableDictionary *trackInfo = [@{@"fileurl":fileURL,
                                        @"tracknum":@(track),
                                        @"samplesize":@(ssz),
                                        @"options":@(options),
                                        @"kind":@(typeOptions),
                                        @"layout":@(layoutOptions),
                                        @"starttime":@(startTime),
                                        } mutableCopy];
    
    JWPlayerFileInfo *fileReference = nil;
    if (refFile) {
        NSError *error = nil;
        AVAudioFile *audioFile = [[AVAudioFile alloc] initForReading:fileURL error:&error];
        AVAudioFormat *processingFormat = [audioFile processingFormat];
        NSTimeInterval durationSeconds = audioFile.length / processingFormat.sampleRate;
        
        id startInsetValue = refFile[@"startinset"];
        float startInset = startInsetValue ? [startInsetValue floatValue] : 0.0;
        id endInsetValue = refFile[@"endinset"];
        float endInset = endInsetValue ? [endInsetValue floatValue] : 0.0;
        
        fileReference =
        [[JWPlayerFileInfo alloc] initWithCurrentPosition:0.0 duration:durationSeconds
                                            startPosition:startTime
                                               startInset:startInset
                                                 endInset:endInset];
        
        // Create a NEW Dict object for referencefile
        trackInfo[@"referencefile"] =[@{@"duration":@(durationSeconds),
                                        @"startinset":@(startInset),
                                        @"endinset":@(endInset),
                                        } mutableCopy];

        NSLog(@"%s %.2f %.2f %.2f",__func__,startInset,endInset,durationSeconds);
    }
    
    _tracks[sid] = trackInfo;
    
    [self configureColors:trackColors forTackId:sid];
    
    if (track==1) { // Do some first track stuff
        _scrubber.viewOptions = _viewOptions;
        [_scrubber prepareForTracks];
        if ((_viewOptions == ScrubberViewOptionDisplayLabels) || (_viewOptions == ScrubberViewOptionDisplayOnlyValueLabels)) {
            dispatch_async(dispatch_get_main_queue(), ^{
                _scrubber.playHeadValueStr = @"";
//                _scrubber.playHeadValueStr = [NSString stringWithFormat:@"%.0f",0.0];
                if ([_delegate respondsToSelector:@selector( durationInSecondsOfAudioFile:forScrubberId:)]) {
                    _scrubber.remainingValueStr =
                    [NSString stringWithFormat:@"%.0f",[_delegate durationInSecondsOfAudioFile:self forScrubberId:sid]];
                    _scrubber.durationValueStr =
                    [NSString stringWithFormat:@"%.0f seconds",[_delegate durationInSecondsOfAudioFile:self forScrubberId:sid]];
                }
                
                if ([_delegate respondsToSelector:@selector( processingFormatStr:forScrubberId:)])
                    _scrubber.formatValueStr = [_delegate processingFormatStr:self forScrubberId:sid];
            });
        }
        
        // consider scrubber colors
        if (_scrubberColors == nil) {
            [self configureScrubberColors:[self scrubberColorsDefaultConfig1]];
        }
    }
    
    if (startTime > 0.0) {
        [_scrubber setTrackStartPosition:startTime forTrack:track];
        _durationForTrack[track] = startTime;
    }
    
    [self audioFileAnalyzerForFile:fileURL forTrackId:sid usingFileReference:fileReference];
    
    if (completion)
        completion();

    return sid;
}


// prepareScrubberListenerSource

-(NSString*)prepareScrubberListenerSource:(id <JWScrubberBufferControllerDelegate>)scrubberSource
                           withSampleSize:(SampleSize)ssz
                                  options:(SamplingOptions)options
                                     type:(VABKindOptions)typeOptions
                                   layout:(VABLayoutOptions)layoutOptions
                             onCompletion:(JWScrubberControllerCompletionHandler)completion {

    return [self prepareScrubberListenerSource:scrubberSource withSampleSize:ssz options:options type:typeOptions layout:layoutOptions colors:nil onCompletion:nil];
}

-(NSString*)prepareScrubberListenerSource:(id <JWScrubberBufferControllerDelegate>)scrubberSource
                           withSampleSize:(SampleSize)ssz
                                  options:(SamplingOptions)options
                                     type:(VABKindOptions)typeOptions
                                   layout:(VABLayoutOptions)layoutOptions
                                   colors:(NSDictionary*)trackColors
                             onCompletion:(JWScrubberControllerCompletionHandler)completion
{
    
    NSString *sid = [[NSUUID UUID] UUIDString];
    
    _trackCount++;
    NSUInteger track  = _trackCount;
    
    _tracks[sid] = [@{@"source":scrubberSource==nil ? (id <JWScrubberBufferControllerDelegate>)[NSNull null] : scrubberSource,
                      @"tracknum":@(track),
                      @"samplesize":@(ssz),
                      @"options":@(options),
                      @"kind":@(typeOptions),
                      @"layout":@(layoutOptions)
                      }
                    mutableCopy];

    [self configureColors:trackColors forTackId:sid];

    
    if (track==1) { // Do some first track stuff
        _scrubber.viewOptions = _viewOptions;
        [_scrubber prepareForTracks];
        if ((_viewOptions == ScrubberViewOptionDisplayLabels) || (_viewOptions == ScrubberViewOptionDisplayOnlyValueLabels)) {
            dispatch_async(dispatch_get_main_queue(), ^{
                _scrubber.playHeadValueStr = @"";
            });
        }
        
        // consider scrubber colors
        if (_scrubberColors == nil) {
            [self configureScrubberColors:[self scrubberColorsDefaultConfig1]];
        }
    }
    
    _buffersReceivedCounts[track] = 0;
    _buffersSentCounts[track] = 0;

    _elapsedTimesSoFar[track] = 0.000f;
    _loudestSamplesSofar[track] = 0.0001f;

    if (completion)
        completion();

    return sid;
}


#pragma mark -

-(BOOL)isPlaying {
    return [_playerTimer isValid];
}

-(void)progressPlayHead {
    
    if ((_viewOptions == ScrubberViewOptionDisplayLabels) || (_viewOptions == ScrubberViewOptionDisplayOnlyValueLabels)) {

        NSString *sid = _playerTrackId;

        if ([_delegate respondsToSelector:@selector( currentPositionInSecondsOfAudioFile:forScrubberId:)]) {
            NSString *value;
            CGFloat cp = [_delegate currentPositionInSecondsOfAudioFile:self forScrubberId:sid];
            if (cp < 0)
                cp = 0.0;
            if  (cp < 1.0)
                value = @"";
            else
                value = [NSString stringWithFormat:_playerProgressFormatString,cp];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                _scrubber.playHeadValueStr = value;
            });
        }

        if ([_delegate respondsToSelector:@selector( remainingDurationInSecondsOfAudioFile:forScrubberId:)]) {
            NSString *value = [NSString stringWithFormat:@"%.0f",[_delegate remainingDurationInSecondsOfAudioFile:self forScrubberId:sid]];
            dispatch_async(dispatch_get_main_queue(), ^{
                _scrubber.remainingValueStr = value;
            });
        }
    }
}

-(void)progressPlayHeadAtPostion:(CGFloat)pos {
    
    if ((_viewOptions == ScrubberViewOptionDisplayLabels) || (_viewOptions == ScrubberViewOptionDisplayOnlyValueLabels)) {
        CGFloat cp = pos;
        if (cp < 0)
            cp = 0.0;

        dispatch_async(dispatch_get_main_queue(), ^{
            _scrubber.playHeadValueStr = [NSString stringWithFormat:@"%.2f",cp];
        });
    }
}

//                if  (cp < 1.0)
//                    _scrubber.playHeadValueStr = @"";
//                else
//                    _scrubber.playHeadValueStr = [NSString stringWithFormat:_playerProgressFormatString,cp];


-(void)startPlayTimer {
    
    CGFloat playerTiming = 0.10;
    
    if (_recordingStartTime == nil) {
        [self progressPlayHead];
    } else {
        _scrubber.clipEnd.hidden = YES;
        
        self.recordingTimer = [NSTimer timerWithTimeInterval:0.14 target:self selector:@selector(recorderTimerFired:) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:_recordingTimer forMode:NSRunLoopCommonModes];

        playerTiming = .20;
    }
    
    self.playerTimer = [NSTimer timerWithTimeInterval:playerTiming target:self selector:@selector(playTimerFired:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_playerTimer forMode:NSRunLoopCommonModes];
}


-(void)recorderTimerFired:(NSTimer*)timer {
    
    if (timer.valid) {
        if (_recordingStartTime != nil) {
            dispatch_async (dispatch_get_global_queue( QOS_CLASS_USER_INTERACTIVE,0),^{
                [self audioFileAnalyzerForRecorderFile:_recordingURL forTrackId:_playerTrackId];
            });
        }
    }
}

-(void)playTimerFired:(NSTimer*)timer {

    if (timer.valid) {
        if (_recordingStartTime == nil) {
            
            [self progressPlayHead];
            // Obtain the progress of the audio file from the Engine
            // and set the scrubber to that progress
            float progress = 0.0;
            if ([_delegate respondsToSelector:@selector( progressOfAudioFile:forScrubberId:)])
                progress = [_delegate progressOfAudioFile:self forScrubberId:_playerTrackId];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.scrubber trackScrubberToProgress:progress];
            });
            
            if (_pulseOn) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self pulseOnProgress:progress];
                });
            }
            
        } else {
            
            CGFloat cp = [_delegate currentPositionInSecondsOfAudioFile:self forScrubberId:_playerTrackId];

            [self progressPlayHeadAtPostion:cp];

            dispatch_async(dispatch_get_main_queue(), ^{
                [_scrubber setScrubberLength:cp];
                [self.scrubber trackScrubberToPostion:cp timeAnimated:YES];
            });
        }
        
    } else {
        NSLog(@"%s invld tmr",__func__);
    }
}

#pragma mark - Camera

-(void)setBackgroundToClear {
    [_scrubber setBackgroundToClear];
}


#pragma mark - pulse types

//#define TRACEPULSE

-(void)pulseOnProgress:(CGFloat)progress {
    [self pulseOnProgress:progress trackId:_playerTrackId];
}

-(void)pulseOnProgress:(CGFloat)progress trackId:(NSString*)trackId {
    // float currentPosSeconds = [_delegate currentPositionInSecondsOfAudioFile:self forScrubberId:sid];
    // find index holding values use first for duration division

    float currentPosSeconds = 0;

    if ([_delegate respondsToSelector:@selector( durationInSecondsOfAudioFile:forScrubberId:)]) {
        currentPosSeconds =
        [_delegate durationInSecondsOfAudioFile:self forScrubberId:trackId ] * progress;
    }
    
    float buffersDuration = [_pulseSamplesDurations[0] floatValue];
    NSUInteger indexOfBuffer = 0;
    if (buffersDuration > 0)
        indexOfBuffer = floor(currentPosSeconds/buffersDuration);
    
    float remainder = (currentPosSeconds / buffersDuration);
    remainder -= indexOfBuffer;
    
    float remainderProgress = 1.0 - remainder;
    
    if (indexOfBuffer > [_pulseSamples count] - 1) {
#ifdef TRACEPULSE
        NSLog(@"%s OUT of Range index %ld dur %.2f currentPos %.3f",__func__,indexOfBuffer,buffersDuration,currentPosSeconds);
#endif
    } else {
        
        NSUInteger pulseType = 3;
        NSArray *pulsData = _pulseSamples[indexOfBuffer];
        
        if (pulseType == 1) {
            float progressValue = [pulsData[0] floatValue];  // as a fraction of duration
            float endSampleValue = [pulsData[1] floatValue]; // the first sample value
            // pulse anim 1 -  to first point
            
            if (remainderProgress > progressValue ) {
                progressValue = [pulsData[2] floatValue];  // as a fraction of duration
                endSampleValue = [pulsData[3] floatValue]; // the first sample value
                [_scrubber pulseLight:0 endValue:endSampleValue duration:progressValue * buffersDuration];
            } else {
                [_scrubber pulseLight:0 endValue:endSampleValue duration:progressValue * buffersDuration];
            }

        } else if (pulseType == 2) {
            
            float startSampleValue = [pulsData[1] floatValue];  // as a fraction of duration
            float progressValue = [pulsData[0] floatValue];  // as a fraction of duration
            float endSampleValue = [pulsData[1] floatValue]; // the first sample value
            if ([pulsData[0] floatValue] > 0.50) {
                // first value h
            }
            
#ifdef TRACEPULSE
            NSLog(@"%s ndx %ld prValue %.3f endsmplvl %.3f rem %.4f",__func__,indexOfBuffer,progressValue,endSampleValue,remainder);
#endif
            float remainingDuration = buffersDuration - progressValue;
            if (remainder > 0.20 ) {
                startSampleValue = endSampleValue; // the first sample value
                endSampleValue = [pulsData[3] floatValue]; // the second sample value
                
                //                    NSLog(@"%s ndx %ld dur %.2f cpos %.3f pavg %.2f prValue %.3f endsmplvl %.3f",__func__,
                //                          indexOfBuffer,buffersDuration,currentPosSeconds,
                //                          pulseDataAvg,progressValue,endSampleValue);
                
                double delayInSecs = progressValue;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSecs * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    // pulse anim 2 -  first point to second point
                    [_scrubber pulseBackLight:0 endValue:endSampleValue duration:remainingDuration];
                });
            } else {
#ifdef TRACEPULSE
                NSLog(@"SKIP\n");
#endif
            }

            
        } else if (pulseType == 3) {
            
            NSArray *pulsData = _pulseSamples[indexOfBuffer];
            float pulseDataAvg = ([pulsData[1] floatValue] + [pulsData[3] floatValue])/2;
            //                float progressValue = [pulsData[0] floatValue] * buffersDuration;  // as a fraction of duration
            float progressValue = [pulsData[0] floatValue];  // as a fraction of duration
            float startSampleValue = pulseDataAvg; // the first sample value
            float endSampleValue = [pulsData[1] floatValue]; // the first sample value
            // pulse anim 1 -  to first point
            if (remainder > 0.35 ) {
                //we are skipping use the second value
                endSampleValue = [pulsData[3] floatValue]; // the first sample value
            }
            [_scrubber pulseBackLight:0 endValue:endSampleValue duration:progressValue];
            //                if ([pulsData[0] floatValue] > 0.50) {
            //                    // first value h
            //                }
            //                NSLog(@"%s ndx %ld prValue %.3f endsmplvl %.3f rem %.4f",__func__,indexOfBuffer,progressValue,endSampleValue,remainder);
            float remainingDuration = buffersDuration - progressValue;
            if (remainder > 0.15 ) {
                startSampleValue = endSampleValue; // the first sample value
                endSampleValue = [pulsData[3] floatValue]; // the second sample value
#ifdef TRACEPULSE
                NSLog(@"%s ndx %ld dur %.2f cpos %.3f pavg %.2f prValue %.3f endsmplvl %.3f",__func__,
                      indexOfBuffer,buffersDuration,currentPosSeconds,
                      pulseDataAvg,progressValue,endSampleValue);
#endif
                double delayInSecs = progressValue;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSecs * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    // pulse anim 2 -  first point to second point
                    [_scrubber pulseBackLight:0 endValue:endSampleValue duration:remainingDuration];
                });
            } else {
#ifdef TRACEPULSE
                NSLog(@"SKIP\n");
#endif
            }
            
        } else if (pulseType == 4) {
            float pulseDataAvg = ([pulsData[1] floatValue] + [pulsData[3] floatValue])/2;
            float progressValue = [pulsData[0] floatValue];  // as a fraction of duration
            float startSampleValue;
            float endSampleValue;
            
            startSampleValue = [pulsData[1] floatValue];; // the first sample value
            endSampleValue = [pulsData[3] floatValue]; // the second sample value
            
            float middleProgressValue =([pulsData[2] floatValue] * buffersDuration) - progressValue;
            float remainingDuration = buffersDuration - middleProgressValue;
#ifdef TRACEPULSE
            NSLog(@"%s ndx %ld dur %.2f cpos %.3f pavg %.2f prValue %.3f endsmplvl %.3f",__func__,
                  indexOfBuffer,buffersDuration,currentPosSeconds,
                  pulseDataAvg,progressValue,endSampleValue);
#endif
            float lastStartValue = endSampleValue;
            float lastEndValue = pulseDataAvg;
            double delayInSecs = progressValue;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSecs * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                // pulse anim 2 -  first point to second point
                [_scrubber pulseBackLight:startSampleValue endValue:endSampleValue duration:middleProgressValue];
                double delayInSecs = middleProgressValue;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSecs * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    // pulse anim 3 -  second value to avg
                    [_scrubber pulseBackLight:lastStartValue endValue:lastEndValue duration:remainingDuration];
                });
            });
        }
    }
}

#pragma mark - bufferReceivedForTrackId

// PLAYING

- (void)bufferReceivedForTrackId:(NSString*)tid buffer:(AVAudioPCMBuffer *)buffer
                  atReadPosition:(AVAudioFramePosition)readPosition
                   loudestSample:(CGFloat)loudestSampleAllBuffers
{
    // Identify the track
    
    NSUInteger track = [(NSNumber*)_tracks[tid][@"tracknum"] unsignedIntegerValue];
    
    // GET the options and Configure them

    SampleSize sz = [_tracks[tid][@"samplesize"] unsignedIntValue];
    SamplerSampleSize bufferSampleSize = SSampleSizeMin;
    if (sz ==SampleSize4) {
        bufferSampleSize = SSampleSize4;
    } else if (sz ==SampleSize6) {
        bufferSampleSize = SSampleSize6;
    } else if (sz ==SampleSize8) {
        bufferSampleSize = SSampleSize8;
    } else if (sz ==SampleSize10) {
        bufferSampleSize = SSampleSize10;
    } else if (sz ==SampleSize14) {
        bufferSampleSize = SSampleSize14;
    } else if (sz ==SampleSize18) {
        bufferSampleSize = SSampleSize18;
    }
    
    // GET the options and Configure them
    SamplingOptions options = [self configOptionsForTrack:tid];
    VABLayoutOptions layoutOptions = [self layoutOptionsForTrack:tid];
    VABKindOptions typeOptions = [self kindOptionsForTrack:tid];
    
    BOOL dc = options & SamplingOptionDualChannel;  // dual channel
    BOOL computeAverages  = ! (options & SamplingOptionNoAverages);
    BOOL collectPulseData = options & SamplingOptionCollectPulseData;

    if  (_pulseOn == NO  && collectPulseData)
        _pulseOn = YES;
    
    id trackColors = _trackColorsByTrackId[tid];
    if (trackColors == nil)
        trackColors = _trackColorsAllTracks;
    
    // Compute relevant data for this buffer
    
    _buffersReceivedCounts[track]++;
    
    float startDuration = _durationForTrack[track];

    Float64 mSampleRate = buffer.format.streamDescription->mSampleRate;
    Float64 duration =  (1.0 / mSampleRate) * buffer.format.streamDescription->mFramesPerPacket;
    float durThisBuffer = duration * buffer.frameLength;

    _durationForTrack[track] += durThisBuffer;
    
    NSUInteger bufferNo = _buffersReceivedCounts[track];
    
    // Dispatch creation of Sample data
    
    dispatch_async(_bufferReceivedQueue, ^{
        
        JWBufferSampler *bufferSampler =
        [[JWBufferSampler alloc] initWithBuffer:buffer atReadPosition:readPosition
                                     sampleSize:bufferSampleSize
                                    dualChannel:dc
                                computeAverages:computeAverages
                                   pulseSamples:collectPulseData
                                  loudestSample:loudestSampleAllBuffers ];
        
        if (collectPulseData) {
            [self.pulseSamplesDurations addObject:@(bufferSampler.durationThisBuffer)];
            CGFloat pulsePosLowest = (CGFloat)bufferSampler.lowestSampleFramePostion / buffer.frameLength;
            CGFloat pulsePosLoudest = (CGFloat)bufferSampler.loudestSampleFramePostion / buffer.frameLength;
            /*
             Each element has four values
             valuePos , value , valuePos , value
             Describing two samples the lowest and highest
             */
            if (pulsePosLowest > pulsePosLoudest) {
                [self.pulseSamples addObject:@[@(pulsePosLoudest),@(bufferSampler.loudestSampleValue),  @(pulsePosLowest),@(bufferSampler.lowestSampleValue)]];
            } else {
                [self.pulseSamples addObject:@[@(pulsePosLowest),@(bufferSampler.lowestSampleValue),  @(pulsePosLoudest),@(bufferSampler.loudestSampleValue)]];
            }
        }
        
        
        // when finished sampling add the buffer to the view
        dispatch_async(_bufferSampledQueue, ^{
            
            NSUInteger finalValue;
//            if (_buffersSentCounts[track] > _buffersReceivedCounts[track])
//                finalValue = 0; // not finsihed
//            else
                finalValue = _buffersSentCounts[track];  // finished heres the number

            [self.scrubber addAudioViewChannelSamples:bufferSampler.samples
                                       averageSamples:bufferSampler.averageSamples
                                      channel2Samples:bufferSampler.samplesChannel2
                                      averageSamples2:bufferSampler.averageSamplesChannel2
                                              inTrack:track
                                        startDuration:(NSTimeInterval)startDuration
                                             duration:(NSTimeInterval)bufferSampler.durationThisBuffer
                                                final:finalValue
                                              options:options
                                                 type:typeOptions
                                               layout:layoutOptions
                                               colors:trackColors
                                            bufferSeq:bufferNo
                                          autoAdvance:NO
                                            recording:NO
                                              editing:NO
                                                 size:_scrubberControllerSize ];
        }); //_bufferSampledQueue
        
    }); //_bufferReceivedQueue

}


// PLAYing Editing

- (void)bufferReceivedForEditingTrackId:(NSString*)tid buffer:(AVAudioPCMBuffer *)buffer
                  atReadPosition:(AVAudioFramePosition)readPosition
                   loudestSample:(CGFloat)loudestSampleAllBuffers
{
    // Identify the track
    NSUInteger track = [(NSNumber*)_tracks[tid][@"tracknum"] unsignedIntegerValue];
    
    // GET the options and Configure them
    
    SampleSize sz = [_tracks[tid][@"samplesize"] unsignedIntValue];
    SamplerSampleSize bufferSampleSize = SSampleSizeMin;
    if (sz ==SampleSize4) {
        bufferSampleSize = SSampleSize4;
    } else if (sz ==SampleSize6) {
        bufferSampleSize = SSampleSize6;
    } else if (sz ==SampleSize8) {
        bufferSampleSize = SSampleSize8;
    } else if (sz ==SampleSize10) {
        bufferSampleSize = SSampleSize10;
    } else if (sz ==SampleSize14) {
        bufferSampleSize = SSampleSize14;
    } else if (sz ==SampleSize18) {
        bufferSampleSize = SSampleSize18;
    }
    
    // GET the options and Configure them
    SamplingOptions options = [self configOptionsForTrack:tid];
    VABLayoutOptions layoutOptions = [self layoutOptionsForTrack:tid];
    VABKindOptions typeOptions = [self kindOptionsForTrack:tid];
    
    BOOL dc = options & SamplingOptionDualChannel;  // dual channel
    BOOL computeAverages  = ! (options & SamplingOptionNoAverages);
    BOOL collectPulseData = options & SamplingOptionCollectPulseData;
    //BOOL collectPulseData = NO; // editing
    
    if  (_pulseOn == NO  && collectPulseData)
        _pulseOn = YES;

    // EDITING
    id trackColors =
    _trackColorsByTrackId[tid];
    if (trackColors == nil)
        trackColors = _trackColorsAllTracks;

//    @{
//      JWColorScrubberTopPeak : [[UIColor lightGrayColor] colorWithAlphaComponent:0.6],
//      JWColorScrubberTopAvg : [UIColor colorWithWhite:0.6 alpha:0.5] ,
//      JWColorScrubberBottomAvg : [UIColor colorWithWhite:0.6 alpha:0.5],
//      JWColorScrubberBottomPeak : [[UIColor lightGrayColor] colorWithAlphaComponent:0.6],
//      JWColorScrubberTopPeakNoAvg : [[UIColor lightGrayColor] colorWithAlphaComponent:0.8],
//      JWColorScrubberBottomPeakNoAvg : [[UIColor lightGrayColor] colorWithAlphaComponent:0.8],
//      };
    
    // Compute relevant data for this buffer
    
    _buffersReceivedCounts[0]++;   // use first index EDITING
    
    float startDuration = _durationForTrack[track];
    
    Float64 mSampleRate = buffer.format.streamDescription->mSampleRate;
    Float64 duration =  (1.0 / mSampleRate) * buffer.format.streamDescription->mFramesPerPacket;
    float durThisBuffer = duration * buffer.frameLength;
    
    _durationForTrack[track] += durThisBuffer;
    
    NSUInteger bufferNo = _buffersReceivedCounts[0];
    // Dispatch creation of Sample data
    
    dispatch_async(_bufferReceivedQueue, ^{
        
        JWBufferSampler *bufferSampler =
        [[JWBufferSampler alloc] initWithBuffer:buffer atReadPosition:readPosition
                                     sampleSize:bufferSampleSize
                                    dualChannel:dc
                                computeAverages:computeAverages
                                   pulseSamples:collectPulseData
                                  loudestSample:loudestSampleAllBuffers ];
        
        // when finished sampling add the buffer to the view
        
        dispatch_async(_bufferSampledQueue, ^{
            
            NSUInteger finalValue;
//            if (_buffersSentCounts[track] > _buffersReceivedCounts[track])
//                finalValue = 0; // not finsihed
//            else
                finalValue = _buffersSentCounts[0];  // finished heres the number

            [self.scrubber addAudioViewChannelSamples:bufferSampler.samples
                                       averageSamples:bufferSampler.averageSamples
                                      channel2Samples:bufferSampler.samplesChannel2
                                      averageSamples2:bufferSampler.averageSamplesChannel2
                                              inTrack:track
                                        startDuration:(NSTimeInterval)startDuration
                                             duration:(NSTimeInterval)bufferSampler.durationThisBuffer
                                                final:finalValue
                                              options:options
                                                 type:typeOptions
                                               layout:layoutOptions
                                               colors:trackColors
                                            bufferSeq:bufferNo
                                          autoAdvance:NO
                                            recording:NO
                                              editing:YES
                                                 size:_scrubberControllerSize ];
        }); //_bufferSampledQueue
        
    }); //_bufferReceivedQueue
    
}


// RECORDING buffer received
// AS listener

- (void)bufferReceivedForTrackId:(NSString*)tid buffer:(AVAudioPCMBuffer *)buffer
                  atReadPosition:(AVAudioFramePosition)readPosition
{
    // Identify the track
    
    NSUInteger track = [(NSNumber*)_tracks[tid][@"tracknum"] unsignedIntegerValue];
    
    // GET the options and Configure them

    SampleSize sz = [_tracks[tid][@"samplesize"] unsignedIntValue];
    SamplerSampleSize bufferSampleSize = SSampleSizeMin;
    if (sz ==SampleSize4) {
        bufferSampleSize = SSampleSize4;
    } else if (sz ==SampleSize6) {
        bufferSampleSize = SSampleSize6;
    } else if (sz ==SampleSize8) {
        bufferSampleSize = SSampleSize8;
    } else if (sz ==SampleSize10) {
        bufferSampleSize = SSampleSize10;
    } else if (sz ==SampleSize14) {
        bufferSampleSize = SSampleSize14;
    } else if (sz ==SampleSize18) {
        bufferSampleSize = SSampleSize18;
    }

    SamplingOptions options = [self configOptionsForTrack:tid];
    VABLayoutOptions layoutOptions = [self layoutOptionsForTrack:tid];
    VABKindOptions typeOptions = [self kindOptionsForTrack:tid];
    
    BOOL dc = options & SamplingOptionDualChannel;  // dual channel
    BOOL computeAverages  = ! (options & SamplingOptionNoAverages);
    BOOL collectPulseData = options & SamplingOptionCollectPulseData;
    
    if  (_pulseOn == NO  && collectPulseData)
        _pulseOn = YES;
    
    id trackColors = _trackColorsByTrackId[tid];
    if (trackColors == nil) {
        trackColors = _trackColorsAllTracks;
    }
    
    // Compute relevant data for this buffer

    _buffersReceivedCount++;
    _buffersReceivedCounts[track]++;

    float startDuration = _durationForTrack[track];
    
    NSLog(@"BR StartDur %.3f in track %ld",startDuration,track);

    Float64 mSampleRate = buffer.format.streamDescription->mSampleRate;
    Float64 duration =  (1.0 / mSampleRate) * buffer.format.streamDescription->mFramesPerPacket;
    float durThisBuffer = duration * buffer.frameLength;
    
    if ([self.playerTimer isValid]) {
        _durationForTrack[track] += durThisBuffer;
    } else {
        
    }

    NSUInteger bufferNo = _buffersReceivedCounts[track];
    
    // Dispatch creation of Sample data

    dispatch_async(_bufferReceivedPerformanceQueue, ^{

        JWBufferSampler *bufferSampler =
        [[JWBufferSampler alloc] initWithBuffer:buffer atReadPosition:readPosition
                                     sampleSize:bufferSampleSize
                                    dualChannel:dc
                                computeAverages:computeAverages
                                   pulseSamples:collectPulseData
                             loudestSampleSoFar:(float)_loudestSamplesSofar[track]];

        // updtae stats on loudest so far for the track
        
        if (bufferSampler.loudestSample > _loudestSamplesSofar[track])
            _loudestSamplesSofar[track] = bufferSampler.loudestSample;
        
        _elapsedTimesSoFar[track] += (CGFloat)[bufferSampler durationThisBuffer];
        
        // Auto advance additionally should be checked for whther we are playing
        // cehck against player timer
        // TODO: check the options for autoadvance
        
        BOOL autoAdvance = NO; // maybe we have a tap on mixer
//        if (_numberOfTracks == 1) {
//            autoAdvance = YES;
//        }
        
        if (collectPulseData) {
            [self.pulseSamplesDurations addObject:@(bufferSampler.durationThisBuffer)];
            CGFloat pulsePosLowest = (CGFloat)bufferSampler.lowestSampleFramePostion / buffer.frameLength;
            CGFloat pulsePosLoudest = (CGFloat)bufferSampler.loudestSampleFramePostion / buffer.frameLength;
            /*
             Each element has four values
             valuePos , value , valuePos , value
             Describing two samples the lowest and highest
             */
            if (pulsePosLowest > pulsePosLoudest) {
                [self.pulseSamples addObject:@[@(pulsePosLoudest),@(bufferSampler.loudestSampleValue),  @(pulsePosLowest),@(bufferSampler.lowestSampleValue)]];
            } else {
                [self.pulseSamples addObject:@[@(pulsePosLowest),@(bufferSampler.lowestSampleValue),  @(pulsePosLoudest),@(bufferSampler.loudestSampleValue)]];
            }
        }

//        NSLog(@"%ld %.3f",track,bufferSampler.durationThisBuffer);
        
        dispatch_async(_bufferSampledPerformanceQueue, ^{
            
            NSUInteger finalValue;
//            if (_buffersSentCounts[track] > _buffersReceivedCounts[track])
//                finalValue = 0; // not finsihed
//            else
                finalValue = _buffersSentCounts[track];  // finished heres the number

            [self.scrubber addAudioViewChannelSamples:bufferSampler.samples
                                       averageSamples:bufferSampler.averageSamples
                                      channel2Samples:bufferSampler.samplesChannel2
                                      averageSamples2:bufferSampler.averageSamplesChannel2
                                              inTrack:track
                                        startDuration:(NSTimeInterval)startDuration
                                             duration:(NSTimeInterval)bufferSampler.durationThisBuffer
                                                final:finalValue
                                              options:options
                                                 type:typeOptions
                                               layout:layoutOptions
                                               colors:trackColors
                                            bufferSeq:bufferNo
                                          autoAdvance:autoAdvance
                                            recording:YES
                                              editing:NO
                                                 size:_scrubberControllerSize];
            
        }); //_bufferSampledPerformanceQueue
        
        if (autoAdvance) {
            // is primary track
            dispatch_async(dispatch_get_main_queue(), ^{
                _scrubber.playHeadValueStr = [NSString stringWithFormat:@"%.0f",_elapsedTimesSoFar[track]];
            });
        }
        
    }); // _bufferReceivedPerformanceQueue
    
}


// ARE the biffers completed
-(NSUInteger)buffersCompletedTrack:(NSUInteger)track {
    
    NSUInteger result;
    if (_buffersSentCounts[track] > _buffersReceivedCounts[track]) {
        // not finsihed
        result = 0;
    } else {
        result = _buffersSentCounts[track];  // finished heres the number
    }
    
    return result;
    
}



#pragma mark meter samples

// 2 channels each with peak samples
- (void)meterChannelSamples:(NSArray *)samples samplesForSecondChannel:(NSArray *)samples2 andDuration:(NSTimeInterval)duration forTrackId:(NSString*)tid
{
    [self meterChannelSamplesWithAverages:samples averageSamples:nil channel2Samples:samples2 averageSamples2:nil andDuration:duration forTrackId:tid];
}

// 2 channels each with peak and average samples
- (void)meterChannelSamplesWithAverages:(NSArray *)samples
                         averageSamples:(NSArray*)averageSamples
                        channel2Samples:(NSArray*)samples2 averageSamples2:(NSArray*)averageSamples2
                            andDuration:(NSTimeInterval)duration forTrackId:(NSString*)tid
{
    NSNumber * lastSample = [samples lastObject];
    NSNumber * firstSample = [samples firstObject];
    [_scrubber pulseRecording:[firstSample floatValue] endValue:[lastSample floatValue] duration:duration];
}



//    NSLog(@"%s nsamples %ld",__func__,(unsigned long)[samples count]);
//    NSLog(@"%s %@",__func__,[_tracks[tid] description]);


#pragma mark File Analyzer

//#define TRACEANALYZE

-(void)audioFileAnalyzerForFile:(NSURL*)fileURL forTrackId:(NSString*)tid {
    
    [self audioFileAnalyzerForFile:fileURL forTrackId:tid usingFileReference:nil];
}

-(void)audioFileAnalyzerForFile:(NSURL*)fileURL forTrackId:(NSString*)tid usingFileReference:(JWPlayerFileInfo *)fileReference {
    
    [self audioFileAnalyzerForFile:fileURL forTrackId:tid usingFileReference:fileReference edit:NO];
}

-(void)audioFileAnalyzerForFile:(NSURL*)fileURL forTrackId:(NSString*)tid usingFileReference:(JWPlayerFileInfo *)fileReference edit:(BOOL)editing {
    
    if (!fileURL)
        return;
    
    BOOL readsEntireAudioForLoudest = YES; // even with file ref
    NSError *error;
    AVAudioFile *audioFile = [[AVAudioFile alloc] initForReading:fileURL error:&error];
    AVAudioFormat *processingFormat = [audioFile processingFormat];
    AVAudioFramePosition fileLength = audioFile.length;
    
#ifdef TRACEANALYZE
    NSLog(@"%sLength: %lld, %.3f seconds  \nFile: %@  ",__func__,
          (long long)fileLength, fileLength / audioFile.fileFormat.sampleRate, [fileURL lastPathComponent]);
#endif
    AVAudioFrameCount framesToReadCount = 0;
    // DETERMINE READPOS and TOTAL READLENGTH
    // COMPUTE framesToReadCount
    // NO FILEREF implies start at ZERO
    // READ from the File at startReadPos for framesToReadCount
    // COMPUTE framesToReadCount
    AVAudioFrameCount remainingFrameCount = 0;
    AVAudioFramePosition startReadPosition = 0;

    if (readsEntireAudioForLoudest) {
        startReadPosition = 0;
        remainingFrameCount =  (AVAudioFrameCount)(fileLength - startReadPosition);
        
    } else {
        
        if (editing == NO && fileReference) {
            [fileReference calculateAtCurrentPosition:fileReference.trackStartPosition];
            
            if (fileReference.readPositionInReferencedTrack < 0.0) {
                NSLog(@"%s read position negative",__func__);
            } else {
                //Sample Rate: The number of times an analog signal is measured (sampled) per second
                startReadPosition = fileReference.readPositionInReferencedTrack *  processingFormat.sampleRate;
                
#ifdef TRACEANALYZE
                NSLog(@"%s ref dur %.2fs remaining %.2fs readpos %lld ",__func__,
                      fileReference.duration,
                      fileReference.remainingInTrack,
                      startReadPosition);
#endif
            }
            
            remainingFrameCount =  fileReference.remainingInTrack * processingFormat.sampleRate;
            
        } else {
        
            startReadPosition = 0;
            remainingFrameCount =  (AVAudioFrameCount)(fileLength - startReadPosition);
        }
    }

    
    framesToReadCount = remainingFrameCount;

//    NSLog(@"%s startReadPosition %lld framesToReadCount %u",__func__,startReadPosition,framesToReadCount);

    const AVAudioFrameCount kBufferMaxFrameCapacity = 18 * 1024L;
    AVAudioPCMBuffer *readBuffer = nil;
    // Iterate through entire file DETERMINE loudest sample
    float loudestSample = 0.000000f;
    AVAudioFramePosition loudestSamplePosition = 0;

    audioFile.framePosition = startReadPosition;

    AVAudioFrameCount frameCount = 0; // frames read

    //While the number of frames read is less than the number of frames that need
    //to be read
    while (frameCount < framesToReadCount) {
        
        AVAudioFrameCount framesRemaining = framesToReadCount - frameCount;
        //More frames to read
        if (framesRemaining > 0) {

        } else {
            NSLog(@"%s NO MORE framesRemaining: %u, %.3f secs. ",__func__,framesRemaining, framesRemaining / processingFormat.sampleRate);
            break;
        }
        AVAudioFrameCount framesToRead = (framesRemaining < kBufferMaxFrameCapacity) ? framesRemaining : kBufferMaxFrameCapacity;
        readBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:audioFile.processingFormat frameCapacity:framesToRead];

#ifdef TRACEANALYZE
        NSLog(@"%s framesRemaining: %u, %.3f secs. framesToRead %u, %.3f secs.",__func__,
              framesRemaining, framesRemaining / processingFormat.sampleRate,
              framesToRead, framesToRead / processingFormat.sampleRate);
#endif

        error = nil;

        if ([audioFile readIntoBuffer: readBuffer error: &error]) {
#ifdef TRACEANALYZE
            NSLog(@"%s frameLength: %u, %.3f secs.",__func__,
                  readBuffer.frameLength, readBuffer.frameLength / processingFormat.sampleRate);
#endif
            

            if (readBuffer.frameLength == 0)
                break; // finished

            frameCount += readBuffer.frameLength;
            
            for (AVAudioChannelCount channelIndex = 0; channelIndex < readBuffer.format.channelCount; ++channelIndex){
                float *channelData = readBuffer.floatChannelData[channelIndex];
                for (AVAudioFrameCount frameIndex = 0; frameIndex < readBuffer.frameLength; ++frameIndex){
                    float sampleAbsLevel = fabs(channelData[frameIndex]);
                    if (sampleAbsLevel > loudestSample){
                        loudestSample = sampleAbsLevel;
                        loudestSamplePosition = audioFile.framePosition + frameIndex;
                    }
                }
            }

        } else {
            NSLog(@"failed to read audio file: %@", error);
            //return NO;
            break;
        }
        
#ifdef TRACEANALYZE
        NSLog(@"%s frameCount: %u, %.3f secs.",__func__,frameCount, frameCount / processingFormat.sampleRate);
#endif

    }
    
#ifdef TRACEANALYZE
    NSLog(@"%s Produce Buffers ####",__func__);
#endif
    
    if (editing == NO && fileReference) {
        [fileReference calculateAtCurrentPosition:fileReference.trackStartPosition];
        
        if (fileReference.readPositionInReferencedTrack < 0.0) {
            NSLog(@"%s read position negative",__func__);
        } else {
            startReadPosition = fileReference.readPositionInReferencedTrack *  processingFormat.sampleRate;
            
#ifdef TRACEANALYZE
            NSLog(@"%s ref dur %.2fs remaining %.2fs readpos %lld ",__func__,
                  fileReference.duration,
                  fileReference.remainingInTrack,
                  startReadPosition);
#endif
        }
        
        remainingFrameCount =  fileReference.remainingInTrack * processingFormat.sampleRate;
        
    } else {
        startReadPosition = 0;
        remainingFrameCount =  (AVAudioFrameCount)(fileLength - startReadPosition);
    }


    
    // ===============================================
    
    // Iterate again to generate buffer views

    framesToReadCount = remainingFrameCount;
    frameCount = 0;
    audioFile.framePosition = startReadPosition;
    NSUInteger track = [self trackNumberForTrackId:tid];
    
    //    NSLog(@"%s startReadPosition %lld framesToReadCount %u",__func__,startReadPosition,framesToReadCount);

    _buffersSentCounts[track]++;  // always have one more until we are finished

    const AVAudioFrameCount kBufferMaxFrame = 16 * 1024L; // 18

    while (frameCount < framesToReadCount) {
        
        AVAudioFrameCount framesRemaining = framesToReadCount - frameCount;
        if (framesRemaining > 0) {
            // proceed with
            AVAudioFrameCount framesToRead = (framesRemaining < kBufferMaxFrame) ? framesRemaining : kBufferMaxFrame;
            readBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:audioFile.processingFormat frameCapacity:framesToRead];
#ifdef TRACEANALYZE
            NSLog(@"%s framesRemaining: %u, %.3f secs. framesToRead %u, %.3f secs. Max %u",__func__,
                  framesRemaining, framesRemaining / processingFormat.sampleRate,
                  framesToRead, framesToRead / processingFormat.sampleRate,kBufferMaxFrame);
#endif
            
            error = nil;
            if ([audioFile readIntoBuffer: readBuffer error: &error]) {
                
#ifdef TRACEANALYZE
                NSLog(@"%s frameLength: %u, %.3f secs.",__func__,
                      readBuffer.frameLength, readBuffer.frameLength / processingFormat.sampleRate);
#endif
                if (readBuffer.frameLength > 0) {
          	          
                    frameCount += readBuffer.frameLength;
                    
                    AVAudioFramePosition readPosition = audioFile.framePosition;
                    if (editing == NO) {
                        [self bufferReceivedForTrackId:tid buffer:readBuffer atReadPosition:readPosition loudestSample:loudestSample];
                        _buffersSentCounts[track]++;
                    } else {
                        [self bufferReceivedForEditingTrackId:tid buffer:readBuffer atReadPosition:readPosition loudestSample:loudestSample];
                        _buffersSentCounts[0]++;
                        _buffersSentCounts[track]++;

                    }
                }
            
            } else {
                NSLog(@"failed to read audio file: %@", error);
                break;
            }
            
#ifdef TRACEANALYZE
            NSLog(@"%s frameCount: %u, %.3f secs. framesToReadCount %u",__func__,frameCount, frameCount / processingFormat.sampleRate,framesToReadCount);
#endif
        } else {
            NSLog(@"%s NO MORE framesRemaining: %u, %.3f secs. ",__func__,framesRemaining, framesRemaining / processingFormat.sampleRate);
            break;
        }
    }
    
    _buffersSentCounts[track]--;  // done

}


//===========================================
//
//===========================================

// opens file and reads from _recordingLastReadPosition

-(void)audioFileAnalyzerForRecorderFile:(NSURL*)fileURL forTrackId:(NSString*)tid {

    // RESUMES from last read postion
    NSError *error;
    AVAudioFile *audioFile = [[AVAudioFile alloc] initForReading:fileURL error:&error];
    if (audioFile) {

        audioFile.framePosition = _recordingLastReadPosition;
        
        [self audioFileAnalyzerForRecorderAudioFile:audioFile forTrackId:tid];
        
        _recordingLastReadPosition = audioFile.framePosition;
        
    } else {
        NSLog(@"%sERROR File: %@  ",__func__, [fileURL lastPathComponent]);
    }
}


// prototype - reading a file opened Once
-(void)a_udioFileAnalyzerForRecorderFile:(NSURL*)fileURL forTrackId:(NSString*)tid {
    
    NSError *error;
    AVAudioFramePosition startReadPosition = 0;
    
    AVAudioFile *audioFile = [[AVAudioFile alloc] initForReading:fileURL error:&error];
    if (audioFile) {
        NSLog(@"%sFile: %@  ",__func__, [fileURL lastPathComponent]);
        audioFile.framePosition = startReadPosition;
        self.recordingAudioFile = audioFile;
        [self audioFileAnalyzerForRecorderAudioFile:_recordingAudioFile forTrackId:tid];
    } else {
        NSLog(@"%sERROR File: %@  ",__func__, [fileURL lastPathComponent]);
    }
}


-(void)audioFileAnalyzerForRecorderAudioFile:(AVAudioFile*)audioFile forTrackId:(NSString*)tid {
    
    AVAudioFramePosition fileLength = audioFile.length;
    AVAudioFrameCount remainingFrameCount =  (AVAudioFrameCount)(fileLength - audioFile.framePosition );
    AVAudioFrameCount framesToReadCount = remainingFrameCount;

    AVAudioFormat *processingFormat = [audioFile processingFormat];

    const AVAudioFrameCount kBufferMaxFrameCapacity = 9 * 1024L;

    AVAudioPCMBuffer *readBuffer = nil;
    AVAudioFrameCount frameCount = 0; // frames read
    NSUInteger iterations = 0;
    
    while (frameCount < framesToReadCount) {
        
        AVAudioFrameCount framesRemaining = framesToReadCount - frameCount;
        
        if (framesRemaining > 0) {
            
            if (framesRemaining < kBufferMaxFrameCapacity * 0.5 ) {
                // Done For Now
                break;
            } else {
                readBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:processingFormat frameCapacity:kBufferMaxFrameCapacity];
                
                NSError *error;
                if ([audioFile readIntoBuffer: readBuffer error: &error]) {
                    frameCount += readBuffer.frameLength;
                    
                    [self bufferReceivedForTrackId:tid buffer:readBuffer atReadPosition:audioFile.framePosition];
                }
            }
            
        } else {
            NSLog(@"%s NO MORE framesRemaining: %u, %.3f secs. ",__func__,framesRemaining, framesRemaining / processingFormat.sampleRate);
            break;
        }
        
        iterations++;
        
    }
    
//    NSLog(@"iter %ld",iterations);
    
}


#pragma mark - Effects modifying

-(float)floatValue1 {
//    NSLog(@"%s get backlight %.2f",__func__,self.backlightValue);
    return self.backlightValue;
}
-(float)floatValue2 {
    NSLog(@"%s not used, ignored",__func__);
    return 0.0;
}
-(float)floatValue3 {
    NSLog(@"%s not used, ignored",__func__);
    return 0.0;
}
-(float)floatValue4 {
    NSLog(@"%s not used, ignored",__func__);
    return 0.0;
}
-(BOOL)boolValue1 {
    NSLog(@"%s not used, ignored",__func__);
    return NO;
}
-(BOOL)adjustFloatValue1:(float)value{
    //    NSLog(@"%s adjusting backlightValue %.2f to %.2f",__func__,self.backlightValue,value);
    self.backlightValue = value;
    [_scrubber adjustWhiteBacklightValue:_backlightValue];
    return YES;
}
-(BOOL)adjustFloatValue2:(float)value{
    NSLog(@"%s not used, ignored",__func__);
    return NO;
}
-(BOOL)adjustFloatValue3:(float)value{
    NSLog(@"%s not used, ignored",__func__);
    return NO;
}
-(BOOL)adjustFloatValue4:(float)value{
    NSLog(@"%s not used, ignored",__func__);
    return NO;
}
-(BOOL)adjustBoolValue1:(BOOL)value {
    NSLog(@"%s not used, ignored",__func__);
    return NO;
}
-(NSTimeInterval)timeInterval1 {
    NSLog(@"%s not used, ignored",__func__);
    return 0.0;
}
-(BOOL)adjustTimeInterval1:(NSTimeInterval)value {
    NSLog(@"%s not used, ignored",__func__);
    return NO;
}
-(NSArray*)optionPresets {
    NSLog(@"%s not used, ignored",__func__);
    return nil;
}
-(BOOL)adjustOptionPreset:(NSUInteger)value {
    NSLog(@"%s not used, ignored",__func__);
    return NO;
}
-(void)adjustFloatValue1WithSlider:(id)sender {
    [self adjustFloatValue1:[(UISlider*)sender value]];
}
-(void)adjustFloatValue2WithSlider:(id)sender {
    [self adjustFloatValue2:[(UISlider*)sender value]];
}
-(void)adjustBoolValue1WithSwitch:(id)sender {
    [self adjustBoolValue1:[(UISwitch*)sender isOn]];
}
-(void)adjustFloatValue3WithSlider:(id)sender {
    [self adjustFloatValue3:[(UISlider*)sender value]];
}
-(void)adjustFloatValue4WithSlider:(id)sender {
    [self adjustFloatValue4:[(UISlider*)sender value]];
}
-(void)adjustTimeInterval1WithSlider:(id)sender {
    [self adjustTimeInterval1:(NSTimeInterval)[(UISlider*)sender value]];
}

@end

// ------------------------------------
// FOR REFERENCE - COlor dictionary
// ------------------------------------

//@{
// JWColorScrubberTopPeakNoAvg : [UIColor redColor],
// JWColorScrubberTopAvg : [UIColor redColor],
// JWColorScrubberTopPeak : [[UIColor redColor] colorWithAlphaComponent:0.5],
// JWColorScrubberBottomPeakNoAvg : [UIColor blueColor],
// JWColorScrubberBottomAvg : [UIColor blueColor],
// JWColorScrubberBottomPeak : [[UIColor blueColor] colorWithAlphaComponent:0.5],
// };


