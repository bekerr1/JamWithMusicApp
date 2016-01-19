//
//  MasterViewController.m
//  JWAudio
//
//  Created by JOSEPH KERR on 11/27/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import "MasterViewController.h"
#import "DetailViewController.h"
#import "JWTrackSetsViewController.h"
#import "JWYTSearchTypingViewController.h"
#import "JWMixNodes.h"
#import "JWFileController.h"
#import "JWSourceAudioListsViewController.h"
#import "JWClipAudioViewController.h"
#import "JWCurrentWorkItem.h"

@interface MasterViewController () <JWDetailDelegate,
JWTrackSetsProtocol,JWYTSearchTypingDelegate,JWSourceAudioListsDelegate,UITextFieldDelegate>
{
    BOOL _isAddingNewObject;
    BOOL _isAutoSelecting;
}
@property NSIndexPath *selectedIndexPath;
@property NSMutableArray *objectCollections;  // collects objects
@property NSMutableArray *homeControllerSections;  // collects objects
@property NSIndexPath *selectedDetailIndexPath;
@property NSString *nameChangeString;
@property NSString *lastSearchTerm;

@end

//#define JWSampleFileNameAndExtension @"trimmedMP3.m4a"
//#define JWSampleFileNameAndExtension @"trimmedMP3-45.m4a"
//#define JWSampleFileNameAndExtension @"AminorBackingtrackTrimmedMP3-45.m4a"
#define JWSampleFileNameAndExtension @"TheKillersTrimmedMP3-30.m4a"


@implementation MasterViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _isAddingNewObject = NO;
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
    self.navigationItem.rightBarButtonItem = addButton;

    self.detailViewController =
    (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];

//    _homeControllerSections = [self newHomeMenuLists];
//    [self saveHomeMenuLists];
    
    [self readHomeMenuLists];
    if (_homeControllerSections == nil) {
        _homeControllerSections = [self newHomeMenuLists];
    }

    _isAutoSelecting = NO;

}

- (void)viewWillAppear:(BOOL)animated {
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        self.clearsSelectionOnViewWillAppear = YES;
    } else {
        self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    }
    
    [super viewWillAppear:animated];

    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        [self.detailViewController stopPlaying];
    }

    _isAddingNewObject = NO;

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (_isAutoSelecting) {
        // AUTO SELECT
        self.selectedIndexPath = [NSIndexPath indexPathForRow:2
                                                    inSection:[self indexOfSectionOfType:JWHomeSectionTypeAudioFiles]];
        [self.tableView selectRowAtIndexPath:_selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
        [self performSegueWithIdentifier:@"showDetail" sender:self];
    }
    
//    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
//    if (indexPath) {
//        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
//    }

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark -

-(id)jamTrackObjectAtIndexPath:(NSIndexPath*)indexPath {
    
    id result = nil;
    if (indexPath.section < [_homeControllerSections count]) {
        
        id objectSection = _homeControllerSections[indexPath.section];
        
        JWHomeSectionType sectionType = [self typeForSectionObject:objectSection];
        
        BOOL isTrackItem = YES;;
        NSUInteger virtualRow = indexPath.row;
        if (sectionType == JWHomeSectionTypeAudioFiles) {
            if (indexPath.row > 0) {
                virtualRow--;
            } else {
                isTrackItem = NO;
            }
        }
        else if (sectionType == JWHomeSectionTypeYoutube) {
            if (indexPath.row > 1) {
                virtualRow--;
                virtualRow--;
            } else {
                isTrackItem = NO;
            }
        }
        
        if (isTrackItem) {
            // IS  ATRACK CELL not a controll cell index 0 AUDIOFILES and SEARCH
            id trackObjects = objectSection[@"trackobjectset"];
            if (trackObjects) {
                NSArray *objectCollection = trackObjects;
                NSMutableDictionary *object = objectCollection[virtualRow];
                result = object;
            }
        }
    }
    
    return result;
}


-(void)textFieldDidEndEditing:(UITextField *)textField {
    NSLog(@"%s",__func__);
    
    if (_selectedDetailIndexPath) {
        if ([textField.text length] > 0) {
            NSString *titleText = textField.text;
            NSMutableDictionary *object = [self jamTrackObjectAtIndexPath:_selectedDetailIndexPath];
            if (object) {
                self.nameChangeString = titleText;
            }
        }
    }
}

-(void)nameChanged:(id)sender{
    NSLog(@"%s",__func__);
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    
    self.selectedDetailIndexPath = indexPath;
    [self namePrompt];
}

-(void)namePrompt {
    UIAlertController* actionController =
    [UIAlertController alertControllerWithTitle:@"Track Title" message:@"Enter title for the track" preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction* okAction =
    [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
        
        if (_selectedDetailIndexPath && _nameChangeString) {
            NSMutableDictionary *object = [self jamTrackObjectAtIndexPath:_selectedDetailIndexPath];
            if (object) {
                object[@"usertitle"] = _nameChangeString;
                
                [self saveHomeMenuLists];

                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView beginUpdates];
                    [self.tableView reloadRowsAtIndexPaths:@[_selectedDetailIndexPath]
                                          withRowAnimation:UITableViewRowAnimationNone];
                    [self.tableView endUpdates];
                });
                
                self.nameChangeString = nil;
            }
        }
    }];
    UIAlertAction* cancelAction =
    [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction* action) {
        self.selectedDetailIndexPath = nil;
        self.nameChangeString = nil;

    }];
    
    [actionController addTextFieldWithConfigurationHandler:^(UITextField* textField){
        [textField addTarget:self action:@selector(nameChanged:) forControlEvents:UIControlEventValueChanged];
        textField.delegate = self;
        
        NSString *titleText;
        NSMutableDictionary *object = [self jamTrackObjectAtIndexPath:_selectedDetailIndexPath];
        if (object)
            titleText = [self preferredTitleForObject:object];
        
        textField.text = titleText;
    }];

    [actionController addAction:okAction];
    [actionController addAction:cancelAction];
    [self presentViewController:actionController animated:YES completion:nil];
    
}


#pragma mark - Youtube search delegate JWYTSearchTypingDelegate
-(void)searchTermChanged:(JWYTSearchTypingViewController *)controller {
    _lastSearchTerm = controller.searchTerm;
    NSUInteger section = [self indexOfSectionOfType:JWHomeSectionTypeYoutube];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:section]] withRowAnimation:UITableViewRowAnimationAutomatic];
}
//
//    else if (sectionType == JWHomeSectionTypeYoutube) {
//        
//        if (indexPath.row > 1) {
//            
//            UITableViewCell *toClipCell =
//            [tableView dequeueReusableCellWithIdentifier:@"JWTrackSetToClipCell" forIndexPath:indexPath];
//            cell = toClipCell;
//            virtualRow--;
//            virtualRow--;
//            
//        } else {
//            
//            if (indexPath.row == 0) {
//                UITableViewCell *toYoutubeSearchCell =
//                [tableView dequeueReusableCellWithIdentifier:@"JWYoutubeSearchCell" forIndexPath:indexPath];
//                cell = toYoutubeSearchCell;
//                cell.detailTextLabel.text = _lastSearchTerm; // @"acdc"; // last search term
//            } else if (indexPath.row == 1) {
//                UITableViewCell *toSourceAudioCell =



