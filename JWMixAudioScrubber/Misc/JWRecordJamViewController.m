//
//  JWRecordJamViewController.m
//  JamWithV1.0
//
//  Created by brendan kerr on 9/15/15.
//  Copyright (c) 2015 b3k3r. All rights reserved.
//

/* This view controller's functionality allows recording from microphone while a track is playing
 ----- ----- ----- ----- ----- ----- -----v ----- ----- ----- ----- ----- ----- -----v ----- ----- ----- ----- ----- ----- -----v ----- ----- ----- -----
 1. Upon Record, the base track is loaded and the 5 second intro is loaded before that.
 The five second clip is played and then the base track
 At the conclusion of the 5 second intro, the micro phone is turned on and output o fthe recording is made to file
 
 2. When base track finishes, the microphone is turned OFF
 
 3. A clean copy of the base track exists, and a recording from microphone is saved.
 
 4. Now the user mixes the two with Preview
 
 5. The output of the mix is made.
 
 6. Options are to
 - Save
 - Edit
 - Replay
 Need Options
 - Delete (start over)
 ----- ----- ----- ----- ----- ----- -----x ----- ----- ----- ----- ----- ----- -----x ----- ----- ----- ----- ----- ----- -----x ----- ----- ----- -----
 */

#import "JWRecordJamViewController.h"
#import "JWScrubberViewController.h"
#import "JWCurrentWorkItem.h"
#import "JWUITransportButton.h"
#import "JWMixPanelViewController.h"
#import "JWScrubberController.h"
#import "JWEffectsClipAudioEngine.h"
#import "JWPlayerControlsViewController.h"

@interface JWRecordJamViewController () <
UIAlertViewDelegate, ClipAudioEngineDelgegate,ScrubberDelegate,
JWScrubberControllerDelegate,
JWPlayerControlsDelegate,
JWMixPanelDelegate
> {
    AVCaptureSession* _captureSession;
    int _countDownLabelValue;
    CGFloat _restoreScrubberHeight;
    CGFloat _restoreHeight1;
    CGFloat _restoreHeight2;
    NSUInteger selectedAmpImageIndex;
    BOOL _isPlayingMix;
    BOOL _saved;
    BOOL _stretchVideo;
    BOOL _cameraForcedHidden;
    BOOL _needsRewind;
    BOOL _isMixing;
    BOOL _isRecordingMix;
    BOOL _hasRecordingMix;
    int firstTime;
    NSUInteger _revealMixControlsCount;
    UIColor *iosColor2;
    UIColor *iosColor1;
    UIColor *iosColor3;
    UIColor *iosColor4;
    BOOL colorizedTracks;
}
@property (nonatomic) JWEffectsClipAudioEngine* audioEngine;
@property (nonatomic) AVCaptureVideoPreviewLayer* previewLayer;
@property (nonatomic) JWPlayerControlsViewController* playerControlsViewController;
@property (nonatomic) JWMixPanelViewController* mixPanelViewController;
@property (strong, nonatomic) NSTimer* countDownTimer;
@property (strong, nonatomic) NSTimer* mixerValueFadeTimer;
@property (strong, nonatomic) IBOutlet UIView *previewView;
@property (strong, nonatomic) IBOutlet UIView *scrubberContainer;
@property (strong, nonatomic) IBOutlet UIView *mixEditContainer;
@property (strong, nonatomic) IBOutlet UIView *ampPlayerContainer;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *mixContainerBottomLayout;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *ampPlayerHeightConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *topSpaceForPreview;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *scrubberHeightConstraint;
@property (strong, nonatomic) IBOutlet UILabel *countDownLabel;
@property (strong, nonatomic) IBOutlet UILabel *recordLabel;
@property (strong, nonatomic) JWScrubberViewController *scrubber;
@property (strong, nonatomic) JWScrubberViewController *localScrubber;
@property (nonatomic) NSURL* trimmedURL;
@property (nonatomic) NSURL* fiveSecondURL;
@property (nonatomic) NSMutableDictionary* savedMixList;
@property (nonatomic) NSString *selectedRecorderName;
@property (nonatomic) NSUInteger selectedRecorderIndex;
@property (getter=isRecording) BOOL recording;
@property (getter=isPlaying) BOOL playing;
@property BOOL canPlayback;
@property (strong, nonatomic) JWScrubberController *scrubberController;
@property (strong, nonatomic) NSString *scrubberPrimaryTrackId;
@property (strong, nonatomic) NSDictionary *scrubberPrimaryColors;
@property (nonatomic) BOOL  scrubberPrimaryGreyedOut;
@property (nonatomic) UIColor *saveColorFromRecording;
@property (strong, nonatomic) IBOutlet UIImageView *ampImageView;
@end


@implementation JWRecordJamViewController

- (void)viewDidLoad {

    iosColor1 = [UIColor colorWithRed:128/255.0 green:128/255.0 blue:0/255.0 alpha:1.0]; // asparagus
    iosColor2 = [UIColor colorWithRed:0/255.0 green:64/255.0 blue:128/255.0 alpha:1.0]; // ocean
    iosColor3 = [UIColor colorWithRed:0/255.0 green:128/255.0 blue:255/255.0 alpha:1.0]; // aqua
    iosColor4 = [UIColor colorWithRed:102/255.0 green:204/255.0 blue:255/255.0 alpha:1.0]; // sky
    colorizedTracks = NO;

    _stretchVideo = NO;
    firstTime = 1;
    
    [super viewDidLoad];
    
    // SETUP RIGHT BAR BUTTONS for EDIT and ACTION
    NSMutableArray *buttonItems = [NSMutableArray arrayWithArray:self.navigationItem.rightBarButtonItems];
    [buttonItems addObject:
     [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(onAction:)]];
    [buttonItems addObject:self.editButtonItem ];
    [self.navigationItem setRightBarButtonItems:buttonItems animated:YES];
    
    
    // SETUP AUDIO ENGINE
    self.audioEngine = [[JWEffectsClipAudioEngine alloc] initWithPrimaryFileURL:_trimmedURL fadeInURL:_fiveSecondURL delegate:self];
    
    [_audioEngine setPlayerNodeFileURL:_trimmedURL atIndex:0];
    
    [_audioEngine initializeAudio];

    [_audioEngine playerForNodeAtIndex:0].volume = 0.25;  // bring down the base track so mic can be heard

    _canPlayback = YES;

    // INIT UI ELEMENTS
    [_mixPanelViewController refresh];
    self.countDownLabel.hidden = YES;
    _countDownLabel.textColor = [UIColor whiteColor];
    self.recordLabel.text = @"Track 1";
    self.recordLabel.backgroundColor = [[UIColor orangeColor] colorWithAlphaComponent:0.5];

    [self.navigationController setToolbarHidden:NO];

    // ESTABLISH CAMERA CONNECTION
    [self setupCaptureSession];
    [self previewLayer];
    [self useFrontCamera];
    
    _revealMixControlsCount = 1; // is revealed with playerControls
    // with camera unhidden
    _restoreHeight1 = _ampPlayerHeightConstraint.constant;
    [self.view setNeedsLayout];

    // READ DATA
    [self readSavedMixList];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSelectAmpImage:) name:@"DidSelectAmpImage" object:nil];
}

// Trying to hide camera on startup
//    [self cameraFunction:nil];
//    //cameraFunction:nil
//    self.previewView.hidden = YES;
//    self.topSpaceForPreview.constant = -CGRectGetHeight(self.previewView.frame);
//    _ampPlayerHeightConstraint.constant = _restoreHeight1;
//    _mixContainerBottomLayout.constant = _ampPlayerHeightConstraint.constant;

//    NSMutableArray *playerNodeList = [_audioEngine playerNodeList];
//    NSInteger index = 0;
//    if ([playerNodeList count] > index) {
//        if (JWMixerNodeTypePlayer == [self typeForNodeAtIndex:index nodeList:playerNodeList]){
//            NSMutableDictionary *playerNodeInfo = playerNodeList[index];
//            playerNodeInfo[@"fileURLString"]=[self.trimmedURL path];
//        }
//    }


-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if (firstTime){
        double delayInSecs = 1.0;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSecs * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:1.0 animations:^{
                self.recordLabel.alpha = 0;
            }];
        });
    }
    firstTime = 0;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    selectedAmpImageIndex = [JWCurrentWorkItem sharedInstance].currentAmpImageIndex;
    [self updateAmpImage];
    if (firstTime){
        [_mixPanelViewController refresh];
        [self configureWithPlayerNodeList:nil];// calls [self updateButtonStates];
    }
}

#pragma mark - saved mix list

-(NSString*)documentsDirectoryPath {
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [searchPaths objectAtIndex:0];
}
-(void)saveSavedMixList{
    NSString *fpath = [[self documentsDirectoryPath] stringByAppendingPathComponent:@"savedmixes.dat"];
    [_savedMixList writeToURL:[NSURL fileURLWithPath:fpath] atomically:YES];
    NSLog(@"\n%s\nsavedmixes.dat\n%@",__func__,[_savedMixList description]);
}
-(void)readSavedMixList{
    NSString *fpath = [[self documentsDirectoryPath] stringByAppendingPathComponent:@"savedmixes.dat"];
    _savedMixList = [[NSMutableDictionary alloc] initWithContentsOfURL:[NSURL fileURLWithPath:fpath]];
    if (_savedMixList == nil) {
        _savedMixList = [NSMutableDictionary new];
    }
    NSLog(@"\n%s\nsavedmixes.dat\n%@",__func__,[_savedMixList description]);
}

#pragma mark - action sheets

-(void)onAction:(id)sender{
    if (_hasRecordingMix){
        [self actionsWithMix];
    } else {
        [self actionsNoMix];
    }
}

-(void)actionsNoMix{
    UIAlertController* actionController =
    [UIAlertController alertControllerWithTitle:@"Mixing" message:@"Select something" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* editMix =
    [UIAlertAction actionWithTitle:@"Edit Mix" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
        self.editing = YES;
    }];
    UIAlertAction* editTrimmed =
    [UIAlertAction actionWithTitle:@"Edit Trimmed" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
        [_audioEngine stopAll];
        [self dismissViewControllerAnimated:YES completion:nil];
        if ([_delegate respondsToSelector:@selector(doneGoAgain)])
            [_delegate doneGoAgain];
    }];
    
    
    BOOL canRecordIntoMix = NO;
    if ([self numberOfAvailableRecorders] > 0)
    {
        canRecordIntoMix = YES;
    }
    
    UIAlertAction* recordIntoMix = canRecordIntoMix ?
    [UIAlertAction actionWithTitle:@"Record Into Mix" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
        BOOL knownRecordPosition = NO;
        if (knownRecordPosition) {
            // The Position where to begin recording is known
            // TODO: how it is known
            NSUInteger theKnownPosition = 1;
            if (theKnownPosition == 1) {
                [self prepareToRecordAtCurrentPosition];
            } else {
                [self prepareToRecordAtBeginnig];
            }
        } else {
            // ASK
            [self actionsRecordFrom];
        }
        
    }] : nil;  // nil recordIntoMix if cannot record
    
    UIAlertAction* recordMix =
    [UIAlertAction actionWithTitle:@"Record Mix" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
        [self prepareToRecordMix];
    }];
    UIAlertAction* saveMixSettings =
    [UIAlertAction actionWithTitle:@"Save Mix Settings" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
        NSLog(@"%s feature not implemented",__func__);
    }];
    UIAlertAction* bailMix =
    [UIAlertAction actionWithTitle:@"Bail..." style:_saved ? UIAlertActionStyleCancel: UIAlertActionStyleDestructive handler:^(UIAlertAction* action) {
        [self actionsDismissToQuit];
    }];
    UIAlertAction* cancelAction =
    [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction* action) {
        
    }];
    
    [actionController addAction:editMix];
    [actionController addAction:editTrimmed];
    if (recordIntoMix)
        [actionController addAction:recordIntoMix];
    [actionController addAction:recordMix];
    [actionController addAction:saveMixSettings];
    [actionController addAction:bailMix];
    [actionController addAction:cancelAction];
    [self presentViewController:actionController animated:YES completion:nil];
}

