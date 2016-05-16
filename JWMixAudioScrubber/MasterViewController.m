//
//  MasterViewController.m
//  JWAudio
//
//  co-created by joe and brendan kerr on 11/27/15.
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
#import "UIColor+JW.h"
//#import "JWAWSIdentityManager.h"

@interface MasterViewController () <JWDetailDelegate,
JWTrackSetsProtocol,JWYTSearchTypingDelegate,JWSourceAudioListsDelegate,UITextFieldDelegate>
{
    BOOL _isAddingNewObject;
    BOOL _isAutoSelecting;
    BOOL _insertsSingleRecorderNode;
}
@property NSIndexPath *selectedIndexPath;
@property NSMutableArray *objectCollections;  // collects objects
@property NSMutableArray *homeControllerSections;  // collects objects
@property NSIndexPath *selectedDetailIndexPath;
@property NSString *nameChangeString;
@property NSString *lastSearchTerm;
@property UIImage *scrubberWhiteImage;
@property UIImage *scrubberBlueImage;
@property UIImage *scrubberGreenImage;
@end

//#define JWSampleFileNameAndExtension @"trimmedMP3.m4a"
//#define JWSampleFileNameAndExtension @"trimmedMP3-45.m4a"
//#define JWSampleFileNameAndExtension @"AminorBackingtrackTrimmedMP3-45.m4a"
#define JWSampleFileNameAndExtension @"TheKillersTrimmedMP3-30.m4a"

@implementation MasterViewController

