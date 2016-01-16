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


@interface JWClipAudioViewController () <
UIPickerViewDelegate, UIPickerViewDataSource,JWClipAudioDelegate,JWRecordJamDelegate,
UIGestureRecognizerDelegate
> {
    NSInteger _trackTimeInterval;
    float _5_secondsBeforeStartTime;
    float _startTime;
    float _endTime;
    NSUInteger selectedAmpImageIndex;
    BOOL _panning;
    BOOL _mayPan;

}
@property (strong, nonatomic) IBOutlet UIImageView *ampImageView;
@property (nonatomic) JWClipAudioController *audioClipper;
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
@property (strong, nonatomic) IBOutlet UIColor *viewStartColor;
@property (strong, nonatomic) IBOutlet UISlider *volumeSlider;
@end


@implementation JWClipAudioViewController


#pragma mark - View and Navigation

- (void)viewDidLoad {
    
    _viewStartColor = self.view.backgroundColor;
    
    [super viewDidLoad];
    
    [self initAVAudioSession];
    
    self.songProgress.layer.transform = CATransform3DMakeScale(1.0, 4.2, 1.0);
    self.clipProgressBar.layer.transform = CATransform3DMakeScale(1.0, 9.2, 1.0);
    self.activity.transform = CATransform3DGetAffineTransform(CATransform3DMakeScale(3.0, 3.0, 1.0));
    self.clipProgressBar.layer.opacity = 0.75f;
    self.songProgress.layer.opacity = 0.85f;
    
    [self.activity stopAnimating];
    
    _trackTimeInterval = 7;
    
    if (!_trackName)
        _trackName = @"Unknown Track Name";
    
    self.audioClipper = [JWClipAudioController new];
    _audioClipper.delegate = self;
    
    [self.trackNameDisplay setText:_trackName];
    self.secondsPicker.delegate = self;
    self.secondsPicker.dataSource = self;
    
    _audioClipper.sourceMP3FileURL = [NSURL fileURLWithPath:self.testMP3FileURL];
    [_audioClipper initializeAudioController];
    
    _volumeSlider.value = [_audioClipper volume];
    
    [self addNotifications];
    
    
    if (_thumbImage) {
        self.ampImageView.image = _thumbImage;
        self.ampImageView.layer.borderWidth = 4.2f;
        //        self.ampImageView.layer.cornerRadius = 12.0f;
        //        self.ampImageView.layer.masksToBounds = YES;
        self.ampImageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    
    // Do any additional setup after loading the view.
    
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGesture:)];
    
    self.view.gestureRecognizers = @[panGestureRecognizer];
    
    [self.navigationController setToolbarHidden:NO];
    
    NSLog(@"%s",__func__);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}



-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [_audioClipper ummmStartPlaying];
    
    if (! [self.playerTimer isValid]) {
        [self resumeTimer];
    }
    
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
    UIImage *ampImage = [UIImage imageNamed:[NSString stringWithFormat:@"jwjustscreensonly - %ld",selectedAmpImageIndex + 1]];
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

#pragma make -

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


-(void)addNotifications
{
//    [self.currentTrackStartTime addTarget:self action:@selector(sliderValueMoved:) forControlEvents:UIControlEventValueChanged];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSelectAmpImage:) name:@"DidSelectAmpImage" object:nil];
}

-(void)timerFireMethod:(NSTimer *)timer {
    NSLog(@"%s ",__func__);
    
    if (timer.isValid) {
        _clipProgressBar.progress = 0.0f;
        [self sliderValueMoved:self.currentTrackStartTime];
    }
}


#pragma mark - Clip Audio delegate

-(void)periodicUpdatesToPlayer {

    if (_panning)
    {
        return;
    }
    
    [self syncScrubber:_currentTrackStartTime];
    
    // The rest below is just fluff to change color foreffects
    
    static int counter = 0;  // log counter
    if (counter > 5)
        counter = 0;
    
    if (counter == 0) { // only log so many
        NSLog(@"%s",__func__);
        
    }
    counter++;


    return;
    
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
        
        if (toggle == 2){
            [self effectsBackgroundLight];
        }
    }
    toggleCounter++;
}


// give all the info needed to this method observeValueForKeyPath AVPlayerStatusReadyToPlay
-(void)playerPlayStatusReady:(float)duration {
    
    NSLog(@"%s %.2f",__func__,duration);
    dispatch_async(dispatch_get_main_queue(), ^{
        self.currentTrackStartTime.maximumValue = duration;
        self.currentTrackStartTime.continuous = NO;
    });

    [self sliderValueMoved:self.currentTrackStartTime];

}

#pragma mark - Actions

-(void)finishedTrimmingWithKey:(NSString*)key {

    [self.activity stopAnimating];

    if ([_delegate respondsToSelector:@selector(finishedTrim:withDBKey:)])
        [_delegate finishedTrim:self withDBKey:key];
    
}

-(void)exportAudioSection
{
    [_audioClipper exportAudioSectionStart: _startTime
                                       end: _endTime
                         fiveSecondsBefore: _5_secondsBeforeStartTime withCompletion:^(NSString *key){
                             
                             [self finishedTrimmingWithKey:key];
                                 //[self presentJam];
                         }];
}