-(void)actionsWithMix{
    UIAlertController* actionController =
    [UIAlertController alertControllerWithTitle:@"Has Mix" message:@"Select something" preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction* playMix =
    [UIAlertAction actionWithTitle:@"Play Mix" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
        [_audioEngine playMix];
        [_mixPanelViewController refresh];
        [self configureWithPlayerNodeList:nil];
        [_scrubberController play:nil];
    }];
    UIAlertAction* saveMix =
    [UIAlertAction actionWithTitle:@"Save Mix " style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
        [_savedMixList setValue:[NSNull null] forKey:[[_audioEngine mixOutputFileURL] lastPathComponent]];
        [self saveSavedMixList];
    }];
    UIAlertAction* reMix =
    [UIAlertAction actionWithTitle:@"Re Mix" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
        _hasRecordingMix = NO;
        [_audioEngine reMix]; // Use the output mix as the base for a new mix
        [_mixPanelViewController refresh];
        [self configureWithPlayerNodeList:nil];
    }];
    UIAlertAction* mixAgain =
    [UIAlertAction actionWithTitle:@"Mix Again" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
        _hasRecordingMix = NO;
        [_audioEngine revertToMixing];
        [_mixPanelViewController refresh];
        [self configureWithPlayerNodeList:nil];
    }];
    UIAlertAction* saveMixSettings =
    [UIAlertAction actionWithTitle:@"Save Mix Settings" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
        NSLog(@"%s feature not implemented",__func__);
    }];
    UIAlertAction* cancelAction =
    [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction* action) {
    }];
    
    [actionController addAction:playMix];
    [actionController addAction:saveMix];
    [actionController addAction:reMix];
    [actionController addAction:mixAgain];
    [actionController addAction:saveMixSettings];
    [actionController addAction:cancelAction];
    [self presentViewController:actionController animated:YES completion:nil];
}

-(void)actionsSelectRecorderToRecord{
    /*
     assumes more than one recorder
     */
    UIAlertController* actionController =
    [UIAlertController alertControllerWithTitle:@"Recorders" message:@"Select recorder to use" preferredStyle:UIAlertControllerStyleAlert];

    NSInteger index = 0;
    // first recorder playernode now
    for (NSDictionary *playerNodeInfo in [_audioEngine playerNodeList]) {
        JWMixerNodeTypes nodeType = [self typeForNodeAtIndex:index nodeList:[_audioEngine playerNodeList]];
        if (JWMixerNodeTypePlayerRecorder == nodeType ) {
            [actionController addAction:
             [UIAlertAction actionWithTitle:playerNodeInfo[@"title"] style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
                [self recordAtNodeIndex:index];
            }]
             ];
        }
        index++;
    }
    
    UIAlertAction* cancelAction =
    [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction* action) {
        
    }];
    
    [actionController addAction:cancelAction];
    [self presentViewController:actionController animated:YES completion:nil];
}

-(void)actionsRecordFrom{
    UIAlertController* actionController =
    [UIAlertController alertControllerWithTitle:@"Record From" message:@"Select position" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* fromCurrentPosition =
    [UIAlertAction actionWithTitle:@"Edit Mix" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
        [self prepareToRecordAtCurrentPosition];
    }];
    UIAlertAction* fromBeginning =
    [UIAlertAction actionWithTitle:@"Edit Trimmed" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
        [self prepareToRecordAtBeginnig];
    }];
    UIAlertAction* cancelAction =
    [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction* action) {
    }];

    [actionController addAction:fromCurrentPosition];
    [actionController addAction:fromBeginning];
    [actionController addAction:cancelAction];
    [self presentViewController:actionController animated:YES completion:nil];
}

-(void)actionsDismissToQuit{
    UIAlertController* actionController =
    [UIAlertController alertControllerWithTitle:@"Dismiss To Quit" message:@"Are you sure?" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* fromCurrentPosition =
    [UIAlertAction actionWithTitle:@"YES" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
        [self dismissViewControllerAnimated:YES completion:nil];
        if ([_delegate respondsToSelector:@selector(done)])
            [_delegate done];
    }];
    UIAlertAction* fromBeginning =
    [UIAlertAction actionWithTitle:@"NO" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
    }];
    UIAlertAction* cancelAction =
    [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction* action) {
    }];
    
    [actionController addAction:fromCurrentPosition];
    [actionController addAction:fromBeginning];
    [actionController addAction:cancelAction];
    [self presentViewController:actionController animated:YES completion:nil];
}

#pragma mark -

// Done with this view controller
- (IBAction)done:(id)sender {
    
    if ([_delegate respondsToSelector:@selector(doneGoAgain)])
        [_delegate doneGoAgain];

    [_scrubberController  stopPlaying:nil];
    _scrubberController.delegate = nil;
    _scrubberController = nil;

    self.scrubber.delegate = nil;
    self.scrubber = nil;

    self.localScrubber = nil;
    self.audioEngine.delegate = nil;
    self.audioEngine = nil;

    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)didSelectAmpImage:(NSNotification*)noti {
    
    NSLog(@"%s %@",__func__,[[noti userInfo] description]);

    NSNumber *selectedIndex = noti.userInfo[@"index"];
    if (selectedIndex) {
        selectedAmpImageIndex = [selectedIndex unsignedIntegerValue];
    }
    [self updateAmpImage];
}


#pragma mark - toolbar actions hide reveal items

- (IBAction)cameraFunction:(id)sender {
    
    // set whether to reveal, YES if if is hidden
    BOOL reveal = self.previewView.hidden;
    
    if (reveal) {
        self.previewView.hidden = NO;
        self.topSpaceForPreview.constant = -20;
        
        _restoreHeight1 = _ampPlayerHeightConstraint.constant;
        _ampPlayerHeightConstraint.constant = CGRectGetHeight(self.view.bounds)/5;
        _mixContainerBottomLayout.constant = _ampPlayerHeightConstraint.constant;

    } else {
        self.previewView.hidden = YES;
        self.topSpaceForPreview.constant = -CGRectGetHeight(self.previewView.frame);
        
        _ampPlayerHeightConstraint.constant = _restoreHeight1;
        _mixContainerBottomLayout.constant = _ampPlayerHeightConstraint.constant;
    }
    
    [self.view setNeedsLayout];
}

- (IBAction)scrubberReveal:(id)sender {
    
    BOOL hidden = self.scrubberContainer.hidden;
    if (hidden) {
        // set unhidden
        _scrubberHeightConstraint.constant = _restoreScrubberHeight;
        [self.view setNeedsLayout];
        self.scrubberContainer.hidden = NO;
    } else {
        // set hidden
        _restoreScrubberHeight = _scrubberHeightConstraint.constant;
        _scrubberHeightConstraint.constant = 0;
        [self.view setNeedsLayout];
        self.scrubberContainer.hidden = YES;
    }
}

- (IBAction)mixPanelReveal:(id)sender {
    /*
     Three way TOGGLE is to display non-display of Mix controls
     The first reveal will display along with playerControls
     The second reveal will display without playerControls
     */
    BOOL hidden = self.mixEditContainer.hidden;
    if (hidden) {
        // set unhidden

        _revealMixControlsCount++;
        
        if (_revealMixControlsCount > 1) {
            _ampPlayerHeightConstraint.constant = 0;
            _mixContainerBottomLayout.constant = _ampPlayerHeightConstraint.constant;
        } else {
            _ampPlayerHeightConstraint.constant = CGRectGetHeight(self.view.bounds)/5;
            _mixContainerBottomLayout.constant = _ampPlayerHeightConstraint.constant;
        }
        [self.view setNeedsLayout];
        self.mixEditContainer.hidden = NO;
        
        if (_revealMixControlsCount > 1)
            _revealMixControlsCount = 0;

    } else {
        // set hidden
        CGRect fr = self.mixEditContainer.frame;
        self.mixEditContainer.hidden = YES;
        _ampPlayerHeightConstraint.constant = CGRectGetHeight(self.view.bounds) - fr.origin.y - 44;  // minus navigation bar
        [self.view setNeedsLayout];
    }
}

// Need pass edit to mixPanel

-(void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    if (editing) {
        // EDIT YES
        if (self.previewView.hidden == NO) {
            _cameraForcedHidden = YES;
            [self cameraFunction:nil];
        }
        
        _restoreHeight1 = _ampPlayerHeightConstraint.constant;
        _ampPlayerHeightConstraint.constant = 0;
        _mixContainerBottomLayout.constant = _ampPlayerHeightConstraint.constant;
        [self.view setNeedsLayout];

        // SET button items for EDIT
        NSMutableArray *buttonItems = [NSMutableArray new];
        [buttonItems addObject:self.editButtonItem ];
        [buttonItems addObject:
         [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self.mixPanelViewController action:@selector(addAction:)]];
        
        [self.navigationItem setRightBarButtonItems:buttonItems animated:YES];
        
    } else {
        // EDIT NO
        if (_cameraForcedHidden) {
            if (self.previewView.hidden == YES) {
                [self cameraFunction:nil];
            }
            _cameraForcedHidden = NO;;
        }
        
        _ampPlayerHeightConstraint.constant = _restoreHeight1;
        _mixContainerBottomLayout.constant = _ampPlayerHeightConstraint.constant;
        [self.view setNeedsLayout];
        
        // SET button items for NOT EDIT
        NSMutableArray *buttonItems = [NSMutableArray new];
        [buttonItems addObject:
         [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(onAction:)]];
        [buttonItems addObject:self.editButtonItem ];
        [self.navigationItem setRightBarButtonItems:buttonItems animated:YES];
    }
    
    [_mixPanelViewController setEditing:editing];
    
}

#pragma mark - helpers
- (void)updateUIElements {
    _playerControlsViewController.canPlayback = _canPlayback;
    _playerControlsViewController.recording = _recording;
    _playerControlsViewController.playing = _playing;
    [_playerControlsViewController updateUIElements];
}

-(void) updateButtonStates {
    _playerControlsViewController.canPlayback = _canPlayback;
    _playerControlsViewController.recording = _recording;
    _playerControlsViewController.playing = _playing;
    [_playerControlsViewController updateButtonStates];
    [self updateButtonStatesForPlayState:playState];
}

#pragma mark  helper messages
-(void)messageMixAvailable {
    self.recordLabel.text = @"Mix Completed and Available";
    self.recordLabel.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:0.5];
    [UIView animateWithDuration:0.5 animations:^{
        self.recordLabel.alpha = 1.0;
    }];
    double delayInSecs = 1.0;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSecs * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:delayInSecs/2 animations:^{
            self.recordLabel.alpha = 0;
        }];
    });
}
-(void)messageMixerReady {
    self.recordLabel.text = @"Mixer Ready";
    self.recordLabel.backgroundColor = [[UIColor purpleColor] colorWithAlphaComponent:0.5];
    [UIView animateWithDuration:0.5 animations:^{
        self.recordLabel.alpha = 1.0;
    }];
    double delayInSecs = 1.0;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSecs * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:delayInSecs/2 animations:^{
            self.recordLabel.alpha = 0;
        }];
    });
}
-(void)messageRecordMix {
    self.recordLabel.text = @"Record Mix";
    self.recordLabel.backgroundColor = [[UIColor purpleColor] colorWithAlphaComponent:0.5];
    [UIView animateWithDuration:0.5 animations:^{
        self.recordLabel.alpha = 1.0;
    }];
    double delayInSecs = 1.0;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSecs * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:delayInSecs/2 animations:^{
            self.recordLabel.alpha = 0;
        }];
    });
}
-(void)messageJamReady {
    self.recordLabel.textColor = [UIColor whiteColor];
    self.recordLabel.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.7];
    self.recordLabel.text = @"JAM!";
    [UIView animateWithDuration:0.5 animations:^{
        self.recordLabel.alpha = 1.0;
    }];
    double delayInSecs = 1.0;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSecs * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:delayInSecs/2 animations:^{
            self.recordLabel.alpha = 0;
        }];
    });
    CATransform3D scaleTrans = CATransform3DMakeScale(3.2, 3.2, 1.0);
    _recordLabel.layer.transform = CATransform3DIdentity;
    [UIView animateWithDuration:.60f delay:0.10 options:UIViewAnimationOptionAutoreverse | UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         _recordLabel.layer.transform = scaleTrans;
                     } completion:^(BOOL fini){
                         _recordLabel.layer.transform = CATransform3DIdentity;
                     }];
}

