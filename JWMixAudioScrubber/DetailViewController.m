//
//  DetailViewController.m
//  JWAudioScrubber
//
//  co-created by joe and brendan kerr on 12/25/15.
//  Copyright © 2015 b3k3r. All rights reserved.
//

#import "DetailViewController.h"
#import "JWAudioPlayerController.h"
#import "JWCurrentWorkItem.h"
#import "JWActivityItemProvider.h"
#import "JWFileTransferActivity.h"
#import "JWCameraViewController.h"

@import MediaPlayer;

@interface DetailViewController () <JWAudioPlayerControllerDelegate,UIDocumentInteractionControllerDelegate> {
    BOOL _playing;  // used to set toolbar items play state in effects mode
    BOOL _paused;
    NSUInteger selectedAmpImageIndex; // the currently selected amp image index
    NSUInteger _countDownLabelValue;
}
@property (strong, nonatomic) JWAudioPlayerController* playerController;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *playButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *pauseButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *forwardButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *rewindButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *fixedSpace;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *fixedSpace2;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *flexSpace1;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *flexSpace2;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *exportButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *effectsButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *cameraButton;
@property (strong, nonatomic) IBOutlet UIView *volumeView;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *scrubberActivity;
@property (strong, nonatomic) IBOutlet UIView *scrubberContainerView;
@property (strong, nonatomic) IBOutlet UIImageView *logoImageView; // holds the amp image
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *layoutConstraintScrubberHeight;
@property (strong, nonatomic) IBOutlet UIView *sctv;
@property (strong, nonatomic) IBOutlet UIView *mixeditContainerView;
@property (strong, nonatomic) IBOutlet UILabel *countDownLabel;
@property (nonatomic) NSMutableString *statusString;
@property (nonatomic) NSArray *trackItems; // the track items being used by this detail
@property (nonatomic) UIColor *restoreColor;
@property (nonatomic) id scrubber; // holds the scrubber object contained in sb container
@property (nonatomic) id playerControls; // holds the playercontrols object contained in sb container
@property (nonatomic) id mixEdit; // holds the mixed object contained in sb container
@property (nonatomic) NSTimer *fiveSecondTimer;
@end


@implementation DetailViewController

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem {

    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
    } else {
    }
    
    if (_playerController)
        [self configureView];
}

// Update the view.

- (void)configureView {
    
    self.view.backgroundColor = [UIColor blackColor];
    _scrubberContainerView.hidden = YES;
    [_scrubberActivity startAnimating];
    if (_detailItem) {
        
        id hasTrackObjectSet = _detailItem[@"trackobjectset"];
        if (hasTrackObjectSet) {
            
            //Seems like these are the same?
            //self.trackItems = [_delegate tracks:self forJamTrackKey:_detailItem[@"key"]];
            self.trackItems = hasTrackObjectSet;
            
            NSLog(@"%s %@",__func__,[_trackItems description]);
            
            
        }
        
        if (_playerController) {
            // SETUP AUDIO PLAYER CONTROLLER
            if (_trackItems && hasTrackObjectSet) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_playerController setTrackSet:_trackItems];
                });
            }
        }
    }
    
    [self revealScrubber];
    
    double delayInSecs = 0.80;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSecs * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [_scrubberActivity stopAnimating];
    });
}

-(void)revealScrubber {
    [self revealScrubberAnimated:YES];
}

-(void)revealScrubberAnimated:(BOOL)animated {
    
    if (animated) {
        _scrubberContainerView.alpha = 0;
        _scrubberContainerView.hidden = NO;

        [UIView animateWithDuration:0.10 delay:1.0 options:UIViewAnimationOptionCurveLinear animations:^{
            _scrubberContainerView.alpha = 1.0;
        } completion:^(BOOL fini){

            [UIView animateWithDuration:0.10 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.view.backgroundColor = self.restoreColor;
            } completion:nil];
        }];
        
    } else {
        _scrubberContainerView.alpha = 1.0;
        _scrubberContainerView.hidden = NO;
        self.view.backgroundColor = self.restoreColor;
        [self.navigationController setToolbarHidden:NO];
    }
}

