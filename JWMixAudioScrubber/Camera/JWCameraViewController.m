//
//  JWCameraJWCameraViewController.m
//  JWMixAudioScrubber
//
//  co-created by joe and brendan kerr on 1/11/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

#import "JWCameraViewController.h"
#import "JWScrubberController.h"
#import "JWAudioPlayerCameraController.h"
#import "JWPlayerControlsViewController.h"

/* 
 
 jwVideoSettings has the keys -
 "inputdevice"
 "videostabilizationmode"
 
 
 */

typedef NS_ENUM( NSInteger, AVCamSetupResult ) {
    AVCamSetupResultSuccess,
    AVCamSetupResultCameraNotAuthorized,
    AVCamSetupResultSessionConfigurationFailed
};

@interface JWCameraViewController () <JWAudioPlayerControllerDelegate>
@property (nonatomic,assign) AVCamSetupResult setupResult;
@property (nonatomic) AVCaptureSession *captureSession;
@property (nonatomic) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic) AVCaptureMovieFileOutput *videoDataMovie;
@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic) NSMutableDictionary *jwVideoSettings;

@property (nonatomic) IBOutlet UIView *buttonsContainer;
@property (nonatomic) IBOutlet UIView *scrubContainer;
@property (nonatomic) IBOutlet NSLayoutConstraint *layoutConstraintScrubberHeight;

@property (nonatomic) id scrubberVC;
@property (nonatomic) id playerControlsVC;

@property (nonatomic) JWAudioPlayerCameraController *apcc;

// Cleaning up unused properties
// TODO: These buttons are not needed here i think
@property (nonatomic) JWUITransportButton *rewind;
@property (nonatomic) JWUITransportButton *playPause;
@property (nonatomic) JWUITransportButton *record;

//@property (nonatomic) UIViewController *storyboardVC;
//@property (nonatomic,strong) JWScrubberController *sc1;

@end


@implementation JWCameraViewController


//The view you want to present

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    NSLog(@"\n");
    NSLog(@"-------=========CAMERA VC STARTS HERE========---------");
    NSLog(@"%s", __func__);
    
    self.sessionQueue = dispatch_queue_create("session queue",
                                              dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL,QOS_CLASS_USER_INITIATED, 0));
    
    self.setupResult = AVCamSetupResultSuccess;
    
    self.apcc = [[JWAudioPlayerCameraController alloc] init];
    self.apcc.delegate = self;
    
    [self.apcc initializePlayerControllerWithScrubber:_scrubberVC playerControles:_playerControlsVC withCompletion:^{
        [self.apcc setTrackSet:_apccTrackSet];
    }];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


// Do any additional setup after loading the view.
//self.sessionQueue = dispatch_queue_create( "session queue", DISPATCH_QUEUE_SERIAL );

//    dispatch_queue_attr_t queue = dispatch_queue_attr_make_with_qos_class(NULL, QOS_CLASS_USER_INITIATED, 0);
//    self.sessionQueue = dispatch_queue_create( "session queue", queue);




#pragma mark - INITIALIze

// Returns whether to continue camera processing

-(BOOL)authorizeCamera {
    
    BOOL  result = YES;
    
    // Check video authorization status. Video access is required and audio access is optional.
    // If audio access is denied, audio is not recorded during movie recording.
    switch ( [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] )
    {
        case AVAuthorizationStatusAuthorized:
            // The user has previously granted access to the camera.
            break;
            
        case AVAuthorizationStatusDenied:
            // The user has previously denied access.
            self.setupResult = AVCamSetupResultCameraNotAuthorized;
            result = NO;
            break;
            
        case AVAuthorizationStatusNotDetermined:
        {
            // The user has not yet been presented with the option to grant video access.
            // We suspend the session queue to delay session setup until the access request has completed to avoid
            // asking the user for audio access if video access is denied.
            // Note that audio access will be implicitly requested when we create an AVCaptureDeviceInput for audio during session setup.
            dispatch_suspend( self.sessionQueue );
            
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^( BOOL granted ) {
                
                if (granted) {
                    dispatch_resume( self.sessionQueue );
                } else {
                    self.setupResult = AVCamSetupResultCameraNotAuthorized;
                }
            }];
            
        }
            break;
            
        default:
            self.setupResult = AVCamSetupResultCameraNotAuthorized;
            result = NO;
            break;
    }
    
    
    return result;
}

