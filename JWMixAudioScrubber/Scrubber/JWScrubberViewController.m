//
//  ScrubberViewController.m
//  AVAEMixerSample
//
//  co-created by joe and brendan kerr on 9/17/15.
//  Copyright (c) 2015 apple. All rights reserved.
//

#import "JWScrubberViewController.h"
#import "JWVisualAudioBufferView.h"
#import "JWScalingVisualAudioBufferView.h"
#import "JWScrubberGradientLayer.h"
#import "JWScrubberClipEndsLayer.h"
#import "JWPlayerFileInfo.h"
#import "UIColor+JW.h"
@import AVFoundation;
@import QuartzCore;

const int maxTracks = 10;
const NSString *JWColorScrubberTopPeak = @"TopPeak";
const NSString *JWColorScrubberBottomPeak = @"BottomPeak";
const NSString *JWColorScrubberTopAvg = @"TopAvg";
const NSString *JWColorScrubberBottomAvg = @"BottomAvg";
const NSString *JWColorScrubberTopPeakNoAvg = @"TopPeakNoAvg";
const NSString *JWColorScrubberBottomPeakNoAvg = @"BottomPeakNoAvg";
const NSString *JWColorBackgroundHueColor = @"HueColor";
const NSString *JWColorBackgroundHueGradientColor1 = @"HueGradientColor1";
const NSString *JWColorBackgroundHueGradientColor2 = @"HueGradientColor2";
const NSString *JWColorBackgroundTrackGradientColor1 = @"TrackGradientColor1";
const NSString *JWColorBackgroundTrackGradientColor2 = @"TrackGradientColor2";
const NSString *JWColorBackgroundTrackGradientColor3 = @"TrackGradientColor3";
const NSString *JWColorBackgroundHeaderGradientColor1 = @"HeaderGradientColor1";
const NSString *JWColorBackgroundHeaderGradientColor2 = @"HeaderGradientColor2";
typedef NS_ENUM(NSInteger, ScrubberEditType) {
    ScrubberEditNone = 0,
    ScrubberEditLeft,
    ScrubberEditRight,
    ScrubberEditStart
};


@interface JWScrubberViewController () <UIScrollViewDelegate> {
    CGFloat _uiPointsPerSecondLength;
    CGFloat _scaleduiPointsPerSecondLength;
    CGFloat _vTrackLength;  // track length in UI points
    CGFloat _tracksOffest;
    CGFloat _outputValue;
    CGFloat _currentPositions[maxTracks];
    CGFloat _vTrackLengths[maxTracks];
    CGFloat _startPositions[maxTracks];
    NSUInteger _audioViewBufferCounts[maxTracks];
    CGFloat _overrideScrubberLength;  // in points
    ScrubberEditType _editType;
    BOOL _trackingCurrentPosition;
    BOOL _listenToScrolling;
    BOOL _isRecording;
    BOOL _isScaled;
    BOOL _pulseBlocked;
    BOOL _hueAndGradientsConfigured;
    BOOL _hueNeedsUpdate;
    BOOL _waitForAnimated;
    BOOL _trackingEdit;
    BOOL _seeksToPositionOnEdit;
}
@property (strong, nonatomic) IBOutlet UIView *playHeadWindow;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *topLayoutScrollViewConstraint;
@property (strong, nonatomic) IBOutlet UIProgressView *recordingProgressView;
@property (strong, nonatomic) IBOutlet UIProgressView *scrubberProgressView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *recordingBottomConstraint;
@property (strong, nonatomic) IBOutlet UILabel *playheadLabel;
@property (strong, nonatomic) IBOutlet UILabel *playheadValueLabel;
@property (strong, nonatomic) IBOutlet UILabel *durationLabel;
@property (strong, nonatomic) IBOutlet UILabel *durationValueLabel;
@property (strong, nonatomic) IBOutlet UILabel *remainingLabel;
@property (strong, nonatomic) IBOutlet UILabel *remainingValueLabel;
@property (strong, nonatomic) IBOutlet UILabel *formatLabel;
@property (strong, nonatomic) IBOutlet UILabel *formatValueLabel;
@property (nonatomic) CGRect lastRect;
@property (nonatomic) UIView *clipBegin;
//@property (nonatomic) UIView *clipEnd;
@property (nonatomic) UIView *editLayerLeft;
@property (nonatomic) UIView *editLayerRight;
@property (nonatomic) UIView *editClipButton;
@property (nonatomic) CAGradientLayer *gradient;
@property (nonatomic) JWScrubberClipEndsLayer *gradientLeft;
@property (nonatomic) JWScrubberClipEndsLayer *gradientRight;
@property (nonatomic) JWScrubberGradientLayer *pulseBaseLayer;
@property (nonatomic) JWScrubberGradientLayer *hueLayer;
@property (nonatomic) JWScrubberGradientLayer *headerLayer;
@property (nonatomic) NSMutableArray *trackGradients;
@property (nonatomic) JWPlayerFileInfo *editFileReference;
@property (nonatomic) NSUInteger editTrack;  // currenttrack being edited
@property (nonatomic) NSUInteger recordingTrack;  // recording track being record
@end


@implementation JWScrubberViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    _playerProgressFormatString = @"%.0f";
    //_playerProgressFormatString = @"%00.2f";
    _seeksToPositionOnEdit = NO;
    _editTrack = 0;
    _recordingTrack = 0;
    _uiPointsPerSecondLength = 90.0; // 80 width per second
//    _uiPointsPerSecondLength = 102.0; // 80 width per second
//    _uiPointsPerSecondLength = 320.0; // 80 width per second
    _vTrackLength = 0.0;
    for (int i=0; i < maxTracks; i++) {
        _currentPositions[i] = 0.0f;
        _vTrackLengths[i] = 0.00f;
        _startPositions[i] = 0.000f;
    }

    CGFloat scrubberLengthSeconds = 7.0;
    scrubberLengthSeconds = 0;
    _overrideScrubberLength = scrubberLengthSeconds * _uiPointsPerSecondLength;
    _lastRect = CGRectZero;
    [self reset];
    
    _editType = ScrubberEditNone;
    _listenToScrolling = YES;
    _trackingCurrentPosition = YES;

    // VIEW COLROS AND VISIBILITY
    self.view.backgroundColor = [UIColor whiteColor];
    self.scrollView.backgroundColor = [UIColor clearColor];
    self.playHeadWindow.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.10];
    _playHeadWindow.layer.borderWidth = 0.90;
    _playHeadWindow.layer.borderColor = _playHeadWindow.backgroundColor.CGColor;
    self.playHeadWindow.hidden = YES;
    self.scrollView.delegate = self;
    self.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;
    self.scrollView.bounces = NO;
    self.recordingProgressView.hidden = YES;
    self.recordingProgressView.alpha = 0.5;
    self.recordingProgressView.layer.transform = CATransform3DMakeScale(1.0, 6.2, 1.0);
    self.scrubberProgressView.layer.transform = CATransform3DMakeScale(1.0, 8.4, 1.0);
    self.scrubberProgressView.progress = 0.0;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator> _Nonnull)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    CGPoint offset = _scrollView.contentOffset;
    CGFloat pos = offset.x + self.scrollView.contentInset.left;
    NSLog(@"%s pos %.2f",__func__,pos);
    
    CGSize vsize = size;
    
    [self configureBookendClips:vsize];

    [self configureEditLayer:vsize];
    
    _tracksOffest = vsize.width/2;  // playhead is in middle
    self.scrollView.contentInset = UIEdgeInsetsMake(0, _tracksOffest, 0, _tracksOffest);

    offset.x = pos - self.scrollView.contentInset.left;
    
    [_scrollView setContentOffset:offset animated:NO];
}

#pragma mark -

- (void)resetScrubberForRecording {  // public
    _isRecording = YES;
    [self transitionToRecording];
    [self.view setNeedsLayout];
    [self resetScrubber];
    _isRecording = YES;
}

- (void)resetScrubber {  // public

    _isRecording = NO;
    
    self.scrollView.layer.transform = CATransform3DIdentity;

    [self reset];
    
    self.playHeadValueStr = nil;
    self.durationValueStr = nil;
    self.remainingValueStr = nil;
    self.formatValueStr = nil;
    self.playheadValueLabel.text = _playHeadValueStr;
    self.durationValueLabel.text = _durationValueStr;
    self.remainingValueLabel.text = _remainingValueStr;
    self.formatValueLabel.text = _formatValueStr;
    [_playheadValueLabel setNeedsDisplay];
    [_durationValueLabel setNeedsDisplay];
    [_remainingValueLabel setNeedsDisplay];
    [_formatValueLabel setNeedsDisplay];

    _vTrackLength = 0.0;
    for (int i=0; i < maxTracks; i++) {
        _vTrackLengths[i] = 0.0f;
    }

//    [self.scrollView setNeedsLayout];
    [self.view setNeedsLayout];
}

- (void)resetScrubberForReload {  // public
    // SOFT RESET - could be used for changing jamtracks altogether
    // keeping anything intact
    
    _isRecording = NO;
    
    self.scrollView.layer.transform = CATransform3DIdentity;
    
    [self reset];
    
    self.playHeadValueStr = nil;
    self.durationValueStr = nil;
    self.remainingValueStr = nil;
    self.formatValueStr = nil;
    self.playheadValueLabel.text = _playHeadValueStr;
    self.durationValueLabel.text = _durationValueStr;
    self.remainingValueLabel.text = _remainingValueStr;
    self.formatValueLabel.text = _formatValueStr;
    [_playheadValueLabel setNeedsDisplay];
    [_durationValueLabel setNeedsDisplay];
    [_remainingValueLabel setNeedsDisplay];
    [_formatValueLabel setNeedsDisplay];
    
    _vTrackLength = 0.0;
    for (int i=0; i < maxTracks; i++) {
        _vTrackLengths[i] = 0.0f;
    }
    
    //    [self.scrollView setNeedsLayout];
    [self.view setNeedsLayout];
}

- (void)reset { // private
    
    _trackingEdit = NO;
    [self rewindToBeginningAnimated:NO];
    for (UIView *view in self.scrollView.subviews)
    {
        [view removeFromSuperview];
    }
    _clipBegin = nil;
    _clipEnd = nil;
    
    for (int i=0; i < maxTracks; i++)
    {
        _startPositions[i] = 0.000f;
    }

    for (int i=0; i < maxTracks; i++)
    {
        _currentPositions[i] = _startPositions[i];
        _audioViewBufferCounts[i]=0;

    }
    _outputValue = 1.0;
    _darkBackground = YES;
    self.scrollView.contentSize = CGSizeZero;
}

- (void)refresh {
    [self.view setNeedsLayout];
    [self.scrollView setNeedsLayout];
//    [self.scrollView setNeedsDisplay];
}

// TODO: make transitionToReadyForPlay
- (void)readyForPlay {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.playHeadWindow.layer.borderColor = [[UIColor greenColor] colorWithAlphaComponent:0.80].CGColor;
    });
}

-(void)readyForScrub {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.playHeadWindow.layer.borderColor = [[UIColor iosStrawberryColor] colorWithAlphaComponent:0.65].CGColor;
    });
}


#pragma mark - REWINDS

- (void)rewindToBeginning {
    [self rewindToBeginningAnimated:YES];
}

- (void)rewindToBeginningAnimated:(BOOL)animated {
    
    CGPoint offset = _scrollView.contentOffset;
    CGFloat pos = offset.x + self.scrollView.contentInset.left;
    CGPoint startOffest = CGPointMake( - self.scrollView.contentInset.left,0);
    [_scrollView setContentOffset:startOffest animated:animated];

    if (pos > 0.0) {
        if (animated) {
            _listenToScrolling = NO;
//            _trackingEdit = NO;
            _waitForAnimated = YES;
        }
    } else {
        _listenToScrolling = YES;
//        _trackingEdit = YES;
    }
}

- (void)rewindToEnd {
    [self rewindToEndAnimated:YES];
}

- (void)rewindToEndAnimated:(BOOL)animated {
    
    if (animated)
        _listenToScrolling = NO;

    CGPoint offest = CGPointMake( - self.scrollView.contentInset.left + [self largestTrackEndPosition],0);
    if (animated) {
//        _trackingEdit = NO;
        _waitForAnimated = YES;
    }
    [_scrollView setContentOffset:offest animated:animated];
}

- (void)rewindToBeginningOfTrack:(NSUInteger)track {
    [self rewindToBeginningOfTrack:track animated:YES];
}

- (void)rewindToBeginningOfTrack:(NSUInteger)track animated:(BOOL)animated {

//    _trackingEdit = NO;
    
    NSDictionary *trackInfo = [_delegate trackInfoForTrack:track];
    
    id startTimeValue = trackInfo[@"starttime"];
    CGFloat startTime = startTimeValue ? [startTimeValue floatValue] : 0.0;

    // secs = pos/_uiPointsPerSecondLength
    
    CGFloat pos = startTime * _uiPointsPerSecondLength;
    CGPoint startOffset = CGPointMake( - self.scrollView.contentInset.left + pos,0);
    NSLog(@"%s pos %.2f for startTime %.2f secs %@",__func__,pos,startTime,NSStringFromCGPoint(startOffset));

    if (pos > 0.0) {
        // 0 or greater
        if (animated) {
            //_trackingEdit = NO;
            _listenToScrolling = NO;
            _waitForAnimated = YES;
            [_scrollView setContentOffset:startOffset animated:animated];
        }
        else {
            [_scrollView setContentOffset:startOffset animated:NO];
            //_trackingEdit = YES;
            _listenToScrolling = YES;
        }
    } else {
        //_trackingEdit = YES;
        [_scrollView setContentOffset:startOffset animated:NO];
        _listenToScrolling = YES;
    }
    
}

- (void)rewindToEndOfTrack:(NSUInteger)track {
    [self rewindToEndOfTrack:track animated:YES];
}

// secs = pos/_uiPointsPerSecondLength

- (void)rewindToEndOfTrack:(NSUInteger)track animated:(BOOL)animated {
    
//    _trackingEdit = NO;
//    if (animated == NO)
//        _listenToScrolling = YES;
    
    CGFloat pos = 0;
    
    // COMPUTE the position
    // using starttime and duration either from file reference or track Info
    NSTimeInterval duration = 0.0;
    JWPlayerFileInfo *fileRef = [_delegate fileReferenceObjectForTrack:track];
    
    if (fileRef) {
        duration = fileRef.duration;
        pos = (fileRef.trackStartPosition + fileRef.duration) * _uiPointsPerSecondLength;
        
    } else {
        NSDictionary *trackInfo = [_delegate trackInfoForTrack:track];
        id startTimeValue = trackInfo[@"starttime"];
        CGFloat startTime = startTimeValue ? [startTimeValue floatValue] : 0.0;
        
        duration = [_delegate lengthInSecondsForTrack:track];
        
        pos = (startTime + duration) * _uiPointsPerSecondLength;
    }
    
    CGPoint startOffset = CGPointMake( - self.scrollView.contentInset.left + pos,0);
    CGFloat distFromCurrent = 0;
    CGPoint offset = _scrollView.contentOffset;
    CGFloat cpos = offset.x + self.scrollView.contentInset.left;
    //    float currentPositionSeconds = pos / _uiPointsPerSecondLength;

    if (cpos < pos)
        distFromCurrent = pos - cpos;
    else if (cpos > pos)
        distFromCurrent = cpos - pos;

    
    NSLog(@"%s pos %.2f dist %.3f dur %.2fs %@",__func__,pos,distFromCurrent,duration,NSStringFromCGPoint(startOffset));
    
    if (distFromCurrent > 0.0001) {
        NSLog(@"%s move pos %.2f dist %.3f %@",__func__,pos,distFromCurrent,NSStringFromCGPoint(startOffset));

        if (animated) {
            _listenToScrolling = NO;
            _trackingEdit = NO;
            _waitForAnimated = YES;
            [_scrollView setContentOffset:startOffset animated:animated];
        }
        else {
            [_scrollView setContentOffset:startOffset animated:NO];
            _trackingEdit = YES;
            _listenToScrolling = YES;
        }
    } else {
        NSLog(@"%s move unanimated pos %.2f dist %.3f %@",__func__,pos,distFromCurrent,NSStringFromCGPoint(startOffset));

        //_trackingEdit = YES;
        _listenToScrolling = YES;
        [_scrollView setContentOffset:startOffset animated:NO];
    }
    
}


#pragma mark - helper

-(CGFloat)largestTrackLen {
    
//    CGFloat resultLargestLen = 0.00f;
    CGFloat resultLargestLen = _overrideScrubberLength;
    for (int i=0; i < maxTracks; i++) {
        if (_vTrackLengths[i] > resultLargestLen)
            resultLargestLen = _vTrackLengths[i];
    }
    return resultLargestLen;
}

-(CGFloat)largestTrackEndPosition {
    
//    CGFloat resultLargestLen = 0.00f;
    CGFloat resultLargestLen = _overrideScrubberLength;
    for (int i=0; i < maxTracks; i++) {
        CGFloat len = _vTrackLengths[i] + _startPositions[i];
        if (len > resultLargestLen)
            resultLargestLen = len;
    }
    
//    NSLog(@"%s %.3f",__func__,resultLargestLen);
    return resultLargestLen;
    
}


#pragma mark - Setters