-(void)predictScrubberHeight {
    
    if (_detailItem) {
        id hasTrackObjectSet = _detailItem[@"trackobjectset"];
        if (hasTrackObjectSet) {
            
            //NSArray *items = [_delegate tracks:self forJamTrackKey:_detailItem[@"key"]];
            NSArray *items = hasTrackObjectSet;
            if (items) {
                [self computeScrubberViewHeight:[items count]];
            }
        }
    }
}

#define DEVICEVOLUMECONTROL


- (void)viewDidLoad {
    
    [super viewDidLoad];
    NSLog(@"===============Cell Select Starts Here=========");
    NSLog(@"%s",__func__);
    [[self.navigationController toolbar] setBarStyle:UIBarStyleBlackTranslucent];
    [self.navigationController setToolbarHidden:NO];
    [self toolbar1Animated:NO];

    [self editingButtons];
    [self predictScrubberHeight];
    self.volumeView.backgroundColor = [UIColor clearColor];
    
    // DEVICE VOLUME CONTROL
#ifdef DEVICEVOLUMECONTROL
    MPVolumeView *mpVolume = [[MPVolumeView alloc] initWithFrame:_volumeView.bounds];
    mpVolume.showsRouteButton = YES;
    mpVolume.autoresizingMask =
    UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin |
    UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    mpVolume.translatesAutoresizingMaskIntoConstraints = true;
    [_volumeView addSubview:mpVolume];
#endif

    
    self.restoreColor = self.view.backgroundColor;
    self.view.backgroundColor = [UIColor blackColor];
    _scrubberContainerView.hidden = YES;
    [_scrubberActivity startAnimating];

    [[self.navigationController navigationBar]
     setBackgroundImage:[UIImage new] forBarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
    [[self.navigationController navigationBar] setShadowImage:[UIImage new]];
    [[self.navigationController navigationBar] setBackgroundColor:[UIColor blackColor]];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(backButtonTapped)];

    
    self.playerController = [JWAudioPlayerController new];
    self.playerController.delegate = self;
    [self.playerController initializePlayerControllerWithScrubberWithAutoplayOn:NO
                                                              usingScrubberView:_scrubber
                                                                 playerControls:_playerControls mixEdit:_mixEdit
                                                                 withCompletion:^{
                                                                     [self configureView];
                                                                 }];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSelectAmpImage:) name:@"DidSelectAmpImage" object:nil];
    
    _countDownLabelValue = 6;
    _paused = NO;
}

//THis method determines if a five second clip is valid by analyzing the title of the jam session, if the session has a title already then it was obtained from some other source and the presence of a five second clip will be determined later on, if the title is "new jam session" then the session is a newly created jam session by clicking the middle tab
-(void)viewWillAppear:(BOOL)animated {
    NSLog(@"%s", __func__);
    [super viewWillAppear:animated];
    selectedAmpImageIndex = [JWCurrentWorkItem sharedInstance].currentAmpImageIndex;
    [self updateAmpImage];
    [self checkForNewSession];
    
    if (_paused) {
        [_playerController resumeDetailSession];
        _paused = NO;
    }

}

-(void)viewDidAppear:(BOOL)animated {
    NSLog(@"%s",__func__);
    [super viewDidAppear:animated];
}


-(void)viewDidLayoutSubviews {
    NSLog(@"%s",__func__);
    
    
}

-(void)dealloc {
    NSLog(@"%s",__func__);
}

-(void)viewWillDisappear:(BOOL)animated {
    NSLog(@"%s",__func__);
    [super viewWillDisappear:animated];
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - amp image

-(void)updateAmpImage {
    UIImage *ampImage = [UIImage imageNamed:[NSString stringWithFormat:@"jwjustscreensonly - %ld",selectedAmpImageIndex + 1]];
    dispatch_async(dispatch_get_main_queue(), ^{
        _logoImageView.image = ampImage;
        [self.logoImageView setNeedsLayout];
    });
}

-(void)didSelectAmpImage:(NSNotification*)noti {
    NSNumber *selectedIndex = noti.userInfo[@"index"];
    if (selectedIndex)
        selectedAmpImageIndex = [selectedIndex unsignedIntegerValue];

    [self updateAmpImage];
}

#pragma mark - commands/target

-(void)stopPlaying {
    [self.playerController stop];
    self.playerController = nil;  // kill the player controller
}

//SCRUBBER CONTROLLER EMBEDED IN SCTV

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if ([segue.identifier isEqualToString:@"JWScrubberView"]) {
        self.scrubber = segue.destinationViewController;
    } else if ([segue.identifier isEqualToString:@"JWPlayerControlsView"]) {
        self.playerControls = segue.destinationViewController;
    } else if ([segue.identifier isEqualToString:@"JWMixEditEmbed"]){
        self.mixEdit = segue.destinationViewController;
    } else if ([segue.identifier isEqualToString:@"cameraActionSegue"]) {
        JWCameraViewController *destin = (JWCameraViewController *)segue.destinationViewController;
        [destin setApccTrackSet:_trackItems];
        [_playerController pauseDetailSession];
        _paused = YES;
        //NSArray *childVC = destin.childViewControllers;
        
    }

}

