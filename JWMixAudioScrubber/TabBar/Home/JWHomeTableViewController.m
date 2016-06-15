//
//  JWHomeTableViewController.m
//  JamWDev
//
//  Created by brendan kerr on 4/17/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//


/*
 
 Home controller purpose - Home controller serves as an area for the user to see:
    *Sessions started.
    *Following artists uploaded tracks
    *
 
 Home controller data -
    -Mutable array of dictionaries (1 - jam session, 2 - downloaded tracks)
        -1 
            -@"sessionset" : has array of sessions
                -[index] = dictionary with a title, track object set (array of tracks), duration, number of tracks, genre, instrument, key, title-author
                    -@"trackobjectset": each track (node) has info, fileURL, date created, key, type
 
        -2 (same as above right now, will change)
 
 
 */
#import "JWHomeTableViewController.h"
#import "JWHTVJamSessionTableViewCell.h"
#import "DetailViewController.h"
#import "JWClipAudioViewController.h"
#import "JWAWSIdentityManager.h"
#import "JWFileManager.h"
#import "JWCurrentWorkItem.h"
#import "JWJamSessionCoordinator.h"
#import "JWMixNodes.h"

@interface JWHomeTableViewController() <JWDetailDelegate>


@property (nonatomic) NSIndexPath *selectedDetailIndexPath;
@property (nonatomic) JWJamSessionCoordinator *coordinator;

@end

@implementation JWHomeTableViewController


-(void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"%s", __func__);
    
    
    _coordinator = [JWJamSessionCoordinator new];
    
    
    UIView *backgroundView = [UIView new];
    backgroundView.backgroundColor = [UIColor blackColor];
    self.tableView.backgroundView = backgroundView;
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
//    [[self.navigationController toolbar] setBarStyle:UIBarStyleBlack];
//    [self.navigationController setToolbarHidden:YES];
//    //[[self.navigationController navigationBar]
//    // setBackgroundImage:[UIImage new] forBarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
//    [[self.navigationController navigationBar] setShadowImage:[UIImage new]];
//    [[self.navigationController navigationBar] setBackgroundColor:[UIColor blackColor]];
//    
}



-(void)viewWillAppear:(BOOL)animated {
    NSLog(@"%s", __func__);
    [super viewWillAppear:animated];
    
    self.homeControllerData = [[JWFileManager defaultManager] homeItemsList];
    [self.tableView reloadData];
    
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
}



#pragma mark - TABLE VIEW DELEGATE


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [(NSArray *)self.homeControllerData[section][@"sessionset"] count];
    
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return [self.homeControllerData count];
}



//- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section  {
//    
//    UITableViewHeaderFooterView *view = [UITableViewHeaderFooterView new];
//    view.contentView.backgroundColor = [UIColor blackColor];
//    //[view.textLabel setTextColor:[UIColor yellowColor]];
//    //[view.detailTextLabel setTextColor:[UIColor yellowColor]];
//    return view;
//    
//}


-(void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    
    [header.textLabel setTextColor:[UIColor whiteColor]];
    [header.contentView setBackgroundColor:[UIColor blackColor]];
    
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    
    return 30.0;
    
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {

    return self.homeControllerData[section][@"title"];

}



-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    JWHTVJamSessionTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SessionCell"];
    
    cell = [self configureCell:cell forIndexPath:indexPath];
    
    return cell;
}