-(void)setPlayHeadValueStr:(NSString *)playHeadValueStr
{
    if (_playHeadValueStr != playHeadValueStr) {
        _playHeadValueStr = playHeadValueStr;
        _playheadValueLabel.text = _playHeadValueStr;
        [_playheadValueLabel setNeedsDisplay];
    }
}
-(void)setFormatValueStr:(NSString *)formatValueStr
{
    if (_formatValueStr != formatValueStr) {
        _formatValueStr = formatValueStr;
        _formatValueLabel.text = _formatValueStr;
        [_formatValueLabel setNeedsDisplay];
    }
}
-(void)setRemainingValueStr:(NSString *)remainingValueStr
{
    if (_remainingValueStr != remainingValueStr) {
        _remainingValueStr = remainingValueStr;
        _remainingValueLabel.text = _remainingValueStr;
        [_playheadValueLabel setNeedsDisplay];
    }
}
-(void)setDurationValueStr:(NSString *)durationValueStr
{
    if (_durationValueStr != durationValueStr) {
        _durationValueStr = durationValueStr;
        _durationValueLabel.text = _durationValueStr;
        [_durationValueLabel setNeedsDisplay];
    }
}

-(void)setHueColor:(UIColor *)hueColor {
    _hueColor = hueColor;
    _hueNeedsUpdate = YES;
    [self.view setNeedsLayout];
}

-(void)setTrackStartPosition:(CGFloat)startPositionSeconds forTrack:(NSUInteger)track {
    _startPositions[track] = startPositionSeconds * _uiPointsPerSecondLength;
    _currentPositions[track] = _startPositions[track];
    _vTrackLengths[track]=0.0;
}

//    NSLog(@"%s %ld",__func__,viewOptions);

-(void)setViewOptions:(ScrubberViewOptions)viewOptions {
    
    _viewOptions = viewOptions;
    
    if (_viewOptions == 0)
        _viewOptions = ScrubberViewOptionNone;
    
//    NSLog(@"%s %.2f",__func__,self.topLayoutScrollViewConstraint.constant);
    
    if (_viewOptions == ScrubberViewOptionNone || _viewOptions == ScrubberViewOptionDisplayFullView || _viewOptions == ScrubberViewOptionsDisplayInCameraView) {
        // neither is SET full view
        _durationLabel.hidden = YES;
        _remainingLabel.hidden = YES;
        _playheadLabel.hidden = YES;
        _formatLabel.hidden = YES;
        _durationValueLabel.hidden = YES;
        _remainingValueLabel.hidden = YES;
        _playheadValueLabel.hidden = YES;
        _formatValueLabel.hidden = YES;
        self.topLayoutScrollViewConstraint.constant = 0;
        [self.view setNeedsLayout];
    }
    else if (_viewOptions == ScrubberViewOptionDisplayLabels) {
        _durationLabel.hidden = NO;
        _remainingLabel.hidden = NO;
        _playheadLabel.hidden = NO;
        _formatLabel.hidden = NO;
        _durationValueLabel.hidden = NO;
        _remainingValueLabel.hidden = NO;
        _playheadValueLabel.hidden = NO;
        _formatValueLabel.hidden = NO;
        self.topLayoutScrollViewConstraint.constant = 46; // just below text labels
        [self.view setNeedsLayout];
    }
    
    else if (_viewOptions == ScrubberViewOptionDisplayOnlyValueLabels) {
        _durationLabel.hidden = YES;
        _remainingLabel.hidden = YES;
        _playheadLabel.hidden = YES;
        _formatLabel.hidden = YES;
        _durationValueLabel.hidden = NO;
        _remainingValueLabel.hidden = NO;
        _playheadValueLabel.hidden = NO;
        _formatValueLabel.hidden = NO;
        self.topLayoutScrollViewConstraint.constant = 38; // just below numbers
        [self.view setNeedsLayout];
    }
    
//    NSLog(@"%s %.2f",__func__,self.topLayoutScrollViewConstraint.constant);
    
}


-(void)setPulseBackLight:(BOOL)pulseBackLight {
    _pulseBackLight = pulseBackLight;
}


-(void)setScrubberLength:(CGFloat)scrubberLength {
    _overrideScrubberLength = scrubberLength * _uiPointsPerSecondLength;

    CGFloat h = self.scrollView.contentSize.height;
    [self adjustContentSize:CGSizeMake(_overrideScrubberLength, h)];
    
}

-(void)setBackgroundToClear {
    self.view.backgroundColor = [UIColor clearColor];
}


#pragma mark -


-(void)prepareForTracksWithSize:(CGSize)size {
    
    _tracksOffest = size.width/2;  // playhead is in middle
    self.scrollView.contentInset = UIEdgeInsetsMake(0, _tracksOffest, 0, _tracksOffest);
    self.scrollView.contentSize = CGSizeZero;
    [self configureBookendClips:size];
    self.playHeadWindow.hidden = NO;
}

-(void)prepareForTracks {
    CGSize size = [_delegate viewSize];
    [self prepareForTracksWithSize:size];
}

-(void)prepareForTracksInCamera {
    CGSize size = [_delegate viewSize];
    [self prepareForTracksWithSize:size];
}

// allows length to be set

-(void)prepareToPlay:(NSUInteger)track atPosition:(CGFloat)position{

    [self prepareToPlay:1];
    NSLog(@"%s pos %.2f",__func__,position);
    _listenToScrolling = NO;
    CGFloat pos = position * _uiPointsPerSecondLength;
    
 //    - self.scrollView.contentInset.left
    CGPoint startOffest = CGPointMake(  pos - self.scrollView.contentInset.left,_scrollView.contentOffset.y);
    [_scrollView setContentOffset:startOffest animated:NO];
}

-(void)prepareToPlay:(NSUInteger)track {
//    _vTrackLength = _vTrackLengths[track];
    _vTrackLength = _vTrackLengths[track] + _startPositions[track];
    if (self.playHeadWindow.hidden == YES) {  // first time at viewDidload
        self.playHeadWindow.alpha = 0.0;
        self.playHeadWindow.hidden = NO;
        [UIView animateWithDuration:.10 delay:0.0 options:UIViewAnimationOptionCurveLinear
                         animations:^{
                             self.playHeadWindow.alpha = 1.0;
                         } completion:nil];
    }
}

-(void)prepareToRecord:(NSUInteger)track atPosition:(CGFloat)position{
    
    [self prepareToPlay:track];
    //    NSLog(@"%s pos %.2f",__func__,position);
    _listenToScrolling = NO;
    CGFloat pos = position * _uiPointsPerSecondLength;
    CGPoint startOffest = CGPointMake( - self.scrollView.contentInset.left + pos,0);
    [_scrollView setContentOffset:startOffest animated:NO];
}


#pragma mark -

-(void)userTrackingProgressBeginning {
    CGFloat pos = 0.00; //offset.x + self.scrollView.contentInset.left;
    self.playHeadValueStr = @"";
    CGFloat endPosition = [self largestTrackEndPosition];
    self.remainingValueStr = [NSString stringWithFormat:@"%.0f",endPosition/_uiPointsPerSecondLength - pos/_uiPointsPerSecondLength];
    if ([_delegate respondsToSelector:@selector(positionInTrackChangedPosition:)]) {
        [_delegate positionInTrackChangedPosition:pos/_uiPointsPerSecondLength];
    }
}

-(void)userTrackingProgressEnd {
    CGFloat endPosition = [self largestTrackEndPosition];
    CGFloat pos = endPosition;
    self.playHeadValueStr = [NSString stringWithFormat:_playerProgressFormatString,pos/_uiPointsPerSecondLength];
    self.remainingValueStr = [NSString stringWithFormat:@"%.0f",endPosition/_uiPointsPerSecondLength - pos/_uiPointsPerSecondLength];
    if ([_delegate respondsToSelector:@selector(positionInTrackChangedPosition:)]) {
        [_delegate positionInTrackChangedPosition:pos/_uiPointsPerSecondLength];
    }
}

-(void)userTrackingComputeProgressAtCurrentPosition {
    CGPoint offset = _scrollView.contentOffset;
    CGFloat pos = offset.x + self.scrollView.contentInset.left;
    if (pos  < 0) {
        //        NSLog(@"%s Less than ZERO %.2f",__func__,pos);
    } else {
        //        NSLog(@"%s SOMEWHERE GREATER ZERO",__func__);
        //        NSUInteger progressTrack = 1;
        CGFloat endPosition = [self largestTrackEndPosition];
        if (pos < endPosition) {
            self.playHeadValueStr = [NSString stringWithFormat:_playerProgressFormatString,pos/_uiPointsPerSecondLength];
            self.remainingValueStr = [NSString stringWithFormat:@"%.0f",endPosition/_uiPointsPerSecondLength - pos/_uiPointsPerSecondLength];
            if ([_delegate respondsToSelector:@selector(positionInTrackChangedPosition:)]) {
                [_delegate positionInTrackChangedPosition:pos/_uiPointsPerSecondLength];
            }
        }
    }
}


//    NSLog(@"%s pos %.2f ,__func__,)pos;
//        NSLog(@"%s SOMEWHERE GREATER ZERO",__func__);
//        NSUInteger progressTrack = 1;

// pos is greater or equal zero
-(void)userTrackingComputeProgressAtPosition:(CGFloat)pos {
    CGFloat endPosition = [self largestTrackEndPosition];
    if (pos < endPosition) {
        CGFloat cp = pos/_uiPointsPerSecondLength;
        if (cp < 0)
            cp = 0.0;

        self.playHeadValueStr = [NSString stringWithFormat:@"%.2f",cp];
        self.remainingValueStr = [NSString stringWithFormat:@"%.0f",endPosition/_uiPointsPerSecondLength - pos/_uiPointsPerSecondLength];
        if ([_delegate respondsToSelector:@selector(positionInTrackChangedPosition:)]) {
            [_delegate positionInTrackChangedPosition:cp];
        }

        CGFloat progress = pos/endPosition;
        dispatch_async(dispatch_get_main_queue(), ^{
            self.scrubberProgressView.progress = progress;
        });


    }
}


//        if  (cp < 1.00)
//            self.playHeadValueStr = @"";
//        else
//        self.playHeadValueStr = [NSString stringWithFormat:_playerProgressFormatString,cp];

/*
[_delegate positionInTrackChangedPosition:pos/_uiPointsPerSecondLength];
 
 crashes here
 scrollViewTrackingatpos
 DidEndScrolling anim
 
 While backing out of detail record jam
 
 2016-01-22 16:02:24.011 JamWDev[25073:2588079] -[JWAudioEngine startEngine] starts here
 2016-01-22 16:02:24.011 JamWDev[25073:2588079] -[JWScrubberController reset]
 2016-01-22 16:02:24.011 JamWDev[25073:2588079] usePlayerScrubber for recorderplayer YES at index 0
 2016-01-22 16:02:24.015 JamWDev[25073:2588079] usePlayerScrubber for recorderplayer YES at index 1
 2016-01-22 16:02:24.017 JamWDev[25073:2588079] No Active player nodes to stop.
 2016-01-22 16:02:24.017 JamWDev[25073:2588079] scheduleAllWithOptions 0.000 secondsin, 2 nodes
 2016-01-22 16:02:24.018 JamWDev[25073:2588079] AE FileLength: 168366  3.818 seconds. Buffer length 168366
 2016-01-22 16:02:24.018 JamWDev[25073:2588079] AE FileLength: 44100  1.000 seconds. Buffer length 44100
 2016-01-22 16:02:24.022 JamWDev[25073:2588079] -[JWAudioRecorderController boolValue1] get isPlaying 0
 Jan 22 16:02:24  JamWDev[25073] <Error>: CGContextSetLineWidth: invalid line width: negative values are not allowed.
 Jan 22 16:02:24  JamWDev[25073] <Error>: CGContextSetLineWidth: invalid line width: negative values are not allowed.
 2016-01-22 16:02:24.240 JamWDev[25073:2588079] audioPlayerNode PLAY
 2016-01-22 16:02:24.252 JamWDev[25073:2588079] audioPlayerNode PLAY
 2016-01-22 16:02:25.274 JamWDev[25073:2589082] Audio Completed for playerAtIndex 1
 2016-01-22 16:02:25.504 JamWDev[25073:2588079] audioPlayerNode STOP
 2016-01-22 16:02:25.504 JamWDev[25073:2589082] Audio Completed for playerAtIndex 0
 2016-01-22 16:02:25.505 JamWDev[25073:2588079] audioPlayerNode STOP
 2016-01-22 16:02:25.505 JamWDev[25073:2588079] -[JWAudioPlayerController stop] STOP player controller
 2016-01-22 16:02:25.508 JamWDev[25073:2588079] audioPlayerNode STOP
 2016-01-22 16:02:25.508 JamWDev[25073:2588079] audioPlayerNode STOP
 2016-01-22 16:02:25.508 JamWDev[25073:2588079] scheduleAllWithOptions 0.000 secondsin, 2 nodes
 2016-01-22 16:02:25.509 JamWDev[25073:2588079] AE FileLength: 168366  3.818 seconds. Buffer length 168366
 2016-01-22 16:02:25.509 JamWDev[25073:2588079] AE FileLength: 44100  1.000 seconds. Buffer length 44100

*/


#pragma mark -

-(void)scrollViewTrackingAtCurrentPosition {
    [self scrollViewTrackingAtPosition: _scrollView.contentOffset.x + _scrollView.contentInset.left];
}

-(void)scrollViewTrackingAtPosition:(CGFloat)position {

//    self.playHeadWindow.layer.borderColor = [UIColor colorWithWhite:0.7 alpha:0.5].CGColor;
    if (_trackingCurrentPosition) {
//        self.playHeadWindow.layer.borderColor = [[UIColor iosStrawberryColor] colorWithAlphaComponent:0.65].CGColor;
        [self userTrackingComputeProgressAtPosition:position];
        
    }

    if (_trackingEdit) {
        self.playHeadWindow.layer.borderColor = [[UIColor yellowColor] colorWithAlphaComponent:0.65].CGColor;

//        self.playHeadWindow.layer.borderColor = [UIColor colorWithWhite:0.9 alpha:1.0].CGColor;
        if (_editType == ScrubberEditLeft ) {
            [self userTrackingComputeEditingLeftProgressAtPosition:position];
            
        } else if (_editType == ScrubberEditRight ) {
            [self userTrackingComputeEditingRightProgressAtPosition:position];
            
        }
        
        // Start doesnt move _editType == ScrubberEditStart
    }
}

//    else {
//        NSLog(@"%s not tracking edit",__func__);
//
////        if (_trackingCurrentPosition) {
////            [self userTrackingComputeProgress];
////            NSLog(@"%s not tracking edit",__func__);
////        } else {
////            NSLog(@"%s not tracking edit and current position",__func__);
////        }
//
//    }

#pragma mark - scrollViewDelegate

// #define TRACESCROLL

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {

//    NSLog(@"%s",__func__);
    if (_listenToScrolling) {
        CGFloat pos = scrollView.contentOffset.x + self.scrollView.contentInset.left;
        if (pos  < 0) {
            //NSLog(@"%s not tracking position %.3f",__func__,pos);
        } else {
            
            self.playHeadWindow.layer.borderColor = self.playHeadWindow.backgroundColor.CGColor;
            [self scrollViewTrackingAtPosition:pos];

//            double delayInSecs = 0.10;
//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSecs * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                self.playHeadWindow.layer.borderColor = self.playHeadWindow.backgroundColor.CGColor;
//                 NSLog(@"%s",__func__);
//            });

            

        }
    } else {
//        NSLog(@"%s not listening to scrolling",__func__);
//        self.playHeadWindow.layer.borderColor = self.playHeadWindow.backgroundColor.CGColor;
    }
}

// velocity It is points/millisecond.