-(void)backButtonTapped {
    NSLog(@"Back %s", __func__);
    //cut everything
    [_playerController stopKill];
    
    //Called from the presented view controller, ui kit asks the presenting view controller to dismiss (home tab table view controller)
    [self dismissViewControllerAnimated:YES completion:^(){
        
    }];
}

#pragma mark - FIVE SECOND COUNT DOWN


-(void)startRecordCountDown:(void (^)())completion {
    NSLog(@"%s", __func__);
    self.fiveSecondTimer =
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(countdownTimerFireMethod:) userInfo:completion repeats:YES];
    
    
}

//TODO:FIve second stuff
-(void)countdownTimerFireMethod:(NSTimer *)timer {
    NSLog(@"%s", __func__);
    //NSLog(@"%s count %d volume: %f",__func__, _countDownLabelValue,[_audioEngine mixerVolume]);
    
    _countDownLabelValue--;
    
    if (_countDownLabelValue > 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self presentCountDownValue];
        });
    } else {
        self.countDownLabel.hidden = YES;
        void (^completion)() = timer.userInfo;
        completion();
        [self.fiveSecondTimer invalidate];
    }
}

-(void)presentCountDownValue {
    NSLog(@"CountDown at: %lu inside %s", _countDownLabelValue, __func__);
    self.countDownLabel.hidden = NO;
    self.countDownLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)_countDownLabelValue];
    
    CATransform3D scaleTrans = CATransform3DMakeScale(3.2, 3.2, 1.0);
    _countDownLabel.alpha = 1.0;
    _countDownLabel.layer.transform = CATransform3DIdentity;
    [UIView animateWithDuration:.60f delay:0.0 options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         _countDownLabel.layer.transform = scaleTrans;
                     } completion:^(BOOL fini){
                     }];
    
    [UIView animateWithDuration:.40f delay:0.4 options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         _countDownLabel.alpha = 0.00f;
                     } completion:^(BOOL fini){
                     }];
}




#pragma mark - TOOLBAR BUTTON ACTIONS

//Doesnt hit this action becuase a segue is triggered taht probably voids this method
- (IBAction)revealCameraButton:(UIBarButtonItem *)sender {
    
    [_playerController pauseDetailSession];
}

- (IBAction)buttonPressed:(UIBarButtonItem *)sender {
    
    if (sender == _playButton) {
        NSLog(@"%s PLAY",__func__);
        _playing = YES;
        [self toolbar2WithPlay:_playing];
        [_playerController play];
                
    } else if (sender == _forwardButton) {
        NSLog(@"%s FWD",__func__);

    } else  if (sender == _rewindButton) {
        NSLog(@"%s REWIND",__func__);
        [_playerController rewind];
        
    } else if (sender == _pauseButton) {
        NSLog(@"%s PAUSE", __func__);
        _playing = NO;
        [self toolbar2WithPlay:_playing];
        [_playerController pause];
    }
}

-(void)toolbar1 {
    [self toolbar1Animated:YES];
}

-(void)toolbar1Animated:(BOOL)animated {
    [self setToolbarItems:@[_cameraButton, _flexSpace1,_effectsButton,_exportButton] animated:animated];
}

-(void)toolbar2WithPlay:(BOOL)playbutton {
    [self setToolbarItems:@[_rewindButton, _fixedSpace, !playbutton ? _playButton : _pauseButton, _fixedSpace2, _forwardButton,_flexSpace1,_effectsButton,_exportButton] animated:YES];
}

#pragma mark - delegate??

- (IBAction)saveAction:(id)sender {
    NSLog(@"%s", __func__);
    [_delegate save:self cachKey:_detailItem[@"key"]];
}


