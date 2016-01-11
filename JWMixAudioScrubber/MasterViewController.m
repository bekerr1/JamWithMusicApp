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


@interface MasterViewController () <JWDetailDelegate,JWTrackSetsProtocol,JWYTSearchTypingDelegate,JWSourceAudioListsDelegate,UITextFieldDelegate>
{
    BOOL _isAddingNewObject;
}
@property NSIndexPath *selectedIndexPath;
@property NSMutableArray *objectCollections;  // collects objects
@property NSMutableArray *homeControllerSections;  // collects objects
@property NSIndexPath *selectedDetailIndexPath;
@property NSString *nameChangeString;

//@property JWFileController *fileController;
@end

//#define JWSampleFileNameAndExtension @"trimmedMP3.m4a"
//#define JWSampleFileNameAndExtension @"trimmedMP3-45.m4a"
//#define JWSampleFileNameAndExtension @"AminorBackingtrackTrimmedMP3-45.m4a"

#define JWSampleFileNameAndExtension @"TheKillersTrimmedMP3-30.m4a"


@implementation MasterViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    
    _isAddingNewObject = NO;
//    self.fileController = [JWFileController new];
//    [self.fileController update];
    

    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
    self.navigationItem.rightBarButtonItem = addButton;
    self.detailViewController =
    (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];

    [self readUserOrderedList];

    [self readHomeMenuLists];
    if (_homeControllerSections == nil) {
        _homeControllerSections = [self newHomeMenuLists];
    }
    
    
}

- (void)viewWillAppear:(BOOL)animated {
    self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    [super viewWillAppear:animated];
    
    _isAddingNewObject = NO;

    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        [self.detailViewController stopPlaying];
    }
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
    
//    [tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
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
        if (object) {
            
            id userTitleValue = object[@"usertitle"];
            id titleValue = object[@"title"];
            
            if (userTitleValue) {
                titleText = userTitleValue;
            } else {
                if (titleValue) {
                    titleText = titleValue;
                } else {
                    titleText = @"";
                }
            }
        }
        
        textField.text = titleText;
    }];

    [actionController addAction:okAction];
    [actionController addAction:cancelAction];
    [self presentViewController:actionController animated:YES completion:nil];
    
}


#pragma mark - Youtube search delegate JWYTSearchTypingDelegate

-(void)finishedTrim:(JWYTSearchTypingViewController *)controller withDBKey:(NSString*)key {
    NSLog(@"%s",__func__);
//    NSString *fname = [NSString stringWithFormat:@"trimmedMP3_%@.m4a",key ? key : @""];
//    NSURL *fileURL = [self fileURLWithFileName:fname];
//    id trackObject = [self newTrackObjectOfType:JWMixerNodeTypePlayer andFileURL:fileURL];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.navigationController popToRootViewControllerAnimated:YES];
    });
}


// This is the active one
-(void)finishedTrim:(id)controller title:(NSString*)title withDBKey:(NSString*)key {
    
    NSLog(@"%s",__func__);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.navigationController popToRootViewControllerAnimated:NO];
    });
    
    NSString *fname = [NSString stringWithFormat:@"trimmedMP3_%@.m4a",key ? key : @""];
    NSURL *fileURL = [self fileURLWithFileName:fname];
    
    //    id trackObject = [self newTrackObjectOfType:JWMixerNodeTypePlayer andFileURL:fileURL];
    
    id track1 = [self newTrackObjectOfType:JWMixerNodeTypePlayer andFileURL:fileURL];
    id track2 = [self newTrackObjectOfType:JWMixerNodeTypePlayerRecorder];
    
    id jamTrack = [self newJamTrackObject];
    
    jamTrack[@"trackobjectset"] = [@[track1, track2] mutableCopy];
    
    jamTrack[@"title"] = title;
    NSUInteger insertSection = [self indexOfSectionOfType:JWHomeSectionTypeAudioFiles];
    
    NSMutableArray *jamTracks = _homeControllerSections[insertSection][@"trackobjectset"];
    
    if (jamTracks) {
        [jamTracks insertObject:jamTrack atIndex:0];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView beginUpdates];
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:insertSection] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:insertSection]]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView endUpdates];
        });
        
        //        [self.tableView reloadData];
    }
    
}