- (void)viewDidLoad {
    [super viewDidLoad];

   // JWAWSIdentityManager *manager = [JWAWSIdentityManager sharedInstance];
    //[manager logOut];
//    _scrubberWhiteImage = [UIImage imageNamed:@"scrub50"];

    _scrubberBlueImage = [UIImage imageNamed:@"scrubberIconBlue"];
    _scrubberWhiteImage = [UIImage imageNamed:@"scrubberIconWhite"];
    _scrubberGreenImage = [UIImage imageNamed:@"scrubberIconGreen"];

    UIView *backgroundView = [UIView new];
    backgroundView.backgroundColor = [UIColor blackColor];
    self.tableView.backgroundView = backgroundView;
    
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
    _insertsSingleRecorderNode = YES;
    [self.tableView reloadData];

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
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - TABLE VIEW INDEX PATH

// indexPath for tableView
#define REDESIGN
#ifdef REDESIGN
-(id)jamTrackObjectAtIndexPath:(NSIndexPath*)indexPath {
    
    id result = nil;
    if (indexPath.section < [_homeControllerSections count]) {
        
        BOOL isTrackItem = YES;;
        NSUInteger virtualRow = indexPath.row;
        NSUInteger count = [self baseRowsForSection:indexPath.section];
        if (indexPath.row < count) {
            isTrackItem = NO; // baserow
        } else {
            virtualRow -= count;
        }
        
        if (isTrackItem) {
            // IS  ATRACK CELL not a controll cell index 0 AUDIOFILES and SEARCH

            id objectSection = _homeControllerSections[indexPath.section];
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


-(NSUInteger)countEmptyRecorderNodesForJamTrackWithKey:(NSString*)key {
    
    NSUInteger result = 0;
    NSDictionary *object = [self jamTrackObjectAtIndexPath:_selectedDetailIndexPath];
    
    id trackNodes = object[@"trackobjectset"];
    for (id trackNode in trackNodes) {
        
        id typeValue = trackNode[@"type"];
        if (typeValue) {
            JWMixerNodeTypes nodeType = [typeValue unsignedIntegerValue];
            if (nodeType == JWMixerNodeTypePlayerRecorder) {
                id fileURL = trackNode[@"fileURL"];
                if (fileURL == nil)
                    result++;
            }
        }
    }
    
    return result;
}


-(NSMutableDictionary*)newTrackObjectOfType:(JWMixerNodeTypes)mixNodeType {
    
    NSMutableDictionary *result = nil;
    if (mixNodeType == JWMixerNodeTypePlayer) {
        return [self newTrackObjectOfType:mixNodeType andFileURL:[self fileURLWithFileName:JWSampleFileNameAndExtension inPath:nil] withAudioFileKey:nil];
        
    } else if (mixNodeType == JWMixerNodeTypePlayerRecorder) {
        return [self newTrackObjectOfType:mixNodeType andFileURL:nil withAudioFileKey:nil];
    }
    return result;
}

//TODO: added with audio file key so i can identify the five second audio file
//coresponding to the trimmed audio file

-(NSMutableDictionary*)newTrackObjectOfType:(JWMixerNodeTypes)mixNodeType andFileURL:(NSURL*)fileURL withAudioFileKey:(NSString *)key {
    
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
    
    if (key)
        result[@"audiofilekey"] = key;
    
    
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

//TODO: added audio file key becuase the key generated here is for (i think) identifying the
//jam track object
-(NSMutableDictionary*)newJamTrackObjectWithFileURL:(NSURL*)fileURL audioFileKey:(NSString *)key {
    NSMutableDictionary *result = nil;
    
    
    id track1 = [self newTrackObjectOfType:JWMixerNodeTypePlayer andFileURL:fileURL withAudioFileKey:key];
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

-(NSMutableDictionary*)newJamTrackObjectWithRecorderFileURL:(NSURL*)fileURL {
    NSMutableDictionary *result = nil;
    
    id track = [self newTrackObjectOfType:JWMixerNodeTypePlayerRecorder andFileURL:nil withAudioFileKey:nil];
    
    NSMutableArray *trackObjects = [@[track] mutableCopy];
    
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

-(NSMutableArray*)newDownloadedJamTracks {
    
    NSMutableArray *result = [NSMutableArray new];
    for (id fileInfo in [[JWFileController sharedInstance] downloadedJamTrackFiles]) {
        NSLog(@"%s %@",__func__,[fileInfo[@"furl"] lastPathComponent]);
        
        NSURL *fileURL = [self fileURLWithFileFlatFileURL:fileInfo[@"furl"]];
        
        //TODO: not sure if the key parameter is needed here
        [result addObject:[self newJamTrackObjectWithFileURL:fileURL audioFileKey:nil]];
    }
    
    return result;
}



-(NSMutableArray*)newHomeMenuLists {
    NSMutableArray *result =
    [@[
       [@{
          
          //will be used for settings and files user sets
          @"title":@"Settings And Files",
          @"type":@(JWHomeSectionTypeOther),
          } mutableCopy],
       
       //Will be supplied by an s3 bucket, Not used
       //       [@{
       //          @"title":@"Provided JamTracks",
       //          @"type":@(JWHomeSectionTypePreloaded),
       //          @"trackobjectset":[self newProvidedJamTracks],
       //          } mutableCopy],
       [@{
          
          //Will be used when user downloads somone elses jam track
          @"title":@"Downloaded JamTracks",
          @"type":@(JWHomeSectionTypeDownloaded),
          @"trackobjectset":[self newDownloadedJamTracks],
          } mutableCopy],
       
       //source audio will be determined by the tab the user is currently in
       //       [@{
       //          @"title":@"Source Audio",
       //          @"type":@(JWHomeSectionTypeYoutube)
       //          } mutableCopy],
       [@{
          
          //Will be used to give user their saved/unfinished jam sessions
          @"title":@"Jam Sessions",
          @"type":@(JWHomeSectionTypeAudioFiles),
          @"trackobjectset":[self newJamTracks],
          } mutableCopy],
       
       //Will not be used, the user will be prompted to sign in when they need to
       //       [@{
       //
       //          @"title":@"User",
       //          @"type":@(JWHomeSectionTypeUser)
       //          } mutableCopy],
       ] mutableCopy
     ];
    
    return result;
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


-(NSString*)preferredTitleForObject:(id)object {
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



#endif

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
    [self detailOptions];
}


-(void)detailOptions {
    
    NSString *title;
    NSMutableString *message = [NSMutableString new];
    NSMutableDictionary *object = [self jamTrackObjectAtIndexPath:_selectedDetailIndexPath];
    if (object)
        title = [self preferredTitleForObject:object];

    NSString * jamTrackKey = object[@"key"];
    NSUInteger countEmpties = [self countEmptyRecorderNodesForJamTrackWithKey:jamTrackKey];
    if ([jamTrackKey length] > 10)
        jamTrackKey = [jamTrackKey substringToIndex:10];
    [message appendString:jamTrackKey];
    if (countEmpties > 0) {
        [message appendString:@"\n\n"];
        if (countEmpties > 1)
            [message appendString:[NSString stringWithFormat:@"has %ld empty recorder nodes",countEmpties]];
        else
            [message appendString:[NSString stringWithFormat:@"has %ld empty recorder node",countEmpties]];
    }

    UIAlertController* actionController =
    [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction* cancelAction =
    [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction* action) {
    }];
    UIAlertAction* changeName =
    [UIAlertAction actionWithTitle:@"Modify Title" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
        [self namePrompt];
    }];
    UIAlertAction* moreInfo =
    [UIAlertAction actionWithTitle:@"More Information" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
        [self moreInfo];
    }];

    UIAlertAction* addNode =
    [UIAlertAction actionWithTitle:@"Add Recorder Node" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
        id jamTrackKey = object[@"key"];
        
        [self addTrackNode:nil toJamTrackWithKey:jamTrackKey];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView beginUpdates];
            [self.tableView reloadRowsAtIndexPaths:@[_selectedDetailIndexPath]
                                  withRowAnimation:UITableViewRowAnimationNone];
            [self.tableView endUpdates];
        });

    }];
    
    UIAlertAction* removeEmpty;
    if (countEmpties > 0) {
        removeEmpty =
        [UIAlertAction actionWithTitle:@"Remove Empty Recorder Nodes" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
            
            id trackNodes = object[@"trackobjectset"];
            if (trackNodes) {
                
                // Find the indexes to delete
                
                NSMutableIndexSet *deleteIndexes = [NSMutableIndexSet new];
                NSUInteger index = 0;
                for (id trackNode in trackNodes) {
                    id typeValue = trackNode[@"type"];
                    if (typeValue) {
                        JWMixerNodeTypes nodeType = [typeValue unsignedIntegerValue];
                        if (nodeType == JWMixerNodeTypePlayerRecorder) {
                            id fileURL = trackNode[@"fileURL"];
                            if (fileURL == nil)
                                [deleteIndexes addIndex:index];
                        }
                    }
                    index++;
                }
                
                // Delete the found indexes
                
                if ([deleteIndexes count] > 0){
                    
                    __block NSUInteger deleteCount = 0;
                    [deleteIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
                        [trackNodes removeObjectAtIndex:idx - deleteCount];
                        deleteCount++;
                    }];

                    [self saveHomeMenuLists];

                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.tableView beginUpdates];
                        [self.tableView reloadRowsAtIndexPaths:@[_selectedDetailIndexPath]
                                              withRowAnimation:UITableViewRowAnimationNone];
                        [self.tableView endUpdates];
                    });
                    
                    
                    
                }
            }
        }];
    }
    