-(void)setupCaptureSession {
    
    // Setup the capture session.
    // In general it is not safe to mutate an AVCaptureSession or any of its inputs, outputs, or connections from multiple threads at the same time.
    // Why not do all of this on the main queue?
    // Because -[AVCaptureSession startRunning] is a blocking call which can take a long time. We dispatch session setup to the sessionQueue
    // so that the main queue isn't blocked, which keeps the UI responsive.
    
    dispatch_async( self.sessionQueue, ^{
        NSLog(@"Started creating the session");
        //CREATE THE SESSION
        _captureSession = [[AVCaptureSession alloc] init];
        
        [self.captureSession beginConfiguration];


        int status = 0;
        
        //CONFIGURE THE SESSION
        if ([_captureSession canSetSessionPreset:AVCaptureSessionPresetMedium]) {
            _captureSession.sessionPreset = AVCaptureSessionPresetMedium;
            
        } else {
            // Handle the failure.
            NSLog(@"Invalid Preset: %@", AVCaptureSessionPresetMedium);
            self.setupResult = AVCamSetupResultSessionConfigurationFailed;
            status = 1;
        }
        
        if (!status) {
            //REMOVE EXISTING DEVICE INPUTS FIRST
            NSArray *currentInputs = [self.captureSession inputs];
            if ([currentInputs count] > 0) {
                NSLog(@"Removing %lu inputs.", (unsigned long)[currentInputs count]);
                for (AVCaptureInput *input in currentInputs) {
                    [self.captureSession removeInput:input];
                }
            }
        }
        
        if (!status) {
            
            AVCaptureDevicePosition prefferedPosition = AVCaptureDevicePositionFront;
            //GET CAPTURE DEVICE FRONT CAMERA AND SET CAPUTRE DEVICE INPUT WITH DEVICE
            NSError* error;
            AVCaptureDevice* captureDevice = [JWCameraViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:prefferedPosition];
            
            if (captureDevice) {
                
                self.jwVideoSettings[@"inputdevice"] = [NSNumber numberWithInteger:prefferedPosition];
                AVCaptureDeviceInput* captureDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
                
                //ADD CAPTURE INPUT TO SESSION
                if ([_captureSession canAddInput:captureDeviceInput] && !error) {
                    [_captureSession addInput:captureDeviceInput];
                    
                    dispatch_async( dispatch_get_main_queue(), ^{
                        
                    } );
                    
                } else {
                    NSLog(@"Capture Device Not Added");
                    self.setupResult = AVCamSetupResultSessionConfigurationFailed;
                    status = 2;
                }
                
            } else {
                NSLog(@"Could not obtain a capture device");
                self.setupResult = AVCamSetupResultSessionConfigurationFailed;
                status = 3;
            }
        }
        
        
        if (!status) {
            //ADD CAPTURE OUTPUT TO SESSION
            AVCaptureMovieFileOutput *videoData = [[AVCaptureMovieFileOutput alloc] init];
            if ([_captureSession canAddOutput:videoData]) {
                [_captureSession addOutput:videoData];
                
                AVCaptureConnection *connection = [videoData connectionWithMediaType:AVMediaTypeVideo];
                if ( connection.isVideoStabilizationSupported ) {
                    connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
                    self.jwVideoSettings[@"videostabilizationmode"] = [NSNumber numberWithInteger:AVCaptureVideoStabilizationModeAuto];
                }
                self.videoDataMovie = videoData;
                [self.apcc setVideoMovie:self.videoDataMovie];
            } else {
                NSLog(@"Video Data Output Not Added.");
                self.setupResult = AVCamSetupResultSessionConfigurationFailed;
                status = 3;
            }
        }
        
        
        [self.captureSession commitConfiguration];
        // SESSION CONFIGURED
        
        [self.apcc setVideoSettings:self.jwVideoSettings];
        
    });
    
}