// This is the active one
-(void)finishedTrim:(id)controller title:(NSString*)title withDBKey:(NSString*)key {
    
    NSLog(@"%s",__func__);
    
    NSString *fname = [NSString stringWithFormat:@"trimmedMP3_%@.m4a",key ? key : @""];
    NSURL *fileURL = [self fileURLWithFileName:fname inPath:nil];
    
    id jamTrack = [self newJamTrackObjectWithFileURL:fileURL];
    
    if ([title length] > 0)
        jamTrack[@"title"] = title;

    NSUInteger insertSection = [self indexOfSectionOfType:JWHomeSectionTypeAudioFiles];
    
    NSMutableArray *jamTracks = _homeControllerSections[insertSection][@"trackobjectset"];
    
    if (jamTracks) {
        
        [jamTracks insertObject:jamTrack atIndex:0];
        
        [self saveHomeMenuLists];

        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:insertSection];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.navigationController popToRootViewControllerAnimated:NO];
            [self.tableView reloadData];
            [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
            [self performSegueWithIdentifier:@"showDetail" sender:self];
        });
    }
    
}

//        // Animated
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self.tableView beginUpdates];
//            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:insertSection] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
//            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:insertSection]]
//                                  withRowAnimation:UITableViewRowAnimationAutomatic];
//            [self.tableView endUpdates];
//        });


-(void)finishedTrim:(JWYTSearchTypingViewController *)controller withDBKey:(NSString*)key {
    NSLog(@"%s",__func__);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.navigationController popToRootViewControllerAnimated:YES];
    });
}


//-(void)finishedTrim:(JWYTSearchTypingViewController *)controller title:(NSString*)title withDBKey:(NSString*)key {

#pragma mark -

-(void)userAudioObtainedInNodeWithKey:(NSString*)nodeKey recordingId:(NSString*)rid {
    
    id nodeInJamTrack = [self jamTrackNodeObjectForKey:nodeKey];
    
    NSString *fname = [NSString stringWithFormat:@"clipRecording_%@.caf",rid ? rid : @""];
    nodeInJamTrack[@"fileURL"] = [self fileURLWithFileName:fname inPath:nil];
    
    [self saveHomeMenuLists];
    
    NSLog(@"NEW RECORDING in track \n%@",[nodeInJamTrack description]);
}


#pragma mark - 

- (void)insertNewObject:(id)sender {
    
    _isAddingNewObject = YES;
    
    [self performSegueWithIdentifier:@"JWSourceAudioFiles" sender:self];
}


#pragma mark - track objects

-(NSMutableDictionary*)newTrackObjectOfType:(JWMixerNodeTypes)mixNodeType {
    
    NSMutableDictionary *result = nil;
    if (mixNodeType == JWMixerNodeTypePlayer) {
        return [self newTrackObjectOfType:mixNodeType andFileURL:[self fileURLWithFileName:JWSampleFileNameAndExtension inPath:nil]];
        
    } else if (mixNodeType == JWMixerNodeTypePlayerRecorder) {
        return [self newTrackObjectOfType:mixNodeType andFileURL:nil];
    }
    return result;
}

-(NSMutableDictionary*)newTrackObjectOfType:(JWMixerNodeTypes)mixNodeType andFileURL:(NSURL*)fileURL {
    
    NSMutableDictionary *result = nil;
    if (mixNodeType == JWMixerNodeTypePlayer) {
        result =
        [@{@"key":[[NSUUID UUID] UUIDString],
           @"title":@"track",
           @"starttime":@(0.0),
           @"date":[NSDate date],
           @"type":@(JWMixerNodeTypePlayer)
           } mutableCopy];
    } else if (mixNodeType == JWMixerNodeTypePlayerRecorder) {
        result =
        [@{@"key":[[NSUUID UUID] UUIDString],
           @"title":@"track recorder",
           @"starttime":@(0.0),
           @"date":[NSDate date],
           @"type":@(JWMixerNodeTypePlayerRecorder)
           } mutableCopy];
    }

    if (fileURL)
        result[@"fileURL"] = fileURL;

    return result;
}

-(NSMutableDictionary*)newTrackObject {
    NSMutableDictionary *result = nil;
    NSURL *fileURL = [self fileURLWithFileName:JWSampleFileNameAndExtension inPath:nil];
    result =
    [@{@"key":[[NSUUID UUID] UUIDString],
       @"title":@"track",
       @"starttime":@(0.0),
       @"date":[NSDate date],
       @"fileURL":fileURL,
       @"type":@(JWMixerNodeTypePlayer)
       } mutableCopy];
    
    return result;
}

-(NSMutableArray*)newTrackObjectSet {
    NSMutableArray *result = nil;
    NSURL *fileURL = [self fileURLWithFileName:JWSampleFileNameAndExtension inPath:nil];

    NSMutableDictionary * fileReference =
    [@{@"duration":@(0),
       @"startinset":@(0.0),
       @"endinset":@(0.0),
       } mutableCopy];
    result =[@[
               [@{@"key":[[NSUUID UUID] UUIDString],
                  @"title":@"track",
                  @"starttime":@(0.0),
                  @"referencefile": fileReference,
                  @"date":[NSDate date],
                  @"fileURL":fileURL,
                  @"type":@(JWMixerNodeTypePlayer)
                  } mutableCopy],
               [@{@"key":[[NSUUID UUID] UUIDString],
                  @"title":@"track",
                  @"starttime":@(0.0),
                  @"date":[NSDate date],
                  @"type":@(JWMixerNodeTypePlayerRecorder)
                  } mutableCopy]
               ] mutableCopy];
    
    return result;
}

-(NSMutableDictionary*)newMixObject {
    NSMutableDictionary *result = nil;
    result =
    [@{@"key":[[NSUUID UUID] UUIDString],
       @"title":@"track set",
       @"titletype":@"jamtrackMix",
       @"trackobjectset":[self newTrackObjectSet],
       @"date":[NSDate date],
       } mutableCopy];
    return result;
}

-(NSMutableArray*)newMixes {
    NSMutableArray *result = nil;
    result =[@[
               [self newMixObject],
               [self newMixObject]
               ] mutableCopy];
    return result;
}

-(NSMutableDictionary*)newJamTrackObject {
    NSMutableDictionary *result = nil;
    
    id track1 = [self newTrackObjectOfType:JWMixerNodeTypePlayer];
    id track2 = [self newTrackObjectOfType:JWMixerNodeTypePlayerRecorder];

    NSMutableArray *trackObjects = [@[track1, track2] mutableCopy];
    
    result =
    [@{@"key":[[NSUUID UUID] UUIDString],
       @"titletype":@"jamtrack",
       @"title":@"jam Track",
       @"trackobjectset":trackObjects,
       @"date":[NSDate date],
       } mutableCopy];
    return result;
}

-(NSMutableDictionary*)newJamTrackObjectWithFileURL:(NSURL*)fileURL {
    NSMutableDictionary *result = nil;
    
    id track1 = [self newTrackObjectOfType:JWMixerNodeTypePlayer andFileURL:fileURL];
    id track2 = [self newTrackObjectOfType:JWMixerNodeTypePlayerRecorder];
    
    NSMutableArray *trackObjects = [@[track1, track2] mutableCopy];
    
    result =
    [@{@"key":[[NSUUID UUID] UUIDString],
       @"titletype":@"jamtrack",
       @"title":@"jam Track",
       @"trackobjectset":trackObjects,
       @"date":[NSDate date],
       } mutableCopy];
    return result;
}