//    UIAlertAction* deleteTrack =
//    [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction* action) {
//    }];

    [actionController addAction:changeName];
    [actionController addAction:addNode];
    if (removeEmpty)
        [actionController addAction:removeEmpty];
    [actionController addAction:moreInfo];
//    [actionController addAction:deleteTrack];
    [actionController addAction:cancelAction];
    [self presentViewController:actionController animated:YES completion:nil];
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

-(void)moreInfo {
    
    NSString *title;
    NSMutableString *message = [NSMutableString new];
    
    NSMutableDictionary *object = [self jamTrackObjectAtIndexPath:_selectedDetailIndexPath];
    if (object)
        title = [self preferredTitleForObject:object];
    
    id jamTrackKey = object[@"key"];
    
    [message appendString:jamTrackKey];
    
    NSDate *createDate = object[@"date"];
    if (createDate) {
        [message appendString:@"\n\n"];
        NSDateFormatter *df = [NSDateFormatter new];
        //        double al = [[JWFileController sharedInstance] audioLengthForFileWithName:[furl lastPathComponent]];
        df.dateStyle = NSDateFormatterMediumStyle;
        df.timeStyle = NSDateFormatterLongStyle;
        [message appendString:[df stringFromDate:createDate]];
        
    }
    UIAlertController* actionController =
    [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* okAction =
    [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
        
    }];
    
    [actionController addAction:okAction];
    [self presentViewController:actionController animated:YES completion:nil];
}


#pragma mark - Insert

-(void)insertNewObject:(id)sender {
    
    [self insertActionDecision];
}

