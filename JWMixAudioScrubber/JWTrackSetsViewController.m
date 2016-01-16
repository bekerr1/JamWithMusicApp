//
//  JWTrackSetsViewController.m
//  JWMixAudioScrubber
//
//  Created by JOSEPH KERR on 1/7/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

#import "JWTrackSetsViewController.h"
#import "DetailViewController.h"

#import "JWTableHeaderView.h"

@interface JWTrackSetsViewController () <JWDetailDelegate>
@property NSIndexPath *selectedIndexPath;
@property NSMutableArray *objectCollections;  // collects objects
@property NSMutableArray *jamTracks;  // keys to collections
@property DetailViewController *detailViewController;
@end


@implementation JWTrackSetsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

//    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
    self.navigationItem.rightBarButtonItem = addButton;
}

- (void)viewWillAppear:(BOOL)animated {
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        
    } else {
        self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    }
    
    [super viewWillAppear:animated];
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        [self.detailViewController stopPlaying];
    }
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
    
    [self.tableView reloadData];
}

- (void)insertNewObject:(id)sender {
    
    NSLog(@"%s not implemented",__func__);
    return;
    
    
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
        self.detailViewController = controller;
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



-(NSArray*)tracksForKey:(NSString*)key {

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
        if (collectionIndex < [_objectCollections count])
            result = _objectCollections[collectionIndex];
    }
    
    return result;
}


#pragma mark -

-(NSString*)detailController:(DetailViewController*)controller titleForJamTrackKey:(NSString*)key {
    
   return [_delegate trackSets:self titleForJamTrackKey:key];
    
}

-(NSString*)detailController:(DetailViewController*)controller titleForTrackAtIndex:(NSUInteger)index
           inJamTrackWithKey:(NSString*)key {
    
    return [_delegate trackSets:self titleForTrackAtIndex:index inJamTrackWithKey:key];
    
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [_objectCollections count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_objectCollections[section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"JWTracksetCell" forIndexPath:indexPath];
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
    
    id titleValue = object[@"title"];
    id titleTypeValue = object[@"titletype"];

    cell.textLabel.text = [NSString stringWithFormat:@"%@%@",
                           [object[@"key"] substringToIndex:5],
                           [fileName length] > 0 ? [NSString stringWithFormat:@"  %@",fileName ] : fileName
                           ];
    
    cell.detailTextLabel.text =
    [NSString stringWithFormat:@"startTime %00.2f, Ref %@, %@ %@",
     startTime,
     object[@"referencefile"]?@"YES":@"NO",
     titleTypeValue ? titleTypeValue : @"",
     titleValue ? titleValue : @""
     ];
    
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
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

- (CGFloat )tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 10;
}

- (CGFloat )tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 40;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section  {
    UITableViewHeaderFooterView *view = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"JWFooterView"];
    
    if (view == nil) {
        view = [[UITableViewHeaderFooterView alloc] initWithReuseIdentifier:@"JWFooterView"];

//        view.backgroundColor = [UIColor blueColor];
        view.contentView.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:0.15];
        
    }
    return view;

}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section  {
    
    
//    JWTableHeaderView *view = [JWTableHeaderView new];
    
    
//    UILabel *label = [[UILabel alloc] init];
//    label.text = [_delegate trackSets:self titleForSection:section];
//    label.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
//    label.textColor = [UIColor whiteColor];
//    CGRect fr  = CGRectZero;
//    fr.origin = CGPointMake(10, 0);
//    label.frame = fr;
//    return label;
    
    
    UITableViewHeaderFooterView *view = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"JWHeaderViewX"];
    
    if (view == nil) {
//        UITableViewCell *sampleCell = [tableView dequeueReusableCellWithIdentifier:@"JWSectionTrack"];

        view = [[UITableViewHeaderFooterView alloc] initWithReuseIdentifier:@"JWHeaderViewX"];
//        view.backgroundColor = [UIColor darkGrayColor];
//        view.contentView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
//        view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
//        view.textLabel.numberOfLines = 2;
//        view.detailTextLabel.numberOfLines = 1;
//       view.textLabel.font = sampleCell.textLabel.font;
//        view.textLabel.textColor = sampleCell.textLabel.textColor;
//        view.textLabel.alpha = 1.0;
//        view.alpha = 1.0;
//        view.backgroundColor = sampleCell.backgroundColor;
//        view.contentView.backgroundColor = sampleCell.contentView.backgroundColor;

    }

    view.contentView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
    view.textLabel.textColor = [UIColor whiteColor];

    view.textLabel.text = [_delegate trackSets:self titleForSection:section];
    
//    view.detailTextLabel.text = [_delegate trackSets:self titleDetailForSection:section];

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