- (void)updateStatusForItem:(NSDictionary*)item {
    NSLog(@"%s", __func__);
    NSURL *fileURL = item[@"fileURL"];
    float delay = 0.0;
    id delayItem = item[@"starttime"];
    if (delayItem)
        delay = [delayItem floatValue];
    
    [_statusString  appendString:[NSString stringWithFormat:@"delay %.2f\n%@\n%@\n%@",
                                  delay, item[@"key"],
                                  [[fileURL path] lastPathComponent],
                                  [item description]]
     ];
}


-(void)computeScrubberViewHeight:(NSUInteger)numberOfTracks{
    CGFloat tracksz = 60.0f;
    NSUInteger nTracks = numberOfTracks;
    if (nTracks == 1)
        tracksz = 140;
    else if (nTracks == 2)
        tracksz = 85.0f;
    else if (nTracks == 3)
        tracksz = 95.0f;
    
    CGFloat expectedHeight = (nTracks  * tracksz);// + 40;  // labels on scrubber
    
    self.layoutConstraintScrubberHeight.constant = expectedHeight;
    
}

#pragma mark -  JWAudioPlayerControllerDelegate


-(id)countDownTarget {
    NSLog(@"%@", self);
    self.countDownLabel.hidden = NO;
    return self;
}

-(CGSize)updateScrubberHeight:(JWAudioPlayerController *)controller {
    NSLog(@"%s", __func__);
    if (_sctv.hidden)
        return CGSizeZero;
    
    [self computeScrubberViewHeight:controller.numberOfTracks];
    
    return CGSizeMake(self.view.bounds.size.width, self.layoutConstraintScrubberHeight.constant);
}

-(void)save:(JWAudioPlayerController *)controller {

    NSLog(@"%s \n _detailItem %@",__func__,[_detailItem description]);

    [self saveAction:nil];
    if (self.editing) {
        self.editing = NO;
        [self editingButtons];
    }

}

-(void)noTrackSelected:(JWAudioPlayerController *)controller {
    _mixeditContainerView.hidden = YES;
    [self toolbar1];
}

-(void)trackSelected:(JWAudioPlayerController *)controller {
    if ([_mixeditContainerView isHidden])
        [self effectsAction:nil];
}

-(void)playTillEnd {
    _playing = NO;
    if (_mixeditContainerView.hidden == NO)
        [self toolbar2WithPlay:_playing];
}

-(void)playerController:(JWAudioPlayerController *)controller didLongPressForTrackAtIndex:(NSUInteger)index {
    [self clipActions];
}

-(void)userAudioObtainedAtIndex:(NSUInteger)index recordingId:(NSString*)rid {
    NSLog(@"%s", __func__);
    if ( index <  [self.trackItems count]){
        id nodeItem = _trackItems[index];
        if ([_delegate respondsToSelector:@selector(userAudioObtainedInNodeWithKey:recordingId:)])
            [_delegate userAudioObtainedInNodeWithKey:nodeItem[@"key"] recordingId:rid];
    }
}

-(void)userAudioObtainedAtIndex:(NSUInteger)index recordingURL:(NSURL *)rurl {
    NSLog(@"%s", __func__);
    if ( index <  [self.trackItems count]){
        id nodeItem = _trackItems[index];
        if ([_delegate respondsToSelector:@selector(userAudioObtainedInNodeWithKey:recordingURL:)])
            [_delegate userAudioObtainedInNodeWithKey:nodeItem[@"key"] recordingURL:rurl];
    }
}

-(void)userAudioObtainedWithComponents:(NSMutableDictionary *)components atIndex:(NSUInteger)index {
    NSLog(@"%s", __func__);
    if (index < [self.trackItems count]) {
        id nodeItem = _trackItems[index];
        if ([_delegate respondsToSelector:@selector(userAudioObtainedWithComponents:atNodeWithKey:)]) {
            [_delegate userAudioObtainedWithComponents:components atNodeWithKey:nodeItem[@"key"]];
        }
    }
}

-(void)effectsChanged:(NSArray*)effects inNodeWithKey:(NSString*)nodeKey {

    NSLog(@"%s %@ %@",__func__,nodeKey,[effects description]);

    if ([_delegate respondsToSelector:@selector(effectsChanged:inNodeWithKey:)])
        [_delegate effectsChanged:effects inNodeWithKey:nodeKey];
}