-(JWHTVJamSessionTableViewCell *)configureCell:(JWHTVJamSessionTableViewCell *)cell forIndexPath:(NSIndexPath *)path {
    
    JWHTVJamSessionTableViewCell *result = nil;
    NSDictionary *sectionData = self.homeControllerData[path.section];
    NSArray *sessionSet = sectionData[@"sessionset"];
    NSDictionary *sessionAt = sessionSet[path.row];
    
    //Has to have title, duration, and track count to be a valid cell
    [cell.titleAuthor setText:[self createStringWithTitle:sessionAt[@"title"] author:[[JWAWSIdentityManager sharedInstance] profileName]]];
    
    NSString *duration = [_coordinator durationOfFirstTrackFromSession:sessionAt];
    [cell.duration setText:duration];
    
    
    //[cell.trackCount setText:[NSString stringWithFormat:@"%@", sessionAt[@"trackcount"]]];
    NSArray *tracks = sessionAt[@"trackobjectset"];
    [cell.trackCount setText:[NSString stringWithFormat:@"%@", [self trackStringFromCount:[tracks count]]]];
    
    //[cell.buttonImage setImage:_scrubberBlueImage forState:UIControlStateNormal];
    [cell setAudioURLsForThisCell:[_coordinator audioURLsForSession:sessionAt]];
    
    //These shouldnt nessesarily be available at cell creation.  If the user is making a blank track for the first time, they will be emptry strings.  I want the user to fill this info out while we record their track from a tap to occupy them.  If a user downloads a track from S3, this info should be present.
    //***arent displayed in cell currently****
//    [cell.genre setText:(sessionAt[@"genre"] == nil) ? @"" : sessionAt[@"genre"]];
//    [cell.tonalKey setText:(sessionAt[@"tonalkey"] == nil) ? @"" : sessionAt[@"tonalkey"]];
//    [cell.instrument setText:(sessionAt[@"instrument"] == nil) ? @"" : sessionAt[@"instrument"]];
    
    
    result = cell;
    
    return result;
}


-(NSString *)createStringWithTitle:(NSString *)title author:(NSString *)author  {
    
    NSAssert(title != nil, @"need title");
    
    if (author) {
        NSLog(@"title string = %@", [NSString stringWithFormat:@"%@-%@", title, author]);
        return [NSString stringWithFormat:@"%@-%@", title, author];
    } else {
        return [NSString stringWithFormat:@"%@", title];
    }
}

-(NSString *)trackStringFromCount:(NSInteger)count {

    if (count > 1) {
        return [NSString stringWithFormat:@"Tracks: %ld", (long)count];
    } else {
        return [NSString stringWithFormat:@"Track: %ld", (long)count];
    }
}


- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    self.selectedDetailIndexPath = indexPath;
    [self detailOptions];
}




-(void)reloadItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section {
    
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:section]]
                          withRowAnimation:UITableViewRowAnimationFade];
    
    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:section] animated:YES scrollPosition:UITableViewScrollPositionNone];
}

