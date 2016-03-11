//
//  JWClipAudioViewController.m
//  JamWIthT
//
//  Created by JOSEPH KERR on 9/30/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

// from   JWPlayerViewController.m  the UI stuff

#import "JWClipAudioViewController.h"
#import "JWRecordJamViewController.h"
#import "JWClipAudioController.h"
#import "JWCurrentWorkItem.h"
#import "JWRangeSliderViewController.h"
#import "CERangeSlider.h"
#import "JWClipAudioHelperViewController.h"

#define MAX_INTERVAL_DISTANCE 60.0

@interface JWClipAudioViewController () <
UIPickerViewDelegate, UIPickerViewDataSource,JWClipAudioDelegate,JWRecordJamDelegate,
UIGestureRecognizerDelegate, AudioHelperDelegate
> {
    NSInteger _trackTimeInterval;
    float _5_secondsBeforeStartTime;
    float _startTime;
    float _endTime;
    NSUInteger selectedAmpImageIndex;
    BOOL _panning;
    BOOL _mayPan;
    BOOL _custom;
    BOOL _smart;
    BOOL _preview;

}
@property (strong, nonatomic) IBOutlet UIImageView *ampImageView;
@property (strong, nonatomic) IBOutlet UIView *sourceViewL;
@property (strong, nonatomic) IBOutlet UIView *sourceViewR;
@property (strong, nonatomic) IBOutlet UIView *rangeSliderContainer;
@property (nonatomic) JWClipAudioController *audioClipper;
@property (nonatomic) JWClipAudioHelperViewController *audioHelperLower;
@property (nonatomic) JWClipAudioHelperViewController *audioHelperUpper;
@property (nonatomic) NSString* testMP3FileURL;
@property (nonatomic) NSTimer* playerTimer;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activity;
@property (strong, nonatomic) IBOutlet UISlider *currentTrackStartTime;
@property (strong, nonatomic) IBOutlet UIProgressView *songProgress;
@property (strong, nonatomic) IBOutlet UIProgressView *clipProgressBar;
@property (strong, nonatomic) IBOutlet UILabel *trackNameDisplay;
@property (strong, nonatomic) IBOutlet UIPickerView *secondsPicker;
@property (strong, nonatomic) IBOutlet UIButton *jamButton;
@property (strong, nonatomic) IBOutlet UIButton *secondLeft;
@property (strong, nonatomic) IBOutlet UIButton *secondRight;
@property (strong, nonatomic) IBOutlet UIButton *replayButton;
@property (strong, nonatomic) IBOutlet UIButton *snapToPositionButton;
@property (strong, nonatomic) IBOutlet UIColor *viewStartColor;
@property (strong, nonatomic) IBOutlet UISlider *volumeSlider;
@property (nonatomic) JWRangeSliderViewController *rsvc;
@property (nonatomic) CERangeSlider *rangeSlider;
@end


@implementation JWClipAudioViewController


#pragma mark - View and Navigation