-(NSMutableArray*)newJamTracks {
    NSMutableArray *result = nil;
    NSMutableArray *jamTracks = [NSMutableArray new];
    NSURL *fileURL;
    NSMutableDictionary *track1;
    NSMutableDictionary *track2;
    
    // JAMTRACK 1
    NSMutableDictionary *jamTrack1 = [self newJamTrackObject];
    jamTrack1[@"title"] = @"Brendans mix The killers";

    track1 = jamTrack1[@"trackobjectset"][0];
    fileURL = [self fileURLWithFileName:@"TheKillersTrimmedMP3-30.m4a" inPath:@[]];
    track1[@"fileURL"] = fileURL;

    track2 = jamTrack1[@"trackobjectset"][1];
    fileURL = [self fileURLWithFileName:@"clipRecording_killers1.caf" inPath:@[]];
    track2[@"fileURL"] = fileURL;
    
    
    // JAMTRACK 2
    NSMutableDictionary *jamTrack2 = [self newJamTrackObject];
    jamTrack2[@"title"] = @"Brendans mix Aminor1";

    track1 = jamTrack2[@"trackobjectset"][0];
    fileURL = [self fileURLWithFileName:@"AminorBackingtrackTrimmedMP3-45.m4a" inPath:@[]];
    track1[@"fileURL"] = fileURL;

    track2 = jamTrack2[@"trackobjectset"][1];
    fileURL = [self fileURLWithFileName:@"clipRecording_aminor1.caf" inPath:@[]];
    track2[@"fileURL"] = fileURL;

    
    [jamTracks insertObject:jamTrack2 atIndex:0];
    [jamTracks insertObject:jamTrack1 atIndex:0];
    
    result = jamTracks;

    return result;
}


-(NSMutableArray*)newProvidedJamTracks {
    NSMutableArray *result = nil;
    result =[@[
               [self newJamTrackObject],
               [self newJamTrackObject]
               ] mutableCopy];
    return result;
}


//        @{@"furl":fileURL,@"fsize":info[NSFileSize]};

-(NSMutableArray*)newDownloadedJamTracks {
    
    NSMutableArray *result = [NSMutableArray new];
    for (id fileInfo in [[JWFileController sharedInstance] downloadedJamTrackFiles]) {
        NSLog(@"%s %@",__func__,[fileInfo[@"furl"] lastPathComponent]);
        
        NSURL *fileURL = [self fileURLWithFileFlatFileURL:fileInfo[@"furl"]];
        
        [result addObject:[self newJamTrackObjectWithFileURL:fileURL]];
    }

    return result;
}


-(NSMutableArray*)newHomeMenuLists {
    NSMutableArray *result =
    [@[
       [@{
          @"title":@"Settings And Files",
          @"type":@(JWHomeSectionTypeOther),
          } mutableCopy],
       [@{
          @"title":@"Provided JamTracks",
          @"type":@(JWHomeSectionTypePreloaded),
          @"trackobjectset":[self newProvidedJamTracks],
          } mutableCopy],
       [@{
          @"title":@"Downloaded JamTracks",
          @"type":@(JWHomeSectionTypeDownloaded),
          @"trackobjectset":[self newDownloadedJamTracks],
          } mutableCopy],
       [@{
          @"title":@"Source Audio",
          @"type":@(JWHomeSectionTypeYoutube)
          } mutableCopy],
       [@{
          @"title":@"Audio Files",
          @"type":@(JWHomeSectionTypeAudioFiles),
          @"trackobjectset":[self newJamTracks],
          } mutableCopy],
       ] mutableCopy
     ];
    
    return result;
}


//[@{
//   @"title":@"Settings And Files",
//   @"type":@(JWHomeSectionTypeOther),
//   } mutableCopy],
//[@{
//   @"title":@"Provided JamTracks",
//   @"type":@(JWHomeSectionTypePreloaded),
//   @"trackobjectset":[self newProvidedJamTracks],
//   } mutableCopy],
//[@{
//   @"title":@"Downloaded JamTracks",
//   @"type":@(JWHomeSectionTypeDownloaded),
//   @"trackobjectset":[self newDownloadedJamTracks],
//   } mutableCopy],
//[@{
//   @"title":@"YoutubeSearch",
//   @"type":@(JWHomeSectionTypeYoutube)
//   } mutableCopy],
//[@{
//   @"title":@"Audio FIles",
//   @"type":@(JWHomeSectionTypeAudioFiles),
//   @"trackobjectset":[self newJamTracks],
//   } mutableCopy],
//] mutableCopy


#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showDetail"]) {

        DetailViewController *controller = (DetailViewController *)[[segue destinationViewController] topViewController];
        controller.delegate = self;

        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        
        [controller setDetailItem:[self objectSelected]];
        controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
        controller.navigationItem.leftItemsSupplementBackButton = YES;
        self.detailViewController = controller;
        
        if (_isAutoSelecting) {
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            _isAutoSelecting = NO;
        }
        self.selectedIndexPath = indexPath;
        
        
    } else if ([[segue identifier] isEqualToString:@"JWShowAudioFiles"]) {
        
        JWTrackSetsViewController *controller = (JWTrackSetsViewController *)[segue destinationViewController];
        controller.delegate = self;
        
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        if (indexPath.section < [_homeControllerSections count]) {

            id objectSection = _homeControllerSections[indexPath.section];

            JWHomeSectionType sectionType = [self typeForSectionObject:objectSection];
            
            id trackObjectSet;
            if (sectionType == JWHomeSectionTypeAudioFiles)
                trackObjectSet = objectSection[@"trackobjectset"];

            if (trackObjectSet) {
                [controller setTrackSet:trackObjectSet];
                self.selectedIndexPath = indexPath;
            }
        }
        
    } else if ([segue.identifier isEqualToString:@"JWClipAudio"]) {

        JWClipAudioViewController *clipController = (JWClipAudioViewController*)segue.destinationViewController;

        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSString *titleText;
        
        id jamTrackObject = [self jamTrackObjectAtIndexPath:indexPath];
        if (jamTrackObject) {
            
            titleText = [self preferredTitleForObject:jamTrackObject];
            
            id trackNodes = jamTrackObject[@"trackobjectset"];
            if (trackNodes) {
                if ([trackNodes count] > 0) {
                    id trackNode = trackNodes[0];
                    [JWCurrentWorkItem sharedInstance].currentAudioFileURL = trackNode[@"fileURL"];
                }
            }
        }
        
        clipController.trackName = titleText;
        
//        clipController.thumbImage = self.imageView.image;
        
    } else if ([segue.identifier isEqualToString:@"JWYoutubeSearch"]) {
        
        JWYTSearchTypingViewController *controller = (JWYTSearchTypingViewController*)segue.destinationViewController;
        controller.delegate = self;
        controller.searchTerm = _lastSearchTerm;
        
    } else if ([segue.identifier isEqualToString:@"JWSourceAudioFiles"]) {
        
        JWSourceAudioListsViewController *sourceAudioTableViewController = (JWSourceAudioListsViewController*)segue.destinationViewController;
        sourceAudioTableViewController.selectToClip = _isAddingNewObject;
        sourceAudioTableViewController.delegate = self;
    }
    
}


