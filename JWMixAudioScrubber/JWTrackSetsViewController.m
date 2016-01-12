//
//  JWTrackSetsViewController.m
//  JWMixAudioScrubber
//
//  Created by JOSEPH KERR on 1/7/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

#import "JWTrackSetsViewController.h"
#import "DetailViewController.h"

@interface JWTrackSetsViewController () <JWDetailDelegate>
@property NSIndexPath *selectedIndexPath;
@property NSMutableArray *objectCollections;  // collects objects
@property NSMutableArray *jamTracks;  // keys to collections
@end


@implementation JWTrackSetsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

//    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
    self.navigationItem.rightBarButtonItem = addButton;
}

- (void)viewWillAppear:(BOOL)animated {
    self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -

// Array of arrays jamTracks
-(void)setTrackSet:(id)trackSet {
    
    NSLog(@"%s",__func__);
    
    self.objectCollections = [[NSMutableArray alloc] init];
    self.jamTracks = [[NSMutableArray alloc] init];

    if (trackSet) {
        
        for(id jamTrack in trackSet) {
            id trackNodes = jamTrack[@"trackobjectset"];
            if (trackNodes)
                [_objectCollections addObject:jamTrack[@"trackobjectset"]];
            
            [_jamTracks addObject:jamTrack];
        }
    }
    
}


- (void)insertNewObject:(id)sender {
    if (!self.objectCollections) {
        self.objectCollections = [[NSMutableArray alloc] init];
    }
    
    NSMutableArray *objectCollection = nil;
    BOOL useSet = YES;
    
    if (useSet) {
        objectCollection = [self newTrackObjectSet];
        if (objectCollection) {
            [_objectCollections insertObject:objectCollection atIndex:0];
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        
    } else {
        
        NSMutableDictionary *trackObject = [self newTrackObject];
        if (trackObject) {
            NSIndexPath *selected = [self.tableView indexPathForSelectedRow];
            
            if (selected) {
                objectCollection = _objectCollections[selected.section];
                
                [objectCollection insertObject:trackObject atIndex:0];
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:selected.section];
                
                [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                
            } else {
                
                [objectCollection insertObject:trackObject atIndex:0];
                [_objectCollections insertObject:objectCollection atIndex:0];
                [self.tableView insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        }

    }
    
//    [self saveUserOrderedList];
    
}


-(NSMutableDictionary*)newTrackObject {
    NSMutableDictionary *result = nil;
    return result;
}

-(NSMutableArray*)newTrackObjectSet {
    NSMutableArray *result = nil;
    return result;
}


#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([[segue identifier] isEqualToString:@"JWShowDetailFromFiles"]) {
        
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        
        NSDictionary *object = _jamTracks[indexPath.section];
        
        DetailViewController *controller = (DetailViewController *)[[segue destinationViewController] topViewController];
        controller.delegate = self;
        
        [controller setDetailItem:object];
        
        controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
        controller.navigationItem.leftItemsSupplementBackButton = YES;
        
        self.selectedIndexPath = indexPath;
    }
}

#pragma mark - helpers

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
        if (found)
            break;
        
        collectionIndex++;
    }
    
    //    NSLog(@"%s%@ index %ld",__func__,key,index);
    return [NSIndexPath indexPathForRow:index inSection:collectionIndex];
}


-(void)reloadItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section {
    
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:section]]
                          withRowAnimation:UITableViewRowAnimationFade];
    
    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:section] animated:YES scrollPosition:UITableViewScrollPositionNone];
}

#pragma mark - delegate methods