-(void)insertActionDecision {
    UIAlertController* actionController =
    [UIAlertController alertControllerWithTitle:@"ADD JamTrack" message:@"A JamTrack with" preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction* recorderAction =
    [UIAlertAction actionWithTitle:@"One Recorder" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
        [self addTrackNodeToNewJamTrack];
    }];

    UIAlertAction* trackAction =
    [UIAlertAction actionWithTitle:@"Base Track and Recorder" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
        _isAddingNewObject = YES;
        [self performSegueWithIdentifier:@"JWSourceAudioFiles" sender:self];
        // will be her fore a finsihedTrim
    }];

    UIAlertAction* cancelAction =
    [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction* action) {}];
    
    [actionController addAction:recorderAction];
    [actionController addAction:trackAction];
    [actionController addAction:cancelAction];
    [self presentViewController:actionController animated:YES completion:nil];
}


#pragma mark - track objects



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
        
        // SELECTION Requires OS9
        JWYTSearchTypingViewController *controller = (JWYTSearchTypingViewController*)segue.destinationViewController;
        controller.delegate = self;
        controller.searchTerm = _lastSearchTerm;
        
    } else if ([segue.identifier isEqualToString:@"JWSourceAudioFiles"]) {
        
        JWSourceAudioListsViewController *sourceAudioTableViewController = (JWSourceAudioListsViewController*)segue.destinationViewController;
        sourceAudioTableViewController.selectToClip = _isAddingNewObject;
        sourceAudioTableViewController.delegate = self;
    }
    
}

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


// indexpath of jamTrack object (data indexpath)

-(NSIndexPath*)indexPathOfJamTrackCacheItem:(NSString*)key {
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


// return tableview indexPath

-(NSIndexPath*)indexPathOfCacheItem:(NSString*)key {
    NSIndexPath *itemIndexPath = [self indexPathOfJamTrackCacheItem:key];
    NSUInteger index = itemIndexPath.row + [self baseRowsForSection:itemIndexPath.section];
    NSUInteger sectionIndex = itemIndexPath.section;
    
    NSLog(@"%s%@ index %ld section %ld",__func__,key,index,sectionIndex);
    return [NSIndexPath indexPathForRow:index inSection:sectionIndex];
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




#pragma mark - Youtube search delegate JWYTSearchTypingDelegate

-(void)searchTermChanged:(JWYTSearchTypingViewController *)controller {
    _lastSearchTerm = controller.searchTerm;
    NSUInteger section = [self indexOfSectionOfType:JWHomeSectionTypeYoutube];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:section]] withRowAnimation:UITableViewRowAnimationAutomatic];
}


// This is the active one
-(void)finishedTrim:(id)controller title:(NSString*)title withDBKey:(NSString*)key {
    
    NSLog(@"%s",__func__);
    
    NSString *fname = [NSString stringWithFormat:@"trimmedMP3_%@.m4a",key ? key : @""];
    NSURL *fileURL = [self fileURLWithFileName:fname inPath:nil];
    
    id jamTrack = [self newJamTrackObjectWithFileURL:fileURL audioFileKey:nil];
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
    NSLog(@"%s SHOULD NOT USE",__func__);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.navigationController popToRootViewControllerAnimated:YES];
    });
}


#pragma mark -

-(void)effectsChanged:(NSArray*)effects inNodeWithKey:(NSString*)nodeKey {

    NSLog(@"%s %@ %@",__func__,nodeKey,[effects description]);

    id nodeInJamTrack = [self jamTrackNodeObjectForKey:nodeKey];
    if (nodeInJamTrack) {
        
        NSLog(@"%s\nnodeInJamTrack %@ \n %@ %@",__func__,[nodeInJamTrack description],nodeKey,[effects description]);
        
        [(NSMutableDictionary*)nodeInJamTrack setObject:effects forKey:@"effects"];
        
        [self saveHomeMenuLists];
    }
}


-(void)userAudioObtainedInNodeWithKey:(NSString*)nodeKey recordingId:(NSString*)rid {
    
    id nodeInJamTrack = [self jamTrackNodeObjectForKey:nodeKey];
    
    nodeInJamTrack[@"fileURL"] = [self fileURLWithFileName:[NSString stringWithFormat:@"clipRecording_%@.caf",rid ? rid : @""]
                                                    inPath:nil];
    
    [self saveHomeMenuLists];
    
    NSLog(@"NEW RECORDING in track \n%@",[nodeInJamTrack description]);
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
    
    [self addTrackNode:controller toJamTrackWithKey:key];
}


