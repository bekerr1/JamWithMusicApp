//
//  DetailViewController.m
//  JWAudioScrubber
//
//  Created by brendan kerr on 12/25/15.
//  Copyright © 2015 b3k3r. All rights reserved.
//

#import "DetailViewController.h"
#import "JWAudioPlayerController.h"
#import "JWCurrentWorkItem.h"


@interface DetailViewController () <JWAudioPlayerControllerDelegate> {
    BOOL _playing;
    NSUInteger selectedAmpImageIndex;
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
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *scrubberActivity;
@property (strong, nonatomic) IBOutlet UIView *scrubberContainerView;
@property (strong, nonatomic) IBOutlet UIImageView *logoImageView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *layoutConstraintScrubberHeight;
@property (strong, nonatomic) id scrubber;
@property (strong, nonatomic) id playerControls;
@property (strong, nonatomic) id mixEdit;
@property (strong, nonatomic) IBOutlet UIView *sctv;
@property (strong, nonatomic) IBOutlet UIView *mixeditContainerView;
@property (nonatomic) NSMutableString *statusString;
@property (strong, nonatomic) NSArray *trackItems;
@end


@implementation DetailViewController

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem {
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        
        if (_playerController)
        {
            [self configureView];
        }
    }
}
// Update the view.

- (void)configureView {
    
    _scrubberContainerView.hidden = YES;
    [_scrubberActivity startAnimating];

    // Update the user interface for the detail item.
    //[self updateStepperForItem:_detailItem];
    
    if (_detailItem) {
        id hasTrackObjectSet = _detailItem[@"trackobjectset"];
        if (hasTrackObjectSet) {
            self.trackItems = [_delegate tracks:self forJamTrackKey:_detailItem[@"key"]];
            
        } else {
            self.trackItems =[_delegate tracks:self cachKey:_detailItem[@"key"]];
        }
        
        if (_playerController) {
            // SETUP AUDIO ENGINE
            
            if (_trackItems) {
                // MULTIPLE items
                if (hasTrackObjectSet) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_playerController setTrackSet:_trackItems];
                    });
                } else {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_playerController setTrackItems:_trackItems];
                    });
                    
                }
            } else {
                // SINGLE detail item
                if (self.detailItem) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_playerController setTrackItem:_detailItem];
                    });
                }
            }
        }
    }

    _scrubberContainerView.alpha = 0;
    _scrubberContainerView.hidden = NO;
    [UIView animateWithDuration:0.5 delay:0.5 options:UIViewAnimationOptionCurveEaseIn animations:^{
        _scrubberContainerView.alpha = 1.0;
    } completion:^(BOOL fini){
    } ];
    double delayInSecs = 0.6;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSecs * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [_scrubberActivity stopAnimating];
    });

}



- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"%s",__func__);
    [[self.navigationController toolbar] setBarStyle:UIBarStyleBlackTranslucent];
    [self toolbar1];

    _scrubberContainerView.hidden = YES;
    [_scrubberActivity startAnimating];

    self.playerController = [JWAudioPlayerController new];
    self.playerController.delegate = self;
    
//    [self.playerController initializePlayerControllerWithScrubber:_scrubber playerControls:_playerControls mixEdit:_mixEdit];
    
//    _playerController.autoPlay = YES;
//    [self.playerController initializePlayerControllerWithScrubber:_scrubber playerControls:_playerControls mixEdit:_mixEdit
//                                                   withCompletion:^{
//                                                       [self configureView];
//                                                       [self.navigationController setToolbarHidden:NO];
//                                                   }];

    [self.playerController initializePlayerControllerWithScrubberWithAutoplayOn:NO
                                                              usingScrubberView:_scrubber
                                                                 playerControls:_playerControls mixEdit:_mixEdit
                                                                 withCompletion:^{
                                                                     [self configureView];
                                                                     [self.navigationController setToolbarHidden:NO];
                                                                 }];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSelectAmpImage:) name:@"DidSelectAmpImage" object:nil];

}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    selectedAmpImageIndex = [JWCurrentWorkItem sharedInstance].currentAmpImageIndex;
    [self updateAmpImage];
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