-(void)processCaptureSessionSetupResult {
    
    dispatch_async( self.sessionQueue, ^{
        
        switch ( self.setupResult )
        {
            case AVCamSetupResultSuccess:
            {
                [self cameraAttachPreviewlayerAndOrientation];
                
                // Only setup observers and start the session running if setup succeeded.
                
                [self.captureSession startRunning];
                
                NSLog(@"Session is running");
                dispatch_async(dispatch_get_main_queue(), ^() {
                    
                    [self.view bringSubviewToFront:_buttonsContainer];
                    [self.view bringSubviewToFront:_scrubContainer];
                    
                    double delayInSecs = 0.250;
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSecs * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        
                        _buttonsContainer.alpha = 0;
                        _scrubContainer.alpha = 0;
                        _buttonsContainer.hidden = NO;
                        _scrubContainer.hidden = NO;
                        
                        [UIView animateWithDuration:0.5 animations:^{
                            _buttonsContainer.alpha = 1.0;
                            _scrubContainer.alpha = 1.0;
                        }];
                    });
                    
                });
            }
                
                break;
                
            case AVCamSetupResultCameraNotAuthorized:
            {
                dispatch_async( dispatch_get_main_queue(), ^{
                    NSString *message = NSLocalizedString( @"AVCam doesn't have permission to use the camera, please change privacy settings", @"Alert message when the user has denied access to the camera" );
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"AVCam" message:message preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"OK", @"Alert OK button" ) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                        [self dismissOperation];
                    }];
                    
                    [alertController addAction:cancelAction];
                    // Provide quick access to Settings.
                    UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"Settings", @"Alert button to open Settings" ) style:UIAlertActionStyleDefault handler:^( UIAlertAction *action ) {

                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                        [self dismissOperation];

                    }];
                    [alertController addAction:settingsAction];
                    [self presentViewController:alertController animated:YES completion:nil];
                } );
            }
                break;
                
                
            case AVCamSetupResultSessionConfigurationFailed:
            {
                dispatch_async( dispatch_get_main_queue(), ^{
                    NSString *message = NSLocalizedString( @"Unable to capture media", @"Alert message when something goes wrong during capture session configuration" );
                    
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"AVCam" message:message preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"OK", @"Alert OK button" ) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                        [self dismissOperation];
                    }];

                    [alertController addAction:cancelAction];
                    [self presentViewController:alertController animated:YES completion:nil];
                } );
            }
                
                break;
        }
        
    } );
    
}


-(void)cameraAttachPreviewlayerAndOrientation {
    
    UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
    
    AVCaptureVideoOrientation initialVideoOrientation = AVCaptureVideoOrientationPortrait;
    if ( statusBarOrientation != UIInterfaceOrientationUnknown ) {
        initialVideoOrientation = (AVCaptureVideoOrientation)statusBarOrientation;
    }
    
    AVCaptureVideoPreviewLayer *previewLayer = [self previewLayer];
    previewLayer.connection.videoOrientation = initialVideoOrientation;
    
    CABasicAnimation* fadeAnim = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fadeAnim.fromValue = [NSNumber numberWithFloat:0.0];
    fadeAnim.toValue = [NSNumber numberWithFloat:1.0];
    fadeAnim.duration = 0.25;
    [previewLayer addAnimation:fadeAnim forKey:@"opacity"];
    // Change the actual data value in the layer to the final value.
    previewLayer.opacity = 1.0;
    
}


-(void)cameraSetupAndPresentation {
    
    if ([self authorizeCamera]) {
        [self setupCaptureSession];
    }
    
    [self processCaptureSessionSetupResult];
}


#pragma mark - SHOW

- (void)viewWillAppear:(BOOL)animated
{
    NSLog(@"%s", __func__);
    [super viewWillAppear:animated];
    
    _buttonsContainer.hidden = YES;
    _scrubContainer.hidden = YES;
}


-(void)viewDidAppear:(BOOL)animated {
    NSLog(@"%s", __func__);
    [super viewDidAppear:animated];
    
    [self cameraSetupAndPresentation];
}


-(void)viewDidLayoutSubviews {
    NSLog(@"%s", __func__);
}


-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    NSLog(@"%s", __func__);
    
}

#pragma mark - DISMISS

-(void)dismissOperation {
    //cut everything
    //[_apcc stopKill];
    [self dismissViewControllerAnimated:NO completion:nil];
}

-(void)userDismissCamera {
    NSLog(@"%s", __func__);
    [self dismissOperation];
}

-(void)viewWillDisappear:(BOOL)animated {
    NSLog(@"%s", __func__);
    [super viewWillDisappear:animated];
    [_previewLayer removeFromSuperlayer];
}


- (void)viewDidDisappear:(BOOL)animated
{
    //Handle dissapear stuff (the preview layer seems to be getting stuck?)
    NSLog(@"%s", __func__);
    [super viewDidDisappear:animated];
    
    dispatch_async( self.sessionQueue, ^{
        if ( self.setupResult == AVCamSetupResultSuccess ) {
            [self.captureSession stopRunning];
        }
    } );
    
    [self.apcc stopKill];
    [super viewDidDisappear:animated];
}

- (IBAction)myUnwindAction:(UIStoryboardSegue*)unwindSegue {
    NSLog(@"%s", __func__);
    
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"buttonsVC"]) {
        
        _playerControlsVC = segue.destinationViewController;
        
    } else if ([segue.identifier isEqualToString:@"scrubberVC"]) {
        
        _scrubberVC = segue.destinationViewController;
    }
}

#pragma mark - CAMERA CONFIG