- (void)sliderValueMoved:(UISlider *)sender {
    
    [self.playerTimer invalidate];
    
    _5_secondsBeforeStartTime = sender.value - 5;
    _startTime = sender.value;
    _endTime = (sender.value) + _trackTimeInterval;
    
    NSLog(@"Slider Moved to start time: %f and should end at time: %f", _startTime, _endTime);
    
    
    self.playerTimer =
    [NSTimer scheduledTimerWithTimeInterval:_trackTimeInterval target:self selector:@selector(timerFireMethod:) userInfo:nil repeats:NO];
    
    _clipProgressBar.progress = 0.0f;
    
    [_audioClipper seekToTime:(float)sender.value];
    
    
    return;
    
    // REST IS EFFECTS
    static int toggle = 1;  //
    
    CGFloat maxToggles = 5;
    if (toggle > maxToggles)
        toggle = 1;
    CGFloat alpha = toggle/maxToggles * 0.6f;
    self.view.backgroundColor = [_viewStartColor colorWithAlphaComponent:0.2 + alpha];
    toggle++;
    if (toggle <3){
        CGFloat alpha = toggle/maxToggles * 0.5f;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.ampImageView.layer.borderColor = [_viewStartColor colorWithAlphaComponent:0.50 + alpha].CGColor;
            self.secondLeft.backgroundColor = [_viewStartColor colorWithAlphaComponent:0.50 + alpha];
            self.secondRight.backgroundColor = [_viewStartColor colorWithAlphaComponent:0.50 + alpha];
            //        self.jamButton.backgroundColor = [_viewStartColor colorWithAlphaComponent:0.50 + alpha];
        });
    }
    
}


- (IBAction)secondLeftHit:(UIButton *)sender {
    [self.currentTrackStartTime setValue:[self.currentTrackStartTime value] - 1];
    [self sliderValueMoved:self.currentTrackStartTime];
    [self effectsBackgroundDark];
}

- (IBAction)secondRightHit:(UIButton *)sender {
    [self.currentTrackStartTime setValue:[self.currentTrackStartTime value] +1];
    [self sliderValueMoved:self.currentTrackStartTime];
    [self effectsBackgroundLight];
}

//    dispatch_async(dispatch_get_main_queue(), ^{
//        self.ampImageView.layer.borderColor = [_viewStartColor colorWithAlphaComponent:0.8].CGColor;
//    });

//    dispatch_async(dispatch_get_main_queue(), ^{
//        self.ampImageView.layer.borderColor = [_viewStartColor colorWithAlphaComponent:0.2].CGColor;
//    });


//NSLog(@"Slider : max %.3f min %.3f  curr %.3f",
//      _currentTrackStartTime.maximumValue,_currentTrackStartTime.minimumValue,
//      _currentTrackStartTime.value);


- (void)syncScrubber:(UISlider *)sliderValue
{
    if ([_audioClipper timeIsValid])
    {
        double duration = [_audioClipper duration];
        
        if (isfinite(duration) && (duration > 0))
        {
//            NSLog(@"Time : %.3f", [_audioClipper trackProgress]);
            
            [self.songProgress setProgress:[_audioClipper trackProgress] animated:YES];
            
        } else {
            NSLog(@"duration : %.3f", duration);

        }
    } else {
        NSLog(@"invalid time");
    }
    
    NSTimeInterval timeRemaining;
    NSTimeInterval currentPosInTrackSeconds;
    
    currentPosInTrackSeconds = [_audioClipper trackProgress] * _currentTrackStartTime.maximumValue;
    
    timeRemaining = _endTime - currentPosInTrackSeconds;

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

//    [self performSelector:@selector(exportAudioSection) withObject:nil afterDelay:.50f];


- (IBAction)volumeSliderChanged:(id)sender {
    
    [_audioClipper setVolume:[(UISlider*)sender value]];
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

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (row == 0)
        return @"15 Seconds";
    else if (row == 1)
        return @"30 Seconds";
    else if (row == 2)
        return @"45 Seconds";
    else if (row == 3)
        return @"1 Minute";
    NSLog(@"Missed picker row or component");
    return 0;
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (row == 0) {
        _trackTimeInterval = 7;
        [self sliderValueMoved:self.currentTrackStartTime];
    } else if (row == 1) {
        _trackTimeInterval = 30;
        [self sliderValueMoved:self.currentTrackStartTime];
    } else if (row == 2) {
        _trackTimeInterval = 45;
        [self sliderValueMoved:self.currentTrackStartTime];
    } else if (row == 3) {
        _trackTimeInterval = 60;
        [self sliderValueMoved:self.currentTrackStartTime];
    }
}

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if (component == 0)
        return 4;
    return 0;
}


#pragma mark - AVAudioSession

- (void)initAVAudioSession
{
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


//        UIViewController * viewController = [[UIStoryboard storyboardWithName:@"MixPanel" bundle:nil] instantiateInitialViewController];
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self presentViewController:viewController animated:YES completion:nil];
//        });




//-(void)presentJam {
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [self performSegueWithIdentifier:@"ShowRecordController" sender:nil];
//    });
//    [self.activity stopAnimating];
//}

//-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//    
//    if ([[segue identifier] isEqualToString:@"ShowRecordController"]) {
//        
//        UINavigationController* destination = (UINavigationController *) segue.destinationViewController;
//        JWRecordJamViewController* recordJamController = (JWRecordJamViewController *)[destination viewControllers][0];;
//        //        JWRecordJamViewController* destination = (JWRecordJamViewController *) segue.destinationViewController;
//        [recordJamController setTrimmedAudioURL:[_audioClipper trimmedFileURL] andFiveSecondURL:[_audioClipper fiveSecondFileURL]];
//        recordJamController.delegate = self;
//    }
//}