-(NSString*)playerControllerTitleForTrackSet:(JWAudioPlayerController*)controller {
    NSLog(@"%s", __func__);
    return [_delegate detailController:self titleForJamTrackKey:_detailItem[@"key"]];
}

#pragma mark - ActionSheets and ALert


-(void)checkForNewSession {
    
    //Prompt the user to create a name for the track through an alert view
    if ([_detailItem[@"title"]  isEqual: @"New Jam Session"]) {
        
        UIAlertController *newSessionAlert = [UIAlertController alertControllerWithTitle:@"Track Title" message:@"Give your new track a name!" preferredStyle:UIAlertControllerStyleAlert];
        __block UITextField *newTrackField = nil;
        
        [newSessionAlert addTextFieldWithConfigurationHandler:^(UITextField *field) {
            field.placeholder = @"Untitled";
            newTrackField = field;
        }];
        
        UIAlertAction *newNameAction = [UIAlertAction actionWithTitle:@"Create" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            
            _detailItem[@"title"] = newTrackField.text;
            [self.delegate addNewJamSessionToTop:self];
            self.playerController.hasFiveSecondClip = NO;
            
        }];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            //re-Present the tab bar controller on cancel
            [self dismissViewControllerAnimated:YES completion:nil];
        }];
        
        [newSessionAlert addAction:newNameAction];
        [newSessionAlert addAction:cancelAction];
        [self presentViewController:newSessionAlert animated:YES completion:^() {
            
            
        }];
        
        
    }
    
}


-(void)editingButtons{
    if (self.editing) {
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelEdit:)];
        [self.navigationItem setRightBarButtonItem:cancelButton];
        [self.effectsButton setTitle:@"Clip"];
        //        [self.exportButton setTitle:@"Cancel"];
    } else {
        
        UIBarButtonItem *actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(addAction:)];
        [self.navigationItem setRightBarButtonItem:actionButton];
        [self.effectsButton setTitle:@"Effects"];
        //        [self.exportButton setTitle:@"Export"];
    }
}

-(void)cancelEdit:(id)sender {
    if ([_playerController stopEditingSelectedTrackCancel]){
        // SELECTED and EDITING
        self.editing = NO;
        [self editingButtons];
    }
}


// clipActions: ClipLeft, ClipRight, StartPosition

-(void)clipActions {
    
    UIAlertController* actionController =
    [UIAlertController alertControllerWithTitle:@"Clip" message:@"Select Action" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* clipLeftTrack =
    [UIAlertAction actionWithTitle:@"Clip Left" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
        if ([_playerController editSelectedTrackBeginInset]){
            // SELECTED and EDITING
            self.editing = YES;
            [self editingButtons];
        }
    }];
    UIAlertAction* clipRightTrack =
    [UIAlertAction actionWithTitle:@"Clip Right" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
        if ([_playerController editSelectedTrackEndInset]){
            // SELECTED and EDITING
            self.editing = YES;
            [self editingButtons];
        }
    }];
    UIAlertAction* startPosition =
    [UIAlertAction actionWithTitle:@"Set Start Position" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
        if ([_playerController editSelectedTrackStartPosition]){
            // SELECTED and EDITING
            self.editing = YES;
            [self editingButtons];
        }
    }];
    UIAlertAction* cancelAction =
    [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction* action) {
    }];
    [actionController addAction:clipLeftTrack];
    [actionController addAction:clipRightTrack];
    [actionController addAction:startPosition];
    [actionController addAction:cancelAction];
    [self presentViewController:actionController animated:NO completion:nil];
}

// clipActionsEditing: SaveClipEdit, CancelClipEdit, Dismss

-(void)clipActionsEditing {

    UIAlertController* actionController =
    [UIAlertController alertControllerWithTitle:@"Clip Edit" message:@"Save or Cancel Changes" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* saveClipEdit =
    [UIAlertAction actionWithTitle:@"Save Clip Edit" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
        if ([_playerController stopEditingSelectedTrackSave]){
            // SELECTED and EDITING
            self.editing = NO;
            [self editingButtons];
        }
    }];
    UIAlertAction* cancelClipEdit =
    [UIAlertAction actionWithTitle:@"Cancel Clip Edit" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
        [self cancelEdit:nil];
        if ([_playerController stopEditingSelectedTrackCancel]){
            // SELECTED and EDITING
            self.editing = NO;
            [self editingButtons];
        }
    }];
    UIAlertAction* cancelAction =
    [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleCancel handler:^(UIAlertAction* action) {
    }];
    
    [actionController addAction:saveClipEdit];
    [actionController addAction:cancelClipEdit];
    [actionController addAction:cancelAction];
    [self presentViewController:actionController animated:YES completion:nil];
}