-(void)delloc
{
    [self.playerController stop];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - amp image

//NSLog(@"%s %ld",__func__,selectedAmpImageIndex);
//// jwframesandscreens - 3
////jwscreensandcontrols
////jwjustscreensandlogos
//NSLog(@"%s %@",__func__,[[noti userInfo] description]);

-(void)updateAmpImage {
    UIImage *ampImage = [UIImage imageNamed:[NSString stringWithFormat:@"jwjustscreensandlogos - %ld",selectedAmpImageIndex + 1]];
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


#pragma mark - commands

-(void)stopPlaying {
    [self.playerController stop];
}

//SCRUBBER CONTROLLER EMBEDED IN SCTV
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if ([segue.identifier isEqualToString:@"JWScrubberView"]) {
        self.scrubber = segue.destinationViewController;
    } else if ([segue.identifier isEqualToString:@"JWPlayerControlsView"]) {
        self.playerControls = segue.destinationViewController;
    } else if ([segue.identifier isEqualToString:@"JWMixEditEmbed"]){
        self.mixEdit = segue.destinationViewController;
    }
}

#pragma mark - TOOLBAR BUTTON ACTIONS

- (IBAction)buttonPressed:(UIBarButtonItem *)sender {
    
    if (sender == _playButton) {
        NSLog(@"%s PLAY",__func__);
        
        _playing = YES;
        [self toolbar2WithPlay:_playing];
        [_playerController play];
                
    } else if (sender == _forwardButton) {
        NSLog(@"%s PAUSE",__func__);
        
    } else  if (sender == _rewindButton) {
        NSLog(@"%s REWIND",__func__);

        [_playerController rewind];
        
    } else if (sender == _pauseButton) {
        _playing = NO;
        [self toolbar2WithPlay:_playing];
        [_playerController pause];
    }
    
}

-(void)toolbar1 {
    [self setToolbarItems:@[_flexSpace1,_effectsButton,_exportButton] animated:YES];
}

-(void)toolbar2WithPlay:(BOOL)playbutton {
    [self setToolbarItems:@[_rewindButton, _fixedSpace, !playbutton ? _playButton : _pauseButton, _fixedSpace2, _forwardButton,_flexSpace1,_effectsButton,_exportButton] animated:YES];
}

#pragma mark -

- (IBAction)saveAction:(id)sender {
    [_delegate save:self cachKey:_detailItem[@"key"]];
}

- (void)updateStatusForItem:(NSDictionary*)item {
    
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


#pragma mark -  JWAudioPlayerControllerDelegate

-(CGSize)updateScrubberHeight:(JWAudioPlayerController *)controller {
    
    if (_sctv.hidden) {
        return CGSizeZero;
    }
    
    CGFloat tracksz = 60.0f;
    NSUInteger nTracks = controller.numberOfTracks;
    if (nTracks == 1) {
        tracksz = 120;
    } else if (nTracks == 2) {
        tracksz = 85.0f;
    } else if (nTracks == 3) {
        tracksz = 95.0f;
    }
    
    CGFloat expectedHeight = (controller.numberOfTracks  * tracksz);// + 40;  // labels on scrubber
    
    self.layoutConstraintScrubberHeight.constant = expectedHeight;
    
    return CGSizeMake(self.view.bounds.size.width, self.layoutConstraintScrubberHeight.constant);
}

-(void)save:(JWAudioPlayerController *)controller {
    [self saveAction:nil];
}


-(void)noTrackSelected:(JWAudioPlayerController *)controller {
    _mixeditContainerView.hidden = YES;
    [self toolbar1];
}

-(void)trackSelected:(JWAudioPlayerController *)controller {
    if ([_mixeditContainerView isHidden]) {
        [self effectsAction:nil];
    }
}

-(void)playTillEnd {
    
    _playing = NO;
    
    if (_mixeditContainerView.hidden == NO) {
        [self toolbar2WithPlay:_playing];
    }
}

-(void)playerController:(JWAudioPlayerController *)controller didLongPressForTrackAtIndex:(NSUInteger)index {
    [self clipActions];
}

-(void) userAudioObtainedAtIndex:(NSUInteger)index recordingId:(NSString*)rid {
    
    if ( index <  [self.trackItems count]){
        id nodeItem = _trackItems[index];
        if ([_delegate respondsToSelector:@selector(userAudioObtainedInNodeWithKey:recordingId:)])
            [_delegate userAudioObtainedInNodeWithKey:nodeItem[@"key"] recordingId:rid];
    }
}

#pragma mark - ActionSheets and ALert

-(void)editingButtons{
    if (self.editing) {
        [self.effectsButton setTitle:@"Clip"];
        //        [self.exportButton setTitle:@"Cancel"];
    } else {
        [self.effectsButton setTitle:@"Effects"];
        //        [self.exportButton setTitle:@"Export"];
    }
}


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
    [self presentViewController:actionController animated:YES completion:nil];
    
}

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



-(void)addEffectAction {
    NSLog(@"%s", __func__);
    
    //TODO: specify in message which node they are adding the effect to
    UIAlertController *addEffect = [UIAlertController alertControllerWithTitle:@"Add An Effect" message:@"Choose From These Effects" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *addReverbAction = [UIAlertAction actionWithTitle:@"Reverb" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        
    }];
    UIAlertAction *addDelayAction = [UIAlertAction actionWithTitle:@"Delay" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        
    }];
    UIAlertAction *addDistortionAction = [UIAlertAction actionWithTitle:@"Distortion" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        
    }];
    UIAlertAction *addEQAction = [UIAlertAction actionWithTitle:@"EQ" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        
    }];
    
    [addEffect addAction:addReverbAction];
    [addEffect addAction:addDelayAction];
    [addEffect addAction:addDistortionAction];
    [addEffect addAction:addEQAction];
    [addEffect addAction:cancel];
    
    [self presentViewController:addEffect animated:YES completion:nil];
    
}