// shared protocol method with detail and tracksets

// adds playerRecorder node

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
                
                NSUInteger nBaseRows = 1; // for JWHomeSectionTypeAudioFiles
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:nBaseRows+itemIndexPath.row inSection:itemIndexPath.section];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView beginUpdates];
                    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                    [self.tableView endUpdates];
                });
            }
        }
    }
    
    return result;
}

-(void)addTrackNodeToNewJamTrack {
    
    id jamTrack = [self newJamTrackObjectWithRecorderFileURL:nil];

    NSLog(@"%s",__func__);
    
    NSUInteger insertSection = [self indexOfSectionOfType:JWHomeSectionTypeAudioFiles];
    NSMutableArray *jamTracks = _homeControllerSections[insertSection][@"trackobjectset"];
    if (jamTracks) {
        
        [jamTracks insertObject:jamTrack atIndex:0];
        
        [self saveHomeMenuLists];
        
        NSUInteger nBaseRows = 1; // for JWHomeSectionTypeAudioFiles
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:nBaseRows inSection:insertSection];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView beginUpdates];
            [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic ];
            [self.tableView endUpdates];
            [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
            [self performSegueWithIdentifier:@"showDetail" sender:self];
        });
    }
}

-(BOOL)addTrackNodeToNewJamTrack:(NSURL*)fileURL {

    BOOL result = NO;

    id jamTrack = [self newJamTrackObjectWithFileURL:fileURL audioFileKey:nil];

//    id jamTrack = [self newJamTrackObjectWithFileURL:fileURL];
    
    NSLog(@"%s",__func__);
    
    NSUInteger insertSection = [self indexOfSectionOfType:JWHomeSectionTypeAudioFiles];
    NSMutableArray *jamTracks = _homeControllerSections[insertSection][@"trackobjectset"];
    if (jamTracks) {

        jamTrack[@"title"] = [[fileURL lastPathComponent] stringByDeletingPathExtension];
        [jamTracks insertObject:jamTrack atIndex:0];

        result = YES;

        [self saveHomeMenuLists];
    }
    
    return result;
}

-(void)performNewJamTrack:(NSURL*)fileURL {

    BOOL result = [self addTrackNodeToNewJamTrack:fileURL];
    
    if (result) {
        NSUInteger insertSection = [self indexOfSectionOfType:JWHomeSectionTypeAudioFiles];
        NSUInteger nBaseRows = 1; // for JWHomeSectionTypeAudioFiles
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:nBaseRows inSection:insertSection];
        
        BOOL needsPop = ([[self.navigationController viewControllers] count] > 1);
        
        if (needsPop) {
            [self.navigationController popToRootViewControllerAnimated:NO];
            [self.tableView reloadData];
            [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
            [self performSegueWithIdentifier:@"showDetail" sender:self];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView beginUpdates];
                [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic ];
                [self.tableView endUpdates];
                [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
                [self performSegueWithIdentifier:@"showDetail" sender:self];
            });
        }
    }
    
}


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
    NSIndexPath *indexPath = [self indexPathOfCacheItem:key];
    [self reloadItemAtIndex:indexPath.row inSection:indexPath.section];
    
    id jamTrack = [self jamTrackObjectWithKey:key];
    if (jamTrack) {
        NSLog(@"%s%@ %@",__func__,key,[jamTrack description]);
    }