-(void)itemChanged:(DetailViewController*)controller {
//    [self saveUserOrderedList];
}
//
-(void)itemChanged:(DetailViewController*)controller cachKey:(NSString*)key {
    NSLog(@"%s%@",__func__,key);
//    NSIndexPath *item = [self indexPathOfCacheItem:key];
//    [self reloadItemAtIndex:item.row inSection:item.section];
}
//
-(void)save:(DetailViewController*)controller cachKey:(NSString*)key {
    NSLog(@"%s%@",__func__,key);
//    NSIndexPath *item = [self indexPathOfCacheItem:key];
//    [self reloadItemAtIndex:item.row inSection:item.section];
//    [self saveUserOrderedList];
}
//
-(void)addTrack:(DetailViewController*)controller cachKey:(NSString*)key {
    
//    NSIndexPath *item = [self indexPathOfCacheItem:key];
//    NSMutableArray *objectCollection = _objectCollections[item.section];
//    NSMutableDictionary *trackObject = [self newTrackObject];
//    [objectCollection insertObject:trackObject atIndex:0];
//    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:item.section];
//    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}
//

// old way
-(NSArray*)tracks:(DetailViewController*)controller cachKey:(NSString*)key {
    NSIndexPath *item = [self indexPathOfCacheItem:key];
    NSMutableArray *objectCollection = _objectCollections[item.section];
    return objectCollection;
}

// current way
-(NSArray*)tracks:(DetailViewController*)controller forJamTrackKey:(NSString*)key {

    return [self tracksForKey:key];
}


-(NSArray*)tracksForKey:(NSString*)key
{
    NSArray *result = nil;
    NSUInteger collectionIndex = 0;
    
    BOOL found = NO;
    for (id jamTrack in _jamTracks) {
        if ([key isEqualToString:jamTrack[@"key"]]) {
            // found it
            found=YES;
            break;
        }
        collectionIndex++;
    }
    
    if (found) {
        if (collectionIndex < [_objectCollections count]) {
            result = _objectCollections[collectionIndex];
        }
    }
    
    return result;
    
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [_objectCollections count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_objectCollections[section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    NSMutableArray *objectCollection = _objectCollections[indexPath.section];
    NSDictionary *object = objectCollection[indexPath.row];
    
    id startTimeValue = object[@"starttime"];
    NSTimeInterval startTime = 0;
    if (startTimeValue)
        startTime = [startTimeValue doubleValue];
    
    id fileURLValue = object[@"fileURL"];
    NSString *fileName = @"";
    if (fileURLValue)
        fileName = [[(NSURL*)fileURLValue path] lastPathComponent];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@%@",
                           [object[@"key"] substringToIndex:5],
                           [fileName length] > 0 ? [NSString stringWithFormat:@"  %@",fileName ] : fileName
                           ];
    
    cell.detailTextLabel.text =
    [NSString stringWithFormat:@"startTime %00.2f hasRef %@",startTime,object[@"referencefile"]?@"YES":@"NO"];
    
    return cell;
}

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
        
//        [self saveUserOrderedList];
        
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        
    }
}

//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
//    // Return NO if you do not want the specified item to be editable.
//    return @"tracks section";
//}

- (CGFloat )tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 42.0f;
    
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section  {

    UITableViewCell *view = [tableView dequeueReusableCellWithIdentifier:@"JWSectionTrack"];
    view.textLabel.text = [_delegate trackSets:self titleForSection:section];
    view.detailTextLabel.text = [_delegate trackSets:self titleDetailForSection:section];
    return view;
}

//    UITableViewHeaderFooterView *view = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"JWSectionTrack"];
//    view.textLabel.text = @"tracks section";
//    view.detailTextLabel.text = @"more info";
// Return NO if you do not want the specified item to be editable.
//    return @"tracks section";


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
    
//    [self saveUserOrderedList];
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

@end



//        NSMutableArray *objectCollection = _objectCollections[indexPath.section];
//        NSDictionary *object = objectCollection[indexPath.row];


//#pragma mark -

//-(NSString*)documentsDirectoryPath {
//    NSString *result = nil;
//    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    result = [searchPaths objectAtIndex:0];
//    //    NSLog(@"%s %@",__func__, result);
//    return result;
//}
//
//-(NSURL *)fileURLWithFileName:(NSString*)name {
//    NSURL *result;
//    NSString *thisfName = name;//@"mp3file";
//    NSString *thisName = thisfName; //[NSString stringWithFormat:@"%@_%@.mp3",thisfName,dbkey?dbkey:@""];
//    NSMutableString *fname = [[self documentsDirectoryPath] mutableCopy];
//    [fname appendFormat:@"/%@",thisName];
//    result = [NSURL fileURLWithPath:fname];
//    return result;
//}