#pragma mark  setter helpers
-(void)setTrimmedAudioPathWith:(NSString *)trimmedFilePath And5SecondPathWith:(NSString* )fiveSeconds {
    self.trimmedURL = [NSURL fileURLWithPath:trimmedFilePath];
    self.fiveSecondURL = [NSURL fileURLWithPath:fiveSeconds];;
}

-(void)setTrimmedAudioURL:(NSURL *)trimmedFileURL andFiveSecondURL:(NSURL* )fiveSecondURL {
    self.trimmedURL = trimmedFileURL;
    self.fiveSecondURL = fiveSecondURL;
    //NSLog(@"%s \n%@\n%@",__func__,_trimmedURL,_fiveSecondURL);
}

//#pragma mark MixerTable
//TODO: use this when updating
//-(void)audioConfigChanged {
//    [_audioEngine refreshEngineForEffectsNodeChanges];
//    [_audioEngine playAll];
//    [_mixEditViewController refreshNewConfig];
//}


// helpers

#pragma mark  helpers

-(NSUInteger)numberOfAvailableRecorders {
    NSUInteger result = 0;
//    NSInteger index = 0;
//    for (NSDictionary *playerNodeInfo in [_audioEngine playerNodeList]) {

    NSUInteger nNodes = [[_audioEngine playerNodeList] count];
    for (int index = 0; index < nNodes; index++) {
        JWMixerNodeTypes nodeType = [self typeForNodeAtIndex:index nodeList:[_audioEngine playerNodeList]];
        if (JWMixerNodeTypePlayerRecorder == nodeType )
            result++;
    }
    return result;
}

-(NSUInteger)firstAvailableRecorderIndex {
    NSUInteger result = 0;
//    NSInteger index = 0;
    // first recorder playernode now
    NSUInteger nNodes = [[_audioEngine playerNodeList] count];
    for (int index = 0; index < nNodes; index++) {
        JWMixerNodeTypes nodeType = [self typeForNodeAtIndex:index nodeList:[_audioEngine playerNodeList]];
        if (JWMixerNodeTypePlayerRecorder == nodeType ) {
            result=index;
            break;
        }
    }
    return result;
}

-(void)updateAmpImage {
    NSLog(@"%s %ld",__func__, selectedAmpImageIndex);
    //jwjustscreensonly - 2
    //jwjustscreensandlogos - 1
    //jwscreensandcontrols
    //jwscreensandcontrols - 1
    UIImage *ampImage = [UIImage imageNamed:[NSString stringWithFormat:@"jwjustscreensandlogos - %ld",selectedAmpImageIndex + 1]];
    dispatch_async(dispatch_get_main_queue(), ^{
        [_playerControlsViewController.ampImageView setImage:ampImage];
        [self.playerControlsViewController.view setNeedsLayout];
        //        _ampImageView.image = ampImage;
        //        [self.view setNeedsLayout];
    });
}


-(JWMixerNodeTypes)typeForNodeAtIndex:(NSUInteger)index nodeList:(NSArray*)playerNodeList {
    JWMixerNodeTypes result = 0;
    if ([playerNodeList count] > index) {
        NSDictionary *playerNodeInfo = playerNodeList[index];
        
        id type = playerNodeInfo[@"type"];
        if (type)
            result = [(NSNumber*)type integerValue];
    }
    return result;
}



#pragma mark - ScrubberDelegate

-(void)positionInTrackChangedProgress:(CGFloat)progress {
    [_audioEngine setProgressSeekingAudioFile:progress];
    [_audioEngine changeProgressOfSeekingAudioFile:progress ];
}

#pragma mark scrubber controler Delegate for buffers

-(CGFloat)progressOfAudioFile:(JWScrubberController*)self forScrubberId:(NSString*)sid{
    return [_audioEngine progressOfSeekingAudioFile];
}
-(CGFloat)durationInSecondsOfAudioFile:(JWScrubberController*)self forScrubberId:(NSString*)sid{
    return [_audioEngine durationInSecondsOfSeekingAudioFile];
}
-(CGFloat)remainingDurationInSecondsOfAudioFile:(JWScrubberController*)self forScrubberId:(NSString*)sid{
    return [_audioEngine remainingDurationInSecondsOfSeekingAudioFile];
}
-(CGFloat)currentPositionInSecondsOfAudioFile:(JWScrubberController*)self forScrubberId:(NSString*)sid{
    return [_audioEngine currentPositionInSecondsOfSeekingAudioFile];
}
-(NSString*)processingFormatStr:(JWScrubberController*)self forScrubberId:(NSString*)sid{
    return [_audioEngine processingFormatStr];
}


#pragma mark MixPanel delegate

-(void)play {
    
}
-(void)rewind {
    
}
-(void)pause {
    
}
-(void)mixPanelDone:(JWMixPanelViewController*)controller {
    
}

-(id <EffectsHandler>)effectsHandler
{
    return self.audioEngine;
}

-(void)playerNodeListChanged:(JWMixPanelViewController*)controller
{
    [self configureWithPlayerNodeList:[controller playerNodeList]];
}

- (id <JWEffectsModifyingProtocol>) mixNodeControllerForScrubber
{
    return _scrubberController;
}

- (void)recordAtNodeIndex:(NSUInteger)index
{
    [self prepareToRecordWithRecorderAtIndex:index fromBeginning:NO];
}


#pragma mark -

/*
 configureWithPlayerNodeList
 
 will iterate through nodeList
 implementing scrubbers for each
 
 pass nil to nodeList to use current config from engine
 */
-(void)configureWithPlayerNodeList:(NSArray*)nodeList {
    [self configureWithPlayerNodeList:nodeList recording:NO];
}

/*
 recording : whther something is being recorded
 */
-(void)configureWithPlayerNodeList:(NSArray*)nodeList recording:(BOOL)recording {
    [self configureWithPlayerNodeList:nodeList recordingAudio:recording recordingingMix:NO];
}

-(void)configureScrubberColorsRecordingAudio:(BOOL)recordAudio recordingingMix:(BOOL)recordMix hasMixerPlayer:(BOOL)mixerPlayer {
    
    // Configure Track Colors for all Tracks
    // Override per track if wanted
    // configureColors is whole saled the dictionary is simply kept
    // Whereas per track will interleave with this
    // Configure with RED colors for recording
    
    if (colorizedTracks == NO) {  // set the base to whites
        // Track colors whiteColor/ whiteColor - WHITE middle
        [_scrubberController configureColors:
         @{
           JWColorScrubberTopPeak : [[UIColor whiteColor] colorWithAlphaComponent:0.8],
           JWColorScrubberTopAvg : [UIColor colorWithWhite:0.9 alpha:0.5] ,
           JWColorScrubberBottomAvg : [UIColor colorWithWhite:0.9 alpha:0.5],
           JWColorScrubberBottomPeak : [[UIColor whiteColor] colorWithAlphaComponent:0.6],
           
           JWColorScrubberTopPeakNoAvg : [[UIColor whiteColor] colorWithAlphaComponent:0.8],
           JWColorScrubberBottomPeakNoAvg : [[UIColor whiteColor] colorWithAlphaComponent:0.8],
           }
         ];
    }
    
    if (recordMix || recordAudio ) {
        
        [_scrubberController configureScrubberColors:
         @{
           JWColorBackgroundHueColor : [UIColor redColor],
           }];

        // RECORD MIX
        if (recordMix) {
            if (colorizedTracks)
                // Track colors whiteColor/ whiteColor - WHITE middle
                [_scrubberController configureColors:
                 @{
                   JWColorScrubberTopPeak : [[UIColor whiteColor] colorWithAlphaComponent:0.8],
                   JWColorScrubberTopAvg : [UIColor colorWithWhite:0.9 alpha:0.5] ,
                   JWColorScrubberBottomAvg : [UIColor colorWithWhite:0.9 alpha:0.5],
                   JWColorScrubberBottomPeak : [[UIColor whiteColor] colorWithAlphaComponent:0.6],
                   
                   JWColorScrubberTopPeakNoAvg : [[UIColor whiteColor] colorWithAlphaComponent:0.8],
                   JWColorScrubberBottomPeakNoAvg : [[UIColor whiteColor] colorWithAlphaComponent:0.8],
                   }
                 ];
        }
        // RECORDER
        else if (recordAudio) {
            if (colorizedTracks)
                // yellowColor / YELLOW - WHITE middle
                [_scrubberController configureColors:
                 @{
                   JWColorScrubberTopPeak : [[UIColor yellowColor] colorWithAlphaComponent:0.8],
                   JWColorScrubberTopAvg : [UIColor colorWithWhite:0.9 alpha:0.5] ,
                   JWColorScrubberBottomAvg : [UIColor colorWithWhite:0.9 alpha:0.5],
                   JWColorScrubberBottomPeak : [[UIColor yellowColor] colorWithAlphaComponent:0.8],
                   
                   JWColorScrubberTopPeakNoAvg : [[UIColor yellowColor] colorWithAlphaComponent:0.8],
                   JWColorScrubberBottomPeakNoAvg : [[UIColor yellowColor] colorWithAlphaComponent:0.8],
                   }
                 ];
        }
    }
    
    // ALL OTHERS
    else {
        if (colorizedTracks)
            // Configure with WHITE colors for playing
            [_scrubberController configureColors:
             @{
               JWColorScrubberTopAvg : [UIColor colorWithWhite:0.9 alpha:0.5] ,
               JWColorScrubberTopPeak : [UIColor colorWithWhite:0.7 alpha:0.5],
               JWColorScrubberBottomAvg : [UIColor colorWithWhite:0.7 alpha:0.5],
               JWColorScrubberBottomPeak : [UIColor colorWithWhite:0.9 alpha:0.5],
               
               JWColorScrubberBottomPeakNoAvg : [UIColor colorWithWhite:0.9 alpha:0.5] ,
               JWColorScrubberTopPeakNoAvg : [UIColor colorWithWhite:0.9 alpha:0.5],
               }
             ];
        
        // MIXER Player
        
        if (mixerPlayer) {
            [_scrubberController configureScrubberColors:
             @{
               JWColorBackgroundHueColor : iosColor1,
               }];
        } else {
            [_scrubberController configureScrubberColors:
             @{
               JWColorBackgroundHueColor : iosColor2,
               }];
        }
    }
    
}

//    if (recordAudio) {
//        self.saveColorFromRecording = _scrubberController.backLightColor;
//        _scrubberController.backLightColor = [UIColor redColor];
//    } else {
//        if (_saveColorFromRecording) {
//            _scrubberController.backLightColor = _saveColorFromRecording;
//            _saveColorFromRecording = nil;
//        }
//    }



/*
 recordingAudio : whther something is being recorded from mic
 recordingMix : whther is recording mix
 */
