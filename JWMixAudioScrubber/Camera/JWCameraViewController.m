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

@interface JWCameraViewController ()
<JWAudioPlayerControllerDelegate>
{
    
    BOOL _cameraAuthorized;
    BOOL _sessionRunning;
}

@property (nonatomic) AVCamSetupResult setupResult;
@property (nonatomic) AVCaptureSession *captureSession;
@property (nonatomic) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic) AVCaptureMovieFileOutput *videoDataMovie;
@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic) NSMutableDictionary *jwVideoSettings;

@property (nonatomic) UIViewController *storyboardVC;
@property (strong, nonatomic) IBOutlet UIView *buttonsContainer;
@property (strong, nonatomic) IBOutlet UIView *scrubContainer;
@property (nonatomic) id scrubberVC;
@property (nonatomic) id playerControlsVC;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *layoutConstraintScrubberHeight;

@property (nonatomic) JWScrubberController *sc1;
@property (nonatomic) JWAudioPlayerCameraController *apcc;

@property (nonatomic) JWUITransportButton *rewind;
@property (nonatomic) JWUITransportButton *playPause;
@property (nonatomic) JWUITransportButton *record;



@end

@implementation JWCameraViewController


//The view you want to present

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.sessionQueue = dispatch_queue_create( "session queue", DISPATCH_QUEUE_SERIAL );
    
    self.setupResult = AVCamSetupResultSuccess;
    
    self.apcc = [[JWAudioPlayerCameraController alloc] init];
    self.apcc.delegate = self;
    [self.apcc initializePlayerControllerWithScrubber:_scrubberVC playerControles:_playerControlsVC withCompletion:^{
        [self.apcc setTrackSet:_apccTrackSet];
    }];
    
    
    
    // Check video authorization status. Video access is required and audio access is optional.
    // If audio access is denied, audio is not recorded during movie recording.
    switch ( [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] )
    {
        case AVAuthorizationStatusAuthorized:
        {
            // The user has previously granted access to the camera.
            break;
        }
        case AVAuthorizationStatusNotDetermined:
        {
            // The user has not yet been presented with the option to grant video access.
            // We suspend the session queue to delay session setup until the access request has completed to avoid
            // asking the user for audio access if video access is denied.
            // Note that audio access will be implicitly requested when we create an AVCaptureDeviceInput for audio during session setup.
            dispatch_suspend( self.sessionQueue );
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^( BOOL granted ) {
                _cameraAuthorized = granted;
                
                if (_cameraAuthorized) {
                    dispatch_resume( self.sessionQueue );
                } else {
                    self.setupResult = AVCamSetupResultCameraNotAuthorized;
                }
                
            }];
            break;
        }
        default:
        {
            // The user has previously denied access.
            _cameraAuthorized = NO;
            self.setupResult = AVCamSetupResultCameraNotAuthorized;
            break;
        }
    }
    
    
    [self setupCaptureSession];
    //[self previewLayer];
    //[self useFrontCamera];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}




#pragma mark - INITIALIze

-(void)setupCaptureSession {
    
    
    // Setup the capture session.
    // In general it is not safe to mutate an AVCaptureSession or any of its inputs, outputs, or connections from multiple threads at the same time.
    // Why not do all of this on the main queue?
    // Because -[AVCaptureSession startRunning] is a blocking call which can take a long time. We dispatch session setup to the sessionQueue
    // so that the main queue isn't blocked, which keeps the UI responsive.
    dispatch_async( self.sessionQueue, ^{
        
        
        AVCaptureDevicePosition prefferedPosition = AVCaptureDevicePositionFront;
        
        
        //CREATE THE SESSION
        _captureSession = [[AVCaptureSession alloc] init];
        
        //CONFIGURE THE SESSION INSIDE HERE
        [self.captureSession beginConfiguration];
        
        if ([_captureSession canSetSessionPreset:AVCaptureSessionPresetMedium]) {
            _captureSession.sessionPreset = AVCaptureSessionPresetMedium;
        } else {
            // Handle the failure.
            NSLog(@"Invalid Preset: %@", AVCaptureSessionPresetMedium);
            self.setupResult = AVCamSetupResultSessionConfigurationFailed;
        }
        
        //REMOVE EXISTING DEVICE INPUTS FIRST
        NSArray *currentInputs = [self.captureSession inputs];
        if ([currentInputs count] > 0) {
            NSLog(@"Removing %lu inputs.", (unsigned long)[currentInputs count]);
            for (AVCaptureInput *input in currentInputs) {
                [self.captureSession removeInput:input];
            }
            
        }
        
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
                    // Why are we dispatching this to the main queue?
                    // Because AVCaptureVideoPreviewLayer is the backing layer for AAPLPreviewView and UIView
                    // can only be manipulated on the main thread.
                    // Note: As an exception to the above rule, it is not necessary to serialize video orientation changes
                    // on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.
                    
                    // Use the status bar orientation as the initial video orientation. Subsequent orientation changes are handled by
                    // -[viewWillTransitionToSize:withTransitionCoordinator:].
                    UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
                    AVCaptureVideoOrientation initialVideoOrientation = AVCaptureVideoOrientationPortrait;
                    if ( statusBarOrientation != UIInterfaceOrientationUnknown ) {
                        initialVideoOrientation = (AVCaptureVideoOrientation)statusBarOrientation;
                    }
                    
                    AVCaptureVideoPreviewLayer *previewLayer = [self previewLayer];
                    previewLayer.connection.videoOrientation = initialVideoOrientation;
                    
                    [self.view addSubview:_storyboardVC.view];
                } );
                
                
            } else {
                NSLog(@"Capture Device Not Added");
                self.setupResult = AVCamSetupResultSessionConfigurationFailed;
            }
            

        } else {
            NSLog(@"Could not obtain a capture device");
            self.setupResult = AVCamSetupResultSessionConfigurationFailed;
        }
        
        
        
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
        }
        
        [self.captureSession commitConfiguration];
        
        [self.apcc setVideoSettings:self.jwVideoSettings];
        
    });
    
    
    
    
}