-(void)viewDidLoad {
    
    _viewStartColor = self.view.backgroundColor;
    
    [super viewDidLoad];
    [self.activity stopAnimating];
    [self initAVAudioSession];
    self.activity.transform = CATransform3DGetAffineTransform(CATransform3DMakeScale(3.0, 3.0, 1.0));
    self.songProgress.progress = 0.0f;
    self.songProgress.layer.opacity = 0.85f;
    self.songProgress.layer.transform = CATransform3DMakeScale(1.0, 7.4, 1.0);
    self.clipProgressBar.progress = 1.0f;
    self.clipProgressBar.layer.opacity = 0.75f;
    self.clipProgressBar.layer.transform = CATransform3DMakeScale(1.0, 10.4, 1.0);

    self.audioHelperLower.delegate = self;
    self.audioHelperUpper.delegate = self;
    self.rsvc.preview = YES;
    self.rangeSlider = self.rsvc.rangeSlider;
    self.rangeSlider.trackHighlightColour = self.volumeSlider.minimumTrackTintColor;
    self.rangeSlider.trackOutsideColour = self.volumeSlider.maximumTrackTintColor;
    [self.rangeSlider addTarget:self action:@selector(sliderMoved:) forControlEvents:UIControlEventTouchUpInside];
    _trackTimeInterval = 1600;
    
    
    if (!_trackName)
        _trackName = @"Unknown Track Name";
    [self.trackNameDisplay setText:_trackName];
    self.secondsPicker.delegate = self;
    self.secondsPicker.dataSource = self;
    //[self.secondsPicker selectRow:1 inComponent:0 animated:YES];

    self.audioClipper = [JWClipAudioController new];
    _audioClipper.delegate = self;
    _audioClipper.sourceMP3FileURL = [NSURL fileURLWithPath:self.testMP3FileURL];
    [_audioClipper initializeAudioController];
    _volumeSlider.value = [_audioClipper volume];
    
    [self addNotifications];
    
    if (_thumbImage) {
        self.ampImageView.image = _thumbImage;
        self.ampImageView.layer.borderWidth = 4.2f;
        self.ampImageView.contentMode = UIViewContentModeScaleAspectFit;
        self.ampImageView.backgroundColor = [UIColor blackColor];
    }
    
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGesture:)];
    UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGesture:)];
    self.view.gestureRecognizers = @[panGestureRecognizer, longPressRecognizer, tapRecognizer];
    panGestureRecognizer.cancelsTouchesInView = NO;
    longPressRecognizer.cancelsTouchesInView = NO;
    tapRecognizer.cancelsTouchesInView = NO;
    
    _replayButton.layer.cornerRadius = 1.0;
    
    //[self.navigationController setToolbarHidden:YES];
    
    NSLog(@"%s",__func__);
}

-(void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [_audioClipper ummmStartPlaying];
    
//    [_clipProgressBar setProgress:0.0f animated:animated];
//    [_songProgress setProgress:0.0f animated:animated];

    if (! [self.playerTimer isValid])
        [self resumeTimer];
    
    // Set the background image on every appear
    selectedAmpImageIndex = [JWCurrentWorkItem sharedInstance].currentAmpImageIndex;
    if (_thumbImage) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.ampImageView.image = _thumbImage;
            [self.ampImageView setNeedsLayout];
        });
        
    } else {
        [self updateAmpImage];
    }
}

//            UIImage *ampImage = [UIImage imageNamed:[NSString stringWithFormat:@"jwjustscreensonly - %ld",selectedAmpImageIndex + 1]];
//            self.ampImageView.animationImages = @[_thumbImage,ampImage];
//            self.ampImageView.animationDuration=2.0f;
//            self.ampImageView.animationRepeatCount=1;
//            [self.ampImageView startAnimating];

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (self.isMovingFromParentViewController) {
        NSLog(@"%s LEAVING",__func__);
        [self.navigationController setToolbarHidden:YES];
        [_audioClipper killPlayer];
        
    } else {
        NSLog(@"%s STAYING",__func__);
        [_audioClipper ummmStopPlaying];
    }
    
    [self.playerTimer invalidate];
    
}



//    jwjustscreensonly - 2
//    jwjustscreensandlogos - 4
//    jwscreensandcontrols

-(void)updateAmpImage {
    UIImage *ampImage = [UIImage imageNamed:[NSString stringWithFormat:@"jwjustscreensonly - %lu",selectedAmpImageIndex + 1]];
    dispatch_async(dispatch_get_main_queue(), ^{
        _ampImageView.image = ampImage;
        [self.view setNeedsLayout];
    });
}

-(void)didSelectAmpImage:(NSNotification*)noti {
    //    NSLog(@"%s %@",__func__,[[noti userInfo] description]);
    NSNumber *selectedIndex = noti.userInfo[@"index"];
    if (selectedIndex) {
        selectedAmpImageIndex = [selectedIndex unsignedIntegerValue];
    }
    [self updateAmpImage];
}


#pragma make -

-(void)setThumbImage:(UIImage *)thumbImage {
    _thumbImage = thumbImage;
    if (_ampImageView) {
        _ampImageView.image = _thumbImage;
    }
}

