//
//  JWScrubberController.m
//  JamWIthT
//
//  Created by JOSEPH KERR on 10/23/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import "JWScrubberController.h"
#import "JWScrubberViewController.h"
#import "JWBufferSampler.h"
#import "JWPlayerFileInfo.h"
#import "JWScrubberTackModify.h"

const int scMaxTracks = 10;

@interface JWScrubberController () <ScrubberDelegate, JWScrubberTackModifyDelegate > {
    dispatch_queue_t _bufferReceivedQueue;
    dispatch_queue_t _bufferSampledQueue;
    dispatch_queue_t _bufferReceivedPerformanceQueue;
    dispatch_queue_t _bufferSampledPerformanceQueue;
    NSUInteger _buffersReceivedCount;
    NSUInteger _trackCount;
    NSMutableDictionary * _tracks;
    NSUInteger _buffersReceivedCounts[scMaxTracks];
    float _loudestSamplesSofar[scMaxTracks]; // for listener implementation
    float _elapsedTimesSoFar[scMaxTracks];
    float _durationForTrack[scMaxTracks];
    BOOL _pulseOn;
}
@property (nonatomic) JWScrubberViewController *scrubber;
@property (nonatomic) JWPlayerFileInfo *restoreReferenceFileObject;
@property (nonatomic,strong)  NSTimer *playerTimer;
@property (nonatomic,strong)  NSString *playerTrackId;
@property (nonatomic,strong)  NSMutableDictionary *trackColorsByTrackId;
@property (nonatomic,strong)  NSDictionary *trackColorsAllTracks;
@property (nonatomic,strong)  NSDictionary *scrubberColors;
@property (nonatomic,strong)  NSMutableArray *pulseSamples;
@property (nonatomic,strong)  NSMutableArray *pulseSamplesDurations;
@property (nonatomic,readwrite) BOOL isPlaying;
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
        
    }
    return self;
}

-(void)initBufferQueues {
    if (_bufferReceivedQueue == nil) {
        //_bufferReceivedQueue =
        _bufferReceivedQueue =
        dispatch_queue_create("bufferReceived",
                              dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_CONCURRENT,QOS_CLASS_USER_INTERACTIVE, -1));
    }
    if (_bufferSampledQueue == nil) {
        _bufferSampledQueue =
        dispatch_queue_create("bufferProcessing",
                              dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_CONCURRENT,QOS_CLASS_USER_INTERACTIVE, -1));
    }
    
    if (_bufferReceivedPerformanceQueue == nil) {
        _bufferReceivedPerformanceQueue =
        dispatch_queue_create("bufferReceivedP",
                              dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL,QOS_CLASS_USER_INTERACTIVE, -1));
    }
    if (_bufferSampledPerformanceQueue == nil) {
        _bufferSampledPerformanceQueue =
        dispatch_queue_create("bufferProcessingP",
                              dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL,QOS_CLASS_USER_INTERACTIVE, -1));
    }
}


#pragma mark - Effects modifying