//-(void)finishedTrim:(JWYTSearchTypingViewController *)controller title:(NSString*)title withDBKey:(NSString*)key {
//    
//    NSLog(@"%s",__func__);
//    
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [self.navigationController popToRootViewControllerAnimated:NO];
//    });
//
//    NSString *fname = [NSString stringWithFormat:@"trimmedMP3_%@.m4a",key ? key : @""];
//    NSURL *fileURL = [self fileURLWithFileName:fname];
//    
////    id trackObject = [self newTrackObjectOfType:JWMixerNodeTypePlayer andFileURL:fileURL];
//
//    id track1 = [self newTrackObjectOfType:JWMixerNodeTypePlayer andFileURL:fileURL];
//    id track2 = [self newTrackObjectOfType:JWMixerNodeTypePlayerRecorder];
//
//    id jamTrack = [self newJamTrackObject];
//    
//    jamTrack[@"trackobjectset"] = [@[track1, track2] mutableCopy];
//    
//    jamTrack[@"title"] = title;
//    NSUInteger insertSection = [self indexOfSectionOfType:JWHomeSectionTypeAudioFiles];
//    
//    NSMutableArray *jamTracks = _homeControllerSections[insertSection][@"trackobjectset"];
//    
//    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:insertSection] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
//    
//    if (jamTracks) {
//        [jamTracks insertObject:jamTrack atIndex:0];
//        [self.tableView beginUpdates];
//        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:insertSection]]
//                              withRowAnimation:UITableViewRowAnimationAutomatic];
//        [self.tableView endUpdates];
//
////        [self.tableView reloadData];
//    }
//    
//}





#pragma mark - 