//        NSURL *imageURL = [self bestImageURLForMP3Record:mp3DataRecord];
//        if (imageURL) {
//            NSLog(@"DISPATCH %@",[imageURL absoluteString]);
//            dispatch_async(_imageRetrievalQueue, ^{
//                UIImage* youtubeThumb = [UIImage imageWithData:[NSData dataWithContentsOfURL:imageURL]];
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    clipController.thumbImage = youtubeThumb;
//                });
//            });


#pragma mark - helpers

-(JWHomeSectionType)typeForSectionObject:(id)sectionObject {
    JWHomeSectionType result = JWHomeSectionTypeNone;
    id typeValue = sectionObject[@"type"];
    if (typeValue)
        result = [typeValue unsignedIntegerValue];
    return result;
}

-(JWHomeSectionType)typeForSection:(NSUInteger)section {
    JWHomeSectionType result = JWHomeSectionTypeNone;
    if (section < [_homeControllerSections count]) {
        id objectSection = _homeControllerSections[section];
        result = [self typeForSectionObject:objectSection];
    }
    return result;
}


-(id)objectSelected {
    
    id result = nil;
    
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    
    if (indexPath.section < [_homeControllerSections count]) {
        
        id objectSection = _homeControllerSections[indexPath.section];

        NSUInteger virtualRow = indexPath.row;

        JWHomeSectionType sectionType = [self typeForSectionObject:objectSection];
        if (sectionType == JWHomeSectionTypeAudioFiles) {
            if (indexPath.row > 0)  // greater than min
                virtualRow--;
        }
        else if (sectionType == JWHomeSectionTypeYoutube) {
            if (indexPath.row > 1)  // greater than min
                virtualRow--;
        }
        
        if (sectionType == JWHomeSectionTypeAudioFiles || sectionType == JWHomeSectionTypePreloaded) {
            
            id jamTracks = objectSection[@"trackobjectset"];
            if (jamTracks) {
                if (virtualRow < [jamTracks count]) {
                    id jamTrack = jamTracks[virtualRow];
                    result = jamTrack;
                }
            }
        }
    }
    
    return result;
}



// indexpath of jamTrack object

-(NSIndexPath*)indexPathOfJamTrackCacheItem:(NSString*)key
{
    NSUInteger sectionIndex = 0;
    NSUInteger index = 0;
    BOOL found = NO;

    for (id objectSection in _homeControllerSections) {
        id jamTracksInSection = objectSection[@"trackobjectset"];
        index = 0; // new section
        for (id jamTrack in jamTracksInSection) {
            if ([key isEqualToString:jamTrack[@"key"]]) {
                found=YES;
                break;
            }
            index++;
        }
            
        if (found)
            break;
        
        sectionIndex++;
    }
    
    return [NSIndexPath indexPathForRow:index inSection:sectionIndex];
}

// returns a jamTrack that matches key
-(id)jamTrackObjectWithKey:(NSString*)key {
    
    id result;
    for (id objectSection in _homeControllerSections) {
        
        id jamTracks = objectSection[@"trackobjectset"];
        for (id jamTrack in jamTracks) {
            if ([key isEqualToString:jamTrack[@"key"]]) {
                result = jamTrack;
                break;
            }
        }
        if (result)
            break;
    }
    return result;
}

// returns a jamTrack that contains a tracknode that matches key
-(id)jamTrackObjectContainingNodeKey:(NSString*)key {
    
    id result;
    for (id objectSection in _homeControllerSections) {
        
        id jamTracks = objectSection[@"trackobjectset"];
        for (id jamTrack in jamTracks) {
            id trackNodes = jamTrack[@"trackobjectset"];
            for (id trackNode in trackNodes) {
                if ([key isEqualToString:trackNode[@"key"]]) {
                    result = jamTrack; // // jamtrack containing node key
                    break;
                }
            }
            if (result)
                break;
        }
        if (result)
            break;
    }
    
    return result;
}


// returns a trackNode
-(id)jamTrackNodeObjectForKey:(NSString*)key {
    
    id result;
    for (id objectSection in _homeControllerSections) {
        
        id jamTracks = objectSection[@"trackobjectset"];
        for (id jamTrack in jamTracks) {
            id trackNodes = jamTrack[@"trackobjectset"];
            for (id trackNode in trackNodes) {
                if ([key isEqualToString:trackNode[@"key"]]) {
                    result = trackNode; // jamtrack node
                    break;
                }
            }
            if (result)
                break;
        }
        if (result)
            break;
    }
    return result;
}



-(NSIndexPath*)indexPathOfCacheItem:(NSString*)key
{
    NSUInteger collectionIndex = 0;
    NSUInteger index = 0;
    
//    for (id objectCollection in _objectCollections) {
//        BOOL found = NO;
//        index = 0;
//        for (id obj in objectCollection) {
//            if ([key isEqualToString:obj[@"key"]]) {
//                // found it
//                found=YES;
//                break;
//            }
//            index++;
//        }
//        if (found){
//            break;
//        } else {
//            collectionIndex++;
//        }
//        
//    }
    
    //    NSLog(@"%s%@ index %ld",__func__,key,index);
    return [NSIndexPath indexPathForRow:index inSection:collectionIndex];
}


-(void)reloadItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section {
    
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:section]]
                          withRowAnimation:UITableViewRowAnimationFade];
    
    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:section] animated:YES scrollPosition:UITableViewScrollPositionNone];
}


-(NSInteger)indexOfSectionOfType:(JWHomeSectionType)type {
    
    NSInteger result = NSNotFound;
    NSUInteger index = 0;
    
    for (id objectSection in _homeControllerSections) {
        JWHomeSectionType sectionType = [self typeForSectionObject:objectSection];
        if (sectionType == type) {
            result = index;
            break;
        }
        index++;
    }
    return result;
}


-(NSString*)preferredTitleForObject:(id)object
{
    NSString *result;
    id userTitleValue = object[@"usertitle"];
    id titleValue = object[@"title"];
    
    if (userTitleValue) {
        result = userTitleValue;
    } else {
        if (titleValue)
            result = titleValue;
        else
            result = @"";
    }
    
    return result;
}


// return the section array of jamtracks that contain this jam track
-(NSMutableArray*)jamTracksWithJamTrackKey:(NSString*)key {
    NSMutableArray * result;
    NSIndexPath *itemIndexPath = [self indexPathOfJamTrackCacheItem:key];
    
    if (itemIndexPath) {
        id objectSection = _homeControllerSections[itemIndexPath.section];
        result = objectSection[@"trackobjectset"];
    }
    
    return result;
}




#pragma mark - TrackSets delegate methods

-(void)save:(JWTrackSetsViewController*)controller {

    NSLog(@"%s",__func__);
    
    [self saveHomeMenuLists];
}

-(NSString*)trackSets:(JWTrackSetsViewController*)controller titleForSection:(NSUInteger)section {
    
    NSString *result = nil;
    
    id objectSection = _homeControllerSections[[self indexOfSectionOfType:JWHomeSectionTypeAudioFiles]];
    
    id trackObjectSet = objectSection[@"trackobjectset"];
    if (section < [trackObjectSet count])
        result = trackObjectSet[section][@"title"];
    
    if (result == nil) {
        NSLog(@"NIL title %@",[trackObjectSet[section] description]);
    }
    return result;
}