-(void)configureWithPlayerNodeList:(NSArray*)nodeList recordingAudio:(BOOL)recordAudio recordingingMix:(BOOL)recordMix {
    
    if (_hasRecordingMix)
        [self.navigationItem setTitle:@"Has Mix"];
    else
        [self.navigationItem setTitle:@"Mixing"];
    
    
    NSArray *playerNodelist = nodeList ? nodeList : [_audioEngine playerNodeList];

    NSLog(@"%s %@",__func__,[playerNodelist description]);

    BOOL tapMixer = YES;
    if (recordAudio)
        tapMixer = NO;
    if (recordMix)
        tapMixer = YES;

    // Count the number of tracks first, then configure the scrubber and add the tracks
    
    NSUInteger countTracks = 0;
    
    BOOL hasMixerPlayer = NO; // used to set colors
    
    // Logic to count tracks should match adding scrubbers
    // STEP 1 COUNT the number of tracks
    
    NSUInteger nNodes = [[_audioEngine playerNodeList] count];
    for (int index = 0; index < nNodes; index++) {
        
        JWMixerNodeTypes nodeType = [self typeForNodeAtIndex:index nodeList:playerNodelist];

        NSURL *fileURL = [_audioEngine playerNodeFileURLAtIndex:index];

        // PLAYER RECORDER
        if (nodeType == JWMixerNodeTypePlayerRecorder) {
            
            BOOL usePlayerScrubber = NO;  // determine whther to use player or recorder for scrubber
            if (recordAudio && _selectedRecorderIndex == index) {
                // USE recorder
            } else {
                // not the current recorder - useplayer if has fileURL
                if (fileURL == nil) {
                    NSLog(@"%s NO file url at index %d",__func__,index);
                } else {
                    usePlayerScrubber = YES;
                }
            }
            
            if (usePlayerScrubber) {
                countTracks++;
            } else if (recordMix == NO) {
                countTracks++;
            }
        }
        // PLAYER
        else if (nodeType == JWMixerNodeTypePlayer) {
            // dont count if no file URL for player
            if (fileURL)
                countTracks++;
        }
        // MIXER PLAYER
        else if (nodeType == JWMixerNodeTypeMixerPlayer) {
            // dont count if no file URL for player
            if (fileURL)
                countTracks++;
            
            hasMixerPlayer = YES;
            tapMixer = NO;
        }
    }
    
    if (tapMixer)
        countTracks++;

    NSLog(@"%s tracks = %ld",__func__,countTracks);

    // STEP 2 CONFIGURE SCRUBBER SETTINGS

    _scrubberController.useGradient = YES;
    [_scrubberController reset];
    _scrubberController.numberOfTracks = countTracks;
    [self configureScrubberColorsRecordingAudio:recordAudio recordingingMix:recordMix hasMixerPlayer:hasMixerPlayer];
    [_scrubberController setViewOptions:ScrubberViewOptionNone];
    [self updateScrubberHeight];

    // STEP 3 CONTINUE TO ADD TRACKS TO SCRUBBER

    for (int index = 0; index < nNodes; index++) {

        NSURL *fileURL = [_audioEngine playerNodeFileURLAtIndex:index];

        JWMixerNodeTypes nodeType = [self typeForNodeAtIndex:index nodeList:playerNodelist];
        // PLAYER
        if (nodeType == JWMixerNodeTypePlayer) {
            
            if (fileURL) {
                _canPlayback = YES;  // if any one player can play
//                NSLog(@"%s file url at index %ld\n%@",__func__,index,[fileURL description]);
                NSLog(@"%s file at index %d\n%@",__func__,index,[fileURL lastPathComponent]);
                
                // INSIDE  BLUE / BLUE
                [_scrubberController prepareScrubberFileURL:fileURL
                                             withSampleSize:SampleSize14
                                                    options:SamplingOptionDualChannel
                                                       type:VABOptionNone
                                                     layout:VABLayoutOptionOverlayAverages | VABLayoutOptionShowAverageSamples | VABLayoutOptionShowCenterLine
                                                     colors:colorizedTracks
                 ? @{
                     JWColorScrubberTopAvg : [[UIColor blueColor] colorWithAlphaComponent:0.8] ,
                     JWColorScrubberBottomAvg : [[UIColor blueColor] colorWithAlphaComponent:0.5],
                     }:nil
                                               onCompletion:nil];
                
            } else {
                // no file URL for player
                NSLog(@"%s NO file url at index %d",__func__,index);
            }
        }
        // PLAYER RECORDER
        else if (nodeType == JWMixerNodeTypePlayerRecorder) {
            
            BOOL usePlayerScrubber = YES;  // determine whther to use player or recorder for scrubber
            
            if (recordAudio && _selectedRecorderIndex == index) {
                // USE recorder
                usePlayerScrubber = NO;
            } else if (fileURL == nil) {
                usePlayerScrubber = NO;  // not the current recorder - useplayer if has fileURL
            }

            NSLog(@"%s use player %@ at index %d",__func__,usePlayerScrubber?@"YES":@"NO",index);
            
            if (usePlayerScrubber) {

                // PLAYER - YELLOW / YELLOW
                [_scrubberController prepareScrubberFileURL:fileURL
                                             withSampleSize:SampleSize14
                                                    options:SamplingOptionDualChannel
                                                       type:VABOptionNone
                                                     layout:VABLayoutOptionOverlayAverages | VABLayoutOptionShowAverageSamples | VABLayoutOptionShowCenterLine
                                                     colors:colorizedTracks
                 ? @{
                     JWColorScrubberTopPeak : [[UIColor yellowColor] colorWithAlphaComponent:0.7],
                     JWColorScrubberBottomPeak : [[UIColor yellowColor] colorWithAlphaComponent:0.7],
                     }:nil
                                               onCompletion:nil];
                
            } else {
                if (recordMix == NO) { // uninterested in recorder here only need player for PlayerNodes
                    
                    // use recorder
                    NSString *recorderTrackId =
                    [_scrubberController prepareScrubberListenerSource:nil
                                                        withSampleSize:SampleSize10
                                                               options:SamplingOptionDualChannel
                                                                  type:VABOptionCenter
                                                                layout:VABLayoutOptionStackAverages | VABLayoutOptionShowAverageSamples
                                                                colors:colorizedTracks
                     ? @{
                         JWColorScrubberTopPeak : [[UIColor redColor] colorWithAlphaComponent:0.5],
                         JWColorScrubberBottomPeak : [[UIColor yellowColor] colorWithAlphaComponent:0.7],
                         }:nil
                                                          onCompletion:nil];
                    
                    [_audioEngine registerController:_scrubberController withTrackId:recorderTrackId forPlayerRecorderAtIndex:index];
                }
            }
        }
        // MIXER PLAYER
        else if (nodeType == JWMixerNodeTypeMixerPlayer) {
            
            tapMixer = NO;

            if (fileURL) {
                NSLog(@"%s mixfile at index %d\n%@",__func__,index,[fileURL lastPathComponent]);

                // PLAYER - GREEN / GREEN
                [_scrubberController prepareScrubberFileURL:fileURL
                                             withSampleSize:SampleSize14
                                                    options:SamplingOptionDualChannel
                                                       type:VABOptionNone
                                                     layout:VABLayoutOptionStackAverages | VABLayoutOptionShowAverageSamples | VABLayoutOptionShowCenterLine
                                                     colors:colorizedTracks
                 ? @{
                     JWColorScrubberTopPeak : [[UIColor greenColor] colorWithAlphaComponent:0.7],
                     JWColorScrubberBottomPeak : [[UIColor greenColor] colorWithAlphaComponent:0.5],
                     }:nil
                                               onCompletion:nil];
            }
            
        }
        
    } // for each node
    
    
    if (tapMixer) {
        // ADD A TAP to mixer for playAlll
        // GREEN / YELLOW
        NSString *trackidMixerTap =
        [_scrubberController prepareScrubberListenerSource:nil
                                            withSampleSize:SampleSize14
                                                   options:SamplingOptionDualChannel
                                                      type:VABOptionNone
                                                    layout:VABLayoutOptionStackAverages | VABLayoutOptionShowAverageSamples | VABLayoutOptionShowCenterLine
                                                    colors:colorizedTracks
         ? @{
             JWColorScrubberTopPeak : [[UIColor greenColor] colorWithAlphaComponent:0.5],
             JWColorScrubberBottomPeak : [[UIColor yellowColor] colorWithAlphaComponent:0.7],
             }:nil
                                              onCompletion:nil];
        
        [_audioEngine registerController:_scrubberController withTrackId:trackidMixerTap forPlayerRecorder:@"mixer"];
    }

    
    [self updateUIElements];
    
    [self updateButtonStates];
    
}


//NSLog(@"%s file url at index %ld\n%@",__func__,index,[fileURL description]);


#pragma mark - audio engine delegate


/*
 completion notifications
 
 from the audio engine help to understand what has completed
 fiveSecondBufferCompletion - when a fade in is used this is called when fade in completed
   the main audio begins to play immediately after
   this tells us that recording if any has started
 
 userAudioObtained - indeed a recording had started and is finished (stopped Recording)
   the player recorder that recorded the file is updated and will play on next playAll
   under that player recorder
 
 completedPlayingAtPlayerIndex - standard playbacks call this when they have completed
   knowledge of  which index the player has finsihed can be used to conditionally
   perform function, change state, or start process

 mixRecordingCompleted - is called when a reques to record the mix has completed
   a file is generated of the recorded output (that is the recording of the Mixer) while
   playback. The file has been set and configured into a single player PlayerNode list
   to allow playback of just the mix
 
 playingCompleted - deprecated use completedPlayingAtPlayerIndex
 playMixCompleted - deprecated use completedPlayingAtPlayerIndex
 
 */

-(void)fiveSecondBufferCompletion {
    NSLog(@"%s",__func__);
    dispatch_async(dispatch_get_main_queue(), ^{
        self.countDownLabel.hidden = YES;
    });
    [self messageJamReady];
    [self.countDownTimer invalidate];
    [self.mixerValueFadeTimer invalidate];
    _audioEngine.mixerVolume = 1.0;
}

-(void)userAudioObtained {
    NSLog(@"%s",__func__);
    [_scrubberController stopPlaying:nil];
    // The playing of Track while recording from Mic is done, mix it
    [_audioEngine stopAll]; // removes mixer tap if vab installed tap
    // TODO: brendan verify playstate
    playState = (PlayStateStoppedAndReset | PlayStateHasUserAudio);
//    playState |= PlayStateHasUserAudio;
//    playState |= PlayStateStoppedAndReset;
//    playState &= ~PlayStatePlaying;

    _recording = NO;
    _canPlayback = YES;
//    _playing = NO;
    // Automatically startMixing
    _isMixing = YES;
    [_mixPanelViewController refresh];
    [self configureWithPlayerNodeList:nil]; // calls updateButtonStates; which updates StatesplayState
    [self messageMixerReady];
}

-(void)completedPlayingAtPlayerIndex:(NSUInteger)index {
    NSLog(@"%s %ld",__func__,index);
    
    // currently captures simply play all feedback
    if (index==0) { // primary player
        BOOL looping = NO;  // TODO: determine looping
        if (looping == NO) {
            [_scrubberController stopPlaying:nil];
            [_audioEngine stopAll]; // removes mixer tap if vab installed tap
            
            playState |= PlayStateStoppedAndReset;
            
            for (JWPlayerNode* pn in [_audioEngine activePlayerNodes])
            {
                [pn stop];
            }
            [self updateButtonStatesForPlayState:playState];
            // Does not call configure
        }
    }
}

/*
 mixRecordingCompleted
 called when recording mix is completed
 */
-(void)mixRecordingCompleted {
    NSLog(@"%s",__func__);
    [self.navigationItem setTitle:@"Has Mix"];
    [self messageMixAvailable];
    // This is a new recording
    _saved = NO;  // until YES! is satisfied is done
    _playing= NO;
    _canPlayback = YES;
    _isRecordingMix = NO;
    _hasRecordingMix = YES;
    _recording = NO;
    
    [_scrubberController stopPlaying:nil rewind:YES];
    // BUILD the PLAY MIX
    [_audioEngine prepareToPlayMix];
    [self configureWithPlayerNodeList:nil];// will[self updateButtonStates];
}

-(void)playingCompleted {
    NSLog(@"%s",__func__);
    [_scrubberController stopPlaying:nil];
    // This is a new recording
    _saved = NO;  // until YES! is satisfied is done
    _playing = NO;
    self.recordLabel.text = @"";
    [self updateButtonStates];
}

-(void)playMixCompleted {
    NSLog(@"%s",__func__);
    if (_isPlayingMix)
        [_scrubberController stopPlaying:nil];
    //_playing = NO;
    _needsRewind = YES;
    _isPlayingMix = NO;
    _canPlayback = YES;
    [self updateButtonStates];
}


/*
 PlayState - state of player

 playState is used to enable disable playerController buttons
 and operation when those buttons are set
 NOTE: playstate is currently a little flaky and needs attention
 need to ensure if and switches cover all cases or offer a default state
 */

#pragma mark - PlayState and Actions