//    [self saveUserOrderedList];
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
        } else if (sectionType == JWHomeSectionTypeUser) {
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
        return 24;
    typeSection =[self indexOfSectionOfType:JWHomeSectionTypeDownloaded];
    if (typeSection != NSNotFound && section == typeSection)
        return 24;
    typeSection =[self indexOfSectionOfType:JWHomeSectionTypeYoutube];
    if (typeSection != NSNotFound && section == typeSection)
        return 24;
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

    return 5;
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
                section == [self indexOfSectionOfType:JWHomeSectionTypeYoutube] ||
                section == [self indexOfSectionOfType:JWHomeSectionTypeUser]
                ) {
                result = titleValue;
            } else {
                result = [NSString stringWithFormat:@"%@ %@",titleValue,[NSString stringWithFormat:@"%lu items",(unsigned long)count]];
            }
        }
    }
    
    return result;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section  {
    UITableViewHeaderFooterView *view = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"JWHeaderViewX"];
    if (view == nil)
        view = [[UITableViewHeaderFooterView alloc] initWithReuseIdentifier:@"JWHeaderViewX"];
    view.contentView.backgroundColor = [UIColor jwBlackThemeColor];
    view.textLabel.textColor = [UIColor jwSectionTextColor];
    return view;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    CGFloat result = 60;
    NSUInteger count = [self baseRowsForSection:indexPath.section];
    if (indexPath.row < count)
        result = 52;
    else
        result = 78;
    return result;
}


-(NSUInteger)baseRowsForSection:(NSUInteger)section {
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
        } else if (sectionType == JWHomeSectionTypeUser) {
            count ++;
        }
    }
    return count;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(nonnull UITableViewCell *)cell forRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    
    NSUInteger count = [self baseRowsForSection:indexPath.section];

    UIView *backgroundView = [UIView new];
    UIView *sbackgroundView = [UIView new];
    if (indexPath.row < count) {
        backgroundView.backgroundColor = [UIColor lightGrayColor];
        sbackgroundView.backgroundColor = [UIColor iosMercuryColor];
    } else {
        backgroundView.backgroundColor = [UIColor blackColor];
        sbackgroundView.backgroundColor = [UIColor iosSteelColor];
    }
    cell.backgroundView = backgroundView;
    cell.selectedBackgroundView= sbackgroundView;
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
        } else if (sectionType == JWHomeSectionTypeUser) {
            UITableViewCell *userCell =
            [tableView dequeueReusableCellWithIdentifier:@"JWUserAuthentication" forIndexPath:indexPath];
            cell = userCell;
            isTrackItem = NO;
        }
        
        if (isTrackItem) {
            // IS  ATRACK CELL not a controll cell index 0 AUDIOFILES and SEARCH
            id trackObjects = objectSection[@"trackobjectset"];
            if (trackObjects) {
                
                NSString *titleText;
                NSString *detailText;
                NSArray *objectCollection = trackObjects;
                NSDictionary *jamTrack = objectCollection[virtualRow];
                
                titleText = [self preferredTitleForObject:jamTrack];
                
                if ([titleText length] == 0)
                    titleText = @"no title";
                
                id titleTypeValue = jamTrack[@"titletype"];
                if (titleTypeValue)
                    detailText = titleTypeValue;
                
                NSString *durationString;
                UIColor *durationColor = [UIColor blackColor];
                
                BOOL hasEmptyRecorderNode = NO;
                
                id trackNodes = jamTrack[@"trackobjectset"];
                if (trackNodes) {
                    double audioLength = 0;
                    
                    for (id trackNode in trackNodes) {
                        NSURL *fileURL = trackNode[@"fileURL"];
                        id typeValue = trackNode[@"type"];
                        if (typeValue) {
                            JWMixerNodeTypes ptype = [typeValue unsignedIntegerValue];
                            if (ptype == JWMixerNodeTypePlayerRecorder)
                                hasEmptyRecorderNode = (fileURL == nil);
                        }
                        
                        if (fileURL) {
                            double len = [[JWFileController sharedInstance] audioLengthForFileWithName:[fileURL lastPathComponent]];
                            if (len > audioLength)
                                audioLength = len;
                        }
                    }
//                    durationString = [NSString stringWithFormat:@" %.0f sec ",audioLength];
//                    durationString = [NSString stringWithFormat:@"0:%00.0f ",audioLength];
                    durationString = [NSString stringWithFormat:@"0:%02ld ",(NSUInteger)audioLength];
                    durationColor = [UIColor orangeColor];
                    detailText = [detailText stringByAppendingFormat:@" %ld nodes",[trackNodes count]];
                }
                
//                NSString *textLabelText =[NSString stringWithFormat:@"%@%@",durationString,titleText];
                NSString *textLabelText =[NSString stringWithFormat:@"%@%@",durationString,detailText];
                
                NSDictionary *attrs = @{ NSForegroundColorAttributeName : [UIColor whiteColor] };
                
                NSMutableAttributedString *textLabelAttributedText =
                [[NSMutableAttributedString alloc] initWithString:textLabelText attributes:attrs];
                
                [textLabelAttributedText addAttribute:NSForegroundColorAttributeName value:durationColor
                                                range:NSMakeRange(0,durationString.length)];

                [textLabelAttributedText addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:16]
                                                range:NSMakeRange(0,durationString.length)];

//                cell.textLabel.attributedText = textLabelAttributedText;
                
                cell.textLabel.text = titleText;

                cell.detailTextLabel.attributedText = textLabelAttributedText;

//                cell.detailTextLabel.text = detailText;

                if (sectionType == JWHomeSectionTypeAudioFiles) {
                    if (hasEmptyRecorderNode) {
                        cell.imageView.image = _scrubberBlueImage;
                    } else {
                        if ([trackNodes count] > 1)
                            cell.imageView.image = _scrubberGreenImage;
                        else
                            cell.imageView.image = _scrubberWhiteImage;
                    }
                }
                else  {
                    cell.imageView.image = _scrubberWhiteImage;
                }

            }
        }
    }
    
    return cell;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    
    BOOL result = NO;
    NSUInteger count = [self baseRowsForSection:indexPath.section];
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
            BOOL isTrackItem = YES;;
            NSUInteger virtualRow = indexPath.row;
            NSUInteger count = [self baseRowsForSection:indexPath.section];
            if (indexPath.row < count) {
                isTrackItem = NO; // baserow
            } else {
                virtualRow -= count;
            }

            if (isTrackItem) {
                // IS  ATRACK CELL not a controll cell index 0 AUDIOFILES and SEARCH
                id trackObjects = objectSection[@"trackobjectset"];
                if (trackObjects && virtualRow < [trackObjects count]) {
                    [trackObjects removeObjectAtIndex:virtualRow];
                    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
                }
            }
        }

        [self saveHomeMenuLists];
        
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        
        [self saveHomeMenuLists];

    }
}