-(NSString*)trackSets:(JWTrackSetsViewController*)controller titleDetailForSection:(NSUInteger)section {
    
    NSString *result = nil;
    
    id objectSection = _homeControllerSections[[self indexOfSectionOfType:JWHomeSectionTypeAudioFiles]];
    
    id trackObjectSet = objectSection[@"trackobjectset"];
    
    if (section < [trackObjectSet count]) {
        
        NSDateFormatter *dateFormatter = [NSDateFormatter new];
        dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        dateFormatter.timeStyle = NSDateFormatterMediumStyle;
        
        result = [NSString stringWithFormat:@"%@ %@ %@",trackObjectSet[section][@"titletype"],
                  [dateFormatter stringFromDate:trackObjectSet[section][@"date"]],
                  trackObjectSet[section][@"key"]];
    }
    
    return result;
}


-(NSString*)trackSets:(JWTrackSetsViewController*)controller titleForJamTrackKey:(NSString*)key {
    
    NSString * result;
    NSIndexPath *itemIndexPath = [self indexPathOfJamTrackCacheItem:key];
    
    if (itemIndexPath) {
        id objectSection = _homeControllerSections[itemIndexPath.section];
        
        id jamTracks = objectSection[@"trackobjectset"];
        if (jamTracks) {
            id jamTrack = jamTracks[itemIndexPath.row];
            result = [self preferredTitleForObject:jamTrack];
        }
    }
    
    return result;
}


-(NSString*)trackSets:(JWTrackSetsViewController*)controller titleForTrackAtIndex:(NSUInteger)index
    inJamTrackWithKey:(NSString*)key {
    
    NSString * result;
    NSIndexPath *itemIndexPath = [self indexPathOfJamTrackCacheItem:key];
    
    if (itemIndexPath) {
        id objectSection = _homeControllerSections[itemIndexPath.section];
        
        id jamTracks = objectSection[@"trackobjectset"];
        if (jamTracks) {
            id jamTrack = jamTracks[itemIndexPath.row];

            id trackNodes = jamTrack[@"trackobjectset"];
            if (trackNodes) {
                if (index < [trackNodes count]) {
                    id trackNode = trackNode[index];
                    result = [self preferredTitleForObject:trackNode];
                }
            }
        }
    }
    
    return result;
}


-(void)trackSets:(JWTrackSetsViewController*)controller saveJamTrackWithKey:(NSString*)key {
    
    NSIndexPath *itemIndexPath = [self indexPathOfJamTrackCacheItem:key];
    
    id jamTrack;
    
    if (itemIndexPath) {
        id objectSection = _homeControllerSections[itemIndexPath.section];
        id jamTracks = objectSection[@"trackobjectset"];
        if (jamTracks)
            jamTrack = jamTracks[itemIndexPath.row];
    }

    if (jamTrack) {
        NSLog(@"jamTrack Save \n%@\n%@",key,jamTrack[@"key"]);
        [self saveHomeMenuLists];
    } else {
        NSLog(@"jamTrack Save NOT found %@",key);
    }
}



-(void)addTrack:(id)controller cachKey:(NSString*)key {
    NSLog(@"%s",__func__);
    
    NSIndexPath *itemIndexPath = [self indexPathOfJamTrackCacheItem:key];
    
    if (itemIndexPath) {
        id objectSection = _homeControllerSections[itemIndexPath.section];
        
        id jamTracks = objectSection[@"trackobjectset"];
        
        if (jamTracks) {
            if (itemIndexPath.row < [jamTracks count]) {
                id jamTrack = jamTracks[itemIndexPath.row];
                id trackNodes = jamTrack[@"trackobjectset"];
                
                id playerRecorder = [self newTrackObjectOfType:JWMixerNodeTypePlayerRecorder];
                [trackNodes addObject:playerRecorder];
                NSLog(@"%s TRACK ADDED \n%@",__func__,[jamTrack description]);
                [self saveHomeMenuLists];
                
            }
        }
    }
}


// shared protocol method with detail and tracksets

-(id)addTrackNode:(id)controller toJamTrackWithKey:(NSString*)key {
    
    NSLog(@"%s",__func__);
    
    id result;
    NSIndexPath *itemIndexPath = [self indexPathOfJamTrackCacheItem:key];
    
    if (itemIndexPath) {
        id objectSection = _homeControllerSections[itemIndexPath.section];
        
        id jamTracks = objectSection[@"trackobjectset"];
        
        if (jamTracks) {
            if (itemIndexPath.row < [jamTracks count]) {
                id jamTrack = jamTracks[itemIndexPath.row];
                id trackNodes = jamTrack[@"trackobjectset"];
                
                id playerRecorder = [self newTrackObjectOfType:JWMixerNodeTypePlayerRecorder];
                [trackNodes addObject:playerRecorder];
                NSLog(@"%s TRACK ADDED \n%@",__func__,[jamTrack description]);
                
                [self saveHomeMenuLists];
                
                result = jamTrack;
            }
        }
    }
    
    return result;
}


//                id objectSection = _homeControllerSections[[self indexOfSectionOfType:JWHomeSectionTypeAudioFiles]];
//                id trackObjectSet = objectSection[@"trackobjectset"];
//                if ([controller isKindOfClass:[JWTrackSetsViewController class]]) {
//                    [(JWTrackSetsViewController*)controller setTrackSet:trackObjectSet];
//                }


#pragma mark - DetailViewController delegate methods

-(void)itemChanged:(DetailViewController*)controller {
//    [self saveUserOrderedList];
}

-(void)itemChanged:(DetailViewController*)controller cachKey:(NSString*)key {
    NSLog(@"%s%@",__func__,key);
    NSIndexPath *item = [self indexPathOfCacheItem:key];
    [self reloadItemAtIndex:item.row inSection:item.section];
}

-(void)save:(DetailViewController*)controller cachKey:(NSString*)key {
    NSLog(@"%s%@",__func__,key);
    NSIndexPath *item = [self indexPathOfCacheItem:key];
    [self reloadItemAtIndex:item.row inSection:item.section];
//    [self saveUserOrderedList];
}


-(NSArray*)tracks:(DetailViewController*)controller cachKey:(NSString*)key {
    return nil;
}


-(NSArray*)tracks:(DetailViewController*)controller forJamTrackKey:(NSString*)key {
    
    NSArray * result;
    NSIndexPath *itemIndexPath = [self indexPathOfJamTrackCacheItem:key];
    
    if (itemIndexPath) {
        id objectSection = _homeControllerSections[itemIndexPath.section];
        
        id jamTracks = objectSection[@"trackobjectset"];
        if (jamTracks) {
            id jamTrack = jamTracks[itemIndexPath.row];
            id jamTrackNodes = jamTrack[@"trackobjectset"];
            
            result = jamTrackNodes;
        }
    } else {
        result = @[]; // empty array
    }
    
    return result;
}


-(NSString*)detailController:(DetailViewController*)controller titleForJamTrackKey:(NSString*)key {

    NSString * result;
    NSIndexPath *itemIndexPath = [self indexPathOfJamTrackCacheItem:key];
    
    if (itemIndexPath) {
        id objectSection = _homeControllerSections[itemIndexPath.section];
        
        id jamTracks = objectSection[@"trackobjectset"];
        if (jamTracks) {
            id jamTrack = jamTracks[itemIndexPath.row];
            result = [self preferredTitleForObject:jamTrack];
        }
    }
    
    return result;
}