#pragma make - GESTURES

-(void)panGesture:(id)sender{
    //NSLog(@"%s",__func__);
    UIPanGestureRecognizer *gesture = (UIPanGestureRecognizer *)sender;
    CGPoint loc;
    loc = [gesture locationInView:self.clipProgressBar];
    BOOL touchInRange = NO;
    if (loc.y < 2.0 && loc.y > -0.20) {
        touchInRange = YES;
    }
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        NSLog(@"%s BEGAN",__func__);
        if (touchInRange) {
            _mayPan = YES;
            dispatch_async(dispatch_get_main_queue(), ^{
                self.view.backgroundColor = [[UIColor yellowColor] colorWithAlphaComponent:0.7];
            });
            if (_playerTimer.isValid) {
                [self.playerTimer invalidate];
            }
        }
    } else if (gesture.state == UIGestureRecognizerStateEnded) {
        NSLog(@"%s ENDED",__func__);
        if (_mayPan) {
            _panning = NO;
            _mayPan = NO;
            dispatch_async(dispatch_get_main_queue(), ^{
                self.view.backgroundColor = _viewStartColor;
            });
            if ( ! _playerTimer.isValid) {
                [self resumeTimer];
            }
        }
    } else {
        
        // PANNING
        
        if (touchInRange && _mayPan) {
            _panning = YES;
            //NSLog(@"%s %@",__func__,NSStringFromCGPoint(loc));
            CGFloat progressInClip =  loc.x / _clipProgressBar.frame.size.width;
            double clipDuration = (_endTime - _startTime);
            double posInClip = clipDuration * progressInClip;
            double posInTrack = _startTime + posInClip;
            
            [_audioClipper seekToTime:posInTrack];
            
            // Change the progresses
            
            _clipProgressBar.progress = progressInClip;
            if ([_audioClipper timeIsValid]) {
                double duration = [_audioClipper duration];
                if (isfinite(duration) && (duration > 0)){
                    _songProgress.progress = posInTrack / duration;
                }
            }
        }
    }
    
}

-(void)longPress:(id)sender {
    
    UILongPressGestureRecognizer *longPress = (UILongPressGestureRecognizer*)sender;
    
    if (longPress.state == UIGestureRecognizerStateBegan) {
        if (self.rangeSlider.lowerKnobLayer.highlighted == YES) {
            NSLog(@"LONG PRESS ON KNOB.");
            if (self.rsvc.currentlyPanning == NO) {
                self.sourceViewL.hidden = NO;
                [self updatelabelsForChangeInPosition];
                [self.rsvc showLabels];
            }
            
            
        } else if (self.rangeSlider.upperKnobLayer.highlighted == YES) {
            NSLog(@"LONG PRESS ON KNOB.");
            if (self.rsvc.currentlyPanning == NO) {
                self.sourceViewR.hidden = NO;
                [self updatelabelsForChangeInPosition];
                [self.rsvc showLabels];
            }
            
            
        } else {
            
        }
    }
}

-(void)tapGesture:(id)sender {
    NSLog(@"tap herd");
    UITapGestureRecognizer *tap = (UITapGestureRecognizer *)sender;
    CGPoint tapPoint = [tap locationInView:self.view];
    
    
    if (self.sourceViewL.hidden == NO || self.sourceViewR.hidden == NO) {
        
        if (CGRectContainsPoint(self.sourceViewL.frame, tapPoint) || CGRectContainsPoint(self.sourceViewR.frame, tapPoint)) {
            NSLog(@"Tap occured at point %@, and is inside an unhidden container view, do nothing.", NSStringFromCGPoint(tapPoint));
        } else {
            //Tap occured outside a container when one was unhidden.  Hide container and carry on
            self.sourceViewL.hidden = self.sourceViewR.hidden = YES;
            [self.view setBackgroundColor:_viewStartColor];
        }
        
        
    } else {
        //Both are hidden, Nothing to change with the container views
        if (CGRectContainsPoint(self.rsvc.view.frame, tapPoint) || CGRectContainsPoint(self.rangeSliderContainer.frame, tapPoint)) {
            [self updatelabelsForChangeInPosition];
            [self.rsvc showHideLabels];
        }
        
    }
    
    
}