-(void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {

#ifdef TRACESCROLL
    NSLog(@"%s velocity %@ traget %@",__func__,NSStringFromCGPoint(velocity),NSStringFromCGPoint(*targetContentOffset));
#endif
    CGPoint targetPoint = *targetContentOffset;
    CGFloat scrubberBegin = - self.scrollView.contentInset.left;
    if (targetPoint.x == scrubberBegin) {
    }
    CGFloat scrubberEnd = - self.scrollView.contentInset.left + [self largestTrackEndPosition];
    if (targetPoint.x == scrubberEnd) {
    }
#ifdef TRACESCROLL
    NSLog(@"%s scrubberBegin %.2f end %.2f",__func__,scrubberBegin,scrubberEnd);
#endif
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
#ifdef TRACESCROLL
    NSLog(@"%s willDecelerate %@",__func__,@(decelerate));
#endif
    if (decelerate == NO) {
        
        if (_listenToScrolling) {
            CGFloat pos = scrollView.contentOffset.x + self.scrollView.contentInset.left;
            if (pos  < 0) {
#ifdef TRACESCROLL
                NSLog(@"%s not tracking position %.3f",__func__,pos);
#endif
            } else {
                
//                [self scrollViewTrackingAtPosition:pos];
//                NSLog(@"%s ",__func__);

//                self.playHeadWindow.layer.borderColor = [[UIColor iosStrawberryColor] colorWithAlphaComponent:0.65].CGColor;
//                self.playHeadWindow.layer.borderColor = [[UIColor iosSkyColor] colorWithAlphaComponent:0.75].CGColor;
//                double delayInSecs = 1.25;
//                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSecs * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                    self.playHeadWindow.layer.borderColor = self.playHeadWindow.backgroundColor.CGColor;
//                    NSLog(@"%s",__func__);
//
//                });

                
            }
        }
    } else {
        // signal to catch DidEndDecelerating
        
    }
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView   {
    
#ifdef TRACESCROLL
    NSLog(@"%s",__func__);
#endif
    if (_listenToScrolling) {
        CGFloat pos = scrollView.contentOffset.x + self.scrollView.contentInset.left;
        if (pos  < 0) {
#ifdef TRACESCROLL
            NSLog(@"%s not tracking position %.3f",__func__,pos);
#endif

        } else {
            
//            self.playHeadWindow.layer.borderColor = self.playHeadWindow.backgroundColor.CGColor;
            [self scrollViewTrackingAtPosition:pos];
//            self.playHeadWindow.layer.borderColor = [[UIColor iosStrawberryColor] colorWithAlphaComponent:0.65].CGColor;

//            self.playHeadWindow.layer.borderColor = [[UIColor iosSkyColor] colorWithAlphaComponent:0.75].CGColor;
//            double delayInSecs = 1.25;
//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSecs * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                self.playHeadWindow.layer.borderColor = self.playHeadWindow.backgroundColor.CGColor;
//                NSLog(@"%s",__func__);
//
//            });


        }
    } else {
#ifdef TRACESCROLL
        NSLog(@"%s not listening to scrolling",__func__);
#endif

    }
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
#ifdef TRACESCROLL
    NSLog(@"%s",__func__);
#endif
}

-(void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
#ifdef TRACESCROLL
    NSLog(@"%s",__func__);
#endif


    if (_waitForAnimated) {
        _listenToScrolling = YES;
    }

    if (_listenToScrolling) {
        CGFloat pos = scrollView.contentOffset.x + self.scrollView.contentInset.left;
        if (pos  < 0) {
            NSLog(@"%s not tracking position %.3f",__func__,pos);
        } else {
            
            [self scrollViewTrackingAtPosition:pos];
            
            if (pos < 0.000001) {
                self.playHeadWindow.layer.borderColor = self.playHeadWindow.backgroundColor.CGColor;
//                self.playHeadWindow.layer.borderColor = [[UIColor orangeColor] colorWithAlphaComponent:0.99].CGColor;
            } else {
                self.playHeadWindow.layer.borderColor = [[UIColor iosAquaColor] colorWithAlphaComponent:0.99].CGColor;
            }
//            self.playHeadWindow.layer.borderColor = [[UIColor iosStrawberryColor] colorWithAlphaComponent:0.65].CGColor;
//            double delayInSecs = 1.25;
//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSecs * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                self.playHeadWindow.layer.borderColor = self.playHeadWindow.backgroundColor.CGColor;
//                NSLog(@"%s",__func__);
//
//            });


        }
    } else {
        NSLog(@"%s not listening to scrolling",__func__);
    }

    if (_waitForAnimated) {
        _waitForAnimated = NO;
        //_trackingEdit = YES;
    }

    
}

//CGFloat xOffset = bounds.origin.x + _tracksOffest;
////NSLog(@"%s x %.2f xOff %.2f",__func__,bounds.origin.x,_tracksOffest);
//        CGFloat currentProgressPosition   = bounds.origin.x; //  - CGRectGetWidth(self.scrollView.frame)/2 ;
// x = 0 is frame 0 x=1 advances 1 point UI is like 3400 frames
// the UI needs zooming more points, to get to more precise frames
//        CGFloat progressRatio = currentProgressPosition / _vTrackLength;
//        NSLog(@"%s %.4f",__func__,progressRatio);
//        self.playHeadValueStr = [NSString stringWithFormat:@"%.2f s",currentProgressPosition/pointsPerSecond];


#pragma mark -

// called into , to move the player PLAYING

- (void)trackScrubberToProgress:(CGFloat)progress {
    [self trackScrubberToProgress:progress timeAnimated:YES];
    [self.scrubberProgressView setProgress:progress animated:YES];
}

- (void)trackScrubberToProgress:(CGFloat)progress timeAnimated:(BOOL)animated {
    CGFloat offset = self.scrollView.contentInset.left;
    
    CGFloat destinationX = progress * _vTrackLength - offset;
   // destinationX = destinationX; // + pointsPerSecond * 0.085; // seconds adjustment
    
    CGRect bounds = self.scrollView.bounds;
    CGFloat currentx = bounds.origin.x;
    bounds.origin.x = destinationX;
    if (destinationX > _vTrackLength)
        destinationX = _vTrackLength;
    
    CGFloat duration = 0.0;
    CGFloat distanceToTravelX;
    
    if (destinationX > currentx) {
        
        if (animated) {
            distanceToTravelX = destinationX - currentx;
            duration = distanceToTravelX / _uiPointsPerSecondLength;
            
            [UIView animateWithDuration:duration delay:0.0 options:UIViewAnimationOptionCurveLinear
                             animations:^{
                                 self.scrollView.bounds = bounds;
                             } completion:nil];

        } else {
            self.scrollView.bounds = bounds;
            CGFloat pos = (progress * _vTrackLength) / _uiPointsPerSecondLength;
            NSLog(@"%s x- pos %.2f",__func__,pos);

        }
    } else {
        self.scrollView.bounds = bounds;
        CGFloat pos = (progress * _vTrackLength) / _uiPointsPerSecondLength;
        NSLog(@"%s xx pos %.2f _vTrackLength %.3f",__func__,pos,_vTrackLength);
//        [self.scrollView setContentOffset:CGPointMake(destinationX, _scrollView.contentOffset.y)];
    }
}

- (void)setProgress:(CGFloat)progress {
    
    CGFloat destinationX = progress * _vTrackLength - self.scrollView.contentInset.left;
    CGFloat pointsPerSecond = _isScaled ? _scaleduiPointsPerSecondLength : _uiPointsPerSecondLength;

    destinationX = destinationX + pointsPerSecond;
    CGRect bounds = self.scrollView.bounds;
    bounds.origin.x = destinationX;
    if (destinationX > _vTrackLength)
        destinationX = _vTrackLength;
    
    self.scrollView.bounds = bounds;
}


- (void)trackScrubberToPostion:(CGFloat)position timeAnimated:(BOOL)animated {
    [self trackScrubberToPostion:animated timeAnimated:NO animated:NO];
}

- (void)trackScrubberToPostion:(CGFloat)position timeAnimated:(BOOL)animated animated:(BOOL)contentAnimated {
    
    CGFloat offset = self.scrollView.contentInset.left;
    CGFloat contentWidth = _scrollView.contentSize.width;
    CGFloat endx = contentWidth - offset;

    CGFloat destinationX = (position * _uiPointsPerSecondLength) - offset;

    CGFloat overage = 0;
    if (destinationX  > endx ) {
        overage = destinationX - endx;
        destinationX = endx;
    }

    CGRect bounds = self.scrollView.bounds;
    CGFloat currentx = bounds.origin.x;
    CGFloat duration = 0.0;
    CGFloat distanceToTravelX;
    
    //NSLog(@"destinationX %.2f currentx %.3f",destinationX,currentx);

    if (animated) {
    
        bounds.origin.x = destinationX;
        if (destinationX > currentx - 0.0001) {
            distanceToTravelX = destinationX - currentx;
            duration = distanceToTravelX / _uiPointsPerSecondLength;
            
            if (duration < 0.009)
                duration = 0.0;
                
            [UIView animateWithDuration:duration delay:0.0 options:UIViewAnimationOptionCurveLinear
                             animations:^{
                                 self.scrollView.bounds = bounds;
                             } completion:nil];
            
        } else {
            [self.scrollView setContentOffset:CGPointMake(destinationX, _scrollView.contentOffset.y) animated:contentAnimated];
//            NSLog(@"destinationX x+ %.2f currentx %.2f",destinationX,currentx);
        }
    } else {
        
        [_scrollView.layer removeAllAnimations];
        [self.scrollView setContentOffset:CGPointMake(destinationX, _scrollView.contentOffset.y) animated:contentAnimated];
//        NSLog(@"destinationX xx %.2f greatter currentx %.2f pos %.3f",destinationX,currentx,position);
    }
}


//NSLog(@"%s %.4f",__func__,progress);


// A default configuration
// This will set a color for all values

-(void)configureColorsInBufferView:(JWVisualAudioBufferView*)bufferView recording:(BOOL)recording {
    
//    NSLog(@"%s",__func__);
    // Clear color reveals the background which is dark
    BOOL darkBackGround = _darkBackground;
    
    bufferView.darkBackGround = _darkBackground;
    // One configuration
    // Set defaults for this controller
    bufferView.colorForTopPeak = darkBackGround ?
    [UIColor colorWithWhite:1.0 alpha:0.8] :
    [[UIColor blueColor] colorWithAlphaComponent:1.0f];
    if (recording) {
        bufferView.colorForTopAvg = darkBackGround ?
        [UIColor colorWithWhite:1.0 alpha:0.50] :
        [[UIColor blueColor] colorWithAlphaComponent:1.0f];
    } else {
        bufferView.colorForTopAvg = darkBackGround ?
        [UIColor colorWithWhite:1.0 alpha:0.50] :
        [[UIColor blueColor] colorWithAlphaComponent:1.0f];
    }
    bufferView.colorForTopNoAvg = darkBackGround ?
    [UIColor colorWithWhite:1.0 alpha:0.8] :
    [[UIColor blueColor] colorWithAlphaComponent:1.0f];
    bufferView.colorForBottomAvg = bufferView.colorForTopAvg;
    bufferView.colorForBottomNoAvg = bufferView.colorForTopNoAvg;
    bufferView.colorForBottomPeak = bufferView.colorForTopPeak;
}


// configureColors -
// sets the appropriate color in bufferView using dictionary of colors
// if it does not exist in the dictionary passed check the all tracks dictionary
// for the one particular color that is missing in the supplied dictionary
// Passing nil in trackColors and fallback YES will check the allTracks dictionary
// for that ALL colors and essentially set all to default

-(void)configureColors:(NSDictionary*)trackColors withFallback:(BOOL)fallback
          inBufferView:(JWVisualAudioBufferView*)bufferView
             recording:(BOOL)recording {
    
    id colorSpec;
    
    // TOP peak
    colorSpec = nil;
    if (trackColors)
        colorSpec = trackColors[JWColorScrubberTopPeak];
    if (colorSpec){
        bufferView.colorForTopPeak = (UIColor*)colorSpec;
    } else if (_userProvidedColorsAllTracks) {
        colorSpec = _userProvidedColorsAllTracks[JWColorScrubberTopPeak];
        if (colorSpec)
            bufferView.colorForTopPeak = (UIColor*)colorSpec;
    }
    // BOTTOM peak
    colorSpec = nil;
    if (trackColors)
        colorSpec = trackColors[JWColorScrubberBottomPeak];
    if (colorSpec) {
        bufferView.colorForBottomPeak = (UIColor*)colorSpec;
    } else if (_userProvidedColorsAllTracks) {
        colorSpec = _userProvidedColorsAllTracks[JWColorScrubberBottomPeak];
        if (colorSpec)
            bufferView.colorForBottomPeak = (UIColor*)colorSpec;
    }
    // TOP average
    colorSpec = nil;
    if (trackColors)
        colorSpec = trackColors[JWColorScrubberTopAvg];

    if (colorSpec) {
        bufferView.colorForTopAvg = (UIColor*)colorSpec;
    } else if (_userProvidedColorsAllTracks) {
        colorSpec = _userProvidedColorsAllTracks[JWColorScrubberTopAvg];
        if (colorSpec)
            bufferView.colorForTopAvg = (UIColor*)colorSpec;
    }
    // BOTTOM average
    colorSpec = nil;
    if (trackColors)
        colorSpec = trackColors[JWColorScrubberBottomAvg];

    if (colorSpec) {
        bufferView.colorForBottomAvg = (UIColor*)colorSpec;
    } else if (_userProvidedColorsAllTracks) {
        colorSpec = _userProvidedColorsAllTracks[JWColorScrubberBottomAvg];
        if (colorSpec)
            bufferView.colorForBottomAvg = (UIColor*)colorSpec;
    }
    // TOP peak no average
    colorSpec = nil;
    if (trackColors)
        colorSpec = trackColors[JWColorScrubberTopPeakNoAvg];
    if (colorSpec) {
        bufferView.colorForTopNoAvg = (UIColor*)colorSpec;
    } else if (_userProvidedColorsAllTracks) {
        colorSpec = _userProvidedColorsAllTracks[JWColorScrubberTopPeakNoAvg];
        if (colorSpec)
            bufferView.colorForTopNoAvg = (UIColor*)colorSpec;
    }
    // BOTTOM peak no average
    colorSpec = nil;
    if (trackColors)
        colorSpec = trackColors[JWColorScrubberBottomPeakNoAvg];
    if (colorSpec) {
        bufferView.colorForBottomNoAvg = (UIColor*)colorSpec;
    } else if (_userProvidedColorsAllTracks) {
        colorSpec = _userProvidedColorsAllTracks[JWColorScrubberBottomPeakNoAvg];
        if (colorSpec)
            bufferView.colorForBottomNoAvg = (UIColor*)colorSpec;
    }
}


#pragma mark -

//#define DEBUGBUFFER

//// PLAYING multi track - duration seconds
/*
 add bufferView of audio samples
 two arrays for two channel of options
 channel2Samples bare used if dualchannel set in options
 otherwise passing nil to channel2Samples is ok
 */

- (void)addAudioViewChannelSamples:(NSArray*)samples1 averageSamples:(NSArray*)averageSamples
                   channel2Samples:(NSArray*)samples2 averageSamples2:(NSArray*)averageSamples2
                           inTrack:(NSUInteger)track
                     startDuration:(NSTimeInterval)startDuration
                          duration:(NSTimeInterval)duration
                             final:(NSUInteger)finalValue
                           options:(SamplingOptions)options
                              type:(VABKindOptions)typeOptions
                            layout:(VABLayoutOptions)layoutOptions
                            colors:(NSDictionary*)trackColors
                         bufferSeq:(NSUInteger)bufferNo
                       autoAdvance:(BOOL)autoAdvance
                         recording:(BOOL)recording
                           editing:(BOOL)editing
                              size:(CGSize)scrubberViewSize
{

    // STEP 1 COMPUTE SIZE
    CGFloat uiBufferSize = duration * _uiPointsPerSecondLength;
    CGFloat startingPosition = startDuration * _uiPointsPerSecondLength;
    CGFloat bottomLayoutOffset = 0.0;

    // FRAMES fr and mfr  - bufferView frame and bufferViewMirror
    CGRect fr =
    [self frameForBuffer:track bufferWidth:uiBufferSize allTracksHeight:scrubberViewSize.height - bottomLayoutOffset];
    fr.origin.x = startingPosition;
    
    

    // STEP 2 CREATE Buffer View(s)
    
    BOOL useTrackColorInEditStart = NO;
    JWVisualAudioBufferView *bufferView = nil;

    if (editing == NO) {
        _audioViewBufferCounts[track]++;
        
//        NSUInteger avCount = _audioViewBufferCounts[track];

        // NOT EDITING
        bufferView = [[JWVisualAudioBufferView alloc] initWithSamples:samples1 samples2:samples2 samplingOptions:options];
        bufferView.samplesAverages = averageSamples;
        bufferView.samplesAverages2 = averageSamples2;
        bufferView.layoutOptions = layoutOptions;
        bufferView.kindOptions = typeOptions;
        bufferView.recording = recording;
        bufferView.notifString = [NSString stringWithFormat:@"track%lunotification",(unsigned long)track];
        dispatch_async(dispatch_get_main_queue(), ^{
            bufferView.backgroundColor = [UIColor clearColor];
        });
#ifdef DEBUGBUFFER
        bufferView.layer.borderColor = [UIColor grayColor].CGColor;
        bufferView.layer.borderWidth = 0.5;
#endif
        // Clear color reveals the background which is dark
        bufferView.darkBackGround = _darkBackground;
        // If track colors are passed then use them to set the colors of the buffer
        // if not configure the buffer colors using the lone _userProvidedColorsAllTracks
        // and if that does not exist use the defaukt config for colors
        if (trackColors || _userProvidedColorsAllTracks) {
            [self configureColors:trackColors withFallback:YES inBufferView:bufferView recording:recording];
        } else {
            [self configureColorsInBufferView:bufferView recording:recording];
        }
        
        bufferView.userInteractionEnabled = NO;
        
        // NOT EDITING
        CGFloat previousTrackPosition = startingPosition; // is needed for autoadvance
        
        _currentPositions[track] +=  uiBufferSize;
        _vTrackLengths[track] += uiBufferSize;
        
        CGFloat height = scrubberViewSize.height - self.topLayoutScrollViewConstraint.constant - bottomLayoutOffset;
        
        [self adjustContentSize:CGSizeMake([self largestTrackEndPosition],height)];
        
        
        // STEP 3 ADD SUBVIEW BUFFER View

        if (autoAdvance == NO) {
            // add the subview
            dispatch_async(dispatch_get_main_queue(), ^{
                bufferView.frame = fr;
                if (recording) {
                    bufferView.timeToLive = 2.5;
                }
                [self.scrollView addSubview:bufferView];
                [bufferView setNeedsDisplay];
            });
        }
        else {
            // we set the bounds onCenter using current track position before it gets incremented
            // and to advance the animation in correct time
            CGRect bounds = self.scrollView.bounds;
            bounds.origin.x =  previousTrackPosition - _tracksOffest;
            CGRect startBounds = bounds;
            bounds.origin.x += uiBufferSize;
            // Autoadvance is ON so we advance the bounds
            
            dispatch_async(dispatch_get_main_queue(), ^{
                bufferView.frame = fr;
                self.scrollView.bounds = startBounds;
                [self.scrollView addSubview:bufferView];
                [bufferView setNeedsDisplay];
                [UIView animateWithDuration:duration delay:0.0 options:UIViewAnimationOptionCurveLinear
                                 animations:^{
                                     self.scrollView.bounds = bounds;
                                 } completion:nil];
            });
        }


    } else {
        _audioViewBufferCounts[0]++;
        NSUInteger avCount = _audioViewBufferCounts[0];

        // EDITING
        bufferView = [[JWVisualAudioBufferView alloc] initWithSamples:samples1 samples2:samples2 samplingOptions:options];
        bufferView.samplesAverages = averageSamples;
        bufferView.samplesAverages2 = averageSamples2;
        bufferView.layoutOptions = layoutOptions;
        bufferView.kindOptions = typeOptions;
        bufferView.recording = NO;
        bufferView.backgroundColor = [UIColor clearColor];
        bufferView.darkBackGround = _darkBackground;
        bufferView.notifString = [NSString stringWithFormat:@"edittrack%lunotification",(unsigned long)track];
        
        // USE BUFFER MIRROR FOR CLIP LEFT / CLIP RIGHT
        BOOL useBufferMirror = (_editType == ScrubberEditLeft || _editType == ScrubberEditRight );
        
        JWVisualAudioBufferView *bufferViewMirror = nil;

        CGRect mfr = fr; // mirrorframe

        // EDITING USE MIRROR
        if (useBufferMirror) {
            bufferViewMirror = [[JWVisualAudioBufferView alloc] initWithSamples:samples1 samples2:samples2 samplingOptions:options];
            bufferViewMirror.samplesAverages = averageSamples;
            bufferViewMirror.samplesAverages2 = averageSamples2;
            bufferViewMirror.layoutOptions = layoutOptions;
            bufferViewMirror.kindOptions = typeOptions;
            bufferViewMirror.recording = NO;
            bufferViewMirror.backgroundColor = [UIColor clearColor];
            bufferViewMirror.darkBackGround = _darkBackground;
            bufferViewMirror.notifString = [NSString stringWithFormat:@"mirrortrack%lunotification",(unsigned long)track];

            // EDITING COLORS (INACTIVE)
            [self configureColors:@{JWColorScrubberTopPeak : [[UIColor whiteColor] colorWithAlphaComponent:0.7],
                                    JWColorScrubberTopAvg : [UIColor colorWithWhite:0.6 alpha:0.5] ,
                                    JWColorScrubberBottomAvg : [UIColor colorWithWhite:0.6 alpha:0.5],
                                    JWColorScrubberBottomPeak : [[UIColor lightGrayColor] colorWithAlphaComponent:0.6],
                                    JWColorScrubberTopPeakNoAvg : [[UIColor lightGrayColor] colorWithAlphaComponent:0.8],
                                    JWColorScrubberBottomPeakNoAvg : [[UIColor lightGrayColor] colorWithAlphaComponent:0.8],
                                    }
                     withFallback:NO
                     inBufferView:bufferViewMirror recording:NO];
            
            mfr.origin.x = startingPosition - _startPositions[1];
            mfr.origin.y = 0.0;
        }
        // EDITING NOT-MIRRORED EDIT START
        else if (_editType == ScrubberEditStart) {

            fr.origin.x = startingPosition - _startPositions[1];
            fr.origin.y = 0.0;  // gonna be used in bufferView
        }
        // EDITING NOT-MIRRORED EDITING COLORS (ACTIVE)
        else {
            NSLog(@"%s unknown edit type",__func__);
            // Frame fr is what it is
        }
        
        
        // EDITING COLORS (ACTIVE)
        if (useTrackColorInEditStart) {
            if (trackColors || _userProvidedColorsAllTracks) {
                [self configureColors:trackColors withFallback:YES inBufferView:bufferView recording:NO];
            } else {
                [self configureColorsInBufferView:bufferView recording:recording];
            }
        } else {
            // EDITING COLORS (ACTIVE)
            [self configureColors:@{
                                    JWColorScrubberTopPeak : [[UIColor yellowColor] colorWithAlphaComponent:0.6],
                                    JWColorScrubberTopAvg : [[UIColor yellowColor] colorWithAlphaComponent:0.4],
                                    JWColorScrubberBottomAvg : [[UIColor yellowColor] colorWithAlphaComponent:0.4],
                                    JWColorScrubberBottomPeak : [[UIColor yellowColor] colorWithAlphaComponent:0.6],
                                    JWColorScrubberTopPeakNoAvg : [[UIColor yellowColor] colorWithAlphaComponent:0.8],
                                    JWColorScrubberBottomPeakNoAvg : [[UIColor yellowColor] colorWithAlphaComponent:0.8],
                                    }
                     withFallback:NO
                     inBufferView:bufferView recording:NO];
        }
        
        
        // STEP 3 ADD SUBVIEW BUFFER View and/or BUFFER MIRROR View
        
        if (_editType == ScrubberEditLeft || _editType == ScrubberEditRight ) {
            
            // ADD MIRRORED
            _currentPositions[0] +=  uiBufferSize;  // uses first index not used by any other track
            _vTrackLengths[0] += uiBufferSize;
            
            if (_editType == ScrubberEditLeft ) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    bufferViewMirror.frame = mfr;
                    [self.editLayerLeft addSubview:bufferViewMirror];
                    [bufferViewMirror setNeedsDisplay];
                });
            } else if ( _editType == ScrubberEditRight ) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    bufferViewMirror.frame = mfr;
                    [self.editLayerRight addSubview:bufferViewMirror];
                    [bufferViewMirror setNeedsDisplay];
                });
            }
            
            // ADD NON-MIRRORED
            _currentPositions[track] +=  uiBufferSize;
            _vTrackLengths[track] += uiBufferSize;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                bufferView.frame = fr;
                [self.scrollView addSubview:bufferView];
                [bufferView setNeedsDisplay];
            });
            
            // ADJUST CONTENT SIZE
            CGFloat height = scrubberViewSize.height - self.topLayoutScrollViewConstraint.constant - bottomLayoutOffset;
            [self adjustContentSize:CGSizeMake([self largestTrackEndPosition],height)];
            
            //            NSLog(@"editing npos bufferViewMirror %.2f  %@",_currentPositions[0],NSStringFromCGPoint(bufferViewMirror.frame.origin));
            //            NSLog(@"editing npos bufferView       %.2f  %@",_currentPositions[0],NSStringFromCGPoint(bufferView.frame.origin));
            
        } else if (_editType == ScrubberEditStart) {
            
            // ADD NON-MIRRORED to edit layer
            dispatch_async(dispatch_get_main_queue(), ^{
                bufferView.frame = fr;
                [self.editLayerRight addSubview:bufferView];
                [bufferView setNeedsDisplay];
            });
            
            NSLog(@"editing npos bufferView       %.2f  %@",_currentPositions[0],NSStringFromCGPoint(bufferView.frame.origin));
        }
        
        
        if (avCount < finalValue) {
            NSLog(@"NOT FINSIHED track %ld, avCount %lu",(unsigned long)track,avCount );
        } else {
            NSLog(@"FINSIHED track %ld, avCount %lu",(unsigned long)track,avCount );
            _audioViewBufferCounts[0] = 0;
//            [self revealInEditMode];
        }

        
    }  // Editing
    
}