-(NSIndexPath*)indexPathOfJamTrackCacheItem:(NSString*)key {
    NSUInteger sectionIndex = 0;
    NSUInteger index = 0;
    BOOL found = NO;
    
    for (id objectSection in _homeControllerData) {
        id sessionSetInSection = objectSection[@"sessionset"];
        index = 0; // new section
        for (id session in sessionSetInSection) {
            
            if ([key isEqualToString:session[@"key"]]) {
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
    NSUInteger sectionIndex = itemIndexPath.section;
    
    NSLog(@"%s index %@ section %ld",__func__,key,sectionIndex);
    return [NSIndexPath indexPathForRow:itemIndexPath.row inSection:sectionIndex];
}



- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    //all rows in table should not be editable and are sorted by date (for now)...
    //all rows should be editable tho
    return YES;
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        NSLog(@"%s",__func__);
        
        if (indexPath.section < [_homeControllerData count]) {
            
            id objectSection = _homeControllerData[indexPath.section];
            id objectSet = objectSection[@"sessionset"];
            
            if (objectSet) {
                // IS  ATRACK CELL not a controll cell index 0 AUDIOFILES and SEARCH
                
                [objectSet removeObjectAtIndex:indexPath.row];
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
                
            }
        }
        
        [[JWFileManager defaultManager] updateHomeObjectsAndSave:_homeControllerData];
        
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        
        [[JWFileManager defaultManager] saveHomeMenuLists];
        
    }
}




#pragma mark - SEGUE

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    //will be navigating to detail when a cell is selected
    if ([[segue identifier] isEqualToString:@"sessionSelected"]) {
        
        DetailViewController *controller = (DetailViewController *)[(UINavigationController *)[segue destinationViewController] topViewController];

        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        _selectedDetailIndexPath = indexPath;
        
        controller.delegate = self;
        [controller setDetailItem:[self objectSelected]];
        
    }

    //Will be clipping
    else if ([segue.identifier isEqualToString:@"JWClipAudio"]) {
        
        JWClipAudioViewController *clipController = (JWClipAudioViewController*)segue.destinationViewController;
        
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSString *titleText;
        
        id jamTrackObject = [_coordinator jamTrackObjectAtIndexPath:indexPath fromSourceStructure:_homeControllerData];
        if (jamTrackObject) {
            
            titleText = jamTrackObject[@"title"];
            
            NSArray *trackNodes = jamTrackObject[@"trackobjectset"];
            if (trackNodes) {
                if ([trackNodes count] > 0) {
                    id trackNode = trackNodes[0];
                    [JWCurrentWorkItem sharedInstance].currentAudioFileURL = trackNode[@"fileURL"];
                }
            }
        }
        
        clipController.trackName = titleText;
        
        //        clipController.thumbImage = self.imageView.image;
        
    }
    
    //Youtube search will probably be gone in final version
//    else if ([segue.identifier isEqualToString:@"JWYoutubeSearch"]) {
//        
//        // SELECTION Requires OS9
//        JWYTSearchTypingViewController *controller = (JWYTSearchTypingViewController*)segue.destinationViewController;
//        controller.delegate = self;
//        controller.searchTerm = _lastSearchTerm;
//        
//    }
    
    //Dont see us going to source audio files yet
//    else if ([segue.identifier isEqualToString:@"JWSourceAudioFiles"]) {
//        
//        JWSourceAudioListsViewController *sourceAudioTableViewController = (JWSourceAudioListsViewController*)segue.destinationViewController;
//        sourceAudioTableViewController.selectToClip = _isAddingNewObject;
//        sourceAudioTableViewController.delegate = self;
//    }
    
}


/*






-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    
}

 //
 

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

 
*/

#pragma mark - ACTION CONTROLLERS 

-(void)detailOptions {
    
    NSString *title;
    NSMutableString *message = [NSMutableString new];
    NSMutableDictionary *object = [_coordinator jamTrackObjectAtIndexPath:_selectedDetailIndexPath fromSourceStructure:_homeControllerData];
    if (object)
        title = [_coordinator preferredTitleForObject:object];
    
    NSString * jamTrackKey = object[@"key"];
    NSUInteger countEmpties = [_coordinator countEmptyRecorderNodesForJamTrackWithKey:jamTrackKey atIndexPath:_selectedDetailIndexPath fromSource:_homeControllerData];
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
        
        [self addTrackNodeToJamTrackObject:object];
        
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
            
            [self deleteEmptyRecorderNodesAtObject:object];
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
    __block UITextField *nameChange = nil;
    
    [actionController addTextFieldWithConfigurationHandler:^(UITextField* textField){
        
        nameChange = textField;
    }];
    
    
    UIAlertAction* okAction =
    [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
        
        if (_selectedDetailIndexPath) {
            NSMutableDictionary *object = [_coordinator jamTrackObjectAtIndexPath:_selectedDetailIndexPath fromSourceStructure:_homeControllerData];
            if (object) {
                object[@"title"] = nameChange.text;
                
                [[JWFileManager defaultManager] saveHomeMenuLists];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView beginUpdates];
                    [self.tableView reloadRowsAtIndexPaths:@[_selectedDetailIndexPath]
                                          withRowAnimation:UITableViewRowAnimationNone];
                    [self.tableView endUpdates];
                });
            }
        }
    }];
    UIAlertAction* cancelAction =
    [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction* action) {
        self.selectedDetailIndexPath = nil;
        
    }];
    
    
    [actionController addAction:okAction];
    [actionController addAction:cancelAction];
    [self presentViewController:actionController animated:YES completion:nil];
}