// addEffectAction: Reverb, Delay, Distortion, EQ

-(void)addEffectAction {
    
    //TODO: specify in message which node they are adding the effect to
    UIAlertController *addEffect = [UIAlertController alertControllerWithTitle:@"Add An Effect" message:@"Choose From These Effects" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *addReverbAction = [UIAlertAction actionWithTitle:@"Reverb" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        
        [_playerController addEffectToEngineNodelist:@"reverb"];
        
    }];
    UIAlertAction *addDelayAction = [UIAlertAction actionWithTitle:@"Delay" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        
        [_playerController addEffectToEngineNodelist:@"delay"];
        
    }];
    UIAlertAction *addDistortionAction = [UIAlertAction actionWithTitle:@"Distortion" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        
        [_playerController addEffectToEngineNodelist:@"distortion"];
        
    }];
    UIAlertAction *addEQAction = [UIAlertAction actionWithTitle:@"EQ" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        
        [_playerController addEffectToEngineNodelist:@"eq"];
        
    }];
    
    [addEffect addAction:addReverbAction];
    [addEffect addAction:addDelayAction];
    [addEffect addAction:addDistortionAction];
    [addEffect addAction:addEQAction];
    [addEffect addAction:cancel];
    [self presentViewController:addEffect animated:YES completion:nil];
}

#pragma mark -

// MAIN ACTION

// When User wants to add an effect node or a recorder node

- (IBAction)addAction:(id)sender {
    
    // TESTING
//    [self activityAction];
//    return;
//    [self clipActions];
//    return;
    
    NSString *title;
    NSString *message;
    
    UIAlertAction *addEffectAction;
    
    if (self.mixeditContainerView.hidden == YES) {
        title = @"Modify Jam";
        message = @"Can Add Up To 3 Nodes";
    } else {
        title = @"Add Effect or Node";
        message = @"Can Add Up To 3 Nodes And 4 Effects Each Node";
        addEffectAction =
        [UIAlertAction actionWithTitle:@"Add Effect" style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction *action) {
                                   [self addEffectAction];
                               }];
    }
    
    //TODO: specify in message which node they are adding the effect to
    
    UIAlertController *alertController =
    [UIAlertController alertControllerWithTitle:title message:message
                                 preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *clipAction = [UIAlertAction actionWithTitle:@"Clip ..." style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self clipActions];
    }];
    UIAlertAction *activityAction = [UIAlertAction actionWithTitle:@"Share ..." style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self activityAction];
    }];
    UIAlertAction *addNodeAction = [UIAlertAction actionWithTitle:@"Add Node" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if ([_delegate respondsToSelector:@selector(addTrackNode:toJamTrackWithKey:)]) {
            [_delegate addTrackNode:self toJamTrackWithKey:_detailItem[@"key"]];
            [self configureView];
        }
    }];
    
    if (addEffectAction)
        [alertController addAction:addEffectAction];
    
    [alertController addAction:addNodeAction];
    [alertController addAction:clipAction];
    [alertController addAction:activityAction];
    [alertController addAction:cancel];
    [self presentViewController:alertController animated:YES completion:nil];
}

//When User wants to add an effect node or a recorder node

- (IBAction)addNodeOrEffectAction:(id)sender {
    
    NSString *title;
    NSString *message;
    
    UIAlertAction *addEffectAction;
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *addNodeAction = [UIAlertAction actionWithTitle:@"Add Node" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {

        if ([_delegate respondsToSelector:@selector(addTrackNode:toJamTrackWithKey:)]) {
            [_delegate addTrackNode:self toJamTrackWithKey:_detailItem[@"key"]];
            [self configureView];
        }

    }];
    
    if (self.mixeditContainerView.hidden == YES) {
        title = @"Add Node";
        message = @"Can Add Up To 3 Nodes";
    } else {
        title = @"Add Effect or Node";
        message = @"Can Add Up To 3 Nodes And 4 Effects Each Node";
        addEffectAction =
        [UIAlertAction actionWithTitle:@"Add Effect" style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction *action) {
                                   [self addEffectAction];
                               }];
    }
    
    UIAlertController *addNodeOrEffect = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    self.mixeditContainerView.hidden == NO ? [addNodeOrEffect addAction:addEffectAction] : NO;
    [addNodeOrEffect addAction:addNodeAction];
    [addNodeOrEffect addAction:cancel];
    [self presentViewController:addNodeOrEffect animated:YES completion:nil];
}