//    if (finalValue > bufferNo) {
//        NSLog(@"BUFFERS track %ld, %ld",track,finalValue);
//    } else {
//        // finshed
//        NSLog(@"BUFFERS DONE for track %ld count %ld",track,finalValue);
//    }

//    if (avCount < finalValue) {
//        NSLog(@"NOT FINSIHED track %ld, avCount %ld",track,avCount );
//    } else {
//        NSLog(@"FINSIHED track %ld, avCount %ld",track,avCount );
//        _audioViewBufferCounts[track] = 0;
//    }

//        NSUInteger buffersCount = [_delegate buffersCompletedTrack:0];
//        if (buffersCount > 0) {
//            // finshed
//            NSLog(@"BUFFERS DONE for track %ld count %ld",0,buffersCount);
//
//        } else {
//            NSLog(@"BUFFERS track %ld ",0);
//        }




-(void)adjustContentSize:(CGSize)size {
    
    //CGFloat ltl = [self largestTrackEndPosition];
    CGRect clipfr = _clipEnd.frame;
    clipfr.origin.x = size.width;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        _clipEnd.frame = clipfr;
        self.scrollView.contentSize = size;
    });
    
    //CGSizeMake([self largestTrackEndPosition] , scrubberViewSize.height - self.topLayoutScrollViewConstraint.constant - bottomLayoutOffset);
}

//NSDictionary *editTrackColors =
//@{
//  JWColorScrubberTopPeak : [[UIColor yellowColor] colorWithAlphaComponent:0.6],
//  JWColorScrubberTopAvg : [[UIColor yellowColor] colorWithAlphaComponent:0.4],
//  JWColorScrubberBottomAvg : [[UIColor yellowColor] colorWithAlphaComponent:0.4],
//  JWColorScrubberBottomPeak : [[UIColor yellowColor] colorWithAlphaComponent:0.6],
//  JWColorScrubberTopPeakNoAvg : [[UIColor yellowColor] colorWithAlphaComponent:0.8],
//  JWColorScrubberBottomPeakNoAvg : [[UIColor yellowColor] colorWithAlphaComponent:0.8],
//  };

// Helper to compute frame

-(CGRect)frameForBuffer:(NSUInteger)track bufferWidth:(CGFloat)bufferWidth allTracksHeight:(CGFloat)allTracksHeight
{
    CGRect result = CGRectZero;
    CGFloat vHeight = allTracksHeight;

    vHeight -= _topLayoutScrollViewConstraint.constant; // account for labels at top

    // If we have locations use them to compute the Y and trackHeight
    NSUInteger locationsCount = [_locations count];
    CGFloat yOrigin = 0.0;
    CGFloat trackHeight = 0.0;

    // Does this track participate in available locations
    
    if (locationsCount < track) {
        
        // Track is beyond count of locations including no locations at all
        // Distribute evenly among remaining
        
        CGFloat locationFactor = 0.0f;
        CGFloat heightToLastLocation = 0.0;
        CGFloat reaminingHeight = 0.0f;

        if (locationsCount > 0) {
            
            NSUInteger remainingTracks = _numberOfTracks - locationsCount;
            NSUInteger thisTrackOfRemaining = track - locationsCount;

            locationFactor = [[_locations lastObject] floatValue];  // from NSNumber
            heightToLastLocation = locationFactor * vHeight;
            reaminingHeight = vHeight - heightToLastLocation;
            trackHeight = (reaminingHeight/remainingTracks); // - (totalInnespacingSize/remainingTracks);  // minus spacer between

            yOrigin = heightToLastLocation + ((thisTrackOfRemaining -1) * trackHeight);

        } else { // evenly distributed
            locationFactor = (CGFloat)1.0 /_numberOfTracks ;
            trackHeight = (locationFactor * vHeight);
            heightToLastLocation = trackHeight * (track - 1);
           
            yOrigin = heightToLastLocation;
        }
        
    } else {
        
        // Use location to determine track position
        
        CGFloat locationFactor = [_locations[track -1] floatValue];  // from NSNumber
        CGFloat thisTrackEndY = locationFactor * vHeight;
        CGFloat trackHeightToThisTrack = 0.0;
        
        if (track > 1) {
            NSUInteger indexThisTrack = track - 1;
            locationFactor = [_locations[indexThisTrack - 1] floatValue];  // from NSNumber
            
            trackHeightToThisTrack = (locationFactor * vHeight);
        }

        yOrigin = trackHeightToThisTrack;
        trackHeight = thisTrackEndY - yOrigin;
    }
   
    result = CGRectMake(0, yOrigin, bufferWidth, trackHeight );
    
//    NSLog(@"%ld h[%.2f] %@",track,allTracksHeight,NSStringFromCGRect(result));

    return result;
}


-(CGRect)frameForTrack:(NSUInteger)track  allTracksHeight:(CGFloat)allTracksHeight
{
    CGRect result = CGRectZero;
    CGFloat trackWidth = _vTrackLengths[track] + _startPositions[track];
    
    // Use the frameBuffer computation to get the ypos and height
    CGRect fr =[self frameForBuffer:track bufferWidth:0 allTracksHeight:allTracksHeight];
    
    result = CGRectMake(0, fr.origin.y, trackWidth,fr.size.height);
    
    return result;
}


#pragma mark - edit track
/*
 editTrack
 creates a new editFileReference for track
 
 */

// -(void)editTrackData:(NSUInteger)track {
// NSDictionary *trackInfo = [_delegate trackInfoForTrack:track];

-(void)editTrackData:(NSDictionary *)trackInfo {
    
    JWPlayerFileInfo *fileReference = nil;

    NSTimeInterval durationSeconds = 0.0;
    float startTime = 0.0;
    float startInset = 0.0;
    float endInset = 0.0;
    
    id startTimeValue = trackInfo[@"starttime"];
    startTime = startTimeValue ? [startTimeValue floatValue] : 0.0;
    id refFile = trackInfo[@"referencefile"];
    NSURL *fileURL = trackInfo[@"fileurl"];
    if (fileURL) {
        NSError *error = nil;
        AVAudioFile *audioFile = [[AVAudioFile alloc] initForReading:fileURL error:&error];
        AVAudioFormat *processingFormat = [audioFile processingFormat];
        durationSeconds = audioFile.length / processingFormat.sampleRate;
    }
    
    if (refFile) {
        
        id startInsetValue = refFile[@"startinset"];
        startInset = startInsetValue ? [startInsetValue floatValue] : 0.0;
        id endInsetValue = refFile[@"endinset"];
        endInset = endInsetValue ? [endInsetValue floatValue] : 0.0;
        
        fileReference =
        [[JWPlayerFileInfo alloc] initWithCurrentPosition:0.0 duration:durationSeconds
                                            startPosition:startTime
                                               startInset:startInset
                                                 endInset:endInset];
    } else {
        fileReference =
        [[JWPlayerFileInfo alloc] initWithCurrentPosition:0.0 duration:durationSeconds
                                            startPosition:startTime
                                               startInset:startInset
                                                 endInset:endInset];
        
        
    }

    NSLog(@"%s [si %.2f ei %.2f dur %.2f] ts %.2f",__func__,startInset,endInset,durationSeconds,startTime);

    _editFileReference = fileReference;
}


-(void)editTrack:(NSUInteger)track {

    _editTrack = track;

    // Removes the ActiveTrack Duration and delay
    [[NSNotificationCenter defaultCenter] postNotificationName:[NSString stringWithFormat:@"track%lunotification",(unsigned long)track]
                                                        object:self userInfo:@{@"remove":@(0.40),
                                                                               @"removeDelay":@(0.10)}];
    _startPositions[track] = 0.000f;
    _currentPositions[track] = _startPositions[track];
    _vTrackLengths[track] = 0.0;
    
    _startPositions[0] = 0.000f;
    _currentPositions[0] = _startPositions[0];
    _vTrackLengths[0] = 0.0;
}

#pragma mark edit track commands

-(void)editTrack:(NSUInteger)track startInset:(CGFloat)startInset {

    _editType = ScrubberEditLeft;  // set the edit type
    [self editTrack:track];
    [self editTrackData:[_delegate trackInfoForTrack:track]];
    if (_seeksToPositionOnEdit) {
        [self rewindToBeginningOfTrack:track];
    }
    [self configureEditLayer];
    

    // SET THE INITIAL VIEW OF MIRROR TRACK
    
    CGRect bounds = _editLayerLeft.bounds;
    bounds.origin.x = - CGRectGetWidth(bounds);  // to zero
    CGRect startBounds = bounds;
    bounds.origin.x = - CGRectGetWidth(bounds) + (_editFileReference.trackStartPosition * _uiPointsPerSecondLength);

    _editLayerLeft.bounds = startBounds;
    
    [UIView animateWithDuration:0.50 delay:0.10
         usingSpringWithDamping:0.683 initialSpringVelocity:.64 options:0
                     animations:^{
                         _editLayerLeft.bounds = bounds;
                     } completion:nil];


    NSLog(@"%s startInset %.2f [si(%.2f)ei(%.2f) ts %.2f]",__func__,startInset,
          _editFileReference.startPositionInset,
          _editFileReference.endPositionInset,
          _editFileReference.trackStartPosition);
    NSLog(@"%s boundsx %.2f",__func__,bounds.origin.x);
    
    [self revealInEditModeDelayed];
}



-(void)revealInEditMode {
    CGFloat cpos = _scrollView.contentOffset.x + _scrollView.contentInset.left;
    CGFloat spos = _scrollView.contentOffset.x;
    NSLog(@"%s cpos %.2f  sec %.2f",__func__,cpos,cpos/_uiPointsPerSecondLength);
    _scrollView.alpha = 0.5;
    [UIView animateWithDuration:0.25 delay:0
                            options:UIViewAnimationOptionCurveLinear
                         animations:^{
                             _scrollView.alpha = 1.0;
                         } completion:^(BOOL fini){
                         }];
        
    _scrollView.contentOffset = CGPointMake(spos, _scrollView.contentOffset.y);
    [self scrollViewTrackingAtPosition:cpos];
    _listenToScrolling = YES;
}


-(void)revealInEditModeDelayed {
    CGFloat cpos = _scrollView.contentOffset.x + _scrollView.contentInset.left;
    CGFloat spos = _scrollView.contentOffset.x;
    
    NSLog(@"%s cpos %.2f  sec %.2f",__func__,cpos,cpos/_uiPointsPerSecondLength);
    
    _trackingEdit = YES;
    _listenToScrolling = NO;
    
    double delayInSecs = 0.025;
    
    // WAIT for buffers to complete, they cause viewDidScroll
    [UIView animateWithDuration:delayInSecs delay:0 options:0
                     animations:^{
                         _scrollView.alpha = 0.0;
                     } completion:^(BOOL fini){}];
    
    //    NSLog(@"%3f",delayInSecs);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSecs * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        _scrollView.alpha = 0.5;
        [UIView animateWithDuration:0.25 delay:0
                            options:UIViewAnimationOptionCurveLinear
                         animations:^{
                             _scrollView.alpha = 1.0;
                         } completion:^(BOOL fini){
                         }];
        
        _scrollView.contentOffset = CGPointMake(spos, _scrollView.contentOffset.y);
        [self scrollViewTrackingAtPosition:cpos];
        _listenToScrolling = YES;
    });
    
}