// not tested yet
-(NSString*)detailController:(DetailViewController*)controller titleForTrackAtIndex:(NSUInteger)index inJamTrackWithKey:(NSString*)key {
    
    NSString * result;
    NSIndexPath *itemIndexPath = [self indexPathOfJamTrackCacheItem:key];
    
    if (itemIndexPath) {
        id objectSection = _homeControllerSections[itemIndexPath.section];
        
        id jamTracks = objectSection[@"trackobjectset"];
        if (jamTracks) {
            id jamTrack = jamTracks[itemIndexPath.row];
            result = [self preferredTitleForObject:jamTrack];
        }
    }
    
    return result;
}


#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [_homeControllerSections count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    NSUInteger result = 0;
    
    if (section < [_homeControllerSections count]) {
        id trackObjects = _homeControllerSections[section][@"trackobjectset"];
        if (trackObjects)
            result = [trackObjects count];
        
        JWHomeSectionType sectionType = [self typeForSection:section];
        
        if (sectionType == JWHomeSectionTypeAudioFiles) {
            result ++;
        } else if (sectionType == JWHomeSectionTypeYoutube) {
            result ++;
            result ++;
        } else if (sectionType == JWHomeSectionTypeOther) {
            result ++;
        }
    }
    
    return result;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    
    NSInteger typeSection =[self indexOfSectionOfType:JWHomeSectionTypeOther];
    if (typeSection != NSNotFound && section == typeSection)
        return 24;
    typeSection =[self indexOfSectionOfType:JWHomeSectionTypePreloaded];
    if (typeSection != NSNotFound && section == typeSection)
        return 20;
    typeSection =[self indexOfSectionOfType:JWHomeSectionTypeDownloaded];
    if (typeSection != NSNotFound && section == typeSection)
        return 20;
    typeSection =[self indexOfSectionOfType:JWHomeSectionTypeYoutube];
    if (typeSection != NSNotFound && section == typeSection)
        return 30;
    typeSection =[self indexOfSectionOfType:JWHomeSectionTypeMyTracks];
    if (typeSection != NSNotFound && section == typeSection)
        return 24;

    return 24;
}
-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    
    NSInteger typeSection =[self indexOfSectionOfType:JWHomeSectionTypeOther];
    if (typeSection != NSNotFound && section == typeSection)
        return 14;
    typeSection =[self indexOfSectionOfType:JWHomeSectionTypeDownloaded];
    if (typeSection != NSNotFound && section == typeSection)
        return 4;
    typeSection =[self indexOfSectionOfType:JWHomeSectionTypePreloaded];
    if (typeSection != NSNotFound && section == typeSection)
        return 4;
    typeSection =[self indexOfSectionOfType:JWHomeSectionTypeYoutube];
    if (typeSection != NSNotFound && section == typeSection)
        return 4;
    typeSection =[self indexOfSectionOfType:JWHomeSectionTypeMyTracks];
    if (typeSection != NSNotFound && section == typeSection)
        return 10;

    typeSection =[self indexOfSectionOfType:JWHomeSectionTypeAudioFiles];
    if (typeSection != NSNotFound && section == typeSection)
        return 10;

    return 0;
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell ;
    
    if (indexPath.section < [_homeControllerSections count]) {
        
        id objectSection = _homeControllerSections[indexPath.section];

        JWHomeSectionType sectionType = [self typeForSectionObject:objectSection];

        BOOL isTrackItem = YES;;
        NSUInteger virtualRow = indexPath.row;
        
        if (sectionType == JWHomeSectionTypeAudioFiles) {
            if (indexPath.row > 0) {
                UITableViewCell *toDetailCell =
                [tableView dequeueReusableCellWithIdentifier:@"JWTrackSetToDetailCell" forIndexPath:indexPath];
                cell = toDetailCell;
                virtualRow--;
                
            } else {
                UITableViewCell *toAudioFilesCell =
                [tableView dequeueReusableCellWithIdentifier:@"JWAudioFilesSelectionCell" forIndexPath:indexPath];
                cell = toAudioFilesCell;
                isTrackItem = NO;
            }
        }
        else if (sectionType == JWHomeSectionTypeYoutube) {
            
            if (indexPath.row > 1) {
                
                UITableViewCell *toClipCell =
                [tableView dequeueReusableCellWithIdentifier:@"JWTrackSetToClipCell" forIndexPath:indexPath];
                cell = toClipCell;
                virtualRow--;
                virtualRow--;
                
            } else {
                
                if (indexPath.row == 0) {
                    UITableViewCell *toYoutubeSearchCell =
                    [tableView dequeueReusableCellWithIdentifier:@"JWYoutubeSearchCell" forIndexPath:indexPath];
                    cell = toYoutubeSearchCell;
                    cell.detailTextLabel.text = _lastSearchTerm; // @"acdc"; // last search term
                } else if (indexPath.row == 1) {
                    UITableViewCell *toSourceAudioCell =
                    [tableView dequeueReusableCellWithIdentifier:@"JWSourceAudioFilesSelectionCell" forIndexPath:indexPath];
                    cell = toSourceAudioCell;
                    cell.detailTextLabel.text = @"files"; // last search term
                }
                isTrackItem = NO;
            }
        }
        else if (sectionType == JWHomeSectionTypeDownloaded) {
            UITableViewCell *toClipCell =
            [tableView dequeueReusableCellWithIdentifier:@"JWTrackSetToClipCell" forIndexPath:indexPath];
            cell = toClipCell;
        }
        else if (sectionType == JWHomeSectionTypePreloaded) {
            UITableViewCell *toDetailCell =
            [tableView dequeueReusableCellWithIdentifier:@"JWTrackSetToDetailCell" forIndexPath:indexPath];
            cell = toDetailCell;
        }
        else if (sectionType == JWHomeSectionTypeMyTracks) {
            UITableViewCell *toDetailCell =
            [tableView dequeueReusableCellWithIdentifier:@"JWTrackSetToDetailCell" forIndexPath:indexPath];
            cell = toDetailCell;
        }
        else if (sectionType == JWHomeSectionTypeOther) {
            UITableViewCell *toOtherSelectCell =
            [tableView dequeueReusableCellWithIdentifier:@"JWOtherSelectCell" forIndexPath:indexPath];
            cell = toOtherSelectCell;
//            cell.textLabel.text = @"Other" ;
            cell.detailTextLabel.text = @"Amp Selection";
            isTrackItem = NO;
        }
        
        if (isTrackItem) {
            // IS  ATRACK CELL not a controll cell index 0 AUDIOFILES and SEARCH
            id trackObjects = objectSection[@"trackobjectset"];
            if (trackObjects) {
                
                NSArray *objectCollection = trackObjects;
                NSDictionary *jamTrack = objectCollection[virtualRow];
                
                NSString *titleText;
                NSString *detailText;

                titleText = [self preferredTitleForObject:jamTrack];
                
                if ([titleText length] == 0)
                    titleText = @"no title";
                
                id titleTypeValue = jamTrack[@"titletype"];
                if (titleTypeValue)
                    detailText = titleTypeValue;
                
                NSString *durationString;
                UIColor *durationColor = [UIColor blackColor];
                
                id trackNodes = jamTrack[@"trackobjectset"];
                if (trackNodes) {
                    double audioLength = 0;
                    for (id trackNode in trackNodes) {
                        NSURL *fileURL = trackNode[@"fileURL"];
                        id startTimeValue = trackNode[@"starttime"];
                        NSTimeInterval startTime = 0;
                        if (startTimeValue)
                            startTime = [startTimeValue doubleValue];
                        
                        if (fileURL)
                            audioLength += [[JWFileController sharedInstance] audioLengthForFileWithName:[fileURL lastPathComponent]];
                    }
                    durationString = [NSString stringWithFormat:@" %.0f sec ",audioLength];
                    durationColor = [UIColor orangeColor];
                }
                
//                NSString *textLabelText =[NSString stringWithFormat:@"%@%@",durationString,titleText];
                NSString *textLabelText =[NSString stringWithFormat:@"%@%@",detailText, durationString];
                
                NSDictionary *attrs = @{ NSForegroundColorAttributeName : [UIColor whiteColor] };
                
                NSMutableAttributedString *textLabelAttributedText =
                [[NSMutableAttributedString alloc] initWithString:textLabelText attributes:attrs];
                
                [textLabelAttributedText addAttribute:NSForegroundColorAttributeName value:durationColor
                                                range:NSMakeRange(detailText.length,durationString.length)];
                
//                cell.textLabel.attributedText = textLabelAttributedText;
                
                cell.textLabel.text = titleText;

                cell.detailTextLabel.attributedText = textLabelAttributedText;

//                cell.detailTextLabel.text = detailText;
            }
        }
    }
    
    return cell;
}