-(void)moreInfo {
    
    NSString *title;
    NSMutableString *message = [NSMutableString new];
    
    NSMutableDictionary *object = [_coordinator jamTrackObjectAtIndexPath:_selectedDetailIndexPath fromSourceStructure:_homeControllerData];
    if (object)
        title = object[@"title"];
    
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

#pragma mark - HELPERS

//Was used for name change when info button pressed, came up with possible work aorund, may need this later tho.
//-(void)textFieldDidEndEditing:(UITextField *)textField {
//    NSLog(@"%s",__func__);
//    
//    if (_selectedDetailIndexPath) {
//        if ([textField.text length] > 0) {
//            NSString *titleText = textField.text;
//            NSMutableDictionary *object = [self jamTrackObjectAtIndexPath:_selectedDetailIndexPath];
//            if (object) {
//                self.nameChangeString = titleText;
//            }
//        }
//    }
//}

-(JWHomeSectionType)typeForSectionObject:(id)sectionObject {
    JWHomeSectionType result;
    id typeValue = sectionObject[@"type"];
    if (typeValue)
        result = [typeValue unsignedIntegerValue];
    return result;
}

-(JWHomeSectionType)typeForSection:(NSUInteger)section {
    JWHomeSectionType result;
    if (section < [_homeControllerData count]) {
        id objectSection = _homeControllerData[section];
        result = [self typeForSectionObject:objectSection];
    }
    return result;
}

-(id)objectSelected {
    
    id result = nil;
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    if (indexPath.section < [_homeControllerData count]) {
        
        id objectSection = _homeControllerData[indexPath.section];
        id sessionSet = nil;
        JWHomeSectionType sectionType = [self typeForSectionObject:objectSection];
        
        if (sectionType == JWHomeSectionTypeSessions) {
            sessionSet = objectSection[@"sessionset"];
            
        } else if (sectionType == JWHomeSectionTypeDownloadedTracks) {
            
        }
        
        result = sessionSet[indexPath.row];
        
    }
    return result;
}


-(void)addTrackNodeToJamTrackObject:(NSMutableDictionary *)object {
    
    NSMutableArray *tracks = self.homeControllerData[_selectedDetailIndexPath.section][@"sessionset"][_selectedDetailIndexPath.row][@"trackobjectset"];
    [tracks addObject:[_coordinator newJamTrackObjectWithRecorderFileURL:nil]];
}


-(void)deleteEmptyRecorderNodesAtObject:(NSMutableDictionary *)object {
    
    // Find the indexes to delete
    id trackNodes = object[@"trackobjectset"];
    if (trackNodes) {
        
        NSMutableIndexSet *deleteIndexes = [NSMutableIndexSet new];
        NSUInteger index = 0;
        for (id trackNode in trackNodes) {
            id typeValue = trackNode[@"type"];
            if (typeValue) {
                JWAudioNodeType nodeType = [typeValue unsignedIntegerValue];
                if (nodeType == JWAudioNodeTypeRecorder) {
                    id fileURL = trackNode[@"fileURL"];
                    if (fileURL == nil)
                        [deleteIndexes addIndex:index];
                }
            }
            index++;
        }
        
        
        
        if ([deleteIndexes count] > 0){
            
            __block NSUInteger deleteCount = 0;
            [deleteIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
                [trackNodes removeObjectAtIndex:idx - deleteCount];
                deleteCount++;
            }];
            
            [[JWFileManager defaultManager] saveHomeMenuLists];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView beginUpdates];
                [self.tableView reloadRowsAtIndexPaths:@[_selectedDetailIndexPath]
                                      withRowAnimation:UITableViewRowAnimationNone];
                [self.tableView endUpdates];
            });
            
            
            
        }
    }
    
}


-(void)nameChanged:(id)sender{
    NSLog(@"%s",__func__);
}

//-(void)updateAndSaveHomeDataSet {
//    
//    [[JWFileManager defaultManager] updateHomeObjectsAndSave:_homeControllerData];
//}


#pragma mark - FILE SYSTEM (THINKING ABOUT SINGLETON)



#pragma mark - DetailViewController delegate methods

-(void)itemChanged:(DetailViewController*)controller {
    
    //save user list
}