-(void)editTrack:(NSUInteger)track endInset:(CGFloat)endInset {

    _trackingEdit = NO;

    _editType = ScrubberEditRight; // set the edit type
    [self editTrack:track];
    [self editTrackData:[_delegate trackInfoForTrack:track]];
    if (_seeksToPositionOnEdit) {
        [self rewindToEndOfTrack:track];
    }
    [self configureEditLayer];
    
    // SET THE INITIAL VIEW OF MIRROR TRACK
    
    CGRect bounds = _editLayerRight.bounds;
    CGFloat totLength = (_editFileReference.trackDuration * _uiPointsPerSecondLength); // THE MIRRORTRACK LENGTH
    bounds.origin.x = totLength;  // to zero
    CGRect startBounds = bounds;
    // minus total brings End to Left position
    bounds.origin.x = totLength - (endInset * _uiPointsPerSecondLength);

    _editLayerRight.bounds = startBounds;
    [UIView animateWithDuration:0.45 delay:0.10
         usingSpringWithDamping:0.683 initialSpringVelocity:.64 options:0
                     animations:^{
                         _editLayerRight.bounds = bounds;
                     } completion:nil];

//    [self scrollViewTrackingAtCurrentPosition];
    
    NSLog(@"%s endInset %.2f [si(%.2f)ei(%.2f) ts %.2f]",__func__,endInset,
          _editFileReference.startPositionInset,
          _editFileReference.endPositionInset,
          _editFileReference.trackStartPosition);
    NSLog(@"%s boundsx %.2f ",__func__,bounds.origin.x);

// this
//    _trackingEdit = YES;
//    _listenToScrolling = NO;
    
// or this
    
    [self revealInEditModeDelayed];
    
}


-(void)editTrack:(NSUInteger)track startTime:(CGFloat)startTime {

    _editType = ScrubberEditStart; // set the edit type
    [self editTrack:track];
    [self editTrackData:[_delegate trackInfoForTrack:track]];
    if (_seeksToPositionOnEdit) {
        [self rewindToBeginningOfTrack:track];
    }
    [self configureEditLayer];
    
    
    // SET THE INITIAL VIEW OF MIRROR TRACK
    
    CGRect bounds = _editLayerRight.bounds;
    bounds.origin.x = 0.0;
    _editLayerRight.bounds = bounds;

    
    NSLog(@"%s startTime %.2f [si(%.2f)ei(%.2f) ts %.2f]",__func__,startTime,
          _editFileReference.startPositionInset,
          _editFileReference.endPositionInset,
          _editFileReference.trackStartPosition);
    NSLog(@"%s boundsx %.2f ",__func__,bounds.origin.x);
}


#pragma mark - stop editing

/*
 stopEditingTrackCancel
 Caller must already have trackInfo Ready for delegate call in rewindToBeginningOfTrack
 */
-(void)stopEditingTrackCancel:(NSUInteger)track {
    
    _trackingEdit = NO;
    
    // Removes the editingTrack
    [[NSNotificationCenter defaultCenter] postNotificationName:
     [NSString stringWithFormat:@"edittrack%lunotification",(unsigned long)track]
                                                        object:self userInfo:@{@"alpha":@(0.5)}];
    CGFloat delay = .50;
    [[NSNotificationCenter defaultCenter] postNotificationName:
     [NSString stringWithFormat:@"edittrack%lunotification",(unsigned long)track]
                                                        object:self userInfo:@{@"remove":@(delay/2),
                                                                               @"removeDelay":@(delay/2)}];

    //                                                        object:self userInfo:@{@"remove":@(0.25)}];

    if (_seeksToPositionOnEdit) {
        if (_editType == ScrubberEditLeft )
            [self rewindToBeginningOfTrack:track];
        else if ( _editType == ScrubberEditRight )
            [self rewindToEndOfTrack:track];
        else if ( _editType == ScrubberEditStart )
            [self rewindToBeginningOfTrack:track];
    } else {
        // TODO: remember current psoition before editing then go there
        
    }

    [self stopEditingTrackDidCancel:track];
    [_editClipButton removeFromSuperview];
    self.editClipButton = nil;
    _startPositions[0] = 0.0;
    _editType = ScrubberEditNone;
    _editTrack = 0;


}

-(void)clipButtonPressed:(id)sender {

    // CALLS stopEditingTrackSave and notifies the delegate of the event
    
    [UIView animateWithDuration:0.00 delay:0.0
                        options: UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         _editClipButton.backgroundColor = [UIColor iosSkyColor];
                     } completion:^(BOOL fini){
                         _editClipButton.backgroundColor = [UIColor iosSkyColor];
                     }];

    NSUInteger track = _editTrack;
    [self stopEditingTrackSave:_editTrack completion:^(id fileRef) {
        [_delegate editCompletedForTrack:track withTrackInfo:fileRef];
    }];
}

-(id)stopEditingTrackSave:(NSUInteger)track completion:(void (^)(id fileRef))completion {
    
    _trackingEdit = NO;
    
    // Removes the editingTrack
    
    [[NSNotificationCenter defaultCenter] postNotificationName:
     [NSString stringWithFormat:@"edittrack%ldnotification",(unsigned long)track]
                                                        object:self userInfo:@{@"alpha":@(0.75)}];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:
     [NSString stringWithFormat:@"edittrack%ldnotification",(unsigned long)track]
                                                        object:self userInfo:@{@"remove":@(0.25)}];
    
    //                                                            object:self userInfo:@{@"remove":@(0.25),
    //                                                                                   @"removeDelay":@(2.5)}];
    
    
    [self stopEditingTrackDidSave:track animated:YES completion:^{
        if (completion)
            completion(_editFileReference);
    }];
    
    [_editClipButton removeFromSuperview];
    self.editClipButton = nil;
    _startPositions[0] = 0.0;
    _editType = ScrubberEditNone;
    _editTrack = 0;
    
    return nil;
}

/*
 stopEditingTrackDidSave
 Effect clip point is animated to pull away from the track and then disappear
 */
-(void)stopEditingTrackDidSave:(NSUInteger)track  animated:(BOOL)animated completion:(void (^)())completion {

//-(void)stopEditingTrackDidSave:(NSUInteger)track  animated:(BOOL)animated {
    
    BOOL bounceOut = YES;
    BOOL justFadeout = YES;

    // EDIT LEFT
    if (_editType == ScrubberEditLeft ) {
        if (_editLayerLeft) {
            
            if (animated) {
                
                if (completion)
                    completion();

                CGFloat moveLengthSeconds = 0.25;
                CGPoint center = _editLayerLeft.center;
                center.x -= (moveLengthSeconds * _uiPointsPerSecondLength);

                CGFloat delayToAlpha = 0.0;
                CGFloat delayToStartAnimating = 0.0; // delay to allow edit track to disappear
                
                // MOVE OUT THEN HIDE
                if (bounceOut) {
                    [UIView animateWithDuration:0.45 delay:delayToStartAnimating
                         usingSpringWithDamping:0.183 initialSpringVelocity:.84
                                        options:UIViewAnimationOptionCurveEaseOut
                                     animations:^{
                                         _editLayerLeft.center = center;
                                     } completion:^(BOOL fini){
//                                         if (completion)
//                                             completion();

                                     }];
                    
                    delayToAlpha = 0.75 + delayToStartAnimating;

                } else if (justFadeout == NO){
                    [UIView animateWithDuration:moveLengthSeconds delay:delayToStartAnimating
                                        options:UIViewAnimationOptionCurveEaseOut
                                     animations:^{
                                         _editLayerLeft.center = center;
                                     } completion:^(BOOL fini){
//                                         if (completion)
//                                             completion();

                                     }];
                    
                    delayToAlpha = 0.25 + delayToStartAnimating;
                }
                
                [UIView animateWithDuration:0.55 delay:delayToAlpha
                                    options: UIViewAnimationOptionCurveEaseIn
                                 animations:^{
                                     _editLayerLeft.alpha = 0.0;
                                 } completion:^(BOOL fini){
                                     [_editLayerLeft removeFromSuperview];
                                     self.editLayerLeft = nil;
//                                     if (completion)
//                                         completion();
                                 }];
                

                
            } else {
                [_editLayerLeft removeFromSuperview];
                self.editLayerLeft = nil;
                if (completion)
                    completion();
            }
        }
    }
    
    // EDIT RIGHT

    else if ( _editType == ScrubberEditRight ) {
        if (_editLayerRight) {
            if (animated) {
                
                CGFloat moveLengthSeconds = 0.25;
                CGPoint center = _editLayerRight.center;
                center.x += (moveLengthSeconds * _uiPointsPerSecondLength);
                
                CGFloat delayToAlpha = 0.250;
                CGFloat delayToStartAnimating = 0.10; // delay to allow edit track to disappear

                // MOVE OUT THEN HIDE
                if (bounceOut) {
                    [UIView animateWithDuration:0.45 delay:delayToStartAnimating
                         usingSpringWithDamping:0.383 initialSpringVelocity:.84
                                        options:0
                                     animations:^{
                                         _editLayerRight.center = center;
                                     } completion:nil];
                    
                    delayToAlpha = 0.15 + delayToStartAnimating;
                    
                } else {
                    [UIView animateWithDuration:moveLengthSeconds delay:delayToStartAnimating
                                        options:UIViewAnimationOptionCurveEaseOut
                                     animations:^{
                                         _editLayerRight.center = center;
                                     } completion:nil];
                    
                    delayToAlpha = 0.15 + delayToStartAnimating;
                }

                [UIView animateWithDuration:0.75 delay:delayToAlpha
                                    options: UIViewAnimationOptionCurveEaseIn
                                 animations:^{
                                     _editLayerRight.alpha = 0.0;
                                 } completion:^(BOOL fini){
                                     [_editLayerRight removeFromSuperview];
                                     self.editLayerRight = nil;
                                     if (completion) {
                                         completion();
                                     }

                                 }];
            } else {
                [_editLayerRight removeFromSuperview];
                self.editLayerRight = nil;
                if (completion) {
                    completion();
                }

            }
        }
        
    }
    // EDIT START

    else if (_editType == ScrubberEditStart) {
        if (_editLayerRight) {
            if (animated) {
                [UIView animateWithDuration:0.45 delay:0.0  options: UIViewAnimationOptionCurveEaseIn
                                 animations:^{
                                     _editLayerRight.alpha = 0.0;
                                 } completion:^(BOOL fini){
                                     [_editLayerRight removeFromSuperview];
                                     self.editLayerRight = nil;
                                     if (completion) {
                                         completion();
                                     }

                                 }];
            } else {
                [_editLayerRight removeFromSuperview];
                self.editLayerRight = nil;
                if (completion) {
                    completion();
                }
            }
        }
    }
    
}


//-(void)stopEditingTrackDidSave:(NSUInteger)track  {
//    [self stopEditingTrackDidSave:track animated:YES];
//-(id)stopEditingTrackSave:(NSUInteger)track {
//    _trackingEdit = NO;
//    // Removes the editingTrack
//    [[NSNotificationCenter defaultCenter] postNotificationName:[NSString stringWithFormat:@"edittrack%ldnotification",track]
//                                                        object:self userInfo:@{@"alpha":@(0.5)}];
//
//    [[NSNotificationCenter defaultCenter] postNotificationName:[NSString stringWithFormat:@"edittrack%ldnotification",track]
//                                                             object:self userInfo:@{@"remove":@(0.25)}];
//
////                                                        object:self userInfo:@{@"remove":@(0.55),
////                                                                               @"removeDelay":@(0.10)}];
//    [self stopEditingTrackDidSave:track];
//    return _editFileReference;




/*
 stopEditingTrackDidCancel
 
 Effect clip point is animated to not pull away and the mirror track is moved to end
 as it starts at end when editing started
 */

-(void)stopEditingTrackDidCancel:(NSUInteger)track  {
    [self stopEditingTrackDidCancel:track animated:YES];
}

-(void)stopEditingTrackDidCancel:(NSUInteger)track animated:(BOOL)animated {
    
    // EDIT LEFT
    if (_editType == ScrubberEditLeft ) {
        if (_editLayerLeft) {
            if (animated) {
                CGRect bounds = _editLayerLeft.bounds;
                bounds.origin.x = - CGRectGetWidth(bounds);  // to zero
                [UIView animateWithDuration:0.250 delay:0.0
                                    options: UIViewAnimationOptionCurveLinear
                                 animations:^{
                                     _editLayerLeft.bounds = bounds;
                                 } completion:^(BOOL fini){
                                     [UIView animateWithDuration:0.25 delay:0.10
                                                         options: UIViewAnimationOptionCurveEaseIn
                                                      animations:^{
                                                          _editLayerLeft.alpha = 0.0;
                                                      } completion:^(BOOL fini){
                                                          [_editLayerLeft removeFromSuperview];
                                                          self.editLayerLeft = nil;
                                                      }];
                                 }];
            } else {
                [_editLayerLeft removeFromSuperview];
                self.editLayerLeft = nil;
            }
        }
    }
    
    // EDIT RIGHT
    else if (_editType == ScrubberEditRight ) {
        if (_editLayerRight) {
            if (animated) {
                CGRect bounds = _editLayerRight.bounds;
                CGFloat pos = (_editFileReference.trackDuration) * _uiPointsPerSecondLength;
                bounds.origin.x = pos;  // to zero
                [UIView animateWithDuration:0.250 delay:0.0  options: UIViewAnimationOptionCurveLinear
                                 animations:^{
                                     _editLayerRight.bounds = bounds;
                                 } completion:^(BOOL fini){
                                     [UIView animateWithDuration:0.25 delay:0.10
                                                         options: UIViewAnimationOptionCurveEaseIn
                                                      animations:^{
                                                          _editLayerRight.alpha = 0.0;
                                                      } completion:^(BOOL fini){
                                                          [_editLayerRight removeFromSuperview];
                                                          self.editLayerRight = nil;
                                                      }];
                                 }];
            } else {
                [_editLayerRight removeFromSuperview];
                self.editLayerRight = nil;
            }
        }
        
    }
    
    // EDIT START

    else if (_editType == ScrubberEditStart) {
        if (_editLayerRight) {
            if (animated) {
                [UIView animateWithDuration:0.45 delay:0.0
                                    options: UIViewAnimationOptionCurveEaseIn
                                 animations:^{
                                     _editLayerRight.alpha = 0.0;
                                 } completion:^(BOOL fini){
                                     [_editLayerRight removeFromSuperview];
                                     self.editLayerRight = nil;
                                 }];
            } else {
                [_editLayerRight removeFromSuperview];
                self.editLayerRight = nil;
            }
        }
    }
    
}

-(void)stopEditingTrack:(NSUInteger)track  {
    
    _startPositions[0] = 0.0;
    _editType = ScrubberEditNone;
}

#pragma mark -

-(void)saveEditingTrack:(NSUInteger)track {
    
}


//#define DEBUGTRACE

-(void)editingTrackInsetChanged {
    
    // LEFT
    if (_editType == ScrubberEditLeft ) {
        // BEGIN Inset
        CGFloat startInset = _editFileReference.startPositionInset;
        CGRect bounds = _editLayerLeft.bounds;
        CGFloat viewWidth = CGRectGetWidth(_editLayerLeft.frame);
        bounds.origin.x = -viewWidth + (startInset * _uiPointsPerSecondLength);

        _editLayerLeft.bounds = bounds;

        
#ifdef DEBUGTRACE
        NSLog(@"%s startPosInset %.2f trackStart %.2f boundsx %.2f viewW %.2f ",__func__,bounds.origin.x ,viewWidth,
              _editFileReference.startPositionInset,
              _editFileReference.trackStartPosition);
#endif
        // TODO: current Editing track
        if ([_delegate respondsToSelector:@selector(editChangeForTrack:withTrackInfo:)])
            [_delegate editChangeForTrack:1  withTrackInfo:_editFileReference];
        
    }
    
    // RIGHT

    else if (_editType == ScrubberEditRight ) {
        
        // END Inset
        CGFloat endInset = _editFileReference.endPositionInset;
        CGRect bounds = _editLayerRight.bounds;
        CGFloat totLength = (_editFileReference.trackDuration * _uiPointsPerSecondLength); // THE MIRRORTRACK LENGTH
        // minus total brings End to Left position
        bounds.origin.x = totLength - (endInset * _uiPointsPerSecondLength);

        _editLayerRight.bounds = bounds;
        
        
#ifdef DEBUGTRACE
        NSLog(@"%s endPosInset %.2f trackStart %.2f boundsx %.2f",__func__,bounds.origin.x,
              _editFileReference.endPositionInset,
              _editFileReference.trackStartPosition);
#endif
        
        // TODO: current Editing track
        if ([_delegate respondsToSelector:@selector(editChangeForTrack:withTrackInfo:)])
            [_delegate editChangeForTrack:1  withTrackInfo:_editFileReference];
    }
    
}

//        CGFloat totLength = _vTrackLengths[0]; // THE MIRRORTRACK LENGTH
//        // minus total brings End to Left position
//        bounds.origin.x =  totLength - (endInset * _uiPointsPerSecondLength);



// Read vars
//    @property (nonatomic,readonly) float duration;  // duration playback
//    @property (nonatomic,readonly) float remainingInTrack;
//    @property (nonatomic,readonly) float currentPositionIntrack;
//    @property (nonatomic,readonly) float startPositionInReferencedTrack;
//    @property (nonatomic,readonly) float readPositionInReferencedTrack;