-(float)floatValue1 {
    NSLog(@"%s get backlight %.2f",__func__,self.backlightValue);
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

-(void)play:(NSString*)sid {
    
    if ([_playerTimer isValid])
        [_playerTimer invalidate];
    
    if (sid == nil) {
        [_scrubber prepareToPlay:1 atPosition:[_delegate currentPositionInSecondsOfAudioFile:self forScrubberId:nil]];
        // [_scrubber prepareToPlay:1];
    }
    
    [self startPlayTimer];
    [_scrubber transitionToPlay];
    
    if ( (_scrubber.viewOptions == ScrubberViewOptionDisplayLabels)
        || (_scrubber.viewOptions == ScrubberViewOptionDisplayOnlyValueLabels)) {
        dispatch_async(dispatch_get_main_queue(), ^{
            //                _scrubber.playHeadValueStr = [NSString stringWithFormat:@"%.2f s",0.0];
            //                if ([_delegate respondsToSelector:@selector( durationInSecondsOfAudioFile:forScrubberId:)]) {
            //                    _scrubber.remainingValueStr =
            //                    [NSString stringWithFormat:@"%.2f s",[_delegate durationInSecondsOfAudioFile:self forScrubberId:sid]];
            //                }
            if ([_delegate respondsToSelector:@selector( processingFormatStr:forScrubberId:)]) {
                _scrubber.formatValueStr = [_delegate processingFormatStr:self forScrubberId:sid];
            }
        });
    }
    

}

-(void)playRecord:(NSString*)sid {
    
    [self play:sid];
    [_scrubber transitionToRecording];
}

-(void)stopPlaying:(NSString*)sid
{
    [_playerTimer invalidate];
    [_scrubber transitionToStopPlaying];
}

-(void)stopPlaying:(NSString*)sid rewind:(BOOL)rewind;
{
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

    if ([_delegate respondsToSelector:@selector( progressOfAudioFile:forScrubberId:)])
        [self.scrubber trackScrubberToProgress:[_delegate progressOfAudioFile:self forScrubberId:_playerTrackId] timeAnimated:NO];
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

-(void)adjustBackLightValue:(float)value
{
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

-(void)seekToPosition:(NSString*)sid {
    NSLog(@"%s NOT IMPLEMENTED",__func__);
}

-(void)seekToPosition:(NSString*)sid animated:(BOOL)animated {
    NSLog(@"%s NOT IMPLEMENTED",__func__);
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

-(void)setTrackLocations:(NSArray *)trackLocations
{
    _scrubber.locations = trackLocations;
}

-(void)setSampleSize:(SampleSize)sampleSize forTrackWithId:(NSString*)stid{
    _tracks[stid][@"samplesize"]= @(sampleSize);
}
-(SampleSize)sampleSizeForTrackWithId:(NSString*)stid {
    return [(NSNumber*)_tracks[stid][@"samplesize"] unsignedIntegerValue];
}


-(void)setSamplingOptions:(SamplingOptions)options forTrack:(NSString*)stid{
    _tracks[stid][@"options"]= @(options);
}
-(SamplingOptions)configOptionsForTrack:(NSString*)stid {
    id options = _tracks[stid][@"options"];
    if (options)
        return [(NSNumber*)options unsignedIntegerValue];
    return 0; // not found
}

-(void)setKindOptions:(VABKindOptions)options forTrack:(NSString*)stid{
    _tracks[stid][@"kind"]= @(options);
}
-(VABKindOptions)kindOptionsForTrack:(NSString*)stid {
    id options = _tracks[stid][@"kind"];
    if (options)
        return [(NSNumber*)options unsignedIntegerValue];
    return 0; // not found
}

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
    
    UIColor *iosColor1 = [UIColor colorWithRed:128/255.0 green:128/255.0 blue:0/255.0 alpha:1.0]; // asparagus
    UIColor *iosColor2 = [UIColor colorWithRed:0/255.0 green:64/255.0 blue:128/255.0 alpha:1.0]; // ocean
    UIColor *iosColor3 = [UIColor colorWithRed:0/255.0 green:128/255.0 blue:255/255.0 alpha:1.0]; // aqua
    UIColor *iosColor4 = [UIColor colorWithRed:102/255.0 green:204/255.0 blue:255/255.0 alpha:1.0]; // sky

    if (iosColor1) {}
    if (iosColor2) {}
    if (iosColor3) {}
    if (iosColor4) {}

    NSDictionary *scrubberColors =
    @{
      JWColorBackgroundHueColor : iosColor2,
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

    id trackInfo = [_scrubber stopEditingTrackSave:track];
    
    [self editCompletedForTrack:track withTrackInfo:trackInfo];
}

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
    if (refFile) {
        NSURL *fileURL = _tracks[trackId][@"fileurl"];
        NSTimeInterval durationSeconds = 0.0;
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
        
        NSLog(@"%s [%.2fs , %.2fs] %.2fs",__func__,startInset,endInset,durationSeconds);
    } else {
        NSLog(@"%s st %.2f no referencefile",__func__,startTime);
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
    NSLog(@"%s %ld",__func__,track);
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

-(CGSize)viewSize
{
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


#pragma mark edit delegate

-(NSString*)trackIdForTrack:(NSUInteger)track {
    NSLog(@"%s %ld",__func__,track);
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
    NSLog(@"%s %ld",__func__,track);
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

#pragma mark - modify using track detect

-(void)modifyTrack:(NSString*)trackId allTracksHeight:(CGFloat)allTracksHeight {
    NSUInteger track = [(NSNumber*)_tracks[trackId][@"tracknum"] unsignedIntegerValue];
    [_scrubber modifyTrack:track allTracksHeight:allTracksHeight];
}
-(void)modifyTrack:(NSString*)trackId withAlpha:(CGFloat)alpha allTracksHeight:(CGFloat)allTracksHeight {
    NSUInteger track = 1;
    if (trackId)
        track = [(NSNumber*)_tracks[trackId][@"tracknum"] unsignedIntegerValue];
    [_scrubber modifyTrack:track withAlpha:alpha allTracksHeight:allTracksHeight];
}
-(void)modifyTrack:(NSString*)trackId withColors:(NSDictionary*)trackColors allTracksHeight:(CGFloat)allTracksHeight {
    NSUInteger track = 1;
    if (trackId)
        track = [(NSNumber*)_tracks[trackId][@"tracknum"] unsignedIntegerValue];
    NSLog(@"%s %ld",__func__,track);
    [_scrubber modifyTrack:track withColors:trackColors allTracksHeight:allTracksHeight];
}
-(void)modifyTrack:(NSString*)trackId withColors:(NSDictionary*)trackColors alpha:(CGFloat)alpha allTracksHeight:(CGFloat)allTracksHeight {
    NSUInteger track = 1;
    if (trackId)
        track = [(NSNumber*)_tracks[trackId][@"tracknum"] unsignedIntegerValue];
    [_scrubber modifyTrack:track withColors:trackColors alpha:alpha allTracksHeight:allTracksHeight];
    NSLog(@"%s %ld",__func__,track);
}
-(void)modifyTrack:(NSString*)trackId
            layout:(VABLayoutOptions)layoutOptions
              kind:(VABKindOptions)kindOptions
   allTracksHeight:(CGFloat)allTracksHeight
{
    NSUInteger track = [(NSNumber*)_tracks[trackId][@"tracknum"] unsignedIntegerValue];
    [_scrubber modifyTrack:track layout:layoutOptions kind:kindOptions allTracksHeight:allTracksHeight];
    [self setLayoutOptions:layoutOptions forTrack:trackId];
    [self setKindOptions:kindOptions forTrack:trackId];
}

-(void)modifyTrack:(NSString*)trackId
            colors:(NSDictionary*)trackColors
             alpha:(CGFloat)alpha
            layout:(VABLayoutOptions)layoutOptions
              kind:(VABKindOptions)kindOptions
   allTracksHeight:(CGFloat)allTracksHeight
{
    NSUInteger track = [(NSNumber*)_tracks[trackId][@"tracknum"] unsignedIntegerValue];
    [_scrubber modifyTrack:track colors:trackColors alpha:alpha layout:layoutOptions kind:kindOptions allTracksHeight:allTracksHeight];
    [self setLayoutOptions:layoutOptions forTrack:trackId];
    [self setKindOptions:kindOptions forTrack:trackId];
}


#pragma mark -

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


// prepareScrubberFileURL


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
    
    
    if (track==1) {
        
        // Do some first track stuff
        _scrubber.viewOptions = _viewOptions;
        [_scrubber prepareForTracks];
        
        if ((_viewOptions == ScrubberViewOptionDisplayLabels) || (_viewOptions == ScrubberViewOptionDisplayOnlyValueLabels)) {
            dispatch_async(dispatch_get_main_queue(), ^{
                _scrubber.playHeadValueStr = [NSString stringWithFormat:@"%.2f s",0.0];
                if ([_delegate respondsToSelector:@selector( durationInSecondsOfAudioFile:forScrubberId:)]) {
                    _scrubber.remainingValueStr =
                    [NSString stringWithFormat:@"%.2f s",[_delegate durationInSecondsOfAudioFile:self forScrubberId:sid]];
                    _scrubber.durationValueStr =
                    [NSString stringWithFormat:@"%.2f s",[_delegate durationInSecondsOfAudioFile:self forScrubberId:sid]];
                }
                
                if ([_delegate respondsToSelector:@selector( processingFormatStr:forScrubberId:)])
                    _scrubber.formatValueStr = [_delegate processingFormatStr:self forScrubberId:sid];
            });
        }
        
        //_scrubber.useTrackGradient = _useTrackGradient;
        // consider scrubber colors
        if (_scrubberColors == nil)
        {
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

    _buffersReceivedCounts[track] = 0;
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

-(void)startPlayTimer {
    NSString *sid = _playerTrackId;

    if ((_viewOptions == ScrubberViewOptionDisplayLabels) || (_viewOptions == ScrubberViewOptionDisplayOnlyValueLabels)) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([_delegate respondsToSelector:@selector( currentPositionInSecondsOfAudioFile:forScrubberId:)]) {
                _scrubber.playHeadValueStr =
                [NSString stringWithFormat:@"%.2f s",[_delegate currentPositionInSecondsOfAudioFile:self forScrubberId:sid]];
            }
            
            if ([_delegate respondsToSelector:@selector( remainingDurationInSecondsOfAudioFile:forScrubberId:)]) {
                _scrubber.remainingValueStr =
                [NSString stringWithFormat:@"%.2f s",[_delegate remainingDurationInSecondsOfAudioFile:self forScrubberId:sid]];
            }
            
        });
    }

    if ([_delegate respondsToSelector:@selector( progressOfAudioFile:forScrubberId:)])
        [self.scrubber trackScrubberToProgress:[_delegate progressOfAudioFile:self forScrubberId:sid] timeAnimated:NO];

    
    self.playerTimer = [NSTimer timerWithTimeInterval:0.10 target:self selector:@selector(playTimerFired:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_playerTimer forMode:NSRunLoopCommonModes];
}

-(void)playTimerFired:(NSTimer*)timer {
    
    NSString *sid = _playerTrackId;
    
    if (timer.valid) {
        if ((_viewOptions == ScrubberViewOptionDisplayLabels) || (_viewOptions == ScrubberViewOptionDisplayOnlyValueLabels)) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([_delegate respondsToSelector:@selector( currentPositionInSecondsOfAudioFile:forScrubberId:)]) {
                    _scrubber.playHeadValueStr =
                    [NSString stringWithFormat:@"%.2f s",[_delegate currentPositionInSecondsOfAudioFile:self forScrubberId:sid]];
                }
                
                if ([_delegate respondsToSelector:@selector( remainingDurationInSecondsOfAudioFile:forScrubberId:)]) {
                    _scrubber.remainingValueStr =
                    [NSString stringWithFormat:@"%.2f s",[_delegate remainingDurationInSecondsOfAudioFile:self forScrubberId:sid]];
                }
            });
        }
        
        // Obtain the progress of the audio file from the Engine
        // and set the scrubber to that progress

        float progress = 0.0;

        if ([_delegate respondsToSelector:@selector( progressOfAudioFile:forScrubberId:)]) {
            progress = [_delegate progressOfAudioFile:self forScrubberId:sid];
        }

        
        [self.scrubber trackScrubberToProgress:progress];
        
        if (_pulseOn) {

            [self pulseOnProgress:progress trackId:sid];
        }
        
    } // timer valid
}


#pragma mark - pulse types

//#define TRACEPULSE

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
    if (buffersDuration > 0) {
        indexOfBuffer = floor(currentPosSeconds/buffersDuration);
    }
    
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
            float startSampleValue;
            float endSampleValue;
            
            float progressValue = [pulsData[0] floatValue];  // as a fraction of duration
            
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
            
            [self.scrubber addAudioViewChannelSamples:bufferSampler.samples
                                       averageSamples:bufferSampler.averageSamples
                                      channel2Samples:bufferSampler.samplesChannel2
                                      averageSamples2:bufferSampler.averageSamplesChannel2
                                              inTrack:track
                                        startDuration:(NSTimeInterval)startDuration
                                             duration:(NSTimeInterval)bufferSampler.durationThisBuffer
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
            
            [self.scrubber addAudioViewChannelSamples:bufferSampler.samples
                                       averageSamples:bufferSampler.averageSamples
                                      channel2Samples:bufferSampler.samplesChannel2
                                      averageSamples2:bufferSampler.averageSamplesChannel2
                                              inTrack:track
                                        startDuration:(NSTimeInterval)startDuration
                                             duration:(NSTimeInterval)bufferSampler.durationThisBuffer
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

    Float64 mSampleRate = buffer.format.streamDescription->mSampleRate;
    Float64 duration =  (1.0 / mSampleRate) * buffer.format.streamDescription->mFramesPerPacket;
    float durThisBuffer = duration * buffer.frameLength;
    
    _durationForTrack[track] += durThisBuffer;

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
        if (_numberOfTracks == 1) {
            autoAdvance = YES;
        }
        
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
            
            [self.scrubber addAudioViewChannelSamples:bufferSampler.samples
                                       averageSamples:bufferSampler.averageSamples
                                      channel2Samples:bufferSampler.samplesChannel2
                                      averageSamples2:bufferSampler.averageSamplesChannel2
                                              inTrack:track
                                        startDuration:(NSTimeInterval)startDuration
                                             duration:(NSTimeInterval)bufferSampler.durationThisBuffer
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
                _scrubber.playHeadValueStr = [NSString stringWithFormat:@"%.2f s",_elapsedTimesSoFar[track]];
            });
        }
        
    }); // _bufferReceivedPerformanceQueue
    
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

//
//    NSUInteger track = [(NSNumber*)_tracks[tid][@"tracknum"] unsignedIntegerValue];
//    SamplingOptions options = [self configOptionsForTrack:tid];
//    VABLayoutOptions layoutOptions = [self layoutOptionsForTrack:tid];
//    VABKindOptions typeOptions = [self kindOptionsForTrack:tid];
//    id trackColors = _trackColorsByTrackId[tid];
//    if (trackColors == nil)
//        trackColors = _trackColorsAllTracks;
//    BOOL autoAdvance = NO;
//    if (_numberOfTracks == 1)
//        autoAdvance = YES;
//    
//    _buffersReceivedCounts[track]++;
//    _durationForTrack[track] += duration;
//    
//    float startDuration = _durationForTrack[track];
//    NSUInteger bufferNo = _buffersReceivedCounts[track];
////    NSLog(@"%s track %ld nsamples %ld ",__func__,track,(unsigned long)[samples count]);
//    dispatch_async(_bufferReceivedPerformanceQueue, ^{
//        dispatch_async(_bufferSampledPerformanceQueue, ^{
//            
//            _elapsedTimesSoFar[track] += (CGFloat)duration;
//
//            [self.scrubber addAudioViewChannelSamples:samples averageSamples:averageSamples
//                                      channel2Samples:samples2 averageSamples2:averageSamples2
//                                              inTrack:track
//                                        startDuration:(NSTimeInterval)startDuration
//                                             duration:duration
//                                              options:options
//                                                 type:typeOptions
//                                               layout:layoutOptions
//                                               colors:trackColors
//                                            bufferSeq:bufferNo
//                                          autoAdvance:autoAdvance
//                                            recording:YES
//                                              editing:NO
//                                                 size:_scrubberControllerSize ];
//            
//            if (autoAdvance) {
//                // is the primary track
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    _scrubber.playHeadValueStr = [NSString stringWithFormat:@"%.2f s",_elapsedTimesSoFar[track]];
//                });
//            }
//        
//        }); //_bufferReceivedPerformanceQueue
//    }); // _bufferSampledPerformanceQueue
//    
//}


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

    while (frameCount < framesToReadCount) {
        
        AVAudioFrameCount framesRemaining = framesToReadCount - frameCount;
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


    // Iterate again to generate buffer views

    framesToReadCount = remainingFrameCount;
    
//    NSLog(@"%s startReadPosition %lld framesToReadCount %u",__func__,startReadPosition,framesToReadCount);
    
    frameCount = 0;
    audioFile.framePosition = startReadPosition;
    
    while (frameCount < framesToReadCount) {
        
        AVAudioFrameCount framesRemaining = framesToReadCount - frameCount;
        if (framesRemaining > 0) {
            // proceed with
            AVAudioFrameCount framesToRead = (framesRemaining < kBufferMaxFrameCapacity) ? framesRemaining : kBufferMaxFrameCapacity;
            readBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:audioFile.processingFormat frameCapacity:framesToRead];
#ifdef TRACEANALYZE
            NSLog(@"%s framesRemaining: %u, %.3f secs. framesToRead %u, %.3f secs. Max %u",__func__,
                  framesRemaining, framesRemaining / processingFormat.sampleRate,
                  framesToRead, framesToRead / processingFormat.sampleRate,kBufferMaxFrameCapacity);
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
                    } else {
                        [self bufferReceivedForEditingTrackId:tid buffer:readBuffer atReadPosition:readPosition loudestSample:loudestSample];
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


// ------------------------------------
// FOR REFERENCE AND REMOVAL
// ------------------------------------




