//
//  JWTrackSetsViewController.m
//  JWMixAudioScrubber
//
//  Created by JOSEPH KERR on 1/7/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

#import "JWTrackSetsViewController.h"
#import "DetailViewController.h"
#import "JWFileController.h"
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
//    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
//    self.navigationItem.rightBarButtonItem = addButton;
}

- (void)viewWillAppear:(BOOL)animated {
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        
    } else {
        // ipad
        self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    }
    
    [super viewWillAppear:animated];
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        [self.detailViewController stopPlaying];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark -

// Given an array of jamTracks, each jamTrack contains an array of trackNodes

/*

 the jamtracks array is parallel with objectcollections
 to get info on jamtrack and not just tracknodes
 _jamTracks[indexPath.section][@"key"];  The jamTrack is also given to DetailViewController

 */
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
}


#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([[segue identifier] isEqualToString:@"JWShowDetailFromFiles"]) {

        DetailViewController *controller = (DetailViewController *)[[segue destinationViewController] topViewController];
        controller.delegate = self;

        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];

        NSDictionary *object = _jamTracks[indexPath.section];
        
        [controller setDetailItem:object];
        
        controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
        controller.navigationItem.leftItemsSupplementBackButton = YES;
        
        self.detailViewController = controller;
        self.selectedIndexPath = indexPath;
    }
}

#pragma mark - helpers

// the trackNode object
// returns tableView indexPath
-(NSIndexPath*)indexPathOfCacheItem:(NSString*)key {
    
    NSIndexPath *result;
    NSUInteger sectionIndex = 0;
    NSUInteger index = 0;

    BOOL found = NO;

    for (id objectCollection in _objectCollections) {
        index = 0;
        for (id obj in objectCollection) {
            if ([key isEqualToString:obj[@"key"]]) {
                found=YES; // Found it
                break;
            }
            index++;
        }
        if (found)
            break;
        
        sectionIndex++;
    }
    
    if (found) {
        //    NSLog(@"%s%@ index %ld",__func__,key,index);
        result = [NSIndexPath indexPathForRow:index inSection:sectionIndex];
    }
    
    return result;
}

// searches _jamTracks which is parallel to _objectCollections to find sectionIndex

-(NSArray*)tracksForKey:(NSString*)key {
    
    NSArray *result = nil;
    NSUInteger collectionIndex = 0;
    BOOL found = NO;
    
    for (id jamTrack in _jamTracks) {
        if ([key isEqualToString:jamTrack[@"key"]]) {
            found=YES;
            break;
        }
        collectionIndex++;
    }
    
    if (found && collectionIndex < [_objectCollections count])
        result = _objectCollections[collectionIndex];
    
    return result;
}

// returns jamTrack that matches key
-(id)jamTrackForKey:(NSString*)key {
    
    id result = nil;
    for (id jamTrack in _jamTracks) {
        if ([key isEqualToString:jamTrack[@"key"]]) {
            result = jamTrack;
            break;
        }
    }
    
    return result;
}

-(NSInteger)sectionForJamTrackKey:(NSString*)key {
    
    NSInteger result = NSNotFound;
    NSInteger collectionIndex = 0;
    
    for (id jamTrack in _jamTracks) {
        if ([key isEqualToString:jamTrack[@"key"]]) {
            result = collectionIndex;
            break;
        }
        collectionIndex++;
    }
    return result;
}


#pragma mark - DetailViewController delegate methods

// current way
-(NSArray*)tracks:(DetailViewController*)controller forJamTrackKey:(NSString*)key {

    return [self tracksForKey:key];
}

-(NSString*)detailController:(DetailViewController*)controller titleForJamTrackKey:(NSString*)key {
    
   return [_delegate trackSets:self titleForJamTrackKey:key];
}

-(NSString*)detailController:(DetailViewController*)controller titleForTrackAtIndex:(NSUInteger)index
           inJamTrackWithKey:(NSString*)key {
    
    return [_delegate trackSets:self titleForTrackAtIndex:index inJamTrackWithKey:key];
}