/*
 changing the beginning inset changes start position
 */

-(void)userTrackingComputeEditingLeftProgressAtCurrentPosition {
    
    CGPoint offset = _scrollView.contentOffset;
    CGFloat pos = offset.x + self.scrollView.contentInset.left;
    if (pos < 0) {
        // NEGATIVE position in scrollview - read out of bounds
        NSLog(@"%s negative unreadable pos %.2f ",__func__,pos);
        
    } else {
        
        [self userTrackingComputeEditingLeftProgressAtPosition:pos];
    }

}


/*
 
 given a position pos
 convert to currentPositionSeconds
 fileReference calculateAtCurrentPosition in seconds
 if the result of that calculation is a valid readPositionInReferencedTrack
   then use it set positionInset to that
               set starttime currentPositionSeconds
               recognize the change editingTrackInsetChanged
 
 if the result of that calculation is an INVALID readPositionInReferencedTrack
    then consider the

 
 */

-(void)userTrackingComputeEditingLeftProgressAtPosition:(CGFloat)pos {
    
    // pos is greater or equal to zero
    float currentPositionSeconds = pos / _uiPointsPerSecondLength;
    
    // POS > 0 or Zero
    
    // Compute at current
    [_editFileReference calculateAtCurrentPosition:currentPositionSeconds];
    
    float trackReadPosition = _editFileReference.readPositionInReferencedTrack;
    
    if (trackReadPosition > 0){
        // we are still inside the track and interested to take action
        _editFileReference.startPositionInset = trackReadPosition;
        // TODO: turn on and off to change trackStartPosition or 'starttime' or delay
        _editFileReference.trackStartPosition = currentPositionSeconds;
        
        [self editingTrackInsetChanged];
        
    } else {
        // Outside track

        // trackReadPosition < 0
        float startPosition = _editFileReference.startPositionInReferencedTrack;
        float endPosition = _editFileReference.startPositionInReferencedTrack + _editFileReference.trackDuration;
        
        if (currentPositionSeconds > startPosition && currentPositionSeconds < endPosition) {
            
            // CHANGE startPositionInset trackStartPosition
            _editFileReference.startPositionInset = currentPositionSeconds - _editFileReference.startPositionInReferencedTrack;
            _editFileReference.trackStartPosition = _editFileReference.startPositionInset;
            
            [_editFileReference calculateAtCurrentPosition:currentPositionSeconds];
            
            [self editingTrackInsetChanged];
            
        } else {
            
            NSLog(@"%s CURRENTPOS  %.2f NOT in RANGE start %.2f to end %.2f secs",__func__,currentPositionSeconds,startPosition,endPosition);
        }
        
    }
    
}

-(void)userTrackingComputeEditingLeftProgressDebug {
    
    CGPoint offset = _scrollView.contentOffset;
    CGFloat pos = offset.x + self.scrollView.contentInset.left;
    float currentPositionSeconds = pos / _uiPointsPerSecondLength;
    
    if (pos < 0) {
        // NEGATIVE position in scrollview - read out of bounds
        NSLog(@"%s negative unreadable pos %.2f ",__func__,pos);
        
    } else {
        // POS > 0 or Zero
#ifdef DEBUGTRACE
        NSLog(@"%s pos %.2f (%.2f secs) startPosInset %.2f trackStartPos %.2f ",__func__,pos,currentPositionSeconds,
              _editFileReference.startPositionInset,
              _editFileReference.trackStartPosition);
#endif
        
        // Compute at current
        [_editFileReference calculateAtCurrentPosition:currentPositionSeconds];
        
        float trackReadPosition = _editFileReference.readPositionInReferencedTrack;

#ifdef DEBUGTRACE
        NSLog(@"%s pos %.2f (%.2f secs) trackReadPosition %.2f",__func__,pos,currentPositionSeconds,trackReadPosition);
//#else
//        NSLog(@"%s pos %.2f (%.2f secs) trackReadPosition %.2f",__func__,pos,currentPositionSeconds,trackReadPosition);
#endif
        
        if (trackReadPosition > 0){
            // we are still inside the track and interested to take action
            _editFileReference.startPositionInset = trackReadPosition;
            _editFileReference.trackStartPosition = currentPositionSeconds;
            
            [self editingTrackInsetChanged];
            
#ifdef DEBUGTRACE
            NSLog(@"%s pos %.2f (%.2f secs) trackReadPos %.2f startPosInset %.2f trackStartPos %.2f ",__func__,pos,currentPositionSeconds,trackReadPosition,
                  _editFileReference.startPositionInset,
                  _editFileReference.trackStartPosition);
#endif
        } else {
            // trackReadPosition < 0
#ifdef DEBUGTRACE
            NSLog(@"%s Less than ZERO - invalid track readPosition %.2f pos %.2f",__func__,trackReadPosition,pos);
            NSLog(@"%s startPosInReferencedTrack %.2f startPosInset %.2f trackStartPos %.2f ",__func__,
                  _editFileReference.startPositionInReferencedTrack,
                  _editFileReference.startPositionInset,
                  _editFileReference.trackStartPosition);
#endif
            
            float startPosition = _editFileReference.startPositionInReferencedTrack;
            float endPosition = _editFileReference.startPositionInReferencedTrack + _editFileReference.trackDuration;
            
            if (currentPositionSeconds > startPosition && currentPositionSeconds < endPosition) {
                
                // CHANGE startPositionInset trackStartPosition
#ifdef DEBUGTRACE
                NSLog(@"%s CURRENTPOS in RANGE %.2f [ %.2f - %.2f",__func__,currentPositionSeconds,startPosition,endPosition);
#endif
                _editFileReference.startPositionInset = currentPositionSeconds - _editFileReference.startPositionInReferencedTrack;
                _editFileReference.trackStartPosition = _editFileReference.startPositionInset;
                
                [_editFileReference calculateAtCurrentPosition:currentPositionSeconds];
                
                [self editingTrackInsetChanged];
                
#ifdef DEBUGTRACE
                NSLog(@"%s trackReadPos %.2f endPosInset %.2f trackStartPos %.2f ",__func__,trackReadPosition,
                      _editFileReference.endPositionInset,
                      _editFileReference.trackStartPosition);
#endif
                
            } else {
                
                NSLog(@"%s CURRENTPOS  %.2f NOT in RANGE start %.2f to end %.2f secs",__func__,currentPositionSeconds,startPosition,endPosition);
            }
            
        }
    }
    
#ifdef DEBUGTRACE
    NSLog(@"%s RESULT startPosInset %.2f trackStartPos %.2f pos %.2f (%.2f secs) ",__func__,
          _editFileReference.startPositionInset,
          _editFileReference.trackStartPosition,
          pos,currentPositionSeconds );
#endif
    
}

-(void)userTrackingComputeEditingRightProgressAtCurrentPosition {
    
    CGPoint offset = _scrollView.contentOffset;
    CGFloat pos = offset.x + self.scrollView.contentInset.left;
    if (pos < 0) {
        // NEGATIVE position in scrollview - read out of bounds
        NSLog(@"%s negative unreadable pos %.2f ",__func__,pos);
    } else {
        [self userTrackingComputeEditingLeftProgressAtPosition:pos];
    }
}


#define DEBUGTRACE
/*
 
 given a position pos
 convert to currentPositionSeconds
 fileReference calculateAtCurrentPosition in seconds
 if the result of that calculation is a valid readPositionInReferencedTrack
 then use it set positionInset to that
 set starttime currentPositionSeconds
 recognize the change editingTrackInsetChanged
 
 if the result of that calculation is an INVALID readPositionInReferencedTrack
 then consider the
-----
 
 given a position pos (we assume is greater or equal to zero)
 convert to currentPositionSeconds
 fileReference calculateAtCurrentPosition in seconds

 if the result of that calculation is a valid readPositionInReferencedTrack
 __then use it 
 ____set positionInset = trackDuration - readPositionInReferencedTrack
 ____recognize the change editingTrackInsetChanged

 
 */

-(void)userTrackingComputeEditingRightProgressAtPosition:(CGFloat)pos {
    
    float currentPositionSeconds = pos / _uiPointsPerSecondLength;
    
    NSLog(@"%s pos %.2f  secs %.2f ",__func__,pos,currentPositionSeconds);
    // POS > 0 or Zero
#ifdef DEBUGTRACE
    NSLog(@"pos %.2f (%.2f secs) startPosInset %.2f trackStartPos %.2f ",pos,currentPositionSeconds,
          _editFileReference.startPositionInset,
          _editFileReference.trackStartPosition);
#endif
    
    [_editFileReference calculateAtCurrentPosition:currentPositionSeconds];
    
    float trackReadPosition = _editFileReference.readPositionInReferencedTrack;
    
#ifdef DEBUGTRACE
    NSLog(@"pos %.2f (%.2f secs) trackReadPosition %.2f",pos,currentPositionSeconds,trackReadPosition);
#endif
    
    if (trackReadPosition > 0){
        // we are still inside the track and interested to take action
        
        _editFileReference.endPositionInset = _editFileReference.trackDuration - trackReadPosition;
        
        [self editingTrackInsetChanged];
        
        //_editFileReference.startPositionInset = trackReadPosition;
        //_editFileReference.trackStartPosition = currentPositionSeconds;
        
#ifdef DEBUGTRACE
        NSLog(@"pos %.2f (%.2f secs) trackReadPos %.2f endPosInset %.2f trackStartPos %.2f ",pos,currentPositionSeconds,trackReadPosition,
              _editFileReference.endPositionInset,
              _editFileReference.trackStartPosition);
#endif
        
    } else {
        
        // Outside the track
        // trackReadPosition < 0
#ifdef DEBUGTRACE
        NSLog(@"Less than ZERO - invalid track readPosition %.2f pos %.2f",trackReadPosition,pos);
        NSLog(@"startPosInReferencedTrack %.2f endPosInset %.2f trackStartPos %.2f ",
              _editFileReference.startPositionInReferencedTrack,
              _editFileReference.endPositionInset,
              _editFileReference.trackStartPosition);
#endif
        
        float startPosition = _editFileReference.startPositionInReferencedTrack;
        float endPosition = _editFileReference.startPositionInReferencedTrack + _editFileReference.trackDuration;
        
        if (currentPositionSeconds >= startPosition && currentPositionSeconds <= endPosition) {
#ifdef DEBUGTRACE
            NSLog(@"CURRENTPOS in RANGE %.2f ",currentPositionSeconds);
#endif
            
            _editFileReference.endPositionInset = endPosition - currentPositionSeconds;
            
            [_editFileReference calculateAtCurrentPosition:currentPositionSeconds];
            
            [self editingTrackInsetChanged];
            
#ifdef DEBUGTRACE
            NSLog(@"trackReadPos %.2f endPosInset %.2f trackStartPos %.2f ",trackReadPosition,
                  _editFileReference.endPositionInset,
                  _editFileReference.trackStartPosition);
#endif
            
        } else {
            NSLog(@"CURRENTPOS out of RANGE Start %.2f - %.2f ",startPosition,endPosition);
        }
        
    }
    
#ifdef DEBUGTRACE
    NSLog(@"%s RESULT pos %.2f (%.2f secs) endPosInset %.2f trackStartPos %.2f ",__func__,pos,currentPositionSeconds,
          _editFileReference.endPositionInset,
          _editFileReference.trackStartPosition);
    
#endif
    
}


#pragma mark - modify track

-(void)modifyTrack:(NSUInteger)track alpha:(CGFloat)alpha {
    [[NSNotificationCenter defaultCenter] postNotificationName:
     [NSString stringWithFormat:@"track%lunotification",(unsigned long)track]
                                                        object:self userInfo:@{@"alpha":@(alpha)}];
}

-(void)modifyTrack:(NSUInteger)track colors:(NSDictionary*)trackColors {
    [[NSNotificationCenter defaultCenter] postNotificationName:
     [NSString stringWithFormat:@"track%lunotification",(unsigned long)track]
                                                        object:self userInfo:@{@"colors":trackColors}];
}

-(void)modifyTrack:(NSUInteger)track colors:(NSDictionary*)trackColors alpha:(CGFloat)alpha {
    [[NSNotificationCenter defaultCenter] postNotificationName:
     [NSString stringWithFormat:@"track%lunotification",(unsigned long)track]
                                                        object:self userInfo:@{@"colors":trackColors,@"alpha":@(alpha)}];
}

-(void)modifyTrack:(NSUInteger)track pan:(CGFloat)panValue {
    [[NSNotificationCenter defaultCenter] postNotificationName:
     [NSString stringWithFormat:@"track%lunotification",(unsigned long)track]
                                                        object:self userInfo:@{@"pan":@(panValue)}];
}

-(void)modifyTrack:(NSUInteger)track volume:(CGFloat)volumeValue {
    _outputValue = volumeValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:[NSString stringWithFormat:@"track%lunotification",(unsigned long)track]
                                                        object:self userInfo:@{@"volume":@(volumeValue)}];
}

-(void)modifyTrack:(NSUInteger)track colors:(NSDictionary*)trackColors
             alpha:(CGFloat)alpha
            layout:(VABLayoutOptions)layoutOptions
              kind:(VABKindOptions)kindOptions
{
    NSString *notifString = [NSString stringWithFormat:@"track%lunotification",(unsigned long)track];
    [[NSNotificationCenter defaultCenter] postNotificationName:notifString object:self
                                                      userInfo:
     @{@"colors":trackColors,
       @"alpha":@(alpha),
       @"layout":@(layoutOptions),
       @"kind":@(kindOptions)
       }
     ];
}

-(void)modifyTrack:(NSUInteger)track colors:(NSDictionary*)trackColors
            layout:(VABLayoutOptions)layoutOptions
              kind:(VABKindOptions)kindOptions
{
    NSString *notifString = [NSString stringWithFormat:@"track%ldnotification",(unsigned long)track];
    [[NSNotificationCenter defaultCenter] postNotificationName:notifString object:self
                                                      userInfo:
     @{@"colors":trackColors,
       @"layout":@(layoutOptions),
       @"kind":@(kindOptions)
       }
     ];
}



#pragma mark -

-(void)adjustWhiteBacklightValue:(CGFloat)value {
    self.view.backgroundColor = [UIColor colorWithWhite:value alpha:1.0];
}

-(void)pulseRecording:(CGFloat)pulseStartValue endValue:(CGFloat)endValue duration:(CGFloat)duration {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.recordingProgressView setProgress:(pulseStartValue * .6) * .7 animated:YES];
    });
    double delayInSecs = duration;
//    NSLog(@"%3f",delayInSecs);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSecs * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.recordingProgressView setProgress:endValue * .7 animated:YES];
    });
}

//#define TRACEPULSE
/*
 */
-(void)pulseBackLight:(CGFloat)pulseStartValue endValue:(CGFloat)endValue duration:(CGFloat)duration {
    //    self.view.backgroundColor = [UIColor colorWithWhite:pulseStartValue alpha:1.0];
    
    if (_pulseBlocked == NO) {
        BOOL pulseControllerToo = YES;
       
#ifdef TRACEPULSE 
        NSLog(@"PULSE value %.3f dur %.3f",endValue,duration);
#endif
        endValue *= _outputValue;  // OUTPUTValue is factored in

        if (pulseControllerToo)
            self.view.superview.superview.backgroundColor = [UIColor colorWithWhite:endValue alpha:1.0];
        self.view.backgroundColor = [UIColor colorWithWhite:endValue alpha:1.0];
        
//        CGFloat durationFadeMax = 0.20;
        CGFloat durationFadeMax = duration * .75;

        double delayInSecs = duration * .25;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSecs * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [CATransaction begin];
            [CATransaction setAnimationDuration:durationFadeMax * endValue];
            if (pulseControllerToo)
                self.view.superview.superview.backgroundColor = [UIColor colorWithWhite:0 alpha:1.0];
            self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:1.0];
            [CATransaction commit];
            
        });
    }
}

-(void)pulseLight:(CGFloat)pulseStartValue endValue:(CGFloat)endValue duration:(CGFloat)duration {
    if (_pulseBlocked == NO) {
        endValue *= _outputValue;  // OUTPUTValue is factored in
        
        self.pulseBaseLayer.backgroundColor = [UIColor colorWithWhite:1.0 alpha:endValue].CGColor;
        CGFloat durationFadeMax = 0.20;
        double delayInSecs = duration;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSecs * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [CATransaction begin];
            [CATransaction setAnimationDuration:durationFadeMax * endValue];
            if (_pulseBlocked==NO) {
                self.pulseBaseLayer.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0].CGColor;

            }
            [CATransaction commit];
        });
    }
}

//        self.pulseBaseLayer.backgroundColor = [UIColor colorWithWhite:endValue+.08 alpha:1.0].CGColor;
//                self.pulseBaseLayer.backgroundColor = [UIColor colorWithWhite:.1 alpha:1.0].CGColor;


#pragma mark - transition to 


-(void)transitionToPlay {
    if (_usePulse)
        _pulseBlocked = NO;
    
    [CATransaction begin];
    [CATransaction setAnimationDuration:0.9];
//    _scrubberEffectsLayer.color1 = [[UIColor blueColor] colorWithAlphaComponent:0.5];
//    _scrubberEffectsLayer.color2 = [[UIColor blueColor] colorWithAlphaComponent:0.2];
//    [_scrubberEffectsLayer render];
//     [self drawGradientOptionPlayForView:_gradient frame:self.view.frame];
    [CATransaction commit];
    self.scrollView.userInteractionEnabled = NO;
    self.playHeadWindow.backgroundColor = [[UIColor cyanColor] colorWithAlphaComponent:0.09];
    _playHeadWindow.layer.borderColor = _playHeadWindow.backgroundColor.CGColor;

    UIColor *playPinColor= [[UIColor whiteColor] colorWithAlphaComponent:0.80];
    UIView *playHeadPin = [_playHeadWindow subviews][0];
    playHeadPin.backgroundColor = playPinColor;
    
    _listenToScrolling = NO;
}