//    [@{@"key":cacheKey,
//       @"title":@"track",
//       @"starttime":@(0.0),
//       @"referencefile": fileReference,
//       @"date":[NSDate date],
//       @"fileURL":fileURL

//    cell.textLabel.text = object[@"title"];

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
//    return YES;
    
    BOOL result = NO;
    NSUInteger section = indexPath.section;
    NSUInteger count = 0;
    // Compute base rows for section
    if (section < [_homeControllerSections count]) {
        JWHomeSectionType sectionType = [self typeForSection:section];
        if (sectionType == JWHomeSectionTypeAudioFiles) {
            count ++;
        } else if (sectionType == JWHomeSectionTypeYoutube) {
            count ++;
            count ++;
        } else if (sectionType == JWHomeSectionTypeOther) {
            count ++;
        }
    }
    
    if (indexPath.row < count) {
        // baserow
    } else {
        result = YES;
    }
    
    return result;

}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        NSLog(@"%s",__func__);
        
        if (indexPath.section < [_homeControllerSections count]) {
            
            id objectSection = _homeControllerSections[indexPath.section];
            
            JWHomeSectionType sectionType = [self typeForSectionObject:objectSection];
            
            BOOL isTrackItem = YES;;
            NSUInteger virtualRow = indexPath.row;
            
            if (sectionType == JWHomeSectionTypeAudioFiles) {
                if (indexPath.row > 0) {
                    virtualRow--;
                } else {
                    isTrackItem = NO;
                }
            }
            else if (sectionType == JWHomeSectionTypeYoutube) {
                if (indexPath.row > 1) {
                    virtualRow--;
                    virtualRow--;
                } else {
                    isTrackItem = NO;
                }
            }
            
            if (isTrackItem) {
                // IS  ATRACK CELL not a controll cell index 0 AUDIOFILES and SEARCH
                id trackObjects = objectSection[@"trackobjectset"];
                if (trackObjects) {
                    if (virtualRow < [trackObjects count]) {
                        [trackObjects removeObjectAtIndex:virtualRow];
                        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
                    }
                }
            }
        }

        [self saveHomeMenuLists];
        
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        
        [self saveHomeMenuLists];

    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {

    NSString *result;
    if (section < [_homeControllerSections count]) {
        NSUInteger count = 0;
        id trackObjects = _homeControllerSections[section][@"trackobjectset"];
        if (trackObjects) {
            count = [trackObjects count];
        }
        
        id titleValue = _homeControllerSections[section][@"title"];
        if (titleValue) {
            if (section == [self indexOfSectionOfType:JWHomeSectionTypeOther] ||
                section == [self indexOfSectionOfType:JWHomeSectionTypeYoutube]
                ) {
                result = titleValue;
            } else {
                result = [NSString stringWithFormat:@"%@ %@",titleValue,[NSString stringWithFormat:@"%lu items",(unsigned long)count]];
            }
        }
    }
    
    return result;
}

// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    
    NSLog(@"%s",__func__);
    
    
    id moveObject ;
    NSUInteger fromIndex = 0;
    
    NSIndexPath *indexPath = fromIndexPath;
    
    if (indexPath.section < [_homeControllerSections count]) {
        
        id objectSection = _homeControllerSections[indexPath.section];
        
        JWHomeSectionType sectionType = [self typeForSectionObject:objectSection];
        
        BOOL isTrackItem = YES;;
        NSUInteger virtualRow = indexPath.row;
        
        if (sectionType == JWHomeSectionTypeAudioFiles) {
            if (indexPath.row > 0) {
                virtualRow--;
            } else {
                isTrackItem = NO;
            }
        }
        else if (sectionType == JWHomeSectionTypeYoutube) {
            if (indexPath.row > 1) {
                virtualRow--;
                virtualRow--;
            } else {
                isTrackItem = NO;
            }
        }
        
        if (isTrackItem) {
            // IS  ATRACK CELL not a controll cell index 0 AUDIOFILES and SEARCH
            id trackObjects = objectSection[@"trackobjectset"];
            if (trackObjects) {
                if (virtualRow < [trackObjects count]) {
                    
                    moveObject = trackObjects[virtualRow];
                    
                    fromIndex = virtualRow;
                    
                }
            }
        }
    }

    if (moveObject) {
        
        NSIndexPath *indexPath = toIndexPath;
        if (indexPath.section < [_homeControllerSections count]) {
            
            id objectSection = _homeControllerSections[indexPath.section];
            JWHomeSectionType sectionType = [self typeForSectionObject:objectSection];
            
            BOOL isTrackItem = YES;;
            NSUInteger virtualRow = indexPath.row;
            
            if (sectionType == JWHomeSectionTypeAudioFiles) {
                if (indexPath.row > 0) {
                    virtualRow--;
                } else {
                    isTrackItem = NO;
                }
            }
            else if (sectionType == JWHomeSectionTypeYoutube) {
                if (indexPath.row > 1) {
                    virtualRow--;
                    virtualRow--;
                } else {
                    isTrackItem = NO;
                }
            }
            
            if (isTrackItem) {
                // IS  ATRACK CELL not a controll cell index 0 AUDIOFILES and SEARCH
                id trackObjects = objectSection[@"trackobjectset"];
                if (trackObjects) {
                    if (virtualRow < [trackObjects count]) {
                        
                        [trackObjects removeObjectAtIndex:fromIndex];

                        [trackObjects insertObject:moveObject atIndex:virtualRow];
                        
                        [tableView beginUpdates];
                        [tableView reloadSections:[NSIndexSet indexSetWithIndex:fromIndexPath.section]  withRowAnimation:UITableViewRowAnimationAutomatic];
                        
//                        [tableView reloadRowsAtIndexPaths:@[fromIndexPath, toIndexPath]
//                                         withRowAnimation:UITableViewRowAnimationAutomatic];

                        [tableView endUpdates];
                   }
                }
            }
        }
    }

    //        self indexPathOfJamTrackCacheItem:<#(NSString *)#>
    

    
    
//    id moveObject = [_objectCollections[fromIndexPath.section] objectAtIndex:fromIndexPath.row];
//    
//    [_objectCollections[fromIndexPath.section]  removeObjectAtIndex:fromIndexPath.row];
//    [_objectCollections[toIndexPath.section]  insertObject:moveObject atIndex:toIndexPath.row];
    
