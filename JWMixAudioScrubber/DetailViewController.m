//
//  DetailViewController.m
//  JWAudioScrubber
//
//  Created by brendan kerr on 12/25/15.
//  Copyright © 2015 b3k3r. All rights reserved.
//

#import "DetailViewController.h"
#import "JWAudioPlayerController.h"
#import "JWMixEditTableViewController.h"

@interface DetailViewController () <JWAudioPlayerControllerDelegate,JWMixEditDelegate>

@property (strong, nonatomic) JWAudioPlayerController* playerController;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *playButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *pauseButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *forwardButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *rewindButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *fixedSpace;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *fixedSpace2;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *layoutConstraintScrubberHeight;
@property (strong, nonatomic) IBOutlet UIView *sctv;
@property (strong, nonatomic) id scrubberContainerView;
@property (strong, nonatomic) id playerControlsContainerView;
@property (strong, nonatomic) JWMixEditTableViewController  *mixEdit;
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
    
    // Update the user interface for the detail item.
    
    //[self updateStepperForItem:_detailItem];
    
    self.trackItems =[_delegate tracks:self cachKey:_detailItem[@"key"]];
    
    
    // SETUP AUDIO ENGINE
    if (_trackItems) {
        // MULTIPLE items
        if (_playerController)
        {
            [_playerController setTrackItems:_trackItems];
        }
        
    } else {
        // SINGLE detail item
        if (self.detailItem) {
            if (_playerController)
            {
                [_playerController setTrackItem:_detailItem];
            }
            
//            [self updateStatusForItem:_detailItem];
        }
    }

    [self.mixEdit refresh];

    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //TOOL BAR ITEMS FOR AUDIO
    [self setToolbarItems:@[_rewindButton, _fixedSpace, _playButton, _fixedSpace2, _forwardButton] animated:YES];
    
//    _playbackStartDelay = 0.0;
    
    self.playerController = [JWAudioPlayerController new];
    [self.playerController initializePlayerControllerWith:_scrubberContainerView and:_playerControlsContainerView];
    self.playerController.delegate = self;
    
    self.mixEdit.effectsHandler = self.playerController.effectsHandler;

    // Do any additional setup after loading the view, typically from a nib.
    [self configureView];
    
    [self.navigationController setToolbarHidden:NO];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//SCRUBBER CONTROLLER EMBEDED IN SCTV
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if ([segue.identifier isEqualToString:@"JWScrubberView"]) {
        self.scrubberContainerView = segue.destinationViewController;
    } else if ([segue.identifier isEqualToString:@"JWPlayerControlsView"]) {
        self.playerControlsContainerView = segue.destinationViewController;
    } else if ([segue.identifier isEqualToString:@"JWMixEditEmbed"])
    {
        self.mixEdit = (JWMixEditTableViewController*)segue.destinationViewController;
        self.mixEdit.delegateMixEdit = self;
    }

    
}

#pragma mark - BUTTON ACTIONS

- (IBAction)buttonPressed:(UIBarButtonItem *)sender {
    
    if (sender == _playButton) {
        NSLog(@"%s PLAY",__func__);        
        [self setToolbarItems:@[_rewindButton, _fixedSpace, _pauseButton, _fixedSpace2, _forwardButton] animated:NO];
        [_playerController play];
                
    } else if (sender == _forwardButton) {
        NSLog(@"%s PAUSE",__func__);
        
        
    } else  if (sender == _rewindButton) {
        NSLog(@"%s REWIND",__func__);
        [_playerController rewind];
        
    } else if (sender == _pauseButton) {
        
        [self setToolbarItems:@[_rewindButton, _fixedSpace, _playButton, _fixedSpace2, _forwardButton] animated:NO];
        [_playerController pause];
        
    }
    
}


#pragma mark -

- (IBAction)saveAction:(id)sender {
    [_delegate save:self cachKey:_detailItem[@"key"]];
}

- (NSArray *)getTrackSections:(UIBarButtonItem *)sender {
    
    NSArray *tracks = [_delegate tracks:self cachKey:_detailItem[@"key"]];
    self.trackItems = tracks;
    
    return tracks;
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
    CGFloat tracksz = 50.0f;
    NSUInteger nTracks = controller.numberOfTracks;
    if (nTracks == 1) {
        tracksz = 120;
    } else if (nTracks == 2) {
        tracksz = 75.0f;
    } else if (nTracks == 3) {
        tracksz = 55.0f;
    } else {
        tracksz = 45.0f;
    }
    CGFloat expectedHeight = (controller.numberOfTracks  * tracksz);// + 40;  // labels on scrubber
    
    self.layoutConstraintScrubberHeight.constant = expectedHeight;
    
    return CGSizeMake(self.view.bounds.size.width, self.layoutConstraintScrubberHeight.constant);
}

-(void)save:(JWAudioPlayerController *)controller {
    
    [self saveAction:nil];
}

#pragma mark - MixEdit delegate

- (id <JWEffectsModifyingProtocol>) mixNodeControllerForScrubber
{
    return [_playerController scrubberModifier];
}


@end