-(void)transitionToStopPlaying {
    if (_usePulse)
        _pulseBlocked=YES;
    
    [CATransaction begin];
    [CATransaction setAnimationDuration:0.8];
    [CATransaction commit];
    
    self.pulseBaseLayer.backgroundColor = [UIColor clearColor].CGColor;
    self.scrollView.userInteractionEnabled = YES;
    self.recordingProgressView.progress = 0.0;
    self.recordingProgressView.hidden = YES;
    self.playHeadWindow.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.10];
    _playHeadWindow.layer.borderColor = _playHeadWindow.backgroundColor.CGColor;

    UIColor *playPinColor= [[UIColor lightGrayColor] colorWithAlphaComponent:0.80];
    UIView *playHeadPin = [_playHeadWindow subviews][0];
    playHeadPin.backgroundColor = playPinColor;
    self.recordingBottomConstraint.constant = 0.0 + 6.0f;  // bottom height +
    
    _listenToScrolling = YES;
}

-(void)transitionToRecording {
    [self transitionToRecordingSingleRecorder:NO];
}

-(void)transitionToRecordingSingleRecorder:(BOOL)singleRecorder {
    if (_usePulse)
        _pulseBlocked = NO;
    
    [CATransaction begin];
    [CATransaction setAnimationDuration:1.2];
    [CATransaction commit];
    
    self.scrollView.userInteractionEnabled = NO;
    self.playHeadWindow.backgroundColor = [[UIColor cyanColor] colorWithAlphaComponent:0.09];
    _playHeadWindow.layer.borderColor = _playHeadWindow.backgroundColor.CGColor;

    UIColor *playPinColor= [[UIColor whiteColor] colorWithAlphaComponent:0.80];
    UIView *playHeadPin = [_playHeadWindow subviews][0];
    playHeadPin.backgroundColor = playPinColor;
    if (singleRecorder == NO){
        self.recordingProgressView.hidden = NO;
        CGSize size = [_delegate viewSize];
        // track frame
        CGRect tfr = [self frameForBuffer:_recordingTrack bufferWidth:0 allTracksHeight:size.height - _topLayoutScrollViewConstraint.constant ];
        self.recordingBottomConstraint.constant = _topLayoutScrollViewConstraint.constant + tfr.origin.y + CGRectGetHeight(tfr)/2;
    }
    
    _listenToScrolling = NO;
}

-(void)transitionToPlayTillEnd {

    [self.scrubberProgressView setProgress:0.0 animated:YES];

//    [self adjustGradientColorsBack];
}

-(void)transitionToPlayPreview {
    if (_usePulse)
        _pulseBlocked = YES;
    [CATransaction begin];
    [CATransaction setAnimationDuration:0.9];
    [CATransaction commit];
    self.scrollView.userInteractionEnabled = NO;
    
    _listenToScrolling = NO;
}

- (void)transitionToStopPlayPreview {
    self.scrollView.userInteractionEnabled = YES;
    _listenToScrolling = YES;
}


-(void)adjustGradientColorsBack {
    _headerLayer.color1 = [[UIColor blueColor] colorWithAlphaComponent:0.7];
    _headerLayer.color2 = [[UIColor blackColor] colorWithAlphaComponent:0.95];
    [CATransaction begin];
    [CATransaction setAnimationDuration:0.9];
    [_headerLayer render];
    [CATransaction commit];
    double delayInSecs = 0.5;
    //    NSLog(@"%3f",delayInSecs);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSecs * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIColor * hg1 = _headerColor1 ? _headerColor1 : [UIColor darkGrayColor];
        UIColor * hg2 = _headerColor2 ? _headerColor2 : [UIColor blackColor];
        _headerLayer.color1 = [hg1 colorWithAlphaComponent:1.0];
        _headerLayer.color2 = [hg2 colorWithAlphaComponent:0.81];
        [CATransaction begin];
        [CATransaction setAnimationDuration:.55];
        [_headerLayer render];
        [CATransaction commit];
    });
}

#pragma mark -

-(void)viewDidLayoutSubviews {
    if (_useGradient)
    {
        [self gradientConfiguration];
    }
}

// different gradient configurations

-(void)gradientConfiguration {

    CGRect sfr = self.scrollView.frame; // scroll vie wframe
    
    sfr.origin = CGPointZero;

    CGPoint gcenter = CGPointZero;
    CGRect plhGfr = CGRectZero;

    BOOL usesHue = (_hueColor != nil);

    BOOL needsRectUpdate = NO;
    if (CGRectEqualToRect(_lastRect, sfr)) {
        if (usesHue && _hueNeedsUpdate) {
            needsRectUpdate = YES;
            gcenter = self.scrollView.center;
            plhGfr = CGRectMake(0,0,CGRectGetWidth(self.playHeadWindow.frame),
                                CGRectGetHeight(self.playHeadWindow.frame));  // gradient frame
        }
        
    } else {
        needsRectUpdate = YES;
        gcenter = self.scrollView.center;

        _lastRect = sfr;

        plhGfr = CGRectMake(0,0,CGRectGetWidth(self.playHeadWindow.frame),
                            CGRectGetHeight(self.playHeadWindow.frame));  // gradient frame
    }
    
    
//    NSLog(@"%s %@ needsRectUpdate %@",__func__,NSStringFromCGRect(self.scrollView.frame),needsRectUpdate?@"YES":@"NO");

    if (_hueAndGradientsConfigured == NO) {
        needsRectUpdate = YES;

        // HEADER
        if (_headerLayer == nil) {
            JWScrubberGradientLayer *headerLayer =
            [[JWScrubberGradientLayer alloc] initWithKind:JWScrubberGradientKindTopToBottom];
//            UIColor * hg1 = _headerColor1 ? _headerColor1 : [UIColor blueColor];
//            UIColor * hg2 = _headerColor2 ? _headerColor2 : [UIColor greenColor];
//            UIColor * hg1 =  [UIColor blueColor];
//            UIColor * hg2 =  [UIColor greenColor];
            UIColor * hg1 = _headerColor1 ? _headerColor1 : [UIColor darkGrayColor];
            UIColor * hg2 = _headerColor2 ? _headerColor2 : [UIColor blackColor];

            headerLayer.color1 = [hg1 colorWithAlphaComponent:1.0];
            headerLayer.color2 = [hg2 colorWithAlphaComponent:0.81];
            headerLayer.breakingPoint1 = .15;
            self.headerLayer = headerLayer;
        }
        
        // HUE
        if (usesHue && _hueLayer == nil) {
            JWScrubberGradientLayer *hueLayer =  [[JWScrubberGradientLayer alloc] initWithKind:JWScrubberGradientKindTopToBottom];
            hueLayer.breakingPoint1 = .10;
            _hueNeedsUpdate = YES; // configure colors below
            self.hueLayer = hueLayer;
        }

        // TRACK GRADIENT
        if (_useTrackGradient && _trackGradients == nil) {

            _trackGradients = [@[] mutableCopy];
            
            for (int i = 0 ; i<_numberOfTracks;i++) {
                JWScrubberGradientLayer *effectsLayer =
                [[JWScrubberGradientLayer alloc] initWithKind:JWScrubberGradientKindCenteredBreaking];
                effectsLayer.color1 = _trackGradientColor1 ? _trackGradientColor1 : [UIColor blackColor];
                effectsLayer.color2 = _trackGradientColor2 ? _trackGradientColor2 : [[UIColor blackColor] colorWithAlphaComponent:0.8];
                effectsLayer.color3 = _trackGradientColor3 ? _trackGradientColor3 : [UIColor clearColor];

//                effectsLayer.breakingPoint1 = 0.12f;
//                effectsLayer.breakingPoint2 = 0.35;  // allows .30  to include spread at .50
//                effectsLayer.centeredBreakingCenterSpread = 0.09f;  // prob should be less than opening in pulseLayer

                effectsLayer.breakingPoint1 = 0.30f;
                effectsLayer.breakingPoint2 = 0.40;  // allows .30  to include spread at .50
                effectsLayer.centeredBreakingCenterSpread = 0.08f;  // prob should be less than opening in pulseLayer

                [_trackGradients addObject:effectsLayer];
            }
        }
        
        // PULSE LAYER
        if (_usePulse && _pulseBaseLayer == nil) {
            // PULSE BASE LAYER
            // an effects layer is added below so the clip from pulsse layer will be softened
            // Use CenteredBreaking to control amount of fuzz
            
            JWScrubberGradientLayer *pulseEffectsLayer =  (JWScrubberGradientLayer*)[CALayer new];
            
            // Whatever was used to build hue Layer
            //pulseEffectsLayer =  [[JWScrubberPulseGradientLayer alloc] initWithKind:JWScrubberGradientKindTopToBottom];
            pulseEffectsLayer.color1 = [[UIColor blueColor] colorWithAlphaComponent:0.8];  // lighter
            pulseEffectsLayer.color2 = [[UIColor blueColor] colorWithAlphaComponent:0.4];  // lighter
            pulseEffectsLayer.breakingPoint1 = .30;
            
            self.pulseBaseLayer = pulseEffectsLayer;
        }
        
        // ADD THE GRADIENTS
        
        if (_usePulse) {
            [self.view.layer insertSublayer:_pulseBaseLayer atIndex:0];
        }
        
        if (_useTrackGradient) {
            for (id gradient in _trackGradients) {
                [self.view.layer insertSublayer:gradient atIndex:0];
            }
        }
        
        if (usesHue) {
            [self.view.layer insertSublayer:_hueLayer atIndex:0];
        }

        [self.view.layer insertSublayer:_headerLayer atIndex:0];

        _hueAndGradientsConfigured = YES;
    }
    
    if (usesHue && _hueNeedsUpdate) {
        UIColor * hg1 = _hueGradientColor1 ? _hueGradientColor1 : _hueColor;
        UIColor * hg2 = _hueGradientColor2 ? _hueGradientColor2 : _hueColor;
        _hueLayer.color1 = [hg1 colorWithAlphaComponent:0.6];
        _hueLayer.color2 = [hg2 colorWithAlphaComponent:0.3];
        _hueLayer.breakingPoint1 = .30;
        _hueNeedsUpdate = NO;
    }

    
    if (needsRectUpdate) {
        
        CGSize sz = [_delegate viewSize];
        sfr.size.height = sz.height - _topLayoutScrollViewConstraint.constant;
        
//        NSLog(@"%s needs rect update",__func__);
        if (_usePulse) {
            _pulseBaseLayer.frame = plhGfr;
            [_pulseBaseLayer render];
            _pulseBaseLayer.position = gcenter;
        }
        
        if (_useTrackGradient) {
            for (int i = 0 ; i<_numberOfTracks;i++) {
                // GET the frame for the track
                CGRect trect = [self frameForTrack:i+1 allTracksHeight:sz.height];
                // Remember the Y
                CGFloat trackY = trect.origin.y + _topLayoutScrollViewConstraint.constant;
                
                trect.origin = CGPointZero;
                trect.size.width = CGRectGetWidth(sfr);

//                trect.size.height = CGRectGetHeight(sfr) - _topLayoutScrollViewConstraint.constant;

                [(CALayer*)_trackGradients[i] setFrame:trect];
                [(JWScrubberGradientLayer*)_trackGradients[i] render];
                [(CALayer*)_trackGradients[i] setPosition:CGPointMake(CGRectGetWidth(trect)/2, trackY + CGRectGetHeight(trect)/2)];
            }
        }
        
        if (usesHue) {
            _hueLayer.frame = sfr;
            [_hueLayer render];
            _hueLayer.position = gcenter;
        }
        
        if (_headerLayer) {
            CGRect hfr = sfr;
            hfr.size.height = _topLayoutScrollViewConstraint.constant;
            hfr.origin = CGPointZero;
            CGPoint hcenter = gcenter;
            hcenter.y = _topLayoutScrollViewConstraint.constant/2;
            _headerLayer.frame = hfr;
            [_headerLayer render];
            _headerLayer.position = hcenter;
        }
    }
}

//            NSLog(@"_headerLayer %@",NSStringFromCGRect(hfr));
//            NSLog(@"_headerLayer %@",NSStringFromCGPoint(hcenter));

#pragma mark - Configure Edit Layer / BOOK End Clips

-(void)configureEditLayer {
    CGSize size = [_delegate viewSize];
    [self configureEditLayer:size];
}

-(void)configureEditLayer:(CGSize)size {
    
    if (_editType == ScrubberEditLeft ){
        [self configureEditLayerLeft:size];
    } else if (_editType == ScrubberEditStart ||  _editType == ScrubberEditRight ) {
        [self configureEditLayerRight:size];
    }
    
    [self.view bringSubviewToFront:self.playHeadWindow];
}

-(void)configureEditLayerLeft:(CGSize)size {
    CGRect fr = CGRectZero;
    // fr starts at full view
    fr = CGRectMake(0, 0,
                    size.width/2 ,
                    size.height - _topLayoutScrollViewConstraint.constant );
    // adjust to track frame
    CGRect tfr = [self frameForTrack:_editTrack allTracksHeight:size.height];
    fr.origin.y = _topLayoutScrollViewConstraint.constant + tfr.origin.y;
    fr.size.height = tfr.size.height;
    if (_editLayerLeft == nil) {
        _editLayerLeft = [UIView new];
        _editLayerLeft.backgroundColor = [UIColor iosOceanColor];
        _editLayerLeft.clipsToBounds = YES;
        _editLayerLeft.userInteractionEnabled = NO;
        [self.view addSubview:_editLayerLeft];
        [self clipButtonViewLeft:fr];
    }
    _editLayerLeft.frame = fr;
}

-(void)configureEditLayerRight:(CGSize)size {
    CGRect fr = CGRectZero;
    // fr starts at full view
    fr = CGRectMake(size.width/2, 0,
                    size.width/2 ,
                    size.height - _topLayoutScrollViewConstraint.constant );
    // adjust to track frame
    CGRect tfr = [self frameForTrack:_editTrack allTracksHeight:size.height];
    fr.origin.y = _topLayoutScrollViewConstraint.constant + tfr.origin.y;
    fr.size.height = tfr.size.height;
    if (_editLayerRight == nil) {
        _editLayerRight = [UIView new];
        _editLayerRight.backgroundColor = [UIColor iosOceanColor];
        _editLayerRight.clipsToBounds = YES;
        _editLayerRight.userInteractionEnabled = NO;
        [self.view addSubview:_editLayerRight];
        [self clipButtonViewRight:fr];
    }
    _editLayerRight.frame = fr;
}


-(void)clipButtonViewRight:(CGRect)fr {
    [self clipButtonView:fr left:NO];
}

-(void)clipButtonViewLeft:(CGRect)fr {
    [self clipButtonView:fr left:YES];
}