// Override to support rearranging the table view.

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    
    NSLog(@"%s",__func__);
    
    
    id moveObject ;
    NSUInteger fromIndex = 0;
    
    NSIndexPath *indexPath = fromIndexPath;
    
    if (indexPath.section < [_homeControllerSections count]) {
        
        id objectSection = _homeControllerSections[indexPath.section];
        
        BOOL isTrackItem = YES;;
        NSUInteger virtualRow = indexPath.row;
        NSUInteger count = [self baseRowsForSection:indexPath.section];
        if (indexPath.row < count)
            isTrackItem = NO;  // baserow
        else
            virtualRow -= count;
        
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
            
            
            BOOL isTrackItem = YES;;
            NSUInteger virtualRow = indexPath.row;
            NSUInteger count = [self baseRowsForSection:indexPath.section];
            if (indexPath.row < count)
                isTrackItem = NO;  // baserow
            else
                virtualRow -= count;


            if (isTrackItem) {
                // IS  ATRACK CELL not a controll cell index 0 AUDIOFILES and SEARCH

                id objectSection = _homeControllerSections[indexPath.section];

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
        jamTrackNode[@"fileRelativePath"] = [(NSURL*)furl relativePath];
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
    NSLog(@"%s HOMEOBJECTS [%ld]",__func__,(unsigned long)[_homeControllerSections count]);
}

-(void)readHomeMenuLists {
    _homeControllerSections = [[NSMutableArray alloc] initWithContentsOfURL:[self fileURLWithFileName:@"homeObjects"]];
    NSLog(@"home Controller URL: %@", [self fileURLWithFileName:@"homeObjects"]);
    [self serializeInJamTracks];
//    NSLog(@"%s homeObjects %@",__func__,[_homeControllerSections description]);
    NSLog(@"%s HOMEOBJECTS [%ld]",__func__,(unsigned long)[_homeControllerSections count]);
    
    
    // Delete unwanted sections
    NSInteger section = [self indexOfSectionOfType:JWHomeSectionTypeDownloaded];
    if (section != NSNotFound) {
        [_homeControllerSections removeObjectAtIndex:section];
    }
    section = [self indexOfSectionOfType:JWHomeSectionTypePreloaded];
    if (section != NSNotFound) {
        [_homeControllerSections removeObjectAtIndex:section];
    }
}

@end