// Button effects

- (IBAction)effectsAction:(id)sender {

    if (self.editing) {
        [self clipActionsEditing];

    } else {
        
        self.mixeditContainerView.hidden =! self.mixeditContainerView.hidden;
        
        // HIDDEN IS OFF
        if (_mixeditContainerView.hidden == NO) {
            
            // EFFECTS ON
            if (self.playerController.state == JWPlayerStatePlayFromPos)
                _playing = YES;
            else
                _playing = NO;
            
            [self toolbar2WithPlay:_playing];
            
            if (sender == nil) {
                // called in program - track selected from sc
                
            } else {  // from button
                [self.playerController selectValidTrack];
            }
            
        } else {
            // EFFECTS OFF
            [self toolbar1];
            [self.playerController deSelectTrack];
            
            [self.playerController effectsCurrentSettings];
            
        }
    }
}

// Buttomn Export

- (IBAction)exportAction:(id)sender {
    
    NSLog(@"%s NOT IMPLEMENTED",__func__);
}



#pragma mark - Share Action

-(void)activityAction {
    
    NSURL *fileURL;
    
    if ([self.trackItems count] > 0) {
        id item = _trackItems[0];
        fileURL = item[@"fileURL"];
    }
    
    fileURL = [NSURL fileURLWithPath:[fileURL path]];
    
    JWActivityItemProvider *activityItemProvider = [[JWActivityItemProvider alloc] initWithPlaceholderItem:fileURL];
    activityItemProvider.fileURL = fileURL;
    
    JWFileTransferActivity *ftActivity = [JWFileTransferActivity new];
    ftActivity.view = self.view;
    
    UIActivityViewController *avc =
    [[UIActivityViewController alloc] initWithActivityItems:@[fileURL]
                                      applicationActivities:@[ftActivity]];

    NSArray *excludedActivities = @[UIActivityTypePostToTwitter, UIActivityTypePostToFacebook,
                                    UIActivityTypePostToWeibo,
                                    UIActivityTypePrint, UIActivityTypeCopyToPasteboard,
                                    UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll,
                                    UIActivityTypeAddToReadingList, UIActivityTypePostToFlickr,
                                    UIActivityTypePostToVimeo, UIActivityTypePostToTencentWeibo];
    
    avc.excludedActivityTypes = excludedActivities;
    avc.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError){
        if (activityType) {
            if ([activityType isEqualToString:UIActivityTypeAirDrop]) {
                NSLog(@"AIRDROP completed %@ %@",@(completed),[returnedItems description]);
            }
            else if ([activityType isEqualToString:UIActivityTypeMail]) {
                NSLog(@"MAIL completed %@ %@",@(completed),[returnedItems description]);
            }
            else if ([activityType isEqualToString:UIActivityTypeMessage]) {
                NSLog(@"MESSAGE completed %@ %@",@(completed),[returnedItems description]);
            }
            else if ([activityType isEqualToString:@"com.getdropbox.Dropbox.ActionExtension"]) {
                NSLog(@"DROPBOX completed %@ %@",@(completed),[returnedItems description]);
            }
            else if ([activityType isEqualToString:@"com.apple.mobilenotes.SharingExtension"]) {
                NSLog(@"NOTES completed %@ %@",@(completed),[returnedItems description]);
            }
            else{
                NSLog(@"%@ %@ %@",activityType,@(completed),[returnedItems description]);
            }
            
        } else {
            // perhaps CANCEL
            NSLog(@"CANCEL completed %@",@(completed));
        }
        
        // ERROR
        
        if (activityError) {
            NSLog(@"MESSAGE %@",[activityError description]);
        }
    };
    
    
    [self presentViewController:avc animated:YES completion:^{
        
    }];

}


@end