-(AVCaptureVideoPreviewLayer *)previewLayer {
    
    if (!_previewLayer && _captureSession) {
        NSLog(@"%s", __func__);
        CALayer* rootLayer = self.view.layer;
        
        NSLog(@"root layer = %@", NSStringFromCGRect(rootLayer.bounds));
        
        _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
        
        [_previewLayer setOpacity:0.0];
        [_previewLayer setFrame:rootLayer.bounds];
        [_previewLayer setBackgroundColor:[[UIColor clearColor] CGColor]];
        [_previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
        
        [rootLayer setMasksToBounds:YES];
        [rootLayer insertSublayer:_previewLayer atIndex:0];
    }
    
    return _previewLayer;
}


+ (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
    NSLog(@"%lu capture Devices", (unsigned long)[devices count]);
    AVCaptureDevice *captureDevice = devices.firstObject;
    
    for ( AVCaptureDevice *device in devices ) {
        if ( device.position == position ) {
            captureDevice = device;
            break;
        }
    }
    
    NSLog(@"Capture Device Found. %@", captureDevice);
    return captureDevice;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscape;
}


//-(void)record {
//    
//    NSString *movieFileName = @"moviefile";
//    NSString *documentsPath = [[[self documentsDirectoryPath] stringByAppendingString:movieFileName] stringByAppendingPathExtension:@"mov"];
//    NSURL *movieURL = [NSURL fileURLWithPath:documentsPath];
//    
//    [self.videoDataMovie startRecordingToOutputFileURL:movieURL recordingDelegate:self];
//    
//}



#pragma mark - AudioPlayerController delegate

-(CGSize)updateScrubberHeight:(JWAudioPlayerController *)controller {
    
    CGFloat tracksz = 50.0f;
    NSUInteger nTracks = controller.numberOfTracksWithAudio;
    if (nTracks == 1) {
        tracksz = 150.0f;
    } else if (nTracks == 2) {
        tracksz = 75.0f;
    } else if (nTracks == 3) {
        tracksz = 85.0f;
    }
    
    CGFloat expectedHeight = (nTracks  * tracksz);// + 40;  // labels on scrubber
    //CGFloat expectedHeight = (controller.numberOfTracksWithAudio  * tracksz);// + 40;  // labels on scrubber
    
    self.layoutConstraintScrubberHeight.constant = expectedHeight;
    
    CGSize scrubber = CGSizeMake(self.view.bounds.size.width, self.layoutConstraintScrubberHeight.constant);
    NSLog(@"Width: %f, Height: %f", self.view.bounds.size.width, self.view.bounds.size.height);
    NSLog(@"Scrubber Size %@, Bounds Size %@", NSStringFromCGSize(scrubber), NSStringFromCGRect(self.view.bounds));
    
    return scrubber;
}

-(void)playTillEnd {
    // TODO: not implemented
    NSLog(@"%s not implemented",__func__);
}

-(void)save:(JWAudioPlayerController *)controller {
    // TODO: not implemented
    NSLog(@"%s not implemented",__func__);
}

-(void)noTrackSelected:(JWAudioPlayerController *)controller {
    // TODO: not implemented
    NSLog(@"%s not implemented",__func__);
}

-(void)trackSelected:(JWAudioPlayerController *)controller {
    // TODO: not implemented
    NSLog(@"%s not implemented",__func__);
}

-(void)playerController:(JWAudioPlayerController *)controller didLongPressForTrackAtIndex:(NSUInteger)index {
    // TODO: not implemented
    NSLog(@"%s not implemented",__func__);
}

-(void)userAudioObtainedAtIndex:(NSUInteger)index recordingId:(NSString*)rid {
    // TODO: not implemented
    NSLog(@"%s not implemented",__func__);
}

-(void)effectsChanged:(NSArray*)effects inNodeWithKey:(NSString*)nodeKey {
    // TODO: not implemented
    NSLog(@"%s not implemented",__func__);
}

-(NSString*)playerControllerTitleForTrackSet:(JWAudioPlayerController*)controllerkey {
    // TODO: not implemented
    NSLog(@"%s not implemented",__func__);
    return nil;
}

-(void)startRecordCountDown:(void(^)())completion {
    NSLog(@"%s not implemented",__func__);
    
}

-(void)userAudioObtainedAtIndex:(NSUInteger)index recordingURL:(NSURL *)rurl {
    NSLog(@"%s not implemented",__func__);
    
}

-(void)userAudioObtainedWithComponents:(NSDictionary *)components atIndex:(NSUInteger)index {
    NSLog(@"%s not implemented",__func__);
    
}


@end