-(void)clipButtonView:(CGRect)fr left:(BOOL)isLeft {
    
    CGRect bpfr = fr;
    // BUTTON VIEW PANEL
    UIView *buttonPanelView = [UIView new];
    // Square to frame
    bpfr.size.width = 0.40 * CGRectGetWidth(fr);
    if (isLeft)
        bpfr.origin.x = 0.0;
    else
        bpfr.origin.x = fr.origin.x + 0.60 * CGRectGetWidth(fr);

    buttonPanelView.backgroundColor = [UIColor iosTungstenColor];
    CGFloat h = CGRectGetHeight(bpfr) * .750;
    CGFloat xInset = 4;
    bpfr = CGRectInset(bpfr, xInset, (CGRectGetHeight(bpfr) - h) /2);
    buttonPanelView.layer.cornerRadius = 6.0;
    buttonPanelView.layer.borderColor = [UIColor iosSilverColor].CGColor;
    buttonPanelView.layer.borderWidth = 1.2;
    if (isLeft)
        bpfr.origin.x = bpfr.origin.x - buttonPanelView.layer.cornerRadius - xInset;
    else
        bpfr.origin.x = bpfr.origin.x +  buttonPanelView.layer.cornerRadius + xInset;

    buttonPanelView.frame = bpfr;

    // BUTTON
    CGRect bfr = bpfr;
    bfr.origin = CGPointZero;
    UIButton *clipButton = [UIButton buttonWithType:UIButtonTypeCustom];
    clipButton.frame = bfr;
    [clipButton setTitle:@"Clip" forState:UIControlStateNormal];
    [clipButton setTitleColor:[UIColor iosMercuryColor] forState:UIControlStateNormal];
    [clipButton addTarget:self action:@selector(clipButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [buttonPanelView addSubview:clipButton];
    _editClipButton = buttonPanelView;
    [self.view addSubview:_editClipButton];
}


//    NSLog(@"%s %@",__func__,NSStringFromCGSize(size));

// NSLog(@"%s %@",__func__,NSStringFromCGRect(fr));
//        _editLayerLeft.backgroundColor = [UIColor blueColor];
//        _editLayerLeft.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:0.40];
//        _editLayerLeft.backgroundColor = [UIColor darkGrayColor];
//        _editLayerLeft.backgroundColor = [UIColor blueColor];
//        _editLayerRight.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:0.42];
//        _editLayerRight.backgroundColor = [UIColor darkGrayColor];


-(void)configureBookendClips:(CGSize)size {
    
//    NSLog(@"%s %@",__func__,NSStringFromCGSize(size));

    CGRect fr = CGRectZero;
    
    CGFloat offsetToPlayhead = 5;
    
    fr = CGRectMake( -size.width + offsetToPlayhead , 0,
                    size.width + offsetToPlayhead,
                    size.height - _topLayoutScrollViewConstraint.constant );
    CGRect gfr = fr;

    if (_clipBegin == nil) {
        
        _clipBegin = [UIView new];
        self.gradientLeft = [[JWScrubberClipEndsLayer alloc] initWithKind:JWScrubberClipEndsKindLeft];
        // TODO whatEver the effects layer is using
        if (_trackGradientColor1)
            _gradientLeft.color = _trackGradientColor1;
        else
            _gradientLeft.color = [UIColor blackColor];

        _clipBegin.backgroundColor = [UIColor clearColor];
        [self.clipBegin.layer insertSublayer:_gradientLeft atIndex:0];
        [_scrollView addSubview:_clipBegin];
    }
    
    gfr = fr;
    gfr.origin = CGPointZero;
    _gradientLeft.frame = gfr;
    [_gradientLeft render];

    _clipBegin.frame = fr;

    fr = CGRectMake( [self largestTrackEndPosition] - offsetToPlayhead, 0,
                    size.width + offsetToPlayhead,
                    size.height - _topLayoutScrollViewConstraint.constant);
    
    if (_clipEnd == nil) {
        _clipEnd = [UIView new];
        self.gradientRight = [[JWScrubberClipEndsLayer alloc] initWithKind:JWScrubberClipEndsKindRight];
        if (_trackGradientColor1)
            _gradientRight.color = _trackGradientColor1;
        else
            _gradientRight.color = [UIColor blackColor];

        _clipEnd.backgroundColor = [UIColor clearColor];
        [self.clipEnd.layer insertSublayer:_gradientRight atIndex:0];
        [_scrollView addSubview:_clipEnd];
    }
    gfr = fr;
    gfr.origin = CGPointZero;
    _gradientRight.frame = gfr;
    [_gradientRight render];

    _clipEnd.frame = fr;
    
    [self.scrollView setNeedsLayout];
}


#pragma mark - Select Deselect Track

-(void)deSelectTrack {
    if (_selectedTrack > 0 ) {
        // DESELECT if SELECTED
//        [self modifyTrack:_selectedTrack colors:self.userProvidedColorsAllTracks];
        [self modifyTrack:_selectedTrack colors:[_delegate trackColorsForTrack:_selectedTrack]];
        _selectedTrack = 0;
    }
}

-(void)selectTrack:(NSUInteger)track {
    
    if (_editType == ScrubberEditNone) {
        NSUInteger touchTrack = track;
        if (touchTrack > 0) {
            [self modifyTrack:_selectedTrack colors:self.userProvidedColorsAllTracks];
            [self modifyTrack:touchTrack colors:
             @{
               JWColorScrubberTopPeak : [[UIColor orangeColor] colorWithAlphaComponent:0.6],
               JWColorScrubberTopAvg : [[UIColor orangeColor] colorWithAlphaComponent:0.4],
               JWColorScrubberBottomAvg : [[UIColor orangeColor] colorWithAlphaComponent:0.4],
               JWColorScrubberBottomPeak : [[UIColor orangeColor] colorWithAlphaComponent:0.6],
               JWColorScrubberTopPeakNoAvg : [[UIColor orangeColor] colorWithAlphaComponent:0.8],
               JWColorScrubberBottomPeakNoAvg : [[UIColor orangeColor] colorWithAlphaComponent:0.8],
               }];
            
            _selectedTrack = touchTrack;
        }
    } else {
        // EDITING
    }
    
}

-(void) bouncePlayhead {
    
    CATransform3D scaleTrans = CATransform3DMakeScale(1.1, 1.0, 1.0);
    UIColor *playHColor;
    UIColor *playPinColor;
    if ([_delegate isPlaying]) {
        playHColor= [[UIColor cyanColor] colorWithAlphaComponent:0.09];
        playPinColor= [[UIColor whiteColor] colorWithAlphaComponent:0.80];

    } else {
        playHColor = [[UIColor redColor] colorWithAlphaComponent:0.10];
        playPinColor= [[UIColor lightGrayColor] colorWithAlphaComponent:0.80];
    }

    UIView *playHeadPin = [_playHeadWindow subviews][0];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        _playHeadWindow.alpha = 1.0;
        [UIView animateWithDuration:.250f delay:0.0
                            options: UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             _playHeadWindow.transform = CATransform3DGetAffineTransform(scaleTrans);
                             //_playHeadWindow.layer.transform = scaleTrans;
                             _playHeadWindow.alpha = 0.55f;
                             //_playHeadWindow.backgroundColor = [[UIColor greenColor] colorWithAlphaComponent:0.5];
                             playHeadPin.backgroundColor = playPinColor;
                         } completion:^(BOOL fini){
                             
                             [UIView animateWithDuration:.150f delay:0.00
                                                 options: UIViewAnimationOptionCurveEaseIn
                                              animations:^{
                                                  _playHeadWindow.transform = CATransform3DGetAffineTransform(CATransform3DIdentity);
                                                  //_playHeadWindow.layer.transform = CATransform3DIdentity;
                                                  _playHeadWindow.alpha = 1.0;
                                                  _playHeadWindow.backgroundColor = playHColor;

                                                  //_playHeadWindow.backgroundColor = restoreColor;

                                              } completion:^(BOOL fini){
                                              }];

                         }];
        
//        _playHeadWindow.transform = CATransform3DGetAffineTransform(CATransform3DIdentity);

    });
}

- (IBAction)didTap:(id)sender {
    
    UITapGestureRecognizer *tap = (UITapGestureRecognizer *)sender;
    
    CGPoint phTouchPoint = [tap locationInView:self.playHeadWindow];

    BOOL isStatusFrameTouch = NO;
    BOOL isPlayheadTouch = NO;

    
    /*
     check for PLAY HEAD touch, first. Then check for STATUS FRAME touch, and last check select track
     */
    if (CGRectContainsPoint(_playHeadWindow.bounds, phTouchPoint)){
        isPlayheadTouch = YES;
        [_delegate playHeadTapped];
        [self bouncePlayhead];
        
    } else {
        
        CGFloat progress = 0.0;

        if (_listenToScrolling) {
            CGPoint touchPoint = [tap locationInView:self.view];
            CGSize size = self.view.bounds.size;
            size.height = self.topLayoutScrollViewConstraint.constant;
            CGRect statusFrame = CGRectZero;
            statusFrame.size = size;
            if (CGRectContainsPoint(statusFrame, touchPoint))
                isStatusFrameTouch = YES;
            
            if (isStatusFrameTouch) {
                CGFloat padding = 25;
                CGFloat virtualX = touchPoint.x;
                if (isStatusFrameTouch) {
                    progress = touchPoint.x/size.width;
                    if (virtualX > size.width - padding) {
                        virtualX = (size.width - (2*padding));
                        virtualX -= 0.01;
                    } else if (virtualX < padding) {
                        virtualX = 0;
                    } else {
                        virtualX -= padding;
                    }

                    progress = virtualX / (size.width - (2*padding));

                }
                
            }
        }
        
        if (isStatusFrameTouch) {
            _vTrackLength = [self largestTrackEndPosition];
            NSLog(@"progress %.4f",progress);
            CGFloat pos = progress * ([self largestTrackEndPosition] -  self.scrollView.contentInset.left) / _uiPointsPerSecondLength;
            [self scrollViewTrackingAtPosition:pos];
            [self.scrubberProgressView setProgress:progress animated:NO];
            //            [self trackScrubberToProgress:progress timeAnimated:NO];
            [self trackScrubberToPostion:pos timeAnimated:NO animated:YES];
            
        } else {
            
            if (_editType == ScrubberEditNone) {
                // NOT EDITING
                CGPoint touchPoint = [tap locationInView:self.scrollView];
                NSUInteger touchTrack = 0;
                for (int i = 0; i < _numberOfTracks; i++){
                    if (CGRectContainsPoint([self frameForTrack:i+1 allTracksHeight:[_delegate viewSize].height], touchPoint)){
                        touchTrack = i+1;
                        break;
                    }
                }
                if (touchTrack > 0) {
                    if (_selectedTrack == touchTrack) {
                        // DESELECT if SELECTED
                        [self deSelectTrack];
                        [_delegate trackNotSelected];
                    } else {
                        // SELECT TRACK
                        [self selectTrack:touchTrack];
                        [_delegate trackSelected:_selectedTrack];
                    }
                }
            }
        }
    }
    
}

- (IBAction)didLongPress:(id)sender {
    NSLog(@"%s",__func__);
    UILongPressGestureRecognizer *longPress = (UILongPressGestureRecognizer *)sender;
    CGPoint touchPoint = [longPress locationInView:self.view];
    CGSize size = self.view.bounds.size;

    size.height = self.topLayoutScrollViewConstraint.constant;
    BOOL isStatusFrameTouch = NO;
    CGRect statusFrame = CGRectZero;
    statusFrame.size = size;
    if (CGRectContainsPoint(statusFrame, touchPoint))
        isStatusFrameTouch = YES;
    
    CGFloat progress = 0.0;
    if (isStatusFrameTouch) {
        progress = touchPoint.x/size.width;
    }
    
    if (longPress.state == UIGestureRecognizerStateBegan) {
        if (isStatusFrameTouch) {
            NSLog(@"%s SFT BEGAN progress %.3f",__func__,progress);
            _vTrackLength = [self largestTrackEndPosition];
            CGFloat pos = progress * ([self largestTrackEndPosition] -  self.scrollView.contentInset.left) / _uiPointsPerSecondLength;
            [self scrollViewTrackingAtPosition:pos];
            [self.scrubberProgressView setProgress:progress animated:NO];
            [self trackScrubberToPostion:pos timeAnimated:NO animated:YES];
        }
        
    } else if (longPress.state == UIGestureRecognizerStateEnded) {
        
        NSLog(@"%s SFT ENDED",__func__);
    } else if (longPress.state == UIGestureRecognizerStateChanged) {
        
        if (isStatusFrameTouch) {
            CGFloat pos = progress * ([self largestTrackEndPosition] -  self.scrollView.contentInset.left) / _uiPointsPerSecondLength;
            NSLog(@"%s SFT CHANGED  pos %.3f progress %.3f",__func__,pos,progress);
        }
        
    }
    
}


//    return;
//
//    if (_editType == ScrubberEditNone) {
//        UILongPressGestureRecognizer *longPress = (UILongPressGestureRecognizer *)sender;
//
//        if (longPress.state == UIGestureRecognizerStateBegan) {
//            NSLog(@"%s BEGAN",__func__);
//            CGPoint touchPoint = [longPress     locationInView:self.scrollView];
//
//            CGSize size = [_delegate viewSize];
//
//            NSUInteger touchTrack = 0;
//            for (int i = 0; i < _numberOfTracks; i++){
//                CGRect trackFrame = [self frameForTrack:i+1 allTracksHeight:size.height];
//                if (CGRectContainsPoint(trackFrame, touchPoint)){
//                    touchTrack = i+1;
//                    break;
//                }
//            }
//
//            if (touchTrack > 0) {
//                NSLog(@"%s TRACK %lu TOUCHED",__func__,(unsigned long)touchTrack);
//                //[self modifyTrack:touchTrack alpha:0.3];
//                if (_selectedTrack == touchTrack) {
//                    // DESELECT if SELECTED
//                    [self deSelectTrack];
//                    [_delegate trackNotSelected];
//
//                } else {
//                    // SELECT TRACK
//                    [self selectTrack:touchTrack];
//                    [_delegate trackSelected:_selectedTrack];
//                }
//
//                [_delegate longPressOnTrack:touchTrack];
//
//
//            }
//
//        } else if (longPress.state == UIGestureRecognizerStateEnded) {
//            NSLog(@"%s ENDED",__func__);
//        } else if (longPress.state == UIGestureRecognizerStateChanged) {
//            NSLog(@"%s CHANGED",__func__);
//        }
//
//        NSLog(@"%s scrollView %@  view %@",__func__,NSStringFromCGPoint([longPress locationInView:self.scrollView]),
//              NSStringFromCGPoint([longPress locationInView:self.view]));
//
//    } else {
//        // EDITING
//    }


- (IBAction)didDoubleTap:(id)sender {
    
    NSLog(@"%s",__func__);
    UITapGestureRecognizer *tap = (UITapGestureRecognizer *)sender;
    NSLog(@"%s scrollView %@  view %@",__func__,NSStringFromCGPoint([tap locationInView:self.scrollView]),
          NSStringFromCGPoint([tap locationInView:self.view]));
    
    //    self.topLayoutScrollViewConstraint.constant = 38; // just below numbers
    //    NSLog(@"%s %.2f",__func__,self.topLayoutScrollViewConstraint.constant);
    
    CGPoint touchPoint = [tap locationInView:self.scrollView];
    CGSize size = [_delegate viewSize];
    NSUInteger touchTrack = 0;
    for (int i = 0; i < _numberOfTracks; i++){
        CGRect trackFrame = [self frameForTrack:i+1 allTracksHeight:size.height];
        if (CGRectContainsPoint(trackFrame, touchPoint)){
            touchTrack = i+1;
            break;
        }
    }
    
    if (touchTrack > 0) {
        NSLog(@"%s TRACK %lu TOUCHED",__func__,(unsigned long)touchTrack);
//        [self modifyTrack:touchTrack alpha:0.3];
    }

}

- (IBAction)didRotation:(id)sender {
    
    UIRotationGestureRecognizer *gesture = (UIRotationGestureRecognizer *)sender;
    
    CGFloat adjustedValue = 0.0;
    if (gesture.state == UIGestureRecognizerStateBegan) {
        NSLog(@"%s BEGAN",__func__);
    } else if (gesture.state == UIGestureRecognizerStateEnded) {
        NSLog(@"%s ENDED",__func__);
        //        [self adjustWhiteBacklightValue:0.5];
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        NSLog(@"%s CHANGED",__func__);
        if (gesture.rotation > 0 && gesture.rotation < 1.0) {
            adjustedValue = gesture.rotation;
        }
        [self adjustWhiteBacklightValue:adjustedValue];
    }
    NSLog(@"%s %.2f scrollView %@  view %@",__func__,gesture.rotation,NSStringFromCGPoint([gesture locationInView:self.scrollView]),
          NSStringFromCGPoint([gesture locationInView:self.view]));
    
}
- (IBAction)didPinch:(id)sender {
    
    UIPinchGestureRecognizer *gesture = (UIPinchGestureRecognizer *)sender;
    if (gesture.state == UIGestureRecognizerStateBegan) {
        NSLog(@"%s BEGAN",__func__);
    } else if (gesture.state == UIGestureRecognizerStateEnded) {
        NSLog(@"%s ENDED",__func__);
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        NSLog(@"%s CHANGED",__func__);
    }
    NSLog(@"%s %.2f scrollView %@  view %@",__func__,gesture.scale,NSStringFromCGPoint([gesture locationInView:self.scrollView]),
          NSStringFromCGPoint([gesture locationInView:self.view]));
    
    CATransform3D scaleTrans = CATransform3DMakeScale(gesture.scale,1.0, 1.0);
    self.scrollView.layer.transform = scaleTrans;
}

#pragma mark -

-(void)scaleBuffers {
    //    for (UIView *view in self.scrollView.subviews)
    //        [(JWScalingVisualAudioBufferView*)view setScale:_scale];
    //        [(JWScalingVisualAudioBufferView*)view scaleSamples];
    CGFloat trackPosition = _isScaled ?
    self.scrollView.bounds.origin.x/_scaleduiPointsPerSecondLength :
    self.scrollView.bounds.origin.x/_uiPointsPerSecondLength;
    // Layout the new scaled buffers
    // Reset content zero
    CGFloat currentPosition = 0.0f + CGRectGetWidth(self.scrollView.frame)/2;
    _vTrackLength = 0.0;
    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.scrollView.frame), CGRectGetHeight(self.scrollView.frame));
    // Resize each of the buffers per scale
    CGFloat pointsPerSecond = _isScaled ? _scaleduiPointsPerSecondLength : _uiPointsPerSecondLength;
    _scaleduiPointsPerSecondLength = (_uiPointsPerSecondLength * _scale);
    CGFloat contentSz = 0.0;
    for (UIView *view in self.scrollView.subviews)
    {
        CGFloat duration = CGRectGetWidth (view.frame)/ pointsPerSecond;
        CGFloat uiBufferSize = duration * _scaleduiPointsPerSecondLength;
        CGRect fr = view.frame;
        fr.size.width = uiBufferSize;
        fr.origin.x = currentPosition;
        view.frame = fr;
        currentPosition +=  uiBufferSize;
        _vTrackLength += uiBufferSize;
        contentSz += uiBufferSize;
        //        NSLog(@"%s  bufferw %@",__func__,NSStringFromCGRect(view.frame));
    }
    CGSize content = self.scrollView.contentSize;
    content.width += contentSz;
    self.scrollView.contentSize = content;
    for (UIView *view in self.scrollView.subviews){
        [(JWScalingVisualAudioBufferView*)view setScale:_scale];
        [(JWScalingVisualAudioBufferView*)view scaleSamples];
        [view setNeedsDisplay];
    }
    CGRect bounds = self.scrollView.bounds;
    bounds.origin.x = trackPosition * _scaleduiPointsPerSecondLength;
    self.scrollView.bounds = bounds;
    [self.scrollView setNeedsLayout];
    _isScaled = YES;
}


@end




//====================================================================
//
//====================================================================