- (void)insertNewObject:(id)sender {
    
    _isAddingNewObject = YES;
    [self performSegueWithIdentifier:@"JWSourceAudioFiles" sender:self];
    return;
    
    if (!self.objectCollections) {
        self.objectCollections = [[NSMutableArray alloc] init];
    }
    
    NSMutableArray *objectCollection = nil;
    BOOL useSet = YES;
    /*
     Use SET will great a collection of items, here a Tracks Object set
     A Track Object or a Track Object set
     */
    
    if (useSet) {
        objectCollection = [self newTrackObjectSet];
        [_objectCollections insertObject:objectCollection atIndex:0];
        
        
        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        
    } else {
        
        NSMutableDictionary *trackObject = [self newTrackObject];
        NSIndexPath *selected = [self.tableView indexPathForSelectedRow];
        
        // ADD A Track Object to the selected TrackObject set
        if (selected) {
            objectCollection = _objectCollections[selected.section];
            
            [objectCollection insertObject:trackObject atIndex:0];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:selected.section];
            
            [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            
        }
        
        // ELSE CREATES AN NEW TrackObject set
        else {
            
            [objectCollection insertObject:trackObject atIndex:0];
            [_objectCollections insertObject:objectCollection atIndex:0];
            
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
    
    [self saveUserOrderedList];
    
}


#pragma mark - track objects

-(NSMutableDictionary*)newTrackObjectOfType:(JWMixerNodeTypes)mixNodeType {
    
    NSMutableDictionary *result = nil;
    if (mixNodeType == JWMixerNodeTypePlayer) {
        return [self newTrackObjectOfType:mixNodeType andFileURL:[self fileURLWithFileName:JWSampleFileNameAndExtension]];
        
    } else if (mixNodeType == JWMixerNodeTypePlayerRecorder) {
        return [self newTrackObjectOfType:mixNodeType andFileURL:nil];
    }
    return result;
}

-(NSMutableDictionary*)newTrackObjectOfType:(JWMixerNodeTypes)mixNodeType andFileURL:(NSURL*)fileURL {
    
    NSMutableDictionary *result = nil;
    if (mixNodeType == JWMixerNodeTypePlayer) {
//        NSURL *fileURL = [self fileURLWithFileName:JWSampleFileNameAndExtension];
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

    if (fileURL) {
        result[@"fileURL"] = fileURL;
    }

    return result;
}

-(NSMutableDictionary*)newTrackObject {
    NSMutableDictionary *result = nil;
    NSURL *fileURL = [self fileURLWithFileName:JWSampleFileNameAndExtension];
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
    NSURL *fileURL = [self fileURLWithFileName:JWSampleFileNameAndExtension];
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

-(NSMutableArray*)newJamTracks {
    NSMutableArray *result = nil;
    NSMutableArray *jamTracks = [NSMutableArray new];
    
//    // Copy from savedObjects object collections
//    for (id objectCollection in _objectCollections) {
//        NSMutableDictionary *jamTrack = [self newJamTrackObject];
//        jamTrack[@"trackobjectset"] = [NSMutableArray arrayWithArray:objectCollection];
//        [jamTracks addObject:jamTrack];
//    }
    
    NSMutableDictionary *jamTrack1 = [self newJamTrackObject];
    jamTrack1[@"title"] = @"Brendans mix The killers";
    
    NSURL *fileURL = [self fileURLWithFileName:@"TheKillersTrimmedMP3-30.m4a"];
    NSMutableDictionary *track1 = jamTrack1[@"trackobjectset"][0];
    track1[@"fileURL"] = fileURL;
    
    fileURL = [self fileURLWithFileName:@"clipRecording_killers1.caf"];
    NSMutableDictionary *track2 = jamTrack1[@"trackobjectset"][1];
    track2[@"fileURL"] = fileURL;
    
    
    NSMutableDictionary *jamTrack2 = [self newJamTrackObject];
    jamTrack2[@"title"] = @"Brendans mix Aminor1";
    
    fileURL = [self fileURLWithFileName:@"AminorBackingtrackTrimmedMP3-45.m4a"];
    track1 = jamTrack2[@"trackobjectset"][0];
    track1[@"fileURL"] = fileURL;
    
    fileURL = [self fileURLWithFileName:@"clipRecording_aminor1.caf"];
    track2 = jamTrack2[@"trackobjectset"][1];
    track2[@"fileURL"] = fileURL;

    [jamTracks insertObject:jamTrack2 atIndex:0];
    [jamTracks insertObject:jamTrack1 atIndex:0];
    
    if ([jamTracks count] > 0) {
        result = jamTracks;
    }

//    result =[@[
//               [self newJamTrackObject],
//               [self newJamTrackObject]
//               ] mutableCopy];
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
-(NSMutableArray*)newDownloadedJamTracks {
    NSMutableArray *result = [NSMutableArray new];
    
    for (id fileInfo in [[JWFileController sharedInstance] downloadedJamTrackFiles]) {
        
//        @{@"furl":fileURL,@"fsize":info[NSFileSize]};
        
        NSLog(@"%s %@",__func__,[fileInfo[@"furl"] lastPathComponent]);
        [result addObject:[self newTrackObjectOfType:JWMixerNodeTypePlayer andFileURL:fileInfo[@"furl"]]];
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
          @"title":@"YoutubeSearch",
          @"type":@(JWHomeSectionTypeYoutube)
          } mutableCopy],
       [@{
          @"title":@"Audio FIles",
          @"type":@(JWHomeSectionTypeAudioFiles),
          @"trackobjectset":[self newJamTracks],
          } mutableCopy],
       ] mutableCopy
     ];
    
    return result;
}





#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showDetail"]) {

        DetailViewController *controller = (DetailViewController *)[[segue destinationViewController] topViewController];
        controller.delegate = self;

        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
//        NSMutableArray *objectCollection = _objectCollections[indexPath.section];
//        NSDictionary *object = objectCollection[indexPath.row];
//        [controller setDetailItem:object];
        
        [controller setDetailItem:[self objectSelected]];

        controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
        controller.navigationItem.leftItemsSupplementBackButton = YES;
        self.detailViewController = controller;
        
        self.selectedIndexPath = indexPath;
    } else if ([[segue identifier] isEqualToString:@"JWShowAudioFiles"]) {
        
        JWTrackSetsViewController *controller = (JWTrackSetsViewController *)[segue destinationViewController];
        controller.delegate = self;
        
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        if (indexPath.section < [_homeControllerSections count]) {
            
            NSMutableArray *jamTrackNodes = [NSMutableArray new];

            id objectSection = _homeControllerSections[indexPath.section];

            JWHomeSectionType sectionType = [self typeForSectionObject:objectSection];

            if (sectionType == JWHomeSectionTypeAudioFiles) {
                id trackObjectSet = objectSection[@"trackobjectset"];
                for (id trackObject in trackObjectSet)
                    [jamTrackNodes addObject:trackObject[@"trackobjectset"]];
                
            }
            
            [controller setObjectCollections:jamTrackNodes];
            
            self.selectedIndexPath = indexPath;
        }
        
    } else if ([segue.identifier isEqualToString:@"JWClipAudio"]) {
        
//        id mp3DataRecord = _mp3FilesInfo[_currentCacheItem];
//        NSString *title = mp3DataRecord ? mp3DataRecord[JWDbKeyYouTubeData][JWDbKeyYouTubeTitle] : @"unknown";
        
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSString *titleText;
        
        id jamTrackObject = [self jamTrackObjectAtIndexPath:indexPath];

        if (jamTrackObject) {
            
            id userTitleValue = jamTrackObject[@"usertitle"];
            id titleValue = jamTrackObject[@"title"];
            if (userTitleValue) {
                titleText = userTitleValue;
            } else {
                if (titleValue)
                    titleText = titleValue;
                else
                    titleText = @"";
            }
            
            NSURL *fileURL = jamTrackObject[@"fileURL"];
            [JWCurrentWorkItem sharedInstance].currentAudioFileURL = fileURL;

        }
        
        JWClipAudioViewController *clipController = (JWClipAudioViewController*)segue.destinationViewController;
        clipController.trackName = titleText;
//        clipController.thumbImage = self.imageView.image;

        
    } else if ([segue.identifier isEqualToString:@"JWYoutubeSearch"]) {
        
        //        id mp3DataRecord = _mp3FilesInfo[_currentCacheItem];
        //        NSString *title = mp3DataRecord ? mp3DataRecord[JWDbKeyYouTubeData][JWDbKeyYouTubeTitle] : @"unknown";
        //
        JWYTSearchTypingViewController *controller = (JWYTSearchTypingViewController*)segue.destinationViewController;
        controller.delegate = self;
        
        
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

-(JWHomeSectionType)typeForSectionObject:(id)sectionObject
{
    JWHomeSectionType result = JWHomeSectionTypeNone;
    id typeValue = sectionObject[@"type"];
    if (typeValue)
        result = [typeValue unsignedIntegerValue];
    return result;
}

-(JWHomeSectionType)typeForSection:(NSUInteger)section
{
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
    
    NSLog(@"%s %@ %ld %ld",__func__,[indexPath description],indexPath.section,indexPath.row);
    
    if (indexPath.section < [_homeControllerSections count]) {
        
        id objectSection = _homeControllerSections[indexPath.section];
        
        JWHomeSectionType sectionType = [self typeForSectionObject:objectSection];
        
        NSUInteger virtualRow = indexPath.row;
        
        if (sectionType == JWHomeSectionTypeAudioFiles) {
            if (indexPath.row > 0)  // greater than min
                virtualRow--;
        }
        else if (sectionType == JWHomeSectionTypeYoutube) {
            if (indexPath.row > 1)  // greater than min
                virtualRow--;
        }
        
        
        if (sectionType == JWHomeSectionTypeAudioFiles || sectionType == JWHomeSectionTypePreloaded) {
            
            id trackObjectSet = objectSection[@"trackobjectset"];
            if (trackObjectSet) {
                if (virtualRow < [trackObjectSet count]) {
                    id trackObject = trackObjectSet[virtualRow];
                    result = trackObject;
                }
                //                result = trackObjectSet;
                //                result = objectSection;
            }
        }
    }
    
    return result;
}



-(NSIndexPath*)indexPathOfJamTrackCacheItem:(NSString*)key
{
    NSUInteger sectionIndex = 0;
    NSUInteger index = 0;
    BOOL found = NO;

    for (id objectSection in _homeControllerSections) {
        id jamTracksInSection = objectSection[@"trackobjectset"];
        index = 0;
        for (id obj in jamTracksInSection) {
            if ([key isEqualToString:obj[@"key"]]) {
                // found it
                found=YES;
                break;
            }
            index++;
        }
            
        if (found)
            break;
        
        sectionIndex++;
    }
    
    //    NSLog(@"%s%@ index %ld",__func__,key,index);
    return [NSIndexPath indexPathForRow:index inSection:sectionIndex];
    
}


-(NSIndexPath*)indexPathOfCacheItem:(NSString*)key
{
    NSUInteger collectionIndex = 0;
    NSUInteger index = 0;
    
    for (id objectCollection in _objectCollections) {
        BOOL found = NO;
        index = 0;
        for (id obj in objectCollection) {
            if ([key isEqualToString:obj[@"key"]]) {
                // found it
                found=YES;
                break;
            }
            index++;
        }
        if (found){
            break;
        } else {
            collectionIndex++;
        }
        
    }
    
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

#pragma mark - TrackSets delegate methods

-(void)save:(JWTrackSetsViewController*)controller {
    
    id objectSection = _homeControllerSections[[self indexOfSectionOfType:JWHomeSectionTypeAudioFiles]];
    
    id trackObjectSet = objectSection[@"trackobjectset"];
    
    NSUInteger index = 0;
    for (id objectCollection in controller.objectCollections){
        
        if (index < [trackObjectSet count]) {
            id trackObject = trackObjectSet [index];
            trackObject[@"trackobjectset"] = objectCollection;
        }
        index++;
    }
}

-(NSString*)trackSets:(JWTrackSetsViewController*)controller titleForSection:(NSUInteger)section {
    
    NSString *result = nil;
    
    id objectSection = _homeControllerSections[[self indexOfSectionOfType:JWHomeSectionTypeAudioFiles]];
    
    id trackObjectSet = objectSection[@"trackobjectset"];
    if (section < [trackObjectSet count]) {
        result = trackObjectSet[section][@"title"];
    }
    
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
        
        //        result = trackObjectSet[section][@"titletype"];
        result = [NSString stringWithFormat:@"%@ %@ %@",trackObjectSet[section][@"titletype"],
                  [dateFormatter stringFromDate:trackObjectSet[section][@"date"]],
                  trackObjectSet[section][@"key"]];
    }
    
    return result;
}

#pragma mark - delegate methods

-(void)itemChanged:(DetailViewController*)controller {
    [self saveUserOrderedList];
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
    [self saveUserOrderedList];
}


#pragma mark -

-(void)addTrack:(DetailViewController*)controller cachKey:(NSString*)key {
    
    NSIndexPath *item = [self indexPathOfCacheItem:key];
    
    NSMutableArray *objectCollection = _objectCollections[item.section];
    NSMutableDictionary *trackObject = [self newTrackObject];
    
    [objectCollection insertObject:trackObject atIndex:0];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:item.section];
    
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

-(NSArray*)tracks:(DetailViewController*)controller cachKey:(NSString*)key {
    NSIndexPath *item = [self indexPathOfCacheItem:key];
    NSMutableArray *objectCollection = _objectCollections[item.section];
    
    return objectCollection;
}

-(NSArray*)tracks:(DetailViewController*)controller forJamTrackKey:(NSString*)key {
    NSArray * result;
    NSIndexPath *item = [self indexPathOfJamTrackCacheItem:key];
    
    if (item) {
        id objectSection = _homeControllerSections[item.section];
        
        id trackObjectSet = objectSection[@"trackobjectset"];
        if (trackObjectSet) {
            id jamTrackObject = trackObjectSet[item.row];
            id jamTrackObjectSet = jamTrackObject[@"trackobjectset"];
            
            result = jamTrackObjectSet;
        }
    } else {
        result = @[]; // empty array
    }
    
    return result;
}

//            id jamTracks = objectSection[@"trackobjectset"];
//            BOOL found = NO;
//            NSUInteger index = 0;
//            for (id obj in jamTracks) {
//                if ([key isEqualToString:obj[@"key"]]) {
//                    // found it
//                    found=YES;
//                    break;
//                }
//                index++;
//            }



#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//    return [_objectCollections count];
    return [_homeControllerSections count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//    return [_objectCollections[section] count];
    
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
    
    return 0;
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

    UITableViewCell *cell ;
    
    if (indexPath.section < [_homeControllerSections count]) {
        
        id objectSection = _homeControllerSections[indexPath.section];

        JWHomeSectionType sectionType = [self typeForSectionObject:objectSection];

        BOOL isTrackItem = YES;;
        NSUInteger virtualRow = indexPath.row;
        
        if (sectionType == JWHomeSectionTypeAudioFiles) {
            if (indexPath.row > 0) {
                UITableViewCell *toDetailCell = [tableView dequeueReusableCellWithIdentifier:@"JWTrackSetToDetailCell" forIndexPath:indexPath];
                cell = toDetailCell;
                virtualRow--;
                
            } else {
                UITableViewCell *toAudioFilesCell = [tableView dequeueReusableCellWithIdentifier:@"JWAudioFilesSelectionCell" forIndexPath:indexPath];
                cell = toAudioFilesCell;
                isTrackItem = NO;
            }
        }
        else if (sectionType == JWHomeSectionTypeYoutube) {
            
            if (indexPath.row > 1) {
                
                UITableViewCell *toClipCell = [tableView dequeueReusableCellWithIdentifier:@"JWTrackSetToClipCell" forIndexPath:indexPath];
                cell = toClipCell;
                virtualRow--;
                virtualRow--;
                
            } else {
                
                if (indexPath.row == 0) {
                    UITableViewCell *toYoutubeSearchCell = [tableView dequeueReusableCellWithIdentifier:@"JWYoutubeSearchCell" forIndexPath:indexPath];
                    cell = toYoutubeSearchCell;
                    cell.detailTextLabel.text = @"acdc"; // last search term
                } else if (indexPath.row == 1) {
                    UITableViewCell *toSourceAudioCell = [tableView dequeueReusableCellWithIdentifier:@"JWSourceAudioFilesSelectionCell" forIndexPath:indexPath];
                    cell = toSourceAudioCell;
                    cell.detailTextLabel.text = @"files"; // last search term
                }
                isTrackItem = NO;

                
            }
        }
        else if (sectionType == JWHomeSectionTypeDownloaded) {
            UITableViewCell *toClipCell = [tableView dequeueReusableCellWithIdentifier:@"JWTrackSetToClipCell" forIndexPath:indexPath];
            cell = toClipCell;
        }
        else if (sectionType == JWHomeSectionTypePreloaded) {
            UITableViewCell *toDetailCell = [tableView dequeueReusableCellWithIdentifier:@"JWTrackSetToDetailCell" forIndexPath:indexPath];
            cell = toDetailCell;
        }
        else if (sectionType == JWHomeSectionTypeMyTracks) {
            UITableViewCell *toDetailCell = [tableView dequeueReusableCellWithIdentifier:@"JWTrackSetToDetailCell" forIndexPath:indexPath];
            cell = toDetailCell;
        }
        else if (sectionType == JWHomeSectionTypeOther) {
            UITableViewCell *toOtherSelectCell = [tableView dequeueReusableCellWithIdentifier:@"JWOtherSelectCell" forIndexPath:indexPath];
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
                NSDictionary *object = objectCollection[virtualRow];
                
                id startTimeValue = object[@"starttime"];
                NSTimeInterval startTime = 0;
                if (startTimeValue)
                    startTime = [startTimeValue doubleValue];
                id fileURLValue = object[@"fileURL"];
                NSString *fileName = @"";
                if (fileURLValue)
                    fileName = [[(NSURL*)fileURLValue path] lastPathComponent];

                
                NSString *titleText;
                NSString *detailText;

                id userTitleValue = object[@"usertitle"];
                id titleValue = object[@"title"];
                
                if (userTitleValue) {
                    titleText = userTitleValue;
                } else {
                    if (titleValue) {
                        titleText = titleValue;
                    } else {
                        titleText = @"no title";
                    }
                }
                id titleTypeValue = object[@"titletype"];
                if (titleTypeValue)
                    detailText = titleTypeValue;
                
                
                cell.textLabel.text = titleText;
                cell.detailTextLabel.text = detailText;
                
                
                
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
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSMutableArray *objectCollection = _objectCollections[indexPath.section];
        
        [objectCollection removeObjectAtIndex:indexPath.row];
        
        if ([objectCollection count] == 0) {
            [_objectCollections removeObjectAtIndex:indexPath.section];
            [tableView beginUpdates];
            [tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationAutomatic];
            [tableView endUpdates];
        } else {
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
        
        [self saveUserOrderedList];
        
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    // Return NO if you do not want the specified item to be editable.
//    return @"tracks section";

    NSString *result;
    
    if (section < [_homeControllerSections count]) {
        NSUInteger count = 0;
        id trackObjects = _homeControllerSections[section][@"trackobjectset"];
        if (trackObjects) {
            count = [trackObjects count];
        }
        
        JWHomeSectionType sectionType = [self typeForSection:section];

        if (sectionType == JWHomeSectionTypeAudioFiles) {
            if (count>0) {
                count --;
            }
        } else if (sectionType == JWHomeSectionTypeYoutube) {
            if (count>1) {  // min rows
                count --;
            }
        }

        id titleValue = _homeControllerSections[section][@"title"];
        if (titleValue) {
            if (section == [self indexOfSectionOfType:JWHomeSectionTypeOther]) {
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
    
    id moveObject = [_objectCollections[fromIndexPath.section] objectAtIndex:fromIndexPath.row];
    
    [_objectCollections[fromIndexPath.section]  removeObjectAtIndex:fromIndexPath.row];
    [_objectCollections[toIndexPath.section]  insertObject:moveObject atIndex:toIndexPath.row];
    
    if ([_objectCollections[fromIndexPath.section] count] == 0) {
        [_objectCollections removeObjectAtIndex:fromIndexPath.section];
        
        //NSUInteger reloadSection = toIndexPath.section;
        //        if (fromIndexPath.section < toIndexPath.section) {
        //            reloadSection--;
        //        }
        [tableView beginUpdates];
        [tableView deleteSections:[NSIndexSet indexSetWithIndex:fromIndexPath.section] withRowAnimation:UITableViewRowAnimationAutomatic];
        //        [tableView reloadSections:[NSIndexSet indexSetWithIndex:reloadSection]  withRowAnimation:UITableViewRowAnimationAutomatic];
        [tableView endUpdates];
    }
    
    [tableView reloadSectionIndexTitles];
    
    [self saveUserOrderedList];
}

// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}

-(NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
    
    NSLog(@"%s",__func__);
    // Allow the proposed destination.
    return proposedDestinationIndexPath;
}

#pragma mark -

-(NSString*)documentsDirectoryPath {
    NSString *result = nil;
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    result = [searchPaths objectAtIndex:0];
//    NSLog(@"%s %@",__func__, result);
    return result;
}

-(NSURL *)fileURLWithFileName:(NSString*)name {
    NSURL *result;
    NSString *thisfName = name;//@"mp3file";
    NSString *thisName = thisfName; //[NSString stringWithFormat:@"%@_%@.mp3",thisfName,dbkey?dbkey:@""];
    NSMutableString *fname = [[self documentsDirectoryPath] mutableCopy];
    [fname appendFormat:@"/%@",thisName];
    result = [NSURL fileURLWithPath:fname];
    return result;
}

/*
 serializeOut
 Convert any dictionary items that cannot be serialized to serializable format if possible
 fileURL NSURL to Path
 UIColor to rgb alpha
 */
-(void)serializeOut {
    
    for (id objectCollection in _objectCollections) {
        for (id obj in objectCollection) {
            id furl = obj[@"fileURL"];
            if (furl) {
                obj[@"fileName"] = [[(NSURL*)furl path] lastPathComponent];
                [obj removeObjectForKey:@"fileURL"];
            }
        }
    }
}

-(void)saveUserOrderedList {
    [self serializeOut];
    [_objectCollections writeToURL:[self fileURLWithFileName:@"savedobjects"] atomically:YES];
    [self serializeIn];
    
    NSLog(@"%s savedobjects[%ld]",__func__,[_objectCollections count]);
    //    NSLog(@"%savedobjects \n%@",__func__,[_objects description]);
    
}

/*
 serializeIn
 Convert any dictionary items that could not be serialized and were converted to a serializable format
 Path to fileURL NSURL
 rgb-alpha to UIColor
 */

-(void)serializeIn {
    
    for (id objectCollection in _objectCollections) {
        for (id obj in objectCollection) {
            id fname = obj[@"fileName"];
            if (fname) {
                obj[@"fileURL"] = [self fileURLWithFileName:fname];
                [obj removeObjectForKey:@"fileName"];
            }
        }
    }
}

-(void)readUserOrderedList {
    
    _objectCollections = [[NSMutableArray alloc] initWithContentsOfURL:[self fileURLWithFileName:@"savedobjects"]];
    
    [self serializeIn];
    
    NSLog(@"%savedobjects[%ld]",__func__,[_objectCollections count]);
    //    NSLog(@"%savedobjects \n%@",__func__,[_objects description]);
}



#pragma mark -

-(void)serializeOutTrackSet {
    
    for (id objectCollection in _objectCollections) {
        for (id obj in objectCollection) {
            id furl = obj[@"fileURL"];
            if (furl) {
                obj[@"fileName"] = [[(NSURL*)furl path] lastPathComponent];
                [obj removeObjectForKey:@"fileURL"];
            }
        }
    }
}


-(void)serializeInTrackSet {
    
    for (id objectCollection in _objectCollections) {
        for (id obj in objectCollection) {
            id fname = obj[@"fileName"];
            if (fname) {
                obj[@"fileURL"] = [self fileURLWithFileName:fname];
                [obj removeObjectForKey:@"fileName"];
            }
        }
    }
}

-(void)saveHomeMenuLists {
    [_homeControllerSections writeToURL:[self fileURLWithFileName:@"homeObjects"] atomically:YES];

    NSLog(@"%s homeObjects[%ld]",__func__,[_homeControllerSections count]);
}

-(void)readHomeMenuLists {
    _homeControllerSections = [[NSMutableArray alloc] initWithContentsOfURL:[self fileURLWithFileName:@"homeObjects"]];
    
    NSLog(@"%s homeObjects[%ld]",__func__,[_homeControllerSections count]);
}



@end






//    cell.textLabel.text = [NSString stringWithFormat:@"%@ %@ start:%00.2f",
//                           object[@"title"],
//                           [object[@"key"] substringToIndex:6],
//                           startTime];
//    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ hasRef %@",fileName,object[@"referencefile"]?@"YES":@"NO"];


//            cell.textLabel.text = [NSString stringWithFormat:@"%@%@",
//                                   [object[@"key"] substringToIndex:5],
//                                   [fileName length] > 0 ? [NSString stringWithFormat:@"  %@",fileName ] : fileName
//                                   ];
//
//            cell.detailTextLabel.text = [NSString stringWithFormat:@"startTime %00.2f hasRef %@",startTime,object[@"referencefile"]?@"YES":@"NO"];


//UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
//NSMutableArray *objectCollection = _objectCollections[indexPath.section];
//NSDictionary *object = objectCollection[indexPath.row];
//id startTimeValue = object[@"starttime"];
//NSTimeInterval startTime = 0;
//if (startTimeValue)
//startTime = [startTimeValue doubleValue];
//id fileURLValue = object[@"fileURL"];
//NSString *fileName = @"";
//if (fileURLValue){
//    fileName = [[(NSURL*)fileURLValue path] lastPathComponent];
//cell.textLabel.text = [NSString stringWithFormat:@"%@%@",
//                       [object[@"key"] substringToIndex:5],
//                       [fileName length] > 0 ? [NSString stringWithFormat:@"  %@",fileName ] : fileName
//                       ];
//cell.detailTextLabel.text = [NSString stringWithFormat:@"startTime %00.2f hasRef %@",startTime,object[@"referencefile"]?@"YES":@"NO"];
//    NSDictionary *object = self.objects[indexPath.row];
//    NSDate *object = self.objects[indexPath.row];
//    cell.textLabel.text = [object description];