#pragma make -

-(void)effectsBackgroundLight {
    UIColor *cb = self.view.backgroundColor;
    self.view.backgroundColor =[UIColor colorWithWhite:1.0 alpha:1.0f];
    double delayInSecs = 0.45;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSecs * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.view.backgroundColor =cb;
    });
}

-(void)effectsBackgroundDark {
    UIColor *cb = self.view.backgroundColor;
    self.view.backgroundColor =[UIColor colorWithWhite:0.00f alpha:1.0f];
    double delayInSecs = 0.45;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSecs * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.view.backgroundColor =cb;
    });
}

-(BOOL)resumeTimer {
    BOOL result = NO;
    // find time remaining in Clip for this cycle
    NSTimeInterval currentPosInTrackSeconds;

    if ([_audioClipper timeIsValid]) {
        double duration = [_audioClipper duration];
        if (isfinite(duration) && (duration > 0)){
            currentPosInTrackSeconds = [_audioClipper trackProgress] * duration;
            
            NSTimeInterval timeInt = _endTime - currentPosInTrackSeconds;
            self.playerTimer =
            [NSTimer scheduledTimerWithTimeInterval:timeInt target:self selector:@selector(timerFireMethod:) userInfo:nil repeats:NO];

            NSLog(@"New TIMer at %.2f",timeInt);

            result = YES; // started the timer
        }
        
    } else {
        NSLog(@"invalid time");
    }

    return result;
}

-(NSString *)testMP3FileURL {
    
    if (!_testMP3FileURL) {
        
        //        NSString *path = [[NSBundle mainBundle] pathForResource:@"track5" ofType:@"mp3"];
        NSString *path = [[NSBundle mainBundle] pathForResource:@"track88" ofType:@"m4a"];
        
        NSURL *currentFileURL = [JWCurrentWorkItem sharedInstance].currentAudioFileURL;
        
        _testMP3FileURL = currentFileURL ? [currentFileURL path] : path;
    }
    return _testMP3FileURL;
}

-(void)addNotifications {
//    [self.currentTrackStartTime addTarget:self action:@selector(sliderValueMoved:) forControlEvents:UIControlEventValueChanged];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSelectAmpImage:) name:@"DidSelectAmpImage" object:nil];
}

-(void)timerFireMethod:(NSTimer *)timer {
    NSLog(@"%s ",__func__);
    
    if (timer.isValid) {
        _clipProgressBar.progress = 0.0f;
        [self sliderValueMoved:nil];
    }
}

-(void)upperPreviewOver:(NSTimer *)timer {
    
    if (timer.isValid) {
        [self sliderValueMoved:nil];
    }
}


#pragma mark - Clip Audio delegate

-(void)periodicUpdatesToPlayer {

    if (_panning)
    {
        return;
    }
    
    [self syncScrubber:_currentTrackStartTime];

    // log every so often, not all
    static int counter = 0;  // log counter
    if (counter > 10)
        counter = 0;
    if (counter == 0)
    {
        NSLog(@"%s",__func__);
    }
    counter++;

}

/*
    return;

    // The rest below is just fluff to change color foreffects
    // REST is just effects
    static int toggle = 1;  //
    static int toggleCounter = 0; //
    if (toggleCounter > 3)
        toggleCounter = 0;
    if (toggleCounter == 0) {
        CGFloat maxToggles = 7;
        if (toggle > maxToggles)
            toggle = 1;
        CGFloat alpha = toggle/maxToggles * 0.6f;
        self.view.backgroundColor = [_viewStartColor colorWithAlphaComponent:0.30 + alpha];
        toggle++;
        // lowest oocur
        if (toggleCounter <2){
            CGFloat alpha = toggle/maxToggles * 0.5f;
            dispatch_async(dispatch_get_main_queue(), ^{
                self.secondLeft.backgroundColor = [_viewStartColor colorWithAlphaComponent:0.50 + alpha];
                self.secondRight.backgroundColor = [_viewStartColor colorWithAlphaComponent:0.50 + alpha];
                //            self.jamButton.backgroundColor = [_viewStartColor colorWithAlphaComponent:0.50 + alpha];
            });
        }
        if (toggle == 2)
            [self effectsBackgroundLight];
    }
    toggleCounter++;
}
 */