typedef NS_OPTIONS(NSInteger, PlayState) {
    PlayStatePlaying         = 1 << 0, // bits: 0001
    PlayStateStoppedAndReset = 1 << 1,
    PlayStatePaused          = 1 << 2,
    PlayStateRecording       = 1 << 3,
    PlayStateHasUserAudio    = 1 << 4,
};

PlayState playState = PlayStateStoppedAndReset;

-(void)updateButtonStatesForPlayState:(NSUInteger)playState {
//    _playerControlsViewController.canPlayback = _canPlayback;
//    _playerControlsViewController.recording = _recording;
//    _playerControlsViewController.playing = _playing;
    switch (playState) {
        case PlayStatePlaying:
        case PlayStatePlaying | PlayStateRecording:
        case PlayStatePlaying | PlayStateHasUserAudio:
            _playerControlsViewController.recordButton.enabled = YES;
            _playerControlsViewController.recording = YES;
//            _playerControlsViewController.recordButton.drawingStyle = recordEnabledButtonStyle;
            _playerControlsViewController.playing = YES;
            _playerControlsViewController.canPlayback = YES;
//            _playerControlsViewController.playButton.drawingStyle = pauseButtonStyle;
            [_playerControlsViewController updateButtonStates];
            break;
         
        case PlayStateStoppedAndReset:
        case PlayStatePaused:
        case PlayStatePaused | PlayStateRecording:
        case PlayStatePaused | PlayStateHasUserAudio:
            _playerControlsViewController.recordButton.enabled = YES;
            _playerControlsViewController.recording = YES;
//            _playerControlsViewController.playButton.drawingStyle = playButtonStyle;
            _playerControlsViewController.canPlayback = YES;
//            _playerControlsViewController.recordButton.drawingStyle = recordEnabledButtonStyle;
            [_playerControlsViewController updateButtonStates];
            break;
            
        case PlayStateStoppedAndReset | PlayStateHasUserAudio:
            _playerControlsViewController.playing = NO;
            _playerControlsViewController.canPlayback = YES;
//            _playerControlsViewController.playButton.drawingStyle = playButtonStyle;
//            _playerControlsViewController.recordButton.drawingStyle = recordDisabledButtonStyle;
            _playerControlsViewController.recordButton.enabled = NO;
            [_playerControlsViewController updateButtonStates];
            break;
        default:
            NSLog(@"%s lost state",__func__);
            _playerControlsViewController.playing = NO;
            _playerControlsViewController.recording = NO;
            _playerControlsViewController.canPlayback = YES;
            //            _playerControlsViewController.playButton.drawingStyle = playButtonStyle;
            //            _playerControlsViewController.recordButton.drawingStyle = recordDisabledButtonStyle;
            _playerControlsViewController.recordButton.enabled = YES;
            [_playerControlsViewController updateButtonStates];
            break;
    }
    
    [_playerControlsViewController.view setNeedsLayout];

}

- (IBAction)playPauseAction:(id)sender {
    NSLog(@"%s",__func__);
    _recording = NO;

    if (playState == PlayStateStoppedAndReset) { //If stopped, start
        playState = PlayStatePlaying;
        [self playAction];
        
    } else if (playState == PlayStatePlaying) { //if playing, invalidate timer and pause

        [_scrubberController stopPlaying:nil];
        // pause all player nodes
        for (JWPlayerNode* pn in [_audioEngine activePlayerNodes])
        {
            [pn pause];
        }
        [_audioEngine pauseAlll]; // just to suspend _scrubber listener
        playState = PlayStatePaused;
        
    } else if (playState == PlayStatePaused) {  //if paused, start playing
        [self playActionFromPaused];
        playState = PlayStatePlaying;
        for (JWPlayerNode* pn in [_audioEngine activePlayerNodes])
        {
            [pn play];
        }
    } else if (playState == (PlayStatePlaying | PlayStateRecording)) {
        //If they hit the pause button while they are recording (maybe they messed up and want to start over)
        //We must stop and discard the record, reset the play, and start over ourselves
        //Do stuff.....
        
        playState = PlayStatePaused | PlayStateRecording;
        
    } else if (playState == (PlayStatePlaying | PlayStateHasUserAudio)) { //if playing two tracks at once
        [_scrubberController stopPlaying:nil];
        // pause all player nodes
        for (JWPlayerNode* pn in [_audioEngine activePlayerNodes])
            [pn pause];
        [_audioEngine pauseAlll]; // just to suspend _scrubber listener

        playState = PlayStatePaused | PlayStateHasUserAudio;
        
    } else if (playState == (PlayStatePaused | PlayStateHasUserAudio)) { //if two tracks are paused at once
        
        NSLog(@"Paused with User.");
        playState = PlayStatePlaying | PlayStateHasUserAudio;
        [self playAction];

    } else if (playState == (PlayStateStoppedAndReset | PlayStateHasUserAudio)) {
        
        playState = PlayStatePlaying | PlayStateHasUserAudio;
        [self playAction];
    }
    
    
    [self updateButtonStatesForPlayState:playState];
}


- (IBAction)recordAction:(id)sender {
    NSLog(@"%s",__func__);
    
    // recording stops playback and recording if we are already recording
    if (playState == PlayStatePlaying || playState == PlayStatePaused) {
        [self rewindAction:nil];
        playState = PlayStateStoppedAndReset;
    }
    
    if (playState == PlayStateStoppedAndReset) {
        _canPlayback = NO;
        _isRecordingMix = YES;
        
        if ([self numberOfAvailableRecorders] > 1) {
            
            [self actionsSelectRecorderToRecord];
            
        } else {

            // Record the mix
            // Both tracks have finsihed, proceed
            [self messageRecordMix];
            [self prepareToRecord]; // record at first available
            [_scrubberController play:nil];
            playState = PlayStatePlaying | PlayStateRecording;
        }
    }

    [self updateButtonStatesForPlayState:playState];
    
}

//_canPlayback = YES;
//[_audioEngine playAllAndRecordIt]; // will record the output of both players
//_isPlayingMix = NO;
//[_audioEngine prepareToRecord];


- (IBAction)rewindAction:(id)sender {
    
    NSLog(@"%s",__func__);
    
    if (playState & PlayStateHasUserAudio) {
        [_scrubberController stopPlaying:nil rewind:YES];
        [_audioEngine stopAll];
        playState = PlayStateStoppedAndReset | PlayStateHasUserAudio;
        [self updateButtonStatesForPlayState:playState];
    } else {
        [_scrubberController stopPlaying:nil rewind:YES];
        [_audioEngine stopPlayingTrack1];
        playState = PlayStateStoppedAndReset;
        [self updateButtonStatesForPlayState:playState];
    }
    
    [_scrubberController stopPlaying:nil rewind:YES];
    [_audioEngine stopPlayingTrack1];
    playState = PlayStateStoppedAndReset;
    [self updateButtonStatesForPlayState:playState];
}

// HELPER ACTIONS

-(void)rewindActionWhilePlaying {
    //_recording = NO;
    //_playing = NO;
    if (playState & PlayStateHasUserAudio) {
        [_scrubberController stopPlaying:nil rewind:YES];
        [_audioEngine stopAll];
    } else {
        [_scrubberController stopPlaying:nil rewind:YES];
        [_audioEngine stopPlayingTrack1];
    }
}

-(void)playAction {
    [_audioEngine playAlll];
    [_mixPanelViewController refresh];
    [_scrubberController play:nil];
}

-(void)playActionFromPaused {
    [_audioEngine resumeAlll];
    // play all active player nodes
    for (JWPlayerNode* pn in [_audioEngine activePlayerNodes]) {
        [pn play];
    }
    [_scrubberController play:nil];
}


#pragma mark - prepareToRecord
/*
 prepareToRecord methods ready the system for recording and may actually begn recording depending
 
 prepareToRecord -  first available recorder
 prepareToRecordAtCurrentPosition - records at the current loc, with first available recorder
   NOTE: not implemented
 prepareToRecordAtBeginnig - records from the beginning, with first available recorder
 prepareToRecordWithRecorderAtIndex - allows
 
 */
-(void)prepareToRecord {

    [self prepareToRecordFirstAvailable];
}

-(void)prepareToRecordFirstAvailable {
    
    [self prepareToRecordAtBeginnig];
}

-(void)prepareToRecordAtCurrentPosition {
    
    [self prepareToRecordAtCurrentPositionUsingFirstAvailable];
}

-(void)prepareToRecordAtCurrentPositionUsingFirstAvailable {
    if ([self numberOfAvailableRecorders] > 0) {
        [self prepareToRecordWithRecorderAtIndex:[self firstAvailableRecorderIndex] fromBeginning:NO];
    } else {
        NSLog(@"%s NO AVAILABLE recorders",__func__);
    }
}

-(void)prepareToRecordAtBeginnig {
    [self prepareToRecordAtBeginnigUsingFirstAvailable];
}

-(void)prepareToRecordAtBeginnigUsingFirstAvailable {
    if ([self numberOfAvailableRecorders] > 0) {
        [self prepareToRecordWithRecorderAtIndex:[self firstAvailableRecorderIndex] fromBeginning:YES];
    } else {
        NSLog(@"%s NO AVAILABLE recorders",__func__);
    }
}

-(void)prepareToRecordWithRecorderAtIndex:(NSUInteger)index fromBeginning:(BOOL)beginning {
    
    _selectedRecorderIndex = index;
    
    self.scrubberContainer.hidden = NO;

    _canPlayback = NO;
    [self updateButtonStates];

    if (beginning) {
        _countDownLabelValue = 5;
        self.recordLabel.text = @"countdown";
        [self presentCountDownValue];
        self.countDownLabel.hidden = NO;

        [_audioEngine prepareToRecordFromBeginningAtPlayerRecorderNodeIndex:_selectedRecorderIndex];
        
        self.countDownTimer =
        [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(countdownTimerFireMethod:)
                                       userInfo:nil repeats:YES];
        self.mixerValueFadeTimer =
        [NSTimer scheduledTimerWithTimeInterval:0.10 target:self selector:@selector(fadeTimerFireMethod:)
                                       userInfo:nil repeats:YES];
    } else {
        
        [_audioEngine recordWithPlayerRecorderAtNodeIndex:_selectedRecorderIndex];
    }

    [_mixPanelViewController refresh];
    [self configureWithPlayerNodeList:nil recording:YES];
    [self updateButtonStatesForPlayState:playState];
}

/*
 prepareToRecordMix
 
 play mix and record it
 */

-(void)prepareToRecordMix {
    
    [_audioEngine playAllAndRecordIt]; // will record the output of all players
    [_mixPanelViewController refresh];
    [self configureWithPlayerNodeList:nil recordingAudio:NO recordingingMix:YES];
    [_scrubberController play:nil];
}

#pragma mark - countdown to JAM

-(void)fadeTimerFireMethod:(NSTimer *)timer {
//    NSLog(@"%s increase volume: %f",__func__, [_audioEngine mixerVolume]);
    float timerStep = 0.10; // timer interval
    float factorIncrement = timerStep / 5.0f;  // divide by 5 seconds
    float mvol = [_audioEngine mixerVolume] + factorIncrement;

    if (mvol > 1.00f) {
        [timer invalidate];
        _audioEngine.mixerVolume = 1.00f;
        
    } else {
        _audioEngine.mixerVolume = mvol;
    }
}

-(void)countdownTimerFireMethod:(NSTimer *)timer {
    NSLog(@"%s count %d volume: %f",__func__, _countDownLabelValue,[_audioEngine mixerVolume]);
    _countDownLabelValue--;
    if (_countDownLabelValue < 3) {
        self.recordLabel.text = @"";
    }

    if (_countDownLabelValue > 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self presentCountDownValue];
            });
    } else {
        // five second was not completing
        [self.countDownTimer invalidate];
    }
}