-(void)addNewJamSessionToTop:(DetailViewController *)controller {
    
    //Maybe should do it this way in the hometvc method too, then update the home data set instead of updating the home data set then updating the home items list
    for (NSDictionary *section in [[JWFileManager defaultManager] homeItemsList]) {
        JWHomeSectionType sectionType = [section[@"type"] integerValue];
        if (sectionType == JWHomeSectionTypeSessions) {
            
            NSMutableArray *sessions = section[@"sessionset"];
            [sessions insertObject:controller.detailItem atIndex:0];
            break;
        }
    }
    
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
    
    id jamTrack = [_coordinator jamTrackObjectWithKey:key fromSource:_homeControllerData];
    if (jamTrack) {
        NSLog(@"%s%@ %@",__func__,key,[jamTrack description]);
    }
    //    [self saveUserOrderedList];
}


-(void)userAudioObtainedInNodeWithKey:(NSString*)nodeKey recordingId:(NSString*)rid {
    NSLog(@"Hit old userAudioObtained");
    id nodeInJamTrack = [_coordinator jamTrackObjectWithKey:nodeKey fromSource:_homeControllerData];
    
    NSAssert(rid, @"recording id must be present if user audio is obtained.");
    nodeInJamTrack[@"fileURL"] = [[JWFileManager defaultManager] fileURLWithFileName:[NSString stringWithFormat:@"clipRecording_%@.caf", rid]];
    
    [[JWFileManager defaultManager] updateHomeObjectsAndSave:_homeControllerData];
    
    NSLog(@"NEW RECORDING in track \n%@",[nodeInJamTrack description]);
}


-(void)userAudioObtainedInNodeWithKey:(NSString *)nodeKey recordingURL:(NSURL *)rurl {
    
//    id nodeInJamTrack = [_coordinator jamTrackObjectWithKey:nodeKey fromSource:_homeControllerData];
//    
//    NSAssert(rurl, @"recording url must be present");
//    nodeInJamTrack[@"fileURL"] = rurl;
//    
//    [[JWFileManager defaultManager] saveHomeMenuLists];
//    NSLog(@"NEW RECORDING in track \n%@",[nodeInJamTrack description]);
}

-(void)userAudioObtainedWithComponents:(NSDictionary*)components atNodeWithKey:(NSString *)key {
    
    NSMutableDictionary *nodeInJamTrack = [_coordinator jamTrackObjectWithKey:key fromSource:_homeControllerData];
    [nodeInJamTrack addEntriesFromDictionary:components];
    
    [[JWFileManager defaultManager] updateHomeObjectsAndSave:_homeControllerData];
    
    NSLog(@"NEW RECORDING in track \n%@",[nodeInJamTrack description]);
}


-(id)addTrackNode:(id)controller toJamTrackWithKey:(NSString*)key {

    NSLog(@"%s",__func__);

    id result;
    NSIndexPath *itemIndexPath = [_coordinator indexPathOfJamTrackCacheItem:key fromSource:_homeControllerData];

    if (itemIndexPath) {
        id objectSection = _homeControllerData[itemIndexPath.section];

        NSArray *jamTracks = objectSection[@"sessionset"];

        if (jamTracks) {
            if (itemIndexPath.row < [jamTracks count]) {
                id jamTrack = jamTracks[itemIndexPath.row];
                id trackNodes = jamTrack[@"trackobjectset"];

                id playerRecorder = [_coordinator newTrackNodeOfType:JWAudioNodeTypeRecorder andFileURL:nil withAudioFileKey:nil];

                [trackNodes addObject:playerRecorder];
                NSLog(@"%s TRACK ADDED \n%@",__func__,[jamTrack description]);

                [[JWFileManager defaultManager] updateHomeObjectsAndSave:_homeControllerData];

                result = jamTrack;
//Dont know if this has to be done since the table reloads on viewwillappear (this was done in master)
//                NSUInteger nBaseRows = 1; // for JWHomeSectionTypeAudioFiles
//                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:nBaseRows+itemIndexPath.row inSection:itemIndexPath.section];
//
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [self.tableView beginUpdates];
//                    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
//                    [self.tableView endUpdates];
//                });
            }
        }
    }

    return result;
}