// give all the info needed to this method observeValueForKeyPath AVPlayerStatusReadyToPlay
-(void)playerPlayStatusReady:(float)duration {
    
    NSLog(@"%s %.2f",__func__,duration);
    
    _rsvc.custom = NO;
    _smart = NO;
    [self.rangeSlider setMaxAllowedInterval:_trackTimeInterval usingDuration:duration];
    [self formatSliderForModeChange];
    [self.rsvc updateDuration];
    [self sliderValueMoved:nil];

}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"JWRangeSliderSegue"]) {
        self.rsvc = segue.destinationViewController;
    } else if ([segue.identifier isEqualToString:@"LowerHelperVCSegue"]) {
        self.audioHelperLower = segue.destinationViewController;
    } else if ([segue.identifier isEqualToString:@"UpperHelperVCSegue"]) {
        self.audioHelperUpper = segue.destinationViewController;
    }
}

#pragma mark - Actions

-(void)finishedTrimmingWithKey:(NSString*)key {

    [self.activity stopAnimating];

    if ([_delegate respondsToSelector:@selector(finishedTrim:withDBKey:)])
        [_delegate finishedTrim:self withDBKey:key];
}

-(void)exportAudioSection {
    
    [_audioClipper exportAudioSectionStart: _startTime
                                       end: _endTime
                         fiveSecondsBefore: _5_secondsBeforeStartTime withCompletion:^(NSString *key){
                             
                             [self finishedTrimmingWithKey:key];
                         }];
}

-(void)sliderMoved:(CERangeSlider *)sender {
    
    [self sliderValueMoved:sender];
    
}

- (void)sliderValueMoved:(id)sender {
    
    BOOL sliderToUse = _rangeSlider.dragOnLower;
    
    if (self.playerTimer) {
        [self.playerTimer invalidate];
    }
    
    if (_rsvc.custom) {
        
        _5_secondsBeforeStartTime = [self calculateBeforeTime:_rangeSlider.lowerValue withDuration:[_audioClipper duration]];
        _startTime = [self calculateTime:_rangeSlider.lowerValue];
        _endTime = [self calculateTime:_rangeSlider.upperValue];
        _trackTimeInterval = _endTime - _startTime;
        
        if (sliderToUse) {
            
            self.playerTimer =
            [NSTimer scheduledTimerWithTimeInterval:_trackTimeInterval target:self selector:@selector(timerFireMethod:) userInfo:nil repeats:NO];
            
            _clipProgressBar.progress = 0.0f;
            [_audioClipper seekToTime:(float)_startTime];
        } else {
           
            float timeInterval = 3.0;
            self.playerTimer = [NSTimer scheduledTimerWithTimeInterval:timeInterval target:self selector:@selector(upperPreviewOver:) userInfo:nil repeats:NO];
            
            float valueToPlayFrom = _endTime - timeInterval;
            [_audioClipper seekToTime:valueToPlayFrom];
        }
    } else {
        //Only control one slider by user
        _5_secondsBeforeStartTime = [self calculateBeforeTime:_rangeSlider.lowerValue withDuration:[_audioClipper duration]];
        _startTime = [self calculateTime:_rangeSlider.lowerValue];
        _endTime = _startTime + _trackTimeInterval;
        self.playerTimer =
        [NSTimer scheduledTimerWithTimeInterval:_trackTimeInterval target:self selector:@selector(timerFireMethod:) userInfo:nil repeats:NO];
        
        _clipProgressBar.progress = 0.0f;
        [_audioClipper seekToTime:(float)_startTime];

    }
    
    _rangeSlider.lowerKnobLayer.highlighted = NO;
    [_rangeSlider.lowerKnobLayer setNeedsDisplay];
    _rangeSlider.upperKnobLayer.highlighted = NO;
    [_rangeSlider.upperKnobLayer setNeedsDisplay];
    
    
    NSLog(@"Slider moved to start time %f, End time %f, with Five second time %f", _startTime, _endTime, _5_secondsBeforeStartTime);
    
}