//
///*
// serializeOut
// Convert any dictionary items that cannot be serialized to serializable format if possible
// fileURL NSURL to Path
// UIColor to rgb alpha
// */
//-(void)serializeOut {
//    
//    for (id objectCollection in _objectCollections) {
//        for (id obj in objectCollection) {
//            id furl = obj[@"fileURL"];
//            if (furl) {
//                obj[@"fileName"] = [[(NSURL*)furl path] lastPathComponent];
//                [obj removeObjectForKey:@"fileURL"];
//            }
//        }
//    }
//}
//
//-(void)saveUserOrderedList {
//    [self serializeOut];
//    [_objectCollections writeToURL:[self fileURLWithFileName:@"savedobjects"] atomically:YES];
//    [self serializeIn];
//    
//    NSLog(@"%s savedobjects[%ld]",__func__,[_objectCollections count]);
//    //    NSLog(@"%savedobjects \n%@",__func__,[_objects description]);
//    
//}
//
///*
// serializeIn
// Convert any dictionary items that could not be serialized and were converted to a serializable format
// Path to fileURL NSURL
// rgb-alpha to UIColor
// */
//
//-(void)serializeIn {
//    
//    for (id objectCollection in _objectCollections) {
//        for (id obj in objectCollection) {
//            id fname = obj[@"fileName"];
//            if (fname) {
//                obj[@"fileURL"] = [self fileURLWithFileName:fname];
//                [obj removeObjectForKey:@"fileName"];
//            }
//        }
//    }
//}
//
//-(void)readUserOrderedList {
//    _objectCollections = [[NSMutableArray alloc] initWithContentsOfURL:[self fileURLWithFileName:@"savedobjects"]];
//    [self serializeIn];
//    NSLog(@"%savedobjects[%ld]",__func__,[_objectCollections count]);
//    //    NSLog(@"%savedobjects \n%@",__func__,[_objects description]);
//}
//

////#define JWSampleFileName @"trimmedMP3"
////#define JWSampleFileNameAndExtension @"trimmedMP3.m4a"
////#define JWSampleFileName @"trimmedMP3-45"
////#define JWSampleFileNameAndExtension @"trimmedMP3-45.m4a"
////#define JWSampleFileName @"AminorBackingtrackTrimmedMP3-45"
////#define JWSampleFileNameAndExtension @"AminorBackingtrackTrimmedMP3-45.m4a"
//#define JWSampleFileName @"TheKillersTrimmedMP3-30"
//#define JWSampleFileNameAndExtension @"TheKillersTrimmedMP3-30.m4a"
//



//-(NSMutableDictionary*)newTrackObject {
//    NSMutableDictionary *result = nil;
//    //    NSURL *fileURL = [self fileURLWithFileName:JWSampleFileNameAndExtension];
//    //    NSMutableDictionary * fileReference =
//    //    [@{@"duration":@(0),
//    //       @"startinset":@(0.0),
//    //       @"endinset":@(0.0),
//    //       } mutableCopy];
//    //
//    //    // The object to INSERT
//    //    result =
//    //    [@{@"key":[[NSUUID UUID] UUIDString],
//    //       @"title":@"track",
//    //       @"starttime":@(0.0),
//    //       @"referencefile": fileReference,
//    //       @"date":[NSDate date],
//    //       @"fileURL":fileURL
//    //       } mutableCopy];
//    //
//    return result;
//}
//
//-(NSMutableArray*)newTrackObjectSet {
//    
//    NSMutableArray *result = nil;
//    //    NSURL *fileURL = [self fileURLWithFileName:JWSampleFileNameAndExtension];
//    //
//    //    NSMutableDictionary * fileReference =
//    //    [@{@"duration":@(0),
//    //       @"startinset":@(0.0),
//    //       @"endinset":@(0.0),
//    //       } mutableCopy];
//    //
//    //    // The object to INSERT
//    //    result =[@[
//    //               [@{@"key":[[NSUUID UUID] UUIDString],
//    //                  @"title":@"track",
//    //                  @"starttime":@(0.0),
//    //                  @"referencefile": fileReference,
//    //                  @"date":[NSDate date],
//    //                  @"fileURL":fileURL
//    //                  } mutableCopy],
//    //
//    //               [@{@"key":[[NSUUID UUID] UUIDString],
//    //                  @"title":@"track",
//    //                  @"starttime":@(0.0),
//    //                  @"date":[NSDate date],
//    //                  } mutableCopy]
//    //               ] mutableCopy];
//    
//    return result;
//}