//    if ([_objectCollections[fromIndexPath.section] count] == 0) {
//        [_objectCollections removeObjectAtIndex:fromIndexPath.section];
//        
//        //NSUInteger reloadSection = toIndexPath.section;
//        //        if (fromIndexPath.section < toIndexPath.section) {
//        //            reloadSection--;
//        //        }
//        [tableView beginUpdates];
//        [tableView deleteSections:[NSIndexSet indexSetWithIndex:fromIndexPath.section] withRowAnimation:UITableViewRowAnimationAutomatic];
//        //        [tableView reloadSections:[NSIndexSet indexSetWithIndex:reloadSection]  withRowAnimation:UITableViewRowAnimationAutomatic];
//        [tableView endUpdates];
//    }
    
//    [tableView reloadSectionIndexTitles];
    
//    [self saveUserOrderedList];
}

// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return NO; // neess more work
    
    // Return NO if you do not want the item to be re-orderable.
    BOOL result = NO;
    
    NSUInteger section = indexPath.section;
    NSUInteger count = 0;
    // Compute base rows for section
    if (section < [_homeControllerSections count]) {
        JWHomeSectionType sectionType = [self typeForSection:section];
        if (sectionType == JWHomeSectionTypeAudioFiles) {
            count ++;
        } else if (sectionType == JWHomeSectionTypeYoutube) {
            count ++;
            count ++;
        } else if (sectionType == JWHomeSectionTypeOther) {
            count ++;
        }
    }
    
    if (indexPath.row < count) {
        // baserow
    } else {
        result = YES;
    }
    return result;
}

-(NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
    
//    NSLog(@"%s",__func__);
    // Allow the proposed destination.
    
    NSUInteger section = sourceIndexPath.section;
    NSUInteger count = 0;
    // Compute base rows for section
    if (section < [_homeControllerSections count]) {
        JWHomeSectionType sectionType = [self typeForSection:section];
        if (sectionType == JWHomeSectionTypeAudioFiles) {
            count ++;
        } else if (sectionType == JWHomeSectionTypeYoutube) {
            count ++;
            count ++;
        } else if (sectionType == JWHomeSectionTypeOther) {
            count ++;
        }
    }
   
    if (sourceIndexPath.section == proposedDestinationIndexPath.section)
    {
        
    } else {
        proposedDestinationIndexPath = sourceIndexPath;
    }
    
    return proposedDestinationIndexPath;
}

#pragma mark -

-(NSString*)documentsDirectoryPath {
    NSString *result = nil;
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    result = [searchPaths objectAtIndex:0];
    return result;
}

-(NSURL *)fileURLWithFileFlatFileURL:(NSURL*)flatURL{
    NSString *fileName = [flatURL lastPathComponent];
    NSArray *pathComponents = [flatURL pathComponents];
    __block NSUInteger indexToDocuments = 0;
    [pathComponents enumerateObjectsWithOptions:NSEnumerationReverse
                                     usingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                                         if ([obj isEqualToString:@"Documents"]) {
                                             indexToDocuments = idx;
                                             *stop = YES;
                                         }
                                     }];
    
    NSMutableArray *pathFromDocuments = [NSMutableArray new];
    // Iterate one past Documents til count -1 end slash
    for (NSUInteger i = (indexToDocuments + 1); i <  ([pathComponents count] - 1); i++) {
        [pathFromDocuments addObject:pathComponents[i]];
    }
    
    NSURL *result = [self fileURLWithFileName:fileName  inPath:pathFromDocuments];
    return result;
}

-(NSURL *)fileURLWithFileName:(NSString*)name inPath:(NSArray*)pathComponents{
    NSURL *result;
    NSURL *baseURL = [NSURL fileURLWithPath:[self documentsDirectoryPath]];
    NSString *pathString = @"";
    for (id path in pathComponents) {
        pathString = [pathString stringByAppendingPathComponent:path];
    }
    pathString = [pathString stringByAppendingPathComponent:name];
    NSURL *url = [NSURL fileURLWithPath:pathString relativeToURL:baseURL];
    result = url;
    return result;
}

-(NSURL *)fileURLWithRelativePathName:(NSString*)pathName {
    NSURL *result;
    NSURL *baseURL = [NSURL fileURLWithPath:[self documentsDirectoryPath]];
    NSURL *url = [NSURL fileURLWithPath:pathName relativeToURL:baseURL];
    result = url;
    return result;
}

-(NSURL *)fileURLWithFileName:(NSString*)name {
    return [self fileURLWithFileName:name inPath:nil];
}


#pragma mark -

-(void)serializeOutJamTrackNode:(id)jamTrackNode {
    
    id furl = jamTrackNode[@"fileURL"];
    if (furl) {
        jamTrackNode[@"fileRelativePath"] = [(NSURL*)furl relativeString];
        [jamTrackNode removeObjectForKey:@"fileURL"];
     } else {
//        NSLog(@"%s NO FURL %@",__func__,[jamTrackNode description]);
    }
}

-(void)serializeOutJamTrackNodeWithKey:(NSString*)key {
    id jamTrackNode = [self jamTrackNodeObjectForKey:key];
    [self serializeOutJamTrackNode:jamTrackNode];
}

-(void)serializeOutJamTracks {
    for (id objectSection in _homeControllerSections) {
        id jamTracksInSection = objectSection[@"trackobjectset"];
        for (id jamTrack in jamTracksInSection) {
            id jamTrackNodes = jamTrack[@"trackobjectset"];
            for (id jamTrackNode in jamTrackNodes) {
                [self serializeOutJamTrackNode:jamTrackNode];
            }
        }
    }
}


-(void)serializeInJamTrackNode:(id)jamTrackNode {
    id fileRelativePath = jamTrackNode[@"fileRelativePath"];
    if (fileRelativePath)
        jamTrackNode[@"fileURL"] =[self fileURLWithRelativePathName:fileRelativePath];
}

-(void)serializeInJamTrackNodeWithKey:(NSString*)key {
    id jamTrackNode = [self jamTrackNodeObjectForKey:key];
    [self serializeInJamTrackNode:jamTrackNode];
}

-(void)serializeInJamTracks {
    for (id objectSection in _homeControllerSections) {
        id jamTracksInSection = objectSection[@"trackobjectset"];
        for (id jamTrack in jamTracksInSection) {
            id jamTrackNodes = jamTrack[@"trackobjectset"];
            for (id jamTrackNode in jamTrackNodes) {
                [self serializeInJamTrackNode:jamTrackNode];
            }
        }
    }
}


-(void)saveHomeMenuLists {
    [self serializeOutJamTracks];
//    NSLog(@"%s homeObjects %@",__func__,[_homeControllerSections description]);
    [_homeControllerSections writeToURL:[self fileURLWithFileName:@"homeObjects"] atomically:YES];
    [self serializeInJamTracks];
    NSLog(@"%s HOMEOBJECTS [%ld]",__func__,[_homeControllerSections count]);
}

-(void)readHomeMenuLists {
    _homeControllerSections = [[NSMutableArray alloc] initWithContentsOfURL:[self fileURLWithFileName:@"homeObjects"]];
    [self serializeInJamTracks];
//    NSLog(@"%s homeObjects %@",__func__,[_homeControllerSections description]);
    NSLog(@"%s HOMEOBJECTS [%ld]",__func__,[_homeControllerSections count]);
}

@end