-(void)formatSliderForModeChange {
    
    if (_rsvc.custom) {
        self.jamButton.enabled = YES;
    } else if (_rsvc.preview) {
        self.jamButton.enabled = NO;
    } else {
        _rangeSlider.lowerKnobLayer.enabled = YES;
        _rangeSlider.upperKnobLayer.enabled = NO;
        _rangeSlider.upperKnobLayer.hidden = NO;
        _rsvc.upperTimeCount.hidden = NO;
        self.jamButton.enabled = YES;
        [_rangeSlider redrawLayers];
    }
    
    
}



-(float)calculateBeforeTime:(float)fromTime withDuration:(float)duration {
 
    float fiveSecondValue = 5 / duration;
    float validTime = (fromTime - fiveSecondValue);
    
    //positive value is position
    if (validTime >= 0) {
        return validTime * duration;
    } else {
        //Negative value give positive position
        return 0;
    }
}

-(float)calculateTime:(float)fauxTime {
    
    float duration = [_audioClipper duration];
    return ((fauxTime - _rangeSlider.minimumValue) / (_rangeSlider.maximumValue - _rangeSlider.minimumValue)) * duration;
}

- (IBAction)replayButton:(id)sender {
    
    [self sliderMoved:self.rangeSlider];
}

- (IBAction)snapToPosition:(id)sender {
    
    float progress = [_audioClipper trackProgress];
    self.rangeSlider.lowerValue = progress;
    self.rangeSlider.upperValue = self.rangeSlider.lowerValue + (_trackTimeInterval / _rangeSlider.trackDuration);
    self.rangeSlider.dragOnLower = YES;
    [self updatelabelsForChangeInPosition];
    [self sliderMoved:self.rangeSlider];
    
}

- (void)syncScrubber:(UISlider *)sliderValue {
    
    if ([_audioClipper timeIsValid]){
        double duration = [_audioClipper duration];
        if (isfinite(duration) && (duration > 0))
        {
//            NSLog(@"Time : %.3f", [_audioClipper trackProgress]);
            
            [self.songProgress setProgress:[_audioClipper trackProgress] animated:YES];
        } else {
            NSLog(@"duration : %.3f", duration);
        }
    } else {
        NSLog(@"invld tm");
    }
    
    NSTimeInterval currentPosInTrackSeconds = [_audioClipper trackProgress] * _currentTrackStartTime.maximumValue;

    NSTimeInterval timeRemaining = _endTime - currentPosInTrackSeconds;

    [_clipProgressBar setProgress:(_trackTimeInterval - timeRemaining)/_trackTimeInterval animated:YES];
}

- (IBAction)jamButtonPressed:(UIButton *)sender {

    [self.playerTimer invalidate];
    [_audioClipper prepareToClipAudio];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.activity startAnimating];
    });
    [self exportAudioSection];
}

- (IBAction)volumeSliderChanged:(id)sender {
    
    [_audioClipper setVolume:[(UISlider*)sender value]];
}


#pragma mark - CLIP AUDIO HELPER DELEGATE

-(void)seekToPositionInSeconds:(NSUInteger)seconds {
    
    float trackDuration = self.rangeSlider.trackDuration;
    float currentIntervalBetween = self.rangeSlider.upperValue - self.rangeSlider.lowerValue;
    
    if (self.sourceViewL.hidden == NO) {
        
        if (seconds / trackDuration <= 1) {
            self.rangeSlider.lowerValue = seconds / trackDuration;
            self.rangeSlider.upperValue = self.rangeSlider.lowerValue + currentIntervalBetween;
            self.rangeSlider.dragOnLower = YES;
            self.sourceViewL.hidden = YES;
        }
        
    } else if (self.sourceViewR.hidden == NO) {
        
        if (seconds / trackDuration <= 1) {
            self.rangeSlider.upperValue = seconds / trackDuration;
            self.rangeSlider.lowerValue = self.rangeSlider.upperValue - currentIntervalBetween;
            self.rangeSlider.dragOnLower = NO;
            self.sourceViewR.hidden = YES;
        }
        
    }
    
    [self updatelabelsForChangeInPosition];
    [self sliderMoved:self.rangeSlider];
    
}