-(void)save:(DetailViewController*)controller cachKey:(NSString*)key {

    // key is a jamTrack key
    
    [_delegate trackSets:self saveJamTrackWithKey:key];
}

-(void)userAudioObtainedInNodeWithKey:(NSString*)nodeKey recordingId:(NSString*)rid {

    [_delegate userAudioObtainedInNodeWithKey:nodeKey recordingId:rid];
    
    NSIndexPath *nodeIndexPath = [self indexPathOfCacheItem:nodeKey];
    if (nodeIndexPath) {
        // reload a node, can also reload Section
        [self.tableView beginUpdates];
        [self.tableView reloadRowsAtIndexPaths:@[nodeIndexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
    }

    // perhaps update this record for this view controller
    // prefer to have delegate do it and we ask for an update
}

-(id)addTrackNode:(id)controller toJamTrackWithKey:(NSString*)key {

    id result;
    if ([_delegate respondsToSelector:@selector(addTrackNode:toJamTrackWithKey:)]) {
        result = [_delegate addTrackNode:self toJamTrackWithKey:key];
        [self.tableView reloadData];
    }
    
    return result;
}

-(void)addTrack:(DetailViewController*)controller cachKey:(NSString*)key {
    // key is jamTrack Key
    NSLog(@"%s",__func__);
    NSInteger sectionIndex = [self sectionForJamTrackKey:key];
    if (sectionIndex == NSNotFound) {
        
    } else {
        [_delegate addTrack:self cachKey:key];
        [self.tableView reloadData];
    }
}

//        id jamTrack = [self jamTrackForKey:key];
//        dispatch_async(dispatch_get_main_queue(), ^{
//            self.detailViewController.detailItem = jamTrack;
//        });

#pragma mark - Table View Delegate

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

    NSString *durationString;
    UIColor *durationColor = [UIColor blackColor]; // select needed color

    if (fileName.length > 0) {
        double audioLength = [[JWFileController sharedInstance] audioLengthForFileWithName:fileName];
        durationString = [NSString stringWithFormat:@"%.0f sec",audioLength];
        durationColor = [UIColor blackColor];
    } else {
        durationString = @"no recording";
        durationColor = [UIColor darkGrayColor];
    }
    
    NSString *textLabelText =[NSString stringWithFormat:@"%@%@",
                              durationString,
                              [fileName length] > 0 ? [NSString stringWithFormat:@" %@",fileName ] : fileName
                              ];

    NSDictionary *attrs = @{ NSForegroundColorAttributeName : [UIColor darkGrayColor] };
    NSMutableAttributedString *textLabelAttributedText =
    [[NSMutableAttributedString alloc] initWithString:textLabelText attributes:attrs];
    
    [textLabelAttributedText addAttribute:NSForegroundColorAttributeName value:durationColor
                    range:NSMakeRange( 0,durationString.length)];
    
    cell.textLabel.attributedText = textLabelAttributedText;

//    cell.textLabel.text = textLabelText;

//    [object[@"key"] substringToIndex:5],

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

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSMutableArray *objectCollection = _objectCollections[indexPath.section];
        [objectCollection removeObjectAtIndex:indexPath.row];

        [tableView beginUpdates];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
        [tableView endUpdates];

        [_delegate trackSets:self saveJamTrackWithKey:_jamTracks[indexPath.section][@"key"]];
        
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
    UITableViewHeaderFooterView *view = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"JWHeaderViewX"];
    
    if (view == nil) {
        view = [[UITableViewHeaderFooterView alloc] initWithReuseIdentifier:@"JWHeaderViewX"];

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

// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return NO;
}


@end



//    UILabel *label = [[UILabel alloc] init];
//    label.text = [_delegate trackSets:self titleForSection:section];
//    label.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
//    label.textColor = [UIColor whiteColor];
//    CGRect fr  = CGRectZero;
//    fr.origin = CGPointMake(10, 0);
//    label.frame = fr;
//    return label;

//        UITableViewCell *sampleCell = [tableView dequeueReusableCellWithIdentifier:@"JWSectionTrack"];
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