//not used
-(NSArray*)tracks:(DetailViewController*)controller forJamTrackKey:(NSString*)key {
    
    NSArray * result;
    NSIndexPath *itemIndexPath = [self indexPathOfJamTrackCacheItem:key];
    
    if (itemIndexPath) {
        id objectSection = _homeControllerData[itemIndexPath.section];
        
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

//Not used
-(NSString*)detailController:(DetailViewController*)controller titleForJamTrackKey:(NSString*)key {
    
    NSString * result;
    NSIndexPath *itemIndexPath = [self indexPathOfJamTrackCacheItem:key];
    
    if (itemIndexPath) {
        id objectSection = _homeControllerData[itemIndexPath.section];
        
        id jamTracks = objectSection[@"trackobjectset"];
        if (jamTracks) {
            id jamTrack = jamTracks[itemIndexPath.row];
            result = jamTrack[@"title"];
        }
    }
    
    return result;
}


// not tested yet
-(NSString*)detailController:(DetailViewController*)controller titleForTrackAtIndex:(NSUInteger)index inJamTrackWithKey:(NSString*)key {
    
    NSString * result;
    NSIndexPath *itemIndexPath = [self indexPathOfJamTrackCacheItem:key];
    
    if (itemIndexPath) {
        id objectSection = _homeControllerData[itemIndexPath.section];
        
        id jamTracks = objectSection[@"trackobjectset"];
        if (jamTracks) {
            id jamTrack = jamTracks[itemIndexPath.row];
            result = jamTrack[@"title"];
        }
    }
    
    return result;
}



@end






// Override to support rearranging the table view.
//TODO: do this later...
//- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
//
//    NSLog(@"%s",__func__);
//
//
//    id moveObject ;
//    NSUInteger fromIndex = 0;
//
//    NSIndexPath *indexPath = fromIndexPath;
//
//    if (indexPath.section < [_homeControllerData count]) {
//
//        id objectSection = _homeControllerSections[indexPath.section];
//
//        BOOL isTrackItem = YES;;
//        NSUInteger virtualRow = indexPath.row;
//        NSUInteger count = [self baseRowsForSection:indexPath.section];
//        if (indexPath.row < count)
//            isTrackItem = NO;  // baserow
//        else
//            virtualRow -= count;
//
//        if (isTrackItem) {
//            // IS  ATRACK CELL not a controll cell index 0 AUDIOFILES and SEARCH
//            id trackObjects = objectSection[@"trackobjectset"];
//            if (trackObjects) {
//                if (virtualRow < [trackObjects count]) {
//
//                    moveObject = trackObjects[virtualRow];
//                    fromIndex = virtualRow;
//                }
//            }
//        }
//    }
//
//    if (moveObject) {
//
//        NSIndexPath *indexPath = toIndexPath;
//        if (indexPath.section < [_homeControllerSections count]) {
//
//
//            BOOL isTrackItem = YES;;
//            NSUInteger virtualRow = indexPath.row;
//            NSUInteger count = [self baseRowsForSection:indexPath.section];
//            if (indexPath.row < count)
//                isTrackItem = NO;  // baserow
//            else
//                virtualRow -= count;
//
//
//            if (isTrackItem) {
//                // IS  ATRACK CELL not a controll cell index 0 AUDIOFILES and SEARCH
//
//                id objectSection = _homeControllerSections[indexPath.section];
//
//                id trackObjects = objectSection[@"trackobjectset"];
//                if (trackObjects) {
//                    if (virtualRow < [trackObjects count]) {
//
//                        [trackObjects removeObjectAtIndex:fromIndex];
//
//                        [trackObjects insertObject:moveObject atIndex:virtualRow];
//
//                        [tableView beginUpdates];
//                        [tableView reloadSections:[NSIndexSet indexSetWithIndex:fromIndexPath.section]  withRowAnimation:UITableViewRowAnimationAutomatic];
//
//                        //                        [tableView reloadRowsAtIndexPaths:@[fromIndexPath, toIndexPath]
//                        //                                         withRowAnimation:UITableViewRowAnimationAutomatic];
//
//                        [tableView endUpdates];
//                    }
//                }
//            }
//        }
//    }
//
//    //        self indexPathOfJamTrackCacheItem:<#(NSString *)#>
//
//
//
//
//    //    id moveObject = [_objectCollections[fromIndexPath.section] objectAtIndex:fromIndexPath.row];
//    //
//    //    [_objectCollections[fromIndexPath.section]  removeObjectAtIndex:fromIndexPath.row];
//    //    [_objectCollections[toIndexPath.section]  insertObject:moveObject atIndex:toIndexPath.row];
//
//    //    if ([_objectCollections[fromIndexPath.section] count] == 0) {
//    //        [_objectCollections removeObjectAtIndex:fromIndexPath.section];
//    //
//    //        //NSUInteger reloadSection = toIndexPath.section;
//    //        //        if (fromIndexPath.section < toIndexPath.section) {
//    //        //            reloadSection--;
//    //        //        }
//    //        [tableView beginUpdates];
//    //        [tableView deleteSections:[NSIndexSet indexSetWithIndex:fromIndexPath.section] withRowAnimation:UITableViewRowAnimationAutomatic];
//    //        //        [tableView reloadSections:[NSIndexSet indexSetWithIndex:reloadSection]  withRowAnimation:UITableViewRowAnimationAutomatic];
//    //        [tableView endUpdates];
//    //    }
//
//    //    [tableView reloadSectionIndexTitles];
//
//    //    [self saveUserOrderedList];
//}


// Override to support conditional rearranging of the table view.
//TODO: do this later too...
//- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
//
//    return NO; // neess more work
//
//    // Return NO if you do not want the item to be re-orderable.
//    BOOL result = NO;
//
//    NSUInteger section = indexPath.section;
//    NSUInteger count = 0;
//    // Compute base rows for section
//    if (section < [_homeControllerSections count]) {
//        JWHomeSectionType sectionType = [self typeForSection:section];
//        if (sectionType == JWHomeSectionTypeAudioFiles) {
//            count ++;
//        } else if (sectionType == JWHomeSectionTypeYoutube) {
//            count ++;
//            count ++;
//        } else if (sectionType == JWHomeSectionTypeOther) {
//            count ++;
//        }
//    }
//
//    if (indexPath.row < count) {
//        // baserow
//    } else {
//        result = YES;
//    }
//    return result;
//}
//TODO: do this later too lol...
//-(NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
//
//    //    NSLog(@"%s",__func__);
//    // Allow the proposed destination.
//
//    NSUInteger section = sourceIndexPath.section;
//    NSUInteger count = 0;
//    // Compute base rows for section
//    if (section < [_homeControllerSections count]) {
//        JWHomeSectionType sectionType = [self typeForSection:section];
//        if (sectionType == JWHomeSectionTypeAudioFiles) {
//            count ++;
//        } else if (sectionType == JWHomeSectionTypeYoutube) {
//            count ++;
//            count ++;
//        } else if (sectionType == JWHomeSectionTypeOther) {
//            count ++;
//        }
//    }
//
//    if (sourceIndexPath.section == proposedDestinationIndexPath.section)
//    {
//
//    } else {
//        proposedDestinationIndexPath = sourceIndexPath;
//    }
//
//    return proposedDestinationIndexPath;
//}
//
//Probably wount be showing audio files in this controller
//    else if ([[segue identifier] isEqualToString:@"JWShowAudioFiles"]) {
//
//        JWTrackSetsViewController *controller = (JWTrackSetsViewController *)[segue destinationViewController];
//        controller.delegate = self;
//
//        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
//        if (indexPath.section < [_homeControllerSections count]) {
//
//            id objectSection = _homeControllerSections[indexPath.section];
//
//            JWHomeSectionType sectionType = [self typeForSectionObject:objectSection];
//
//            id trackObjectSet;
//            if (sectionType == JWHomeSectionTypeAudioFiles)
//                trackObjectSet = objectSection[@"trackobjectset"];
//
//            if (trackObjectSet) {
//                [controller setTrackSet:trackObjectSet];
//                self.selectedIndexPath = indexPath;
//            }
//        }
//
//    }