-(void)inchLeftPressed {
    
    if (self.sourceViewL.hidden == NO) {
        
        if (_rsvc.custom) {
            //Lower slider being changed lower, should check that against interval
            //Custom mode should check against interval value (dynamic range)
            if ([self valuesInRange]) {
                self.rangeSlider.lowerValue -= 1 / self.rangeSlider.trackDuration;
                self.rangeSlider.dragOnLower = YES;
            }

        } else {
          //Non custom mode means the range is fixed, just move both
            self.rangeSlider.lowerValue -= 1 / self.rangeSlider.trackDuration;
            self.rangeSlider.upperValue -= 1 / self.rangeSlider.trackDuration;
            self.rangeSlider.dragOnLower = YES;
        }
        
        
    } else if (self.sourceViewR.hidden == NO) {
        
        if (_rsvc.custom) {
            //Upper value being changed lower, should check to make sure value doesnt get
            //lower than lower value
            if (self.rangeSlider.upperValue >= self.rangeSlider.lowerValue) {
                self.rangeSlider.upperValue -= 1 / self.rangeSlider.trackDuration;
                self.rangeSlider.dragOnLower = NO;
            }
        } else {
            //this should never happen since custom mode is the only time one should
            //be able to drag/change the upper slider, but for consistency...
            self.rangeSlider.upperValue -= 1 / self.rangeSlider.trackDuration;
            self.rangeSlider.lowerValue -= 1 / self.rangeSlider.trackDuration;
            self.rangeSlider.dragOnLower = YES;
        }
        
    }
    
    [self updatelabelsForChangeInPosition];
    [self sliderMoved:self.rangeSlider];
    
}

-(void)inchRightPressed {
    
    if (self.sourceViewL.hidden == NO) {
        
        if (_rsvc.custom) {
            //lower value being changed upper, should check against upper value
            if (self.rangeSlider.lowerValue <= self.rangeSlider.upperValue) {
                self.rangeSlider.lowerValue += 1 / self.rangeSlider.trackDuration;
                self.rangeSlider.dragOnLower = YES;
            }
            
        } else {
            //Non custom mode means the range is fixed, just move both
            self.rangeSlider.lowerValue += 1 / self.rangeSlider.trackDuration;
            self.rangeSlider.upperValue += 1 / self.rangeSlider.trackDuration;
            self.rangeSlider.dragOnLower = YES;
        } 
        
        
    } else if (self.sourceViewR.hidden == NO) {
        
        if (_rsvc.custom) {
            //Upper value being changed upper, should be check against interval
            if ([self valuesInRange]) {
                self.rangeSlider.upperValue += 1 / self.rangeSlider.trackDuration;
                self.rangeSlider.dragOnLower = NO;
            }
        } else {
            //this should never happen since custom mode is the only time one should
            //be able to drag/change the upper slider, but for consistency...
            self.rangeSlider.upperValue += 1 / self.rangeSlider.trackDuration;
            self.rangeSlider.lowerValue += 1 / self.rangeSlider.trackDuration;
            self.rangeSlider.dragOnLower = YES;
        }
        
    }
    
    [self updatelabelsForChangeInPosition];
    [self sliderMoved:self.rangeSlider];
    
}

-(BOOL)valuesInRange {
    
    float testValue = (self.rangeSlider.upperValue - self.rangeSlider.lowerValue) + 1   / self.rangeSlider.trackDuration;
    if (testValue <= MAX_INTERVAL_DISTANCE / self.rangeSlider.trackDuration) {
        return YES;
    }
    
    return NO;
}

//TODO:implement this for better code readability.  Lots of lower and upper values
//being set everywhere
-(void)moveLowerLayerTo:(float)lowervalue upperLayerTo:(float)uppervalue {
    

    [self updatelabelsForChangeInPosition];
    
}