#pragma mark - SHOW

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    dispatch_async( self.sessionQueue, ^{
        switch ( self.setupResult )
        {
            case AVCamSetupResultSuccess:
            {
                // Only setup observers and start the session running if setup succeeded.
                
                [self.captureSession startRunning];
                _sessionRunning = self.captureSession.isRunning;
                dispatch_async(dispatch_get_main_queue(), ^() {
                    
                    [self.view bringSubviewToFront:_buttonsContainer];
                    [self.view bringSubviewToFront:_scrubContainer];
                    
                });
                
                
                break;
            }
            case AVCamSetupResultCameraNotAuthorized:
            {
                dispatch_async( dispatch_get_main_queue(), ^{
                    NSString *message = NSLocalizedString( @"AVCam doesn't have permission to use the camera, please change privacy settings", @"Alert message when the user has denied access to the camera" );
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"AVCam" message:message preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"OK", @"Alert OK button" ) style:UIAlertActionStyleCancel handler:nil];
                    [alertController addAction:cancelAction];
                    // Provide quick access to Settings.
                    UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"Settings", @"Alert button to open Settings" ) style:UIAlertActionStyleDefault handler:^( UIAlertAction *action ) {
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                    }];
                    [alertController addAction:settingsAction];
                    [self presentViewController:alertController animated:YES completion:nil];
                } );
                break;
            }
            case AVCamSetupResultSessionConfigurationFailed:
            {
                dispatch_async( dispatch_get_main_queue(), ^{
                    NSString *message = NSLocalizedString( @"Unable to capture media", @"Alert message when something goes wrong during capture session configuration" );
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"AVCam" message:message preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"OK", @"Alert OK button" ) style:UIAlertActionStyleCancel handler:nil];
                    [alertController addAction:cancelAction];
                    [self presentViewController:alertController animated:YES completion:nil];
                } );
                break;
            }
        }
    } );
    
    
}

#pragma mark - DISMISS

- (void)viewDidDisappear:(BOOL)animated
{
    dispatch_async( self.sessionQueue, ^{
        if ( self.setupResult == AVCamSetupResultSuccess ) {
            [self.captureSession stopRunning];
        }
    } );
    
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
        _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
        
        [_previewLayer setFrame:rootLayer.bounds];
        [_previewLayer setBackgroundColor:[[UIColor clearColor] CGColor]];
        
        [_previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
        //[_previewLayer setAffineTransform:CGAffineTransformMakeScale(1.35, 1.35)];
        
        [rootLayer setMasksToBounds:YES];
        [rootLayer insertSublayer:_previewLayer atIndex:0];
        //[rootLayer insertSublayer:_rewind.layer atIndex:1];
        
        //[self.view addSubview:_buttonViewContainer];
        //_buttonViewContainer.hidden = YES;
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



#pragma mark - FILE MANAGER

-(NSString*)documentsDirectoryPath {
    NSString *result = nil;
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    result = [searchPaths objectAtIndex:0];
    return result;
}


/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationJWCameraViewController].
 // Pass the selected object to the new view controller.
 }
 */


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
    
    CGSize scrubber = CGSizeMake(self.view.bounds.size.height, self.layoutConstraintScrubberHeight.constant);
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


@end