#pragma mark -

//When User wants to add an effect node or a recorder node
- (IBAction)addAction:(id)sender {
    NSLog(@"%s",__func__);
    
    NSString *title;
    NSString *message;
    
    UIAlertAction *addEffectAction;
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *addNodeAction = [UIAlertAction actionWithTitle:@"Add Node" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {

        NSLog(@"%s ADD NODE not implemented",__func__);
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


- (IBAction)effectsAction:(id)sender {
    NSLog(@"%s",__func__);
    
    if (self.editing) {
        [self clipActionsEditing];

    } else {
        self.mixeditContainerView.hidden =! self.mixeditContainerView.hidden;
        
        // HIDDEN IS OFF
        if (_mixeditContainerView.hidden == NO) {
            
            // EFFECTS ON
            if (self.playerController.state == JWPlayerStatePlayFromPos) {
                _playing = YES;
            } else {
                _playing = NO;
            }
            
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
            
        }
    }

}


- (IBAction)exportAction:(id)sender
{
    NSLog(@"%s",__func__);
}



@end


//    CGFloat tracksz = 50.0f;
//    NSUInteger nTracks = controller.numberOfTracks;
//    if (nTracks == 1) {
//        tracksz = 120;
//    } else if (nTracks == 2) {
//        tracksz = 75.0f;
//    } else if (nTracks == 3) {
//        tracksz = 55.0f;
//    } else {
//        tracksz = 45.0f;
//    }


//- (NSArray *)getTrackSections:(UIBarButtonItem *)sender {
//    NSArray *tracks =
//    self.trackItems = [_delegate tracks:self cachKey:_detailItem[@"key"]];
//    return tracks;
//}


//    double delayInSecs = 0.5;
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSecs * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        _scrubberContainerView.hidden = NO;
//        [_scrubberActivity stopAnimating];
//    });

//    _scrubberContainerView.hidden = NO;
//    [_scrubberActivity stopAnimating];

//    [UIView transitionWithView:_scrubberContainerView duration:0.5 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
//        _scrubberContainerView.hidden = NO;
//    } completion:^(BOOL fini){
//        [_scrubberActivity stopAnimating];
//    }];