-(void)presentCountDownValue {
    self.countDownLabel.text = [NSString stringWithFormat:@"%i", _countDownLabelValue];
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

#pragma mark view controller

-(void)didReceiveMemoryWarning {
    NSLog(@"%s",__func__);
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    NSLog(@"%s",__func__);
    // SCRUBBER VIEW
    if ([segue.identifier isEqualToString:@"ScrubberView"]) {
        self.localScrubber = (JWScrubberViewController*)segue.destinationViewController;
//        self.localScrubber.delegate = self;
        self.localScrubber.useGradient = YES;
        self.scrubber = _localScrubber;
        self.scrubberController = [[JWScrubberController alloc] initWithScrubber:self.scrubber];
        self.scrubberController.delegate = self;
    }

    // MIX PANEL
    else if ([[segue identifier] isEqualToString:@"JWMixPanelEmbedSegue"]) {
        self.mixPanelViewController = (JWMixPanelViewController*)segue.destinationViewController;
//        _mixPanelViewController.effectsHandler = self.audioEngine;
        _mixPanelViewController.delegate = self;
        _mixPanelViewController.embedded = YES;
    }

    // AMP PLAYER
    else if ([[segue identifier] isEqualToString:@"JWAmpPlayerSegue"]) {
        self.playerControlsViewController = (JWPlayerControlsViewController*)segue.destinationViewController;
        _playerControlsViewController.delegate = self;
        [self updateUIElements];
    }

    // UNUSED
    else if ([[segue identifier] isEqualToString:@"JWMixEditEmbedSegue"]) {
//        self.mixEditViewController = (JWMixEditTableViewController*)segue.destinationViewController;
//        _mixEditViewController.delegateMixEdit = self;
//        [_mixEditViewController refresh];
    }
    else if ([[segue identifier] isEqualToString:@"JWRecordJamToMixerControlPanelSegue"]) {
        //TODO: does this even happen with the joint container controller??
        // Joe: NO
//        UINavigationController* destination = (UINavigationController *) segue.destinationViewController;
//        JWMixerTableViewController  *mixerTable = [destination viewControllers][0];
//        //mixerTable.delegateMixerTable = self;
    }
    else if ([[segue identifier] isEqualToString:@"MixPanelSegue"]) {
        // MixPanel presentation
//        UINavigationController* destination = (UINavigationController *) segue.destinationViewController;
//        JWMixPanelViewController  *mixerTable = [destination viewControllers][0];
////        mixerTable.effectsHandler = self.audioEngine;
    }

}

#pragma mark - demo config

/*
 demoConfig - has a number of scrubber controller configs
 
 that show he capabilities ofthe controller
 the methoods used to all be in this object but are now
 in a controller that by setting this as delegate 
 the demos should be operational
 This hookup has not occurred, however the the delegate is defined
 */
-(void)demoConfigAdjustment:(CGFloat)value {

    [_scrubber adjustWhiteBacklightValue:value];
    return;
    
    CGFloat visualAlpha = value;
    CGFloat minVisualAlpha = 0.3;
    if (value < minVisualAlpha) {
        visualAlpha = minVisualAlpha;
        if (value < 0.06) {
            if (_scrubberPrimaryGreyedOut == NO){
                NSLog(@"%s  GREY OUT value %.3f",__func__,value);
                NSDictionary *scrubberColors =
                @{
                  //      JWColorScrubberTopPeakNoAvg : [[UIColor redColor] colorWithAlphaComponent:0.8],
                  JWColorScrubberTopAvg : [UIColor colorWithWhite:0.7 alpha:0.9] ,
                  JWColorScrubberTopPeak : [UIColor colorWithWhite:0.8 alpha:0.8] ,
                  //      JWColorScrubberBottomPeakNoAvg : [[UIColor greenColor] colorWithAlphaComponent:0.8],
                  JWColorScrubberBottomAvg : [UIColor colorWithWhite:0.7 alpha:0.9],
                  JWColorScrubberBottomPeak : [UIColor colorWithWhite:0.8 alpha:0.8],
                  };
                
                [_scrubberController modifyTrack:nil colors:scrubberColors];
                //[_scrubberController modifyTrack:nil withAlpha:0.9 allTracksHeight:_scrubberHeightConstraint.constant];
                _scrubberPrimaryGreyedOut = YES;
            }
            return; // <== RETURNS
            
        } else {
            if (_scrubberPrimaryGreyedOut == YES){
                if (value > 0.06 + .10 ) { // adjust for glitch in value
                    NSLog(@"%s  GREYED OUT RETURNS COLORS value %.3f",__func__,value);
                    [_scrubberController modifyTrack:nil colors:_scrubberPrimaryColors];
                    _scrubberPrimaryGreyedOut = NO;
                }
            }
            return; // <== RETURNS
        }
        // <== RETURNS
    }
    
    visualAlpha += .25 ;
    if (visualAlpha > 1.00f) {
        visualAlpha = 1.0f;
    }
    
    [_scrubberController modifyTrack:nil alpha:visualAlpha];
}
-(void)demoConfig:(CGFloat)value {

    NSUInteger demoIndex = 1;
    if (value < 0) {
        // Left is one lkind of demos
        if (value >  -.08) { demoIndex = 6;
        } else if (value >  -.2) {demoIndex = 7;
        } else if (value >  -.4) {demoIndex = 8;
        } else if (value >  -.6) {demoIndex = 9;
        } else if (value <  -.8) {demoIndex = 10;
        }
    } else {
        // Right is another kind
        if (value <  .08) {demoIndex = 1;
        } else if (value <  .2) {demoIndex = 2;
        } else if (value <  .4) {demoIndex = 3;
        } else if (value <  .6) {demoIndex = 4;
        } else if (value <  .8) {demoIndex = 5;
        }
    }
    switch (demoIndex) {
            // left
//        case 1: [self demoPlayConfiguration1];
//            break;
//        case 2: [self demoPlayConfiguration1a];
//            break;
//        case 3: [self demoPlayConfiguration1c];
//            break;
//        case 4: [self demoPlayConfiguration2];
//            break;
//        case 5: [self demoPlayConfiguration3];
//            break;
//            //right
//        case 6: [self demoPlayConfiguration4];
//            break;
//        case 7: [self demoPlayConfiguration4a];
//            break;
//        case 8: [self demoPlayConfiguration4c];
//            break;
//        case 9: [self demoPlayConfiguration5];
//            break;
//        case 10: [self demoPlayConfiguration6];
//            break;
        default:
            break;
    }
}

#pragma mark - view layout

-(void)viewDidLayoutSubviews {
    
    //Get Preview Layer connection
    
    AVCaptureConnection *previewLayerConnection=self.previewLayer.connection;
    if ([previewLayerConnection isVideoOrientationSupported])
        [previewLayerConnection setVideoOrientation:(AVCaptureVideoOrientation)[[UIApplication sharedApplication] statusBarOrientation]];
    
    if (_stretchVideo) {
        self.previewLayer.frame=self.view.bounds;
    } else {
        [_previewLayer setFrame:self.previewView.bounds];
    }

    [self updateScrubberHeight];
}

-(void)updateScrubberHeight{
    if (_scrubberContainer.hidden) {
        return;
    }
    CGFloat tracksz = 50.0f;
    NSUInteger nTracks = _scrubberController.numberOfTracks;
    if (nTracks == 1) {
        tracksz = 120;
    } else if (nTracks == 2) {
        tracksz = 75.0f;
    } else if (nTracks == 3) {
        tracksz = 55.0f;
    } else {
        tracksz = 45.0f;
    }
    CGFloat expectedHeight = (_scrubberController.numberOfTracks  * tracksz);// + 40;  // labels on scrubber

    self.scrubberHeightConstraint.constant = expectedHeight;
    _restoreScrubberHeight = _scrubberHeightConstraint.constant;
    _scrubberController.scrubberControllerSize = CGSizeMake(self.view.bounds.size.width,self.scrubberHeightConstraint.constant);
}


#pragma mark - video layer

-(AVCaptureVideoPreviewLayer *)previewLayer {
    if (!_previewLayer) {
        CALayer* rootLayer = self.previewView.layer;
        _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
        [_previewLayer setFrame:rootLayer.bounds];
        
        _countDownLabel.textColor = [UIColor whiteColor];
        
        [_previewLayer setBackgroundColor:[[UIColor blackColor] CGColor]];
        
        [_previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
        
        [_previewLayer setAffineTransform:CGAffineTransformMakeScale(1.35, 1.35)];

        [rootLayer setMasksToBounds:YES];
        [rootLayer addSublayer:_previewLayer];
    }
    return _previewLayer;
}

-(void)useFrontCamera {
    for (AVCaptureDevice *d in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if ([d position] == AVCaptureDevicePositionFront) {
            
            [[_previewLayer session] beginConfiguration];
            AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:d error:nil];
            for (AVCaptureInput *oldInput in [[_previewLayer session] inputs]) {
                [[_previewLayer session] removeInput:oldInput];
            }
            [[_previewLayer session] addInput:input];
            [[_previewLayer session] commitConfiguration];
            break;
        }
    }
}

-(void)setupCaptureSession {
    
    _captureSession = [[AVCaptureSession alloc] init];
    
    if ([_captureSession canSetSessionPreset:AVCaptureSessionPresetMedium]) {
        _captureSession.sessionPreset = AVCaptureSessionPresetMedium;
    } else {
        // Handle the failure.
        NSLog(@"Invalid Preset: %@", AVCaptureSessionPresetMedium);
    }
    
    NSError* error;
    AVCaptureDevice* captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput* captureDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    for (AVCaptureInputPort* port in captureDeviceInput.ports) {
        NSLog(@"port: %@", port);
        //        if (/*port has to do with audio*/) {
        //            //disable audio port
        //            port.enabled = NO;
        //        }
    }
    
    if ([_captureSession canAddInput:captureDeviceInput] && !error) {
        [_captureSession addInput:captureDeviceInput];
    } else {
        NSLog(@"Capture Device Not Added");
    }
    
    [_captureSession startRunning];
    
}

@end


//====================================================================
//
//====================================================================









//====================================================================
//
//====================================================================


//dispatch_async(dispatch_get_main_queue(), ^{
//    _scrubber.durationValueStr = [NSString stringWithFormat:@"%.2f s",[_audioEngine durationInSecondsOfSeekingAudioFile]];
//    _scrubber.formatValueStr = [_audioEngine processingFormatStr];
//});

//- (IBAction)editMixAction:(id)sender {
//    NSLog(@"%s",__func__);
//    if (self.editing) {
//        [self setEditing:NO animated:NO];
//    } else {
//        [self setEditing:YES animated:NO];
//    }
//}

// not used
//- (IBAction)recordButtonTapped:(UIButton *)sender {
//    [self prepareToRecord];
//}
// not used
//-(void)recordMixProcess {
////    self.recordButton.enabled = NO;
////    self.previewAudioButton.enabled = NO;
//
//    self.scrubberContainer.hidden = NO;
//    [self presentCountDownValue];
//    self.countDownLabel.hidden = NO;
//}


//        dispatch_async(dispatch_get_main_queue(), ^{
//            _scrubber.durationValueStr = [NSString stringWithFormat:@"%.2f s",[_audioEngine durationInSecondsOfSeekingAudioFile]];
//            _scrubber.formatValueStr = [_audioEngine processingFormatStr];
//            _scrubber.playHeadValueStr = [NSString stringWithFormat:@"%.2f s",0.0];
//            _scrubber.remainingValueStr = [NSString stringWithFormat:@"%.2f s",[_audioEngine durationInSecondsOfSeekingAudioFile]];
//        });
// ---------------------------------------
//-(void)primaryTrackPlayOnStartup
//{
//    [_scrubberController reset];
//    _scrubberController.numberOfTracks = 1;
//    [self updateScrubberHeight];
//    [_scrubberController setViewOptions:ScrubberViewOptionDisplayFullView];
//    NSString *trackId = [_scrubberController prepareScrubberFileURL:[_audioEngine playerNode1FileURL]
//                                                     withSampleSize:SampleSize18
//                                                            options:SamplingOptionDualChannel
//                                                               type:VABOptionNone
//                                                             layout:VABLayoutOptionStackAverages | VABLayoutOptionShowAverageSamples
//                                                       onCompletion:nil];
//    NSLog(@"%s %@",__func__,trackId);
// ---------------------------------------
//-(float)floatValue1ForPlayer:(NSUInteger)playerIndex  forEffectNodeAtIndex:(NSUInteger)index{
//    return [_audioEngine floatValue1ForPlayer:playerIndex forEffectNodeAtIndex:index];
//}
//-(float)floatValue2ForPlayer:(NSUInteger)playerIndex  forEffectNodeAtIndex:(NSUInteger)index{
//    return [_audioEngine floatValue2ForPlayer:playerIndex forEffectNodeAtIndex:index];
//}
//-(BOOL)boolValue1ForPlayer:(NSUInteger)playerIndex  forEffectNodeAtIndex:(NSUInteger)index{
//    return [_audioEngine boolValue1ForPlayer:playerIndex forEffectNodeAtIndex:index];
//}
//-(float)valueForVolumePlayer1 {
//    return [_audioEngine.playerNode1 volume];
//}
//-(float)valueForVolumePlayer2 {
//    return [_audioEngine.playerNode2 volume];
//}
//-(float)valueForPanPlayer1 {
//    return  [_audioEngine.playerNode1 pan];
//}
//-(float)valueForPanPlayer2 {
//    return  [_audioEngine.playerNode2 pan];
//}
// Pan is -1 to 1.0 the caller must ensure correctness
//- (void)playerNode1SliderValueChanged:(CGFloat)value{
//    [_audioEngine.playerNode1 setVolume:value];
//}
//- (void)playerNode2SliderValueChanged:(CGFloat)value{
//    [_audioEngine.playerNode2 setVolume:value];
//}
// Pan is -1 to 1.0 the caller must ensure correctness
//- (void)playerNode1PanSliderValueChanged:(CGFloat)value {
//    [_audioEngine.playerNode1 setPan:value];
//- (void)playerNode2PanSliderValueChanged:(CGFloat)value {
//    [_audioEngine.playerNode2 setPan:value];
// END PAN and VOLUME
// ---------------------------------------
//-(void)startMixing {
//    [_scrubberController reset];
//    NSString *trackId1 = [_scrubberController prepareScrubberFileURL:[_audioEngine playerNode1FileURL]
//                                                     withSampleSize:SampleSize18
//                                                            options:configOptionDualChannel onCompletion:nil];
//    NSString *trackId2 = [_scrubberController prepareScrubberFileURL:[_audioEngine playerNode2FileURL]
//                                                     withSampleSize:SampleSize18
//                                                            options:configOptionDualChannel onCompletion:nil];
//    [_audioEngine prepareToPlayMicRecording];  // track 2 llok at buffersCompleted for track 1 dont start play simulation until then
//-(void)userAudioObtained {
//     [_audioEngine prepareToPlayMicRecording];
//    [_scrubberController reset];
//    NSString *trackId1 = [_scrubberController prepareScrubberFileURL:[_audioEngine playerNode1FileURL]
//                                                      withSampleSize:SampleSize18
//                                                             options:configOptionDualChannel onCompletion:nil];
//    NSString *trackId2 = [_scrubberController prepareScrubberFileURL:[_audioEngine playerNode2FileURL]
//                                                      withSampleSize:SampleSize18
//                                                             options:configOptionDualChannel onCompletion:nil];
//    dispatch_async(dispatch_get_main_queue(), ^{
//        _scrubber.durationValueStr = [NSString stringWithFormat:@"%.2f s",[_audioEngine durationInSecondsOfSeekingAudioFile]];
//        _scrubber.formatValueStr = [_audioEngine processingFormatStr];
// ---------------------------------------
//- (IBAction)previewAudioButtonTapped:(UIButton *)sender {
//    self.recordLabel.text = @"Preview";
//    UIAlertController* satisfiedView =
//    [UIAlertController alertControllerWithTitle:@"Satisfied With Recording?" message:@"Select Yes to Continue." preferredStyle:UIAlertControllerStyleAlert];
//    UIAlertAction* saveAudio =
//    [UIAlertAction actionWithTitle:@"Yes!" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
//        self.recordLabel.textColor = [UIColor blackColor];
//        self.recordLabel.backgroundColor = [UIColor greenColor];
//        _saved = YES;
//        self.recordLabel.text = @"Saved!";
//        [_audioEngine stopAll];
//        [_scrubberController reset];
//        _scrubberController.numberOfTracks = 1;
//        [self updateScrubberHeight];
//        _isPlayingMix = YES;
//        _scrubberPrimaryTrackId = [_scrubberController prepareScrubberFileURL:[_audioEngine playerNode1FileURL]
//        [_audioEngine playMix];
//    }];
//    UIAlertAction* replayAudio =
//    [UIAlertAction actionWithTitle:@"Replay" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
//        [_audioEngine stopAll];
//        [_scrubberController reset];
//        _scrubberController.numberOfTracks = 1;
//        [self updateScrubberHeight];
//        _isPlayingMix = YES;
//        _scrubberPrimaryTrackId = [_scrubberController prepareScrubberFileURL:[_audioEngine playerNode1FileURL]
//        [_audioEngine playMix];
//    }];
//    UIAlertAction* bailAudio =
//    [UIAlertAction actionWithTitle:@"Bail!" style:_saved ?UIAlertActionStyleCancel: UIAlertActionStyleDestructive handler:^(UIAlertAction* action) {
//        [self dismissViewControllerAnimated:YES completion:nil];
//        if ([_delegate respondsToSelector:@selector(done)])
//            [_delegate done];
//    }];
//    UIAlertAction* editAudio =
//    [UIAlertAction actionWithTitle:@"Edit" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
//        [_audioEngine stopAll];
//        [self dismissViewControllerAnimated:YES completion:nil];
//        if ([_delegate respondsToSelector:@selector(doneGoAgain)])
//            [_delegate doneGoAgain];
//        
//    }];
//    UIAlertAction* re_RecordAudio =
//    [UIAlertAction actionWithTitle:@"Record Again" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
//        [_audioEngine stopAll];
//    }];
//    [satisfiedView addAction:saveAudio];
//    [satisfiedView addAction:replayAudio];
//    [satisfiedView addAction:editAudio];
//    [satisfiedView addAction:re_RecordAudio];
//    [satisfiedView addAction:bailAudio];
//    [self presentViewController:satisfiedView animated:YES completion:nil];
//}
// ---------------------------------------
//- (IBAction)baseTrackVolumeSliderValueChanged:(id)sender
//    [_audioEngine setVolumePlayBackTrack:[(UISlider*)sender value]];
// ---------------------------------------
// viewDidload
//self.editing = NO;
//[self.editMixButton setTitle:self.editing ? @"Camera" : @"Controls" forState:UIControlStateNormal];
//
//    NSMutableArray *buttonItems = [NSMutableArray arrayWithArray:self.navigationItem.rightBarButtonItems];
//    [buttonItems addObject:self.editButtonItem];
//    self.navigationItem.rightBarButtonItems = buttonItems;
//    self.navigationItem.rightBarButtonItems[0].enabled = NO;
//
//    self.editMixButton.enabled = YES;
//    if (![_audioEngine micOutputFileExists]) {
//        _hasRecording = NO;
//    } else {
//        -(void)defaultPlayerNodeList {
//            _playerNodeList =
//            [@[
//               [@{@"title":@"playernode1",
//                  @"type":@"playernode",
//                  @"volumevalue":@(0.50),
//                  @"panvalue":@(0.50),
//                  } mutableCopy],
//               [@{@"title":@"playerrecordernode1",
//                  @"type":@"playerrecordernode",
//                  @"volumevalue":@(0.50),
//                  @"panvalue":@(0.50),
//                  } mutableCopy],
//               [@{@"title":@"playernode1",
//                  @"type":@"mixerplayernode",
//                  @"volumevalue":@(0.50),
//                  @"panvalue":@(0.50),
//                  } mutableCopy]
//
//               ]mutableCopy];
//    self.audioEngine = [JWEffectsClipAudioEngine new];
//    [_audioEngine setTrimmedAudioURL:_trimmedURL andFiveSecondURL:_fiveSecondURL];
//    _audioEngine.clipEngineDelegate = self;
//    [_audioEngine initializeAudio];
//    _audioEngine.playerNode1.volume = 0.25;  // bring down the base track so mic can be heard
//    [self.navigationController setToolbarHidden:YES];
//    [self.navigationController setNavigationBarHidden:YES];
// star with camera hidden
//        self.previewView.hidden = NO;
//        self.topSpaceForPreview.constant = -20;
//    self.previewView.hidden = YES;
//    self.topSpaceForPreview.constant = -CGRectGetHeight(self.previewView.frame);
//    [self updateScrubberHeight];
//    [self.view setNeedsUpdat
// ---------------------------------------
//[CATransaction begin];
//[CATransaction setAnimationDuration:1.0f];
//[CATransaction commit];
////        [UIView animateWithDuration:2.0 animations:^{
////            self.topSpaceForPreview.constant = -CGRectGetHeight(self.previewView.frame);
// ---------------------------------------
//            if (_ampPlayerHeightConstraint.constant > CGRectGetHeight(self.view.bounds)/3)
//                _restoreHeight1 = _ampPlayerHeightConstraint.constant;
//                _ampPlayerHeightConstraint.constant = CGRectGetHeight(self.view.bounds)/4;
//            if (_ampPlayerHeightConstraint.constant < CGRectGetHeight(self.view.bounds)/3)
//                _ampPlayerHeightConstraint.constant = _restoreHeight1;
// ---------------------------------------
//@property (strong, nonatomic) IBOutlet UIView *previewView;
//@property (strong, nonatomic) IBOutlet UIView *scrubberContainer;
//@property (strong, nonatomic) IBOutlet UIView *mixEditContainer;
//@property (strong, nonatomic) IBOutlet UIView *ampPlayerContainer;
//@property (strong, nonatomic) IBOutlet NSLayoutConstraint *mixContainerBottomLayout;
//@property (strong, nonatomic) IBOutlet NSLayoutConstraint *ampPlayerHeightConstraint;
//@property (strong, nonatomic) IBOutlet NSLayoutConstraint *topSpaceForPreview;
//@property (strong, nonatomic) IBOutlet NSLayoutConstraint *scrubberHeightConstraint;
//-(void)setEditing:(BOOL)editing animated:(BOOL)animated
//    [super setEditing:editing animated:animated];
//    [self.editMixButton setTitle:self.editing ? @"Camera" : @"Controls" forState:UIControlStateNormal];
//    if (editing) {
//        self.previewView.hidden = YES;
//        self.topSpaceForPreview.constant = -CGRectGetHeight(self.previewView.frame);
//        self.mixEditContainer.hidden = NO;
//    } else {
//        self.previewView.hidden = NO;
//        self.topSpaceForPreview.constant = -20;
//        self.mixEditContainer.hidden = YES;
// ---------------------------------------
//CGFloat height = CGRectGetHeight(self.mixEditContainer.frame);
//        if (height > CGRectGetHeight(self.view.bounds)/3 ) {
//CGFloat height = CGRectGetHeight(self.mixEditContainer.frame);
//        if (height < CGRectGetHeight(self.view.bounds)/3 ) {
// less than min height

//        CGRect fr = self.scrubberContainer.frame;
//        fr.size.height = _restoreScrubberHeight;
//        [CATransaction begin];
//        [CATransaction setAnimationDuration:1.0f];
//        self.scrubberContainer.frame = fr;
//        [CATransaction setCompletionBlock:^{
//            _scrubberHeightConstraint.constant = _restoreScrubberHeight;
//            [self.view setNeedsLayout];
//        }];
//        [CATransaction commit];
//        self.scrubberContainer.hidden = NO;

//        _restoreScrubberHeight = _scrubberHeightConstraint.constant;
//        CGRect fr = self.scrubberContainer.frame;
//        fr.size.height = 0;
//        [CATransaction begin];
//        [CATransaction setAnimationDuration:1.0f];
//        self.scrubberContainer.frame = fr;
//        [CATransaction setCompletionBlock:^{
//            self.scrubberContainer.hidden = YES;
//            _scrubberHeightConstraint.constant = 0;
//            [self.view setNeedsLayout];
//        }];
//        [CATransaction commit];

//        CGRect fr = self.mixEditContainer.frame;
//        fr.size.height = CGRectGetHeight(self.view.bounds)/3;
//
//        [CATransaction begin];
//        [CATransaction setAnimationDuration:1.0f];
//        self.mixEditContainer.frame = fr;
//        [CATransaction setCompletionBlock:^{
//            _ampPlayerHeightConstraint.constant = CGRectGetHeight(self.view.bounds)/4;
//            _mixContainerBottomLayout.constant = _ampPlayerHeightConstraint.constant;
//            [self.view setNeedsLayout];
//        }];
//        [CATransaction commit];
//        self.mixEditContainer.hidden = NO;

//        CGRect fr = self.mixEditContainer.frame;
//        fr.size.height = 0;
//        [CATransaction begin];
//        [CATransaction setAnimationDuration:1.0f];
//        self.mixEditContainer.frame = fr;
//        [CATransaction setCompletionBlock:^{
//            self.mixEditContainer.hidden = YES;
//            _ampPlayerHeightConstraint.constant = CGRectGetHeight(self.view.bounds) - fr.origin.y - 44;  // minus navigation bar
//            [self.view setNeedsLayout];
//
//        }];
//        [CATransaction commit];
// ---------------------------------------
////  NOT STATE MACHINE
//- (IBAction)rewindAction:(id)sender {
//    NSLog(@"%s",__func__);
//    // rewind stops playback and recording
//    if (_isMixing)
//        self.recordLabel.text = @"";
//        _recording = NO;
//        _playing = NO;
//        [self.playerTimer invalidate];
//    [_audioEngine stopPlayingTrack1];
//    [_scrubber rewindToBeginning];
//    [self updateButtonStates];
//}
//-(void)rewindActionWhilePlaying {
//    _recording = NO;
//    //_playing = NO;
//    [self.playerTimer invalidate];
//    [_audioEngine stopPlayingTrack1];
//    [_scrubber rewindToBeginning];
//    //[self updateButtonStates];
//}
//- (IBAction)playPauseAction:(id)sender {
//    NSLog(@"%s",__func__);
//    _recording = NO;
//    _playing = !_playing;
//    if (_playing) {
//        // Play Mode
//        [self playAction];
//    } else {
//        // Pause Mode
//        [self.playerTimer invalidate];
//        if (_hasRecordingMix == NO)
//            [_audioEngine pausePlayingAll];
//    }
//    [self updateButtonStates];
//-(void)playAction {
//    if (_needsRewind) {
//        [_scrubber rewindToBeginning];
//        _needsRewind = NO;
//    }
//    //This shouldnt happen.  I want the final mix to only happen when they decide to export
//    if (_hasRecordingMix) {
//        self.recordLabel.text = @"Playing Mix Recording";
//        _recording = NO;
//        [_audioEngine stopAll]; // stops and reset players
//        [_scrubber resetScrubber];
//        [_audioEngine prepareMasterMixSampling];
//        [_audioEngine playMix];
//        dispatch_async(dispatch_get_main_queue(), ^{
//            _scrubber.durationValueStr = [NSString stringWithFormat:@"%.2f s",[_audioEngine durationInSecondsOfMixFile]];
//            _scrubber.formatValueStr = [_audioEngine mixFileProcessingFormatStr];
//        });
//        _isPlayingMix = YES;
//    } else {
//        if (_isMixing) {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                self.recordLabel.text = @"Mixing";
//            });
//        } else {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                self.recordLabel.text = @"Track 1";
//            });
//        }
//        [_audioEngine playAll];
//    }
//    [self startPlaySimulation];
//}
//- (IBAction)recordAction:(id)sender {
//    NSLog(@"%s",__func__);
//    // recording stops playback and recording if we are already recording
//    if (_playing) {
//        [self rewindAction:nil];
//    }
//    _playing = NO;
//    _recording = !_recording;
//    _canPlayback = YES;
//    if (_recording) {
//        if (_isMixing) {
//            _canPlayback = NO;
//            _isRecordingMix = YES;
//            // Record the mix
//            // Both tracks have finsihed, proceed
//            self.recordLabel.text = @"Record Mix";
//            [self.audioEngine prepareForPreview];
//            dispatch_async(dispatch_get_main_queue(), ^{
//                _scrubber.durationValueStr = [NSString stringWithFormat:@"%.2f s",[_audioEngine durationInSecondsOfSeekingAudioFile]];
//                _scrubber.formatValueStr = [_audioEngine processingFormatStr];
//            });
//            [_audioEngine playAllAndRecordIt]; // will record the output of both players
//            _isPlayingMix = NO;
//            [self startPlaySimulation];
//        } else {
//            [self prepareToRecord];
//        }
//    }
//    else {
//        _hasRecording = YES;
//        _canPlayback = YES;
//    }
//    [self updateButtonStates];
//}
// ---------------------------------------
//        // Startup player
//        NSMutableArray *playerNodeList = [_audioEngine playerNodeList];
//
//        //        [self.scrubber resetScrubber];
//        //        [_audioEngine prepareToPlayTrack1];
//
//        // CONFIGURATION1
//        /*
//         A configuration with two tracks one) primary track
//         and the ather a player
//         try running 1,2,3 and upto 4 players
//         plays the same file
//         in the Audio Engine, a VisualAudio Tap
//         */
//
//        [_scrubberController reset];
//        _scrubberController.numberOfTracks = 2;
//        [self updateScrubberHeight];
//
//        NSInteger index = 0;
//        for (NSDictionary *playerNodeInfo in playerNodeList) {
//            id type = playerNodeInfo[@"type"];
//            if (type){
//                // PLAYER RECORDER
//                if ([@"playerrecordernode" isEqualToString:type]) {
//                    NSURL *fileURL = [_audioEngine playerNodeFileURLAtIndex:index];
//                    if (fileURL == nil) {
//                        // No recording
//                        //        // ADD A TAP to mixer for playAlll
//                        NSString *recorderTrackId =
//                        [_scrubberController prepareScrubberListenerSource:_audioEngine
//                                                            withSampleSize:SampleSize14
//                                                                   options:configOptionDualChannel
//                                                              onCompletion:nil];
//
//                        [_audioEngine registerController:_scrubberController withTrackId:recorderTrackId forPlayerRecorderAtIndex:index];
//
//                    } else {
//                        [_scrubberController prepareScrubberFileURL:fileURL
//                                                     withSampleSize:SampleSize18
//                                                            options:configOptionDualChannel onCompletion:nil];
//                    }
//
//                }
//                // PLAYER
//                else if ([@"playernode" isEqualToString:type]) {
//
//                    NSURL *fileURL = [_audioEngine playerNodeFileURLAtIndex:index];
//                    if (fileURL) {
//                        [_scrubberController prepareScrubberFileURL:fileURL
//                                                     withSampleSize:SampleSize18
//                                                            options:configOptionDualChannel onCompletion:nil];
//                    } else {
//                        // no file URL for player
//
//                    }
//
//                }
//                // MIXER PLAYER
//                else if ([@"mixerplayernode" isEqualToString:type]) {
//
//
//                }
//            }
//
//            index++;
//        }
////                NSString *trackId = [_scrubberController prepareScrubberFileURL:[_audioEngine playerNode1FileURL]
////                                                                  withSampleSize:SampleSize18
////                                                                         options:configOptionDualChannel onCompletion:nil];
////                [_scrubberController prepareScrubberFileURL:[_audioEngine playerNode1FileURL]
////                                                                 withSampleSize:SampleSize18
////                                                                        options:configOptionDualChannel onCompletion:nil];
////                [_scrubberController prepareScrubberFileURL:[_audioEngine playerNode1FileURL]
////                                                                  withSampleSize:SampleSize18
////                                                                         options:configOptionDualChannel onCompletion:nil];
////                [_scrubberController prepareScrubberFileURL:[_audioEngine playerNode1FileURL]
////                                             withSampleSize:SampleSize18
////                                                    options:configOptionDualChannel onCompletion:nil];
//
//        // CONFIGURATION2
//
//        /*
//         A configuration with two tracks one) primary track playing two) a listener on a tap
//         in the Audio Engine, a VisualAudio Tap
//         trackId
//         trackidMixerTap
//
//         */
//
////        [_scrubberController reset];
////        _scrubberController.numberOfTracks = 2;  // one for primary track file and one formixer tap
////
////        NSString *trackId = [_scrubberController prepareScrubberFileURL:[_audioEngine playerNode1FileURL]
////                                                         withSampleSize:SampleSize18
////                                                                options:configOptionDualChannel
////                                                           onCompletion:nil];
////        // ADD A TAP to mixer for playAlll
////        NSString *trackidMixerTap = [_scrubberController prepareScrubberListenerSource:_audioEngine
////                                                                        withSampleSize:SampleSize14
////                                                                               options:configOptionDualChannel
////                                                                          onCompletion:nil];
////
////        [_audioEngine registerController:_scrubberController withTrackId:trackidMixerTap forPlayerRecorder:@"mixer"];
//
//
//        dispatch_async(dispatch_get_main_queue(), ^{
//            _scrubber.durationValueStr = [NSString stringWithFormat:@"%.2f s",[_audioEngine durationInSecondsOfSeekingAudioFile]];
//            _scrubber.formatValueStr = [_audioEngine processingFormatStr];
//            _scrubber.playHeadValueStr = [NSString stringWithFormat:@"%.2f s",0.0];
//            _scrubber.remainingValueStr = [NSString stringWithFormat:@"%.2f s",[_audioEngine durationInSecondsOfSeekingAudioFile]];
//        });
//        [self updateButtonStates];
//    firstTime = 0;
// ---------------------------------------
//    if (_needsRewind) {
//        [_scrubber rewindToBeginning];
//        _needsRewind = NO;
//    }
//This shouldnt happen.  I want the final mix to only happen when they decide to export
//    if (_hasRecordingMix) {
//        self.recordLabel.text = @"Playing Mix Recording";
//        _recording = NO;
//        [_audioEngine stopAll]; // stops and reset players
//        [_scrubber resetScrubber];
//        [_audioEngine prepareMasterMixSampling];
//        [_audioEngine playMix];
//        dispatch_async(dispatch_get_main_queue(), ^{
//            _scrubber.durationValueStr = [NSString stringWithFormat:@"%.2f s",[_audioEngine durationInSecondsOfMixFile]];
//            _scrubber.formatValueStr = [_audioEngine mixFileProcessingFormatStr];
//        });
//        _isPlayingMix = YES;
// ---------------------------------------
//-(void)slider1ValueDidForPlayerAtIndex:(NSUInteger)playerIndex effectNodeAtIndex:(NSUInteger)index toValue:(float)value
//{
//    BOOL result = [_audioEngine adjustFloatValue1ForPlayer:playerIndex forEffectNodeAtIndex:index toValue:value];
//    if (result) {
////        NSLog(@"%s SUCCESS",__func__);
//    } else {
//        NSLog(@"%s FAILED",__func__);
//-(void)switchValueDidChangeForPlayerAtIndex:(NSUInteger)playerIndex effectNodeAtIndex:(NSUInteger)index toValue:(BOOL)value
//    BOOL result = [_audioEngine adjustBoolValue1ForPlayer:playerIndex forEffectNodeAtIndex:index toValue:value];
//    if (result) {
//        NSLog(@"%s SUCCESS",__func__);
//    } else {
//        NSLog(@"%s FAILED",__func__);
// ---------------------------------------
// flat buttons not used anymore
//@property (strong, nonatomic) IBOutlet UIButton *recordButton;
//@property (strong, nonatomic) IBOutlet UIButton *previewAudioButton;
//@property (strong, nonatomic) IBOutlet UIButton *editMixButton;
//@property (nonatomic) JWUITransportButton *rewindButton;
//@property (nonatomic) JWUITransportButton *playButton;
//@property (nonatomic) JWUITransportButton *recordMicButton;
// moved to playerControlsVC
//@property (strong, nonatomic) IBOutlet JWUITransportButton *rewindButton;
//@property (strong, nonatomic) IBOutlet JWUITransportButton *playButton;
//@property (strong, nonatomic) IBOutlet JWUITransportButton *recordMicButton;
