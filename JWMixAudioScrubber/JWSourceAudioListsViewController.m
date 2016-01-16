//
//  JWSourceAudioListsViewController.m
//  JWMixAudioScrubber
//
//  Created by JOSEPH KERR on 1/10/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

#import "JWSourceAudioListsViewController.h"
#import "JWSourceAudioFilesTableViewController.h"

@interface JWSourceAudioListsViewController () <JWSourceAudioFilesDelegate>
@property (strong, nonatomic) IBOutlet UIView *leftContainerView;
@property (strong, nonatomic) IBOutlet UIView *rightContainerView;
@property (strong, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (strong, nonatomic) JWSourceAudioFilesTableViewController *sourceAudioViewController;
@property (strong, nonatomic) JWSourceAudioFilesTableViewController *sourceAudioAllViewController;
@end

@implementation JWSourceAudioListsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationItem setRightBarButtonItem:self.editButtonItem];

    _segmentedControl.selectedSegmentIndex = 0;
    
    [self.view bringSubviewToFront:_leftContainerView];
}


-(void)setEditing:(BOOL)editing animated:(BOOL)animated {
    
    [super setEditing:editing animated:animated];
    if (_segmentedControl.selectedSegmentIndex == 0) {
        _sourceAudioViewController.editing = editing;
    } else {
        _sourceAudioAllViewController.editing = editing;
    }
    
    if (editing) {
        self.segmentedControl.enabled = NO;
    } else {
        self.segmentedControl.enabled = YES;
    }
}


- (IBAction)sgmentedValueChanged:(id)sender {
    
    if ([(UISegmentedControl*)sender selectedSegmentIndex] == 0) {
        [self.view bringSubviewToFront:_leftContainerView];
    } else {
        [self.view bringSubviewToFront:_rightContainerView];
    }
}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"JWSourceAudioArranged"]) {
        _sourceAudioViewController = (JWSourceAudioFilesTableViewController*)segue.destinationViewController;
        _sourceAudioViewController.previewMode = _selectToClip ? NO : YES;
        _sourceAudioViewController.allFiles = NO;
        _sourceAudioViewController.delegate = self;
    } else if ([segue.identifier isEqualToString:@"JWSourceAudioAll"]) {
        _sourceAudioAllViewController = (JWSourceAudioFilesTableViewController*)segue.destinationViewController;
        _sourceAudioAllViewController.previewMode = _selectToClip ? NO : YES;
        _sourceAudioAllViewController.allFiles = YES;
        _sourceAudioAllViewController.delegate = self;
    }
}

#pragma mark - source audio files delegate

-(void)finishedTrim:(id)controller title:(NSString*)title withDBKey:(NSString*)key
{
    if ([_delegate respondsToSelector:@selector(finishedTrim:title:withDBKey:)]) {
        [_delegate finishedTrim:self title:title withDBKey:key];
    }
}

@end