-(void)updatelabelsForChangeInPosition {
    
    [self.rangeSlider setLayerFrames];
    [self.rsvc updateLabelPositionForSeek];
    
}

#pragma mark - RECORD jam delegate

-(void)done {
    NSLog(@"%s",__func__);
    // TODO: need to reset the player and scrubber
}

-(void)doneGoAgain {
    NSLog(@"%s",__func__);
    [_audioClipper goAgain];
}

#pragma mark - PICKER

//-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
//    if (row == 0)
//        return @"15 Seconds";
//    else if (row == 1)
//        return @"30 Seconds";
//    else if (row == 2)
//        return @"45 Seconds";
//    else if (row == 3)
//        return @"1 Minute";
//    NSLog(@"Missed picker row or component");
//    return 0;
//}

-(NSAttributedString *)pickerView:(UIPickerView *)pickerView attributedTitleForRow:(NSInteger)row forComponent:(NSInteger)component {
    
    if (row == 0) {
        NSString *title = @"Preview Audio";
        NSAttributedString *attString = [[NSAttributedString alloc] initWithString:title attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
        return attString;
    } else if (row == 1) {
        NSString *title = @"15 Seconds";
        NSAttributedString *attString = [[NSAttributedString alloc] initWithString:title attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
        return attString;
    } else if (row == 2) {
        NSString *title = @"30 Seconds";
        NSAttributedString *attString = [[NSAttributedString alloc] initWithString:title attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
        return attString;
    } else if (row == 3) {
        NSString *title = @"Custom (1 Min Max)";
        NSAttributedString *attString = [[NSAttributedString alloc] initWithString:title attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
        return attString;
    } else if (row == 4) {
        NSString *title = @"Smart Mode";
        NSAttributedString *attString = [[NSAttributedString alloc] initWithString:title attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
        return attString;
    }
    NSLog(@"Missed picker row or component");
    return 0;
    
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    
    
    _smart = NO;
    _rsvc.preview = NO;
    _rsvc.custom = NO;
    
    if (row == 0) {
        _trackTimeInterval = 600;
        _rsvc.preview = YES;
    
    } else if (row == 1) {
        _trackTimeInterval = 15;
        
    } else if (row == 2) {
        _trackTimeInterval = 30;
        
    } else if (row == 3) {
        _trackTimeInterval = 60;
        _rsvc.custom = YES;
        
    } else if (row == 4) {
        _trackTimeInterval = 60;
        _smart = YES;
        
    }
    
    if ([_audioClipper duration]) {
        [self.rangeSlider setMaxAllowedInterval:_trackTimeInterval usingDuration:[_audioClipper duration]];
    }
    [self formatSliderForModeChange];
    [self updatelabelsForChangeInPosition];
    [self sliderValueMoved:nil];
}

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if (component == 0)
        return 5;
    return 0;
}

#pragma mark - AVAudioSession

- (void)initAVAudioSession {
    // For complete details regarding the use of AVAudioSession see the AVAudioSession Programming Guide
    // https://developer.apple.com/library/ios/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/Introduction/Introduction.html
    
    // Configure the audio session
    AVAudioSession *sessionInstance = [AVAudioSession sharedInstance];
    NSError *error;
    // set the session category
    bool success = [sessionInstance setCategory:AVAudioSessionCategoryPlayback
                                    withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker
                                          error:&error];
    
    if (!success) NSLog(@"Error setting AVAudioSession category! %@\n", [error localizedDescription]);
    
    double hwSampleRate = 44100.0;
    success = [sessionInstance setPreferredSampleRate:hwSampleRate error:&error];
    if (!success) NSLog(@"Error setting preferred sample rate! %@\n", [error localizedDescription]);
    
    NSTimeInterval ioBufferDuration = 0.0029;
    success = [sessionInstance setPreferredIOBufferDuration:ioBufferDuration error:&error];
    if (!success) NSLog(@"Error setting preferred io buffer duration! %@\n", [error localizedDescription]);
}


@end


