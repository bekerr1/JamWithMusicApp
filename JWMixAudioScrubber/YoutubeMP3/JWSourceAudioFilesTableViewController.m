//
//  JWSourceAudioFilesTableViewController.m
//  JamWIthT
//
//  co-created by joe and brendan kerr on 10/4/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

/*
 A TableViewController to display the mp3 files or refrences to of the Youtube Files Downloaded
 Reads an Array _userOrderedList of dbkeys and the mp3Info the keys are used to access the information
 */

#import "JWSourceAudioFilesTableViewController.h"
#import "JWCurrentWorkItem.h"
#import "JWDBKeys.h"
#import "JWClipAudioViewController.h"
#import "JWFileController.h"
#import "UIColor+JW.h"

@import AVKit;
@import AVFoundation;

const NSString *JWDbKeyLinksDirectoryFileName = @"links.dat";
const NSString *JWDbKeyMP3InfoFileName = @"mp3info.dat";
const NSString *JWDbKeyUserOrderedListFileName = @"userlist.dat";

@interface JWSourceAudioFilesTableViewController () <JWClipAudioViewDelegate> {
    AVAudioEngine *_audioEngine;
    AVAudioPlayerNode *_playerNode;
    dispatch_queue_t _imageRetrievalQueue;
}
@property (strong, nonatomic) NSMutableDictionary *images;  //
@property (strong, nonatomic) NSMutableDictionary *mp3FilesInfo; // dbkey : {info about youtube vid and ytmp3 convert
@property (strong, nonatomic) NSMutableDictionary *mp3FilesDescriptions; // dbkey : {info about youtube vid and ytmp3 convert
@property (strong, nonatomic) NSMutableArray *userOrderList;  // dbkey
@property (nonatomic) NSMutableDictionary *mp3filesFilesData; // filesystem file info
@property (nonatomic) NSIndexPath *selectedIndexPath;
@property (nonatomic) NSString *selectedCacheItemKey;
@property (nonatomic) NSArray *allFilesSections;
@property NSIndexPath *selectedDetailIndexPath;
@end


@implementation JWSourceAudioFilesTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.refreshControl  = [UIRefreshControl new];

    [self.refreshControl addTarget:self action:@selector(refreshFromControl:) forControlEvents:UIControlEventValueChanged];
    self.clearsSelectionOnViewWillAppear = NO;
    self.navigationItem.rightBarButtonItem = self.editButtonItem;

    UIView *backgroundView = [UIView new];
    backgroundView.backgroundColor = [UIColor blackColor];
    self.tableView.backgroundView = backgroundView;
    self.tableView.backgroundView.layer.zPosition -= 1; // go behind refresh
    
    if (_imageRetrievalQueue == nil)
        _imageRetrievalQueue =
        dispatch_queue_create("imageProcessingSourceAudio",
                              dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_CONCURRENT,QOS_CLASS_UTILITY, 0));

    if (_allFiles)
        _allFilesSections = @[@[],@[]];  // 2 empties

    self.refreshControl.tintColor = [UIColor iosSilverColor];
    [self.refreshControl beginRefreshing];
    [self initAVAudioSession];
    [self loadData];
}


-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // And the first time when it is moving to the container
    if (self.isMovingToParentViewController) {
        NSLog(@"%s MOVINGTO",__func__);
    } else {
        NSLog(@"%s STAYING",__func__);
    }
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [_playerNode stop];
    if (_allFiles == NO && self.presentedViewController == nil) {
        [[JWFileController sharedInstance] saveUserList];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view content

-(void) refreshFromControl:(id)sender {
    if ([(UIRefreshControl*)sender isRefreshing]) {
        [self loadData];
    }
}

// A listener when other update mp3Info
-(void)mp3InfoHasBeenUpadated:(NSNotification*)noti
{
    [self loadData];
}

- (void)loadData {
    
    dispatch_async (dispatch_get_global_queue( QOS_CLASS_USER_INITIATED,0),^{
        
        [[JWFileController sharedInstance] readFsData];
        [self loadModel];
        dispatch_async (dispatch_get_main_queue(),^{
            [self.tableView reloadData];
            [self.refreshControl endRefreshing];
        });
    });
}

//        double delayInSecs = 0.10;
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSecs * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            [self.refreshControl endRefreshing];
//            [self.tableView beginUpdates];
//            [self.tableView reloadRowsAtIndexPaths:[self.tableView indexPathsForVisibleRows]
//                                  withRowAnimation:UITableViewRowAnimationAutomatic];
//            [self.tableView endUpdates];
//        });


// wip
//    if (_allFiles) {
//        dispatch_async (dispatch_get_global_queue( QOS_CLASS_BACKGROUND,0),^{
//            [_delegate loadDataAllWithCompletion:^{
//                [self loadModel];
//            }];
//        });
//    } else {
//        dispatch_async (dispatch_get_global_queue( QOS_CLASS_BACKGROUND,0),^{
//            [_delegate loadDataWithCompletion:^{
//                [self loadModel];
//            }];
//        });
//    }

- (void)loadModel {

    _mp3FilesInfo = [[JWFileController sharedInstance] mp3FilesInfo];
    _mp3filesFilesData = [NSMutableDictionary new];  // fs info
    self.images = [@{
                    @"iconmusic120":[UIImage imageNamed:@"iconmusic120"]
                     } mutableCopy];

    if (_allFiles) {
        _allFilesSections = @[
                              [[JWFileController sharedInstance] sourceFiles],
                              [[JWFileController sharedInstance] jamTrackFiles],
                              [[JWFileController sharedInstance] downloadedJamTrackFiles],
                              [[JWFileController sharedInstance] trimmedFiles],
                              ];
        
        for (id trimmed in _allFilesSections[3]) {
            NSURL *furl = trimmed[@"furl"];
            id dbKey = [[JWFileController sharedInstance] dbKeyForFileName:[furl lastPathComponent]];
            
            id mp3Data = [self trimmedFileReference:dbKey];
            if (mp3Data) {
                NSString *youtubeVideoId = mp3Data[JWDbKeyYouTubeData][JWDbKeyYouTubeDataVideoId];
                NSString *imageURLStr = mp3Data ? mp3Data[JWDbKeyYouTubeData][JWDbKeyYoutubeThumbnails][@"default"][@"url"] : nil;
                NSURL *imageURL = imageURLStr ? [NSURL URLWithString:imageURLStr] : nil;
                NSLog(@"DISPATCH %@ %@",youtubeVideoId,[imageURL absoluteString]);
                dispatch_async(_imageRetrievalQueue, ^{
                    UIImage* youtubeThumb = [UIImage imageWithData:[NSData dataWithContentsOfURL:imageURL]];
                    @synchronized(_images){
                        self.images[dbKey] = [UIImage imageWithCGImage:youtubeThumb.CGImage scale:0.25 orientation:UIImageOrientationLeft];
//                        self.images[dbKey] = youtubeThumb;
                    }
                });
            }
        }

    } else {
        
        if (_userOrderList == nil) {
            NSLog(@"%s no userlist, creating new one from dictionary keys",__func__ );
            _userOrderList = [NSMutableArray arrayWithArray:[_mp3FilesInfo allKeys]];
            
        } else {
            // add items to end of userlist that are not in
            
            for (NSString *item in [_mp3FilesInfo allKeys] ) {
                NSUInteger index = [_userOrderList indexOfObject:item];
                if (index == NSNotFound) {
                    NSLog(@"%s add new item to user list",__func__);
                    [_userOrderList addObject:item];
                }
            }
        }
        
        NSUInteger index = 0;
        for (id dbKey in _userOrderList) {
            
            id mp3DataRecord = _mp3FilesInfo[dbKey];
            //        NSLog(@"%@",[mp3DataRecord description]);
            NSString *youtubeVideoId = mp3DataRecord[JWDbKeyYouTubeData][JWDbKeyYouTubeDataVideoId];
            NSString *imageURLStr = mp3DataRecord ? mp3DataRecord[JWDbKeyYouTubeData][JWDbKeyYoutubeThumbnails][@"default"][@"url"] : nil;
            NSURL *imageURL = imageURLStr ? [NSURL URLWithString:imageURLStr] : nil;
            NSLog(@"DISPATCH %@ %@",youtubeVideoId,[imageURL absoluteString]);
            dispatch_async(_imageRetrievalQueue, ^{
                UIImage* youtubeThumb = [UIImage imageWithData:[NSData dataWithContentsOfURL:imageURL]];
                @synchronized(_images){
                    self.images[dbKey] = [UIImage imageWithCGImage:youtubeThumb.CGImage scale:1.0 orientation:UIImageOrientationUp];
//                    self.images[dbkey] = youtubeThumb;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        //NSLog(@"index %ld %@ %@",index,youtubeVideoId,[imageURL absoluteString]);
                        [self.tableView beginUpdates];
                        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]]
                                              withRowAnimation:UITableViewRowAnimationNone];
                        [self.tableView endUpdates];
                    });
                }
            });
            
            index++;
        }
        
    } // End arranged
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (_allFiles)  // all files source and downloaded mp3
        return [_allFilesSections count];
    return 1;  // one user order list
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_allFiles)
        return [_allFilesSections[section] count];
    return [_userOrderList count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"JWSourceAudioCellImage" forIndexPath:indexPath];
    NSDateFormatter *df = [NSDateFormatter new];
    UIImage* imageIcon = nil;
    NSString *fileExtension;
    
    NSString *dbKey;
    
    if (_allFiles) {
        
        NSDictionary *fileInfo =_allFilesSections[indexPath.section][indexPath.row];
        NSURL *furl = fileInfo[@"furl"];
        NSDate *createDate;
        NSError *error;
        [furl getResourceValue:&createDate forKey:NSURLCreationDateKey error:&error];

        NSString *fileSizeStr=@"";
        NSNumber *fileSz = fileInfo[@"fsize"];
        if (fileSz) {
            NSUInteger byteSize = [fileSz unsignedLongValue];
            if (byteSize > (1024 * 1024))
                fileSizeStr = [NSString stringWithFormat:@"%.2f mb",byteSize/(1024.0f * 1024.0f)];
            else if (byteSize > 1024)
                fileSizeStr = [NSString stringWithFormat:@"%.2f kb",byteSize/1024.0f];
            else
                fileSizeStr = [NSString stringWithFormat:@"%ld bytes",(unsigned long)byteSize];
        }
        fileExtension = [furl pathExtension];

        id detailText;
        id titleText = [[furl lastPathComponent] stringByDeletingPathExtension];
        if ([titleText length] > 14)
            titleText = [titleText substringToIndex:14];

        dbKey = [[JWFileController sharedInstance] dbKeyForFileName:[furl lastPathComponent]];
        
        double al = [[JWFileController sharedInstance] audioLengthForFileWithName:[furl lastPathComponent]];

        id mp3Data = [self trimmedFileReference:dbKey];
        if (mp3Data) {
            id ytData = mp3Data[JWDbKeyYouTubeData];
            id titleValue;
            if (ytData)
                titleValue = ytData[JWDbKeyYouTubeTitle];
            else
                titleValue = mp3Data[JWDbKeyVideoTitle];
            if (titleValue)
                titleText = titleValue;

            df.dateStyle = NSDateFormatterShortStyle;
            df.timeStyle = NSDateFormatterShortStyle;

            detailText = [NSString stringWithFormat:@"%@  %@", titleText,[df stringFromDate:createDate]];
            titleText = [NSString stringWithFormat:@"%.0fs .%@ %@ %@",al,fileExtension, fileSizeStr,[[furl lastPathComponent] stringByDeletingPathExtension]];
//            titleText = [NSString stringWithFormat:@"%.0fs .%@ %@ %@",al,fileExtension, fileSizeStr,[df stringFromDate:createDate]];

        } else {
            df.dateStyle = NSDateFormatterMediumStyle;
            df.timeStyle = NSDateFormatterShortStyle;

            titleText = [NSString stringWithFormat:@"%00.0fs .%@ %@",al,fileExtension, titleText];
            detailText = [NSString stringWithFormat:@"%@ %@  %@ %@", fileExtension, fileSizeStr,[df stringFromDate:createDate],
                          [[furl lastPathComponent] stringByDeletingPathExtension]];
        }

//        cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
        
        cell.textLabel.text = titleText;
        
        cell.detailTextLabel.text = detailText;
        
        
    } else {

        dbKey = _userOrderList[indexPath.row];

        df.dateStyle = NSDateFormatterShortStyle;
        df.timeStyle = NSDateFormatterMediumStyle;
        NSDate *dateCreated = _mp3FilesInfo[dbKey][JWDbKeyCreationDate];

        //        NSNumber *fileSzNumber;
//        @synchronized(_mp3filesFilesData){
//            fileSzNumber = _mp3filesFilesData[dbKey][@"fsize"];
//        }
//        
        NSString *fileSizeStr; // = [self fileSizeStr:fileSzNumber];
        if (fileSizeStr == nil)
            fileSizeStr = @"";
        
        id videoId = _mp3FilesInfo[dbKey][JWDbKeyYouTubeData][JWDbKeyYouTubeDataVideoId];
        NSURL *furl = [[JWFileController sharedInstance] fileURLForCacheItem:dbKey];
        fileExtension = [furl pathExtension];
        NSString *detailText = [NSString stringWithFormat:@"%@ %@  %@ %@",
                                videoId ? videoId : @"",
                                fileExtension,
                                [df stringFromDate:dateCreated],
                                fileSizeStr
                                ];

        //                                fileSizeStr,[_mp3FilesInfo[dbKey] valueForKey:@"linkstr"]

//        cell.textLabel.text = _mp3FilesInfo[dbKey][JWDbKeyYouTubeData][JWDbKeyYouTubeTitle];
//        cell.detailTextLabel.text = detailText;
        
        cell.textLabel.text = detailText;
        
        cell.detailTextLabel.text = _mp3FilesInfo[dbKey][JWDbKeyYouTubeData][JWDbKeyYouTubeTitle];

    }
    
    if ([self.refreshControl isRefreshing]) {
        @synchronized(_images){
            imageIcon = self.images[@"iconmusic120"];
            NSLog(@"refreshing");
        }
    } else {
        if (dbKey) {
            @synchronized(_images){
                imageIcon = self.images[dbKey];
            }
        }
        if (imageIcon== nil)
            imageIcon = self.images[@"iconmusic120"];
        //            imageIcon = [UIImage imageNamed:@"iconmusic120"];
        
    }

    
    if (_previewMode)
        cell.accessoryType = UITableViewCellAccessoryDetailButton;
    else
        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;

//    cell.accessoryView.tintColor = [UIColor blueColor];
  
    cell.tintColor = [UIColor blueColor];
    cell.imageView.image = imageIcon;

    return cell;
}


-(NSString *)fileSizeStr:(NSNumber*) fileSzNumber{
    NSString *result = nil;
    
    NSUInteger byteSize = [fileSzNumber unsignedLongLongValue];
    if (byteSize > (1024 * 1024))
        result = [NSString stringWithFormat:@"%.2f mb",byteSize/(1024.0f * 1024.0f)];
    else if (byteSize > 1024)
        result = [NSString stringWithFormat:@"%.2f kb",byteSize/1024.0f];
    else
        result = [NSString stringWithFormat:@"%ld bytes",byteSize];

    return result;
}


#pragma mark - Table view delegate

//- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
//    return 20;
//}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath{
    
    self.selectedIndexPath  = indexPath;

    NSURL *fileURL;
    if (_allFiles)
        fileURL = _allFilesSections[indexPath.section][indexPath.row][@"furl"];
    else
        fileURL = [self fileURLForCacheItem:_userOrderList[indexPath.row]];
    
    if (_previewMode) {
        // NOT Selecting to advance to Clipper, but to simply play
        // Perhaps using Detail accessory to allow the other function when preview is ON and OFF
        BOOL playUsingEngine = NO;
        // Start And Stop
        if (playUsingEngine) {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            
            // AVAudioEngine
            if (_playerNode.isPlaying)
                [_playerNode stop];
            else
                [self playFileInEngine: fileURL];
            
        } else {
            // AVPLayer
            if (_playerNode.isPlaying)
                [_playerNode stop];
            
            NSString *dbKey;
            if (_allFiles)
                dbKey = [[JWFileController sharedInstance] dbKeyForFileName:[fileURL lastPathComponent]];
            else
                dbKey = _userOrderList[indexPath.row];
            
            [self playInAvPlayerUsingKey:dbKey file:fileURL atIndexPath:indexPath];
        }
        
        // SET it as the CurrentWork item if file exists
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:[fileURL path]]) {
            [JWCurrentWorkItem sharedInstance].currentAudioFileURL = fileURL;
            [JWCurrentWorkItem sharedInstance].currentAudioOrigin = YouTubeOrigin;
            [JWCurrentWorkItem sharedInstance].timeStamp = [NSDate date];
        }
        
    } else {
        
        [JWCurrentWorkItem sharedInstance].currentAudioFileURL = fileURL;
        [JWCurrentWorkItem sharedInstance].currentAudioOrigin = YouTubeOrigin;
        if (_allFiles) {
            if (indexPath.section == 3) {
                id dbKey = [[JWFileController sharedInstance] dbKeyForFileName:[fileURL lastPathComponent]];
                self.selectedCacheItemKey = @"trimmed";
                [self finishedTrim:(id)self withDBKey:dbKey];
            } else {
                self.selectedCacheItemKey = @"source";
                [self performSegueWithIdentifier:@"JWSourceAllFilesToClipSegue" sender:self];
            }
        } else {
            self.selectedCacheItemKey = _userOrderList[indexPath.row];
            [self performSegueWithIdentifier:@"JWSourceFilesToClipSegue" sender:self];
        }
    }
}


-(void)playInAvPlayerUsingKey:(NSString*)dbKey file:(NSURL*)fileURL atIndexPath:(NSIndexPath*)indexPath {

if (_allFiles) {
    id dbKey = [[JWFileController sharedInstance] dbKeyForFileName:[fileURL lastPathComponent]];
    if (dbKey) {
        id mp3DataRecord = [self trimmedFileReference:dbKey];
        NSURL *imageURL = [self bestImageURLForMP3Record:mp3DataRecord];
        UIImage *imageIcon;
        @synchronized(_images){
            imageIcon = self.images[dbKey];
            if (imageIcon==nil) {
                imageIcon = self.images[@"iconmusic120"];
            } else {
                imageIcon = [UIImage imageWithCGImage:imageIcon.CGImage scale:1.0 orientation:UIImageOrientationUp];
            }
        }
        
        [self playFileUsingAVPlayer:fileURL image:imageIcon imageURL:imageURL];
        
    } else {
        
        UIImage *imageIcon;
        if (indexPath.section == 3) {
            @synchronized(_images){
                imageIcon = self.images[@"iconmusic120"];
            }
        } else {
            imageIcon = [UIImage imageNamed:[NSString stringWithFormat:@"jwjustscreensandlogos - %u",(1 + 1)]];
        }
        
        [self playFileUsingAVPlayer:fileURL image:imageIcon imageURL:nil];
    }
    
} else {
    NSString *dbKey = _userOrderList[indexPath.row];
    id mp3DataRecord =  _mp3FilesInfo[dbKey];
    NSURL *imageURL = [self bestImageURLForMP3Record:mp3DataRecord];
    
    [self playFileUsingAVPlayer:fileURL image:self.images[_userOrderList[indexPath.row]] imageURL:imageURL];
}

}




- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{

    NSString *titleStr;
    if (_allFiles) {
        if (section == 0)
            titleStr = [NSString stringWithFormat:@"Source Audio  %ld Files",[_allFilesSections[section] count]];
        else if (section == 1)
            titleStr = [NSString stringWithFormat:@"JamTrack Audio %ld Files",[_allFilesSections[section] count]];
        else if (section == 2)
            titleStr = [NSString stringWithFormat:@"JamTrack Downloaded %ld Files",[_allFilesSections[section] count]];
        else if (section == 3)
            titleStr = [NSString stringWithFormat:@"Trimmed Audio %ld Files",[_allFilesSections[section] count]];

    } else {
        if (_userOrderList)
            titleStr = [NSString stringWithFormat:@"Your Source Audio %ld Files",[_userOrderList count]];
        else
            titleStr = @"Your Source Audio Files";
    }
    
    return titleStr;
}


- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section  {
    UITableViewHeaderFooterView *view = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"JWHeaderViewX"];
    if (view == nil)
        view = [[UITableViewHeaderFooterView alloc] initWithReuseIdentifier:@"JWHeaderViewX"];
    view.contentView.backgroundColor = [UIColor jwBlackThemeColor];
    view.textLabel.textColor = [UIColor jwSectionTextColor];
    return view;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section  {
    UITableViewHeaderFooterView *view = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"JWHeaderViewX"];
    if (view == nil)
        view = [[UITableViewHeaderFooterView alloc] initWithReuseIdentifier:@"JWHeaderViewX"];
    view.contentView.backgroundColor = [UIColor jwBlackThemeColor];
    view.textLabel.textColor = [UIColor jwSectionTextColor];
    view.textLabel.font = [UIFont systemFontOfSize:14];
    return view;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {

        if (_allFiles) {
            // Delete the row from the data source
            NSError *error;
            [[NSFileManager defaultManager] removeItemAtURL:_allFilesSections[indexPath.section][indexPath.row][@"furl"] error:&error];
//            [(NSMutableArray*)_allFilesSections[indexPath.section] removeObjectAtIndex:indexPath.row];
            [[JWFileController sharedInstance] readFsData];
            _allFilesSections = @[
                                  [[JWFileController sharedInstance] sourceFiles],
                                  [[JWFileController sharedInstance] jamTrackFiles],
                                  [[JWFileController sharedInstance] downloadedJamTrackFiles],
                                  [[JWFileController sharedInstance] trimmedFiles]
                                  ];
        } else {
            
            // Delete the row from the data source
            // Deletes the mp3 file
            NSError *error;
            [[NSFileManager defaultManager] removeItemAtURL:[self fileURLForCacheItem:_userOrderList[indexPath.row]] error:&error];
            
            // We delete from UserList
            // TODO: do we delete from _mp3FileInfo also?  otherwise it gets added back at startup
            BOOL deleteInfoToo = YES;
            if (deleteInfoToo) {
                [_mp3FilesInfo removeObjectForKey:_userOrderList[indexPath.row]];
                [[JWFileController sharedInstance] saveMeta];
            }
            
            [_userOrderList removeObjectAtIndex:indexPath.row];
            [[JWFileController sharedInstance] saveUserList];
        }
        
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
     
     id moveObject = _userOrderList[fromIndexPath.row];
     [_userOrderList removeObjectAtIndex:fromIndexPath.row];
     [_userOrderList insertObject:moveObject atIndex:toIndexPath.row];
     [[JWFileController sharedInstance] saveUserList];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    self.selectedDetailIndexPath = indexPath;
    [self detailOptions];
}

#pragma mark - Detail

-(void)detailOptions {
    
    NSString *title;
    NSMutableString *message = [NSMutableString new];
    
    NSURL *fileURL;
    if (_allFiles)
        fileURL = _allFilesSections[_selectedDetailIndexPath.section][_selectedDetailIndexPath.row][@"furl"];
    else
        fileURL = [self fileURLForCacheItem:_userOrderList[_selectedDetailIndexPath.row]];
    
    if (_previewMode) {
        title = @"Mode: Preview";
        [message appendString:@"Select row to listen to audio"];
    } else {
        title = @"Mode: Select";
        [message appendString:@"Select row to proceed with audio file"];
    }
    
//    [message appendString:@"\n\n"];
//    [message appendString:[fileURL pathExtension]];
//    [message appendString:@"\n"];
//    [message appendString:[[fileURL lastPathComponent] stringByDeletingPathExtension]];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[fileURL path]]) {
        [message appendString:@"\nFile Exists"];
    } else {
        [message appendString:@"\nFile does not exist."];
    }
    
    UIAlertController* actionController =
    [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleActionSheet];

    UIAlertAction* cancelAction =
    [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction* action) {
    }];

    UIAlertAction* useAction =
    [UIAlertAction actionWithTitle:@"Use in New Track" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
        
        NSURL *fileURL;
        if (_allFiles)
            fileURL = _allFilesSections[_selectedDetailIndexPath.section][_selectedDetailIndexPath.row][@"furl"];
        else
            fileURL = [self fileURLForCacheItem:_userOrderList[_selectedDetailIndexPath.row]];
        
        [JWCurrentWorkItem sharedInstance].currentAudioFileURL = fileURL;
        [JWCurrentWorkItem sharedInstance].currentAudioOrigin = YouTubeOrigin;
        if (_allFiles) {
            if (_selectedDetailIndexPath.section == 3) {
                id dbKey = [[JWFileController sharedInstance] dbKeyForFileName:[fileURL lastPathComponent]];
                self.selectedCacheItemKey = @"trimmed";
                [self finishedTrim:(id)self withDBKey:dbKey];
            } else {
                self.selectedCacheItemKey = @"source";
                [self performSegueWithIdentifier:@"JWSourceAllFilesToClipSegue" sender:self];
            }
        } else {
            self.selectedCacheItemKey = _userOrderList[_selectedDetailIndexPath.row];
            [self performSegueWithIdentifier:@"JWSourceFilesToClipSegue" sender:self];
        }

    }];
    
    UIAlertAction* listenAction =
    [UIAlertAction actionWithTitle:@"Listen" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
        
        //        [self tableView:self.tableView didSelectRowAtIndexPath:_selectedDetailIndexPath];
        NSURL *fileURL;
        if (_allFiles)
            fileURL = _allFilesSections[_selectedDetailIndexPath.section][_selectedDetailIndexPath.row][@"furl"];
        else
            fileURL = [self fileURLForCacheItem:_userOrderList[_selectedDetailIndexPath.row]];
        
        BOOL playUsingEngine = NO;
        if (playUsingEngine) {
            [self playFileInEngine: fileURL];
        } else {
            // AVPLayer
            NSString *dbKey;
            if (_allFiles) {
                dbKey = [[JWFileController sharedInstance] dbKeyForFileName:[fileURL lastPathComponent]];
            } else {
                dbKey = _userOrderList[_selectedDetailIndexPath.row];
            }
            
            [self playInAvPlayerUsingKey:dbKey file:fileURL atIndexPath:_selectedDetailIndexPath];
        }
        
    }];
    
    UIAlertAction* moreInfo =
    [UIAlertAction actionWithTitle:@"More Information" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
        [self namePrompt];
    }];

    [actionController addAction:listenAction];
    [actionController addAction:useAction];
    [actionController addAction:moreInfo];
    [actionController addAction:cancelAction];

    [self presentViewController:actionController animated:YES completion:nil];
}




-(void)namePrompt {

    NSString *title;
    NSMutableString *message = [NSMutableString new];
    
    NSURL *fileURL;
    if (_allFiles)
        fileURL = _allFilesSections[_selectedDetailIndexPath.section][_selectedDetailIndexPath.row][@"furl"];
    else
        fileURL = [self fileURLForCacheItem:_userOrderList[_selectedDetailIndexPath.row]];
    
    if (_previewMode) {
        title = @"Mode: Preview";
        [message appendString:@"Select row to listen to audio"];
    } else {
        title = @"Mode: Select";
        [message appendString:@"Select row to proceed with audio file"];
    }

    [message appendString:@"\n\n"];
    [message appendString:[fileURL pathExtension]];
    [message appendString:@"\n"];
    [message appendString:[[fileURL lastPathComponent] stringByDeletingPathExtension]];

    if ([[NSFileManager defaultManager] fileExistsAtPath:[fileURL path]]) {
        [message appendString:@"\nFile Exists"];
    } else {
        [message appendString:@"\nFile does not exist."];
    }
    
    UIAlertController* actionController =
    [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* okAction =
    [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction* action) {
        self.selectedDetailIndexPath = nil;
    }];
    
    [actionController addAction:okAction];
    [self presentViewController:actionController animated:YES completion:nil];
}


#pragma mark -

-(void)playFileUsingAVPlayer:(NSURL*)audioFile {
    [self playFileUsingAVPlayer:audioFile image:nil imageURL:nil];
}

-(void)playFileUsingAVPlayer:(NSURL*)audioFile image:(UIImage*)image imageURL:(NSURL*)imageURL {

    //    NSLog(@"%s %@",__func__,[audioFile lastPathComponent]);
    AVPlayer *myPlayer = [AVPlayer playerWithURL:audioFile];
    myPlayer.volume  = 0.75;
    AVPlayerViewController *playerViewController = [[AVPlayerViewController alloc] init];
    playerViewController.player = myPlayer;
    playerViewController.showsPlaybackControls = YES;

    playerViewController.view.hidden = YES;
//    playerViewController.contentOverlayView.hidden = YES;

    [self presentViewController:playerViewController animated:NO completion:^{

        [myPlayer play];

        CGRect fr = CGRectMake(0, 0,
                               playerViewController.view.bounds.size.width,
                               playerViewController.view.bounds.size.height);
//        CGRect fr = CGRectMake(0, 0,
//                               self.view.frame.size.width,
//                               self.view.frame.size.height);
//        //    playerViewController.view.bounds.size.width,
//        //    playerViewController.view.bounds.size.height);
        UIView *back = [[UIView alloc] initWithFrame:fr];
        back.backgroundColor = [UIColor blackColor];
        back.autoresizingMask =
        UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin |
        UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        back.translatesAutoresizingMaskIntoConstraints = true;
        
        [playerViewController.contentOverlayView addSubview:back];
        playerViewController.contentOverlayView.hidden = NO;
        playerViewController.view.hidden = NO;

        UIImageView *iv1;
        if (image) {
            iv1 = [[UIImageView alloc] initWithImage:image];
            iv1.backgroundColor = [UIColor blackColor];
            iv1.contentMode = UIViewContentModeScaleAspectFit;
            iv1.frame = fr;
            iv1.autoresizingMask =
            UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin |
            UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            iv1.translatesAutoresizingMaskIntoConstraints = true;

            [playerViewController.contentOverlayView addSubview:iv1];
        }

        if (imageURL) {
            NSLog(@"DISPATCH retrieve %@",[imageURL absoluteString]);
            dispatch_async(_imageRetrievalQueue, ^{
                UIImage* youtubeThumb = [UIImage imageWithData:[NSData dataWithContentsOfURL:imageURL]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIImageView *iv = [[UIImageView alloc] initWithImage:youtubeThumb];
                    iv.backgroundColor = [UIColor clearColor];
                    iv.contentMode = UIViewContentModeScaleAspectFit;
                    iv.frame = fr;
                    iv.autoresizingMask =
                    UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin |
                    UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                    iv.translatesAutoresizingMaskIntoConstraints = true;
                    iv.alpha = 0.0;
                    iv.transform = CATransform3DGetAffineTransform(CATransform3DMakeScale(1.1, 1.1, 1.0));

                    [playerViewController.contentOverlayView addSubview:iv];

//                    [UIView animateWithDuration:1.0 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
//                        iv1.alpha = 0.0;
//                    } completion:^(BOOL fini){
//                    }];
//                    [UIView animateWithDuration:1.4 delay:0.650 options:UIViewAnimationOptionCurveEaseIn animations:^{
//                        iv.alpha = 1.0;
//                    } completion:^(BOOL fini){
//                    }];
                    
                    iv1.alpha = 0.0;
                    iv.alpha = 1.0;

                    CGPoint center1 = iv.center;
                    center1.y += 12;
                    CGPoint center2 = center1;
                    center2.y += 20;

                    [UIView animateWithDuration:5.0 delay:0.5
                                        options:UIViewAnimationOptionCurveEaseIn
                                     animations:^{
                                         iv.transform = CATransform3DGetAffineTransform(CATransform3DMakeScale(1.85, 1.85, 1.0));
                                         iv.center = center1;
                                     } completion:^(BOOL fini){
                                         [UIView animateWithDuration:0.50 delay:0.25
                                                             options:UIViewAnimationOptionCurveEaseOut
                                                          animations:^{
                                                              CGPoint center = iv.center;
                                                              center.y += 16;
                                                              iv.transform = CATransform3DGetAffineTransform(CATransform3DMakeScale(1.4, 1.4, 1.0));
                                                              iv.center = center;
                                                              // iv.transform = CATransform3DGetAffineTransform(CATransform3DIdentity);
                                                          } completion:^(BOOL fini){}];
                                     }];
                    
                });
            });
        } // imag URL
        
    }];
}


-(void)playFileInEngine:(NSURL*)audioFile {
    
    _audioEngine = [AVAudioEngine new];
    AVAudioPlayerNode *player = [AVAudioPlayerNode new];
    [_audioEngine attachNode:player];
    
    NSError *error;
    AVAudioFile *file = [[AVAudioFile alloc] initForReading:audioFile error:&error];
    AVAudioMixerNode *mainMixer = [_audioEngine mainMixerNode];
    
    [_audioEngine connect:player to:mainMixer format:file.processingFormat];
    error = nil;
    [_audioEngine startAndReturnError:&error];
    mainMixer.volume = 0.6;
    // attime nil play immediately
    [player scheduleFile:file atTime:nil completionHandler:nil];
    _playerNode = player;
    [player play];
}


#pragma mark - AVAudioSession

- (void)initAVAudioSession
{
    // For complete details regarding the use of AVAudioSession see the AVAudioSession Programming Guide
    // https://developer.apple.com/library/ios/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/Introduction/Introduction.html
    
    // Configure the audio session
    AVAudioSession *sessionInstance = [AVAudioSession sharedInstance];
    NSError *error;
    // set the session category
    bool success = [sessionInstance setCategory:AVAudioSessionCategoryPlayback
                                    withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker
                                          error:&error];

    if (!success) NSLog(@"Error setting AVAudioSession category! %@\n", [error localizedDescription]);
    
    double hwSampleRate = 44100.0;
    success = [sessionInstance setPreferredSampleRate:hwSampleRate error:&error];
    if (!success) NSLog(@"Error setting preferred sample rate! %@\n", [error localizedDescription]);
    
    NSTimeInterval ioBufferDuration = 0.0029;
    success = [sessionInstance setPreferredIOBufferDuration:ioBufferDuration error:&error];
    if (!success) NSLog(@"Error setting preferred io buffer duration! %@\n", [error localizedDescription]);
}


#pragma mark -

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"JWSourceFilesToClipSegue"]) {

        JWClipAudioViewController *clipController = (JWClipAudioViewController*)segue.destinationViewController;

        NSString *dbKey = _userOrderList[_selectedIndexPath.row];

        UIImage* youtubeImage = self.images[dbKey];
        NSString *title;

        id mp3DataRecord = _mp3FilesInfo[dbKey];
        if (mp3DataRecord) {
            title = [self preferredTitleForMP3Record:mp3DataRecord];
        } else {
            title = @"";
        }

        clipController.trackName = title;
        clipController.thumbImage = youtubeImage;  // start with the thumb

        // Get a Higherresolution and deliver when available dont delay presentation by waiting for the image to download

        id urlStr;
//        urlStr = mp3DataRecord[JWDbKeyYouTubeData][JWDbKeyYoutubeThumbnails][@"maxres"][@"url"];
        urlStr = mp3DataRecord[JWDbKeyYouTubeData][JWDbKeyYoutubeThumbnails][@"high"][@"url"];
        if (!urlStr)
            urlStr = mp3DataRecord[JWDbKeyYouTubeData][JWDbKeyYoutubeThumbnails][@"medium"][@"url"];
        
        NSURL *imageURL = urlStr ? [NSURL URLWithString:urlStr] : nil;
        if (imageURL) {
            NSLog(@"DISPATCH %@",[imageURL absoluteString]);
            dispatch_async(_imageRetrievalQueue, ^{
                UIImage* youtubeThumb = [UIImage imageWithData:[NSData dataWithContentsOfURL:imageURL]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    clipController.thumbImage = youtubeThumb;
                });
            });
        }
        
        clipController.delegate = self;

    } else if ([segue.identifier isEqualToString:@"JWSourceAllFilesToClipSegue"]) {
        
        JWClipAudioViewController *clipController = (JWClipAudioViewController*)segue.destinationViewController;
        
        NSURL *fileURL = _allFilesSections[_selectedIndexPath.section][_selectedIndexPath.row][@"furl"];
        
        clipController.trackName = [fileURL lastPathComponent];
        clipController.delegate = self;
    }
}



//
//
//NSURL *fileURL;
//NSString *title;
//UIImage *imageIcon;
//
//if (_allFiles) {
//    id dbKey = [[JWFileController sharedInstance] dbKeyForFileName:[fileURL lastPathComponent]];
//    if (dbKey) {
//        id mp3DataRecord = [self trimmedFileReference:dbKey];
//        NSURL *imageURL = [self bestImageURLForMP3Record:mp3DataRecord];
//        @synchronized(_images){
//            imageIcon = self.images[dbKey];
//            if (imageIcon==nil) {
//                imageIcon = self.images[@"iconmusic120"];
//            } else {
//                imageIcon = [UIImage imageWithCGImage:imageIcon.CGImage scale:1.0 orientation:UIImageOrientationUp];
//            }
//        }
//        
//    } else {
//        
//        UIImage *imageIcon;
//        if (indexPath.section == 3) {
//            @synchronized(_images){
//                imageIcon = self.images[@"iconmusic120"];
//            }
//        } else {
//            imageIcon = [UIImage imageNamed:[NSString stringWithFormat:@"jwjustscreensandlogos - %u",(1 + 1)]];
//        }
//    }
//    
//} else {
//    
//    NSString *dbKey = _userOrderList[_selectedIndexPath.row];
//    UIImage* youtubeImage = self.images[dbKey];
//    
//    id mp3DataRecord = _mp3FilesInfo[dbKey];
//    NSString *title = mp3DataRecord ? mp3DataRecord[JWDbKeyYouTubeData][JWDbKeyYouTubeTitle] : @"unknown";
//    
//    
//    
//    NSString *dbKey = _userOrderList[indexPath.row];
//    id mp3DataRecord =  _mp3FilesInfo[dbKey];
//    NSURL *imageURL = [self bestImageURLForMP3Record:mp3DataRecord];
//    
//    [self playFileUsingAVPlayer:fileURL image:self.images[_userOrderList[indexPath.row]] imageURL:imageURL];
//}
//
//
//
//
//
//NSURL *fileURL;
//NSString *title;
//
//UIImage* image;
//
//if (_allFiles) {
//    
//    fileURL = _allFilesSections[_selectedIndexPath.section][_selectedIndexPath.row][@"furl"];
//    if ([_selectedCacheItemKey isEqualToString:@"source"]) {
//        title = [[fileURL lastPathComponent] stringByDeletingPathExtension];
//        
//    } else if ([_selectedCacheItemKey isEqualToString:@"trimmed"]) {
//        title = [self preferredTitleForFile:fileURL];
//        id mp3Data = [self trimmedFileReference:key];
//        if (mp3Data)
//            title = [self preferredTitleForMP3Record:mp3Data];
//    }
//    
//} else {
//    
//    NSString *dbKey = _userOrderList[_selectedIndexPath.row];
//    UIImage* youtubeImage = self.images[dbKey];
//    
//    id mp3DataRecord = _mp3FilesInfo[dbKey];
//    NSString *title = mp3DataRecord ? mp3DataRecord[JWDbKeyYouTubeData][JWDbKeyYouTubeTitle] : @"unknown";
//    
//    //            mp3DataRecord = _mp3FilesInfo[_selectedCacheItemKey];
//    //            if (mp3DataRecord == nil) {
//    //                NSLog(@"arranged wo mp3record ODD in func %s key %@",__func__,key);
//    //                fileURL = [self fileURLForCacheItem:_userOrderList[_selectedIndexPath.row]];
//    //                title = [self preferredTitleForFile:fileURL];
//    //            }
//}
//
//


#pragma mark - JWCLipAudioViewDelegate


// helper
-(id)trimmedFileReference:(NSString*)dbKey {

    __block id result;
    [_mp3FilesInfo enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {

        id trimmedFilesValue = obj[@"trimmedfilekeys"];
        if (trimmedFilesValue) {
            for (id trimId in trimmedFilesValue) {
                if ([trimId isEqualToString:dbKey]) {
                    result = obj;
                    *stop = YES;
                }
            }
        }
    }];

    return result;
}


-(NSString*)preferredTitleForMP3Record:(id)mp3Data {
    
    NSString *result;
    id ytData = mp3Data[JWDbKeyYouTubeData];
    id titleValue;
    if (ytData)
        titleValue = ytData[JWDbKeyYouTubeTitle];
    else
        titleValue = mp3Data[JWDbKeyVideoTitle];
    if (titleValue)
        result = titleValue;
    return result;
}

-(NSString*)preferredTitleForFile:(NSURL*)fileURL {

    NSString *result;
    result = [[fileURL lastPathComponent] stringByDeletingPathExtension];
    if (result.length > 10)
        result = [result substringToIndex:10];
    return result;
}

// passes the new key for the trimmed files
//-(void)finishedTrim:(JWClipAudioViewController *)controller withDBKey:(NSString*)key {

-(void)finishedTrim:(id)controller withDBKey:(NSString*)key {

    NSString *title;
    NSURL *fileURL;
    
    id mp3DataRecord;
    
    if (_allFiles) {

        fileURL = _allFilesSections[_selectedIndexPath.section][_selectedIndexPath.row][@"furl"];
        if ([_selectedCacheItemKey isEqualToString:@"source"]) {
            title = [[fileURL lastPathComponent] stringByDeletingPathExtension];
            
        } else if ([_selectedCacheItemKey isEqualToString:@"trimmed"]) {
            title = [self preferredTitleForFile:fileURL];
            id mp3Data = [self trimmedFileReference:key];
            if (mp3Data)
                title = [self preferredTitleForMP3Record:mp3Data];
        }
        
    } else {
        mp3DataRecord = _mp3FilesInfo[_selectedCacheItemKey];
        if (mp3DataRecord == nil) {
            NSLog(@"arranged wo mp3record ODD in func %s key %@",__func__,key);
            fileURL = [self fileURLForCacheItem:_userOrderList[_selectedIndexPath.row]];
            title = [self preferredTitleForFile:fileURL];
        }
    }
    
    if (mp3DataRecord) {
        id trimmedFilesValue = mp3DataRecord[@"trimmedfilekeys"];
        if (trimmedFilesValue)
            [(NSMutableArray*)trimmedFilesValue addObject:key];
        else
            mp3DataRecord[@"trimmedfilekeys"] = [@[key] mutableCopy];
        
        [[JWFileController sharedInstance] saveMeta];

        title = [self preferredTitleForMP3Record:mp3DataRecord];
    }

    if ([_delegate respondsToSelector:@selector(finishedTrim:title:withDBKey:)])
        [_delegate finishedTrim:self title:title withDBKey:key];

}


#pragma mark helpers

-(NSURL*)bestImageURLForMP3Record:(NSDictionary*)mp3DataRecord {
    if (mp3DataRecord == nil) {
        return nil;
    }
    id urlStr;
    //    urlStr = mp3DataRecord[JWDbKeyYoutubeThumbnailMaxres];
    //    if (!urlStr)
    urlStr = mp3DataRecord[JWDbKeyYoutubeThumbnailHigh];
    if (!urlStr)
        urlStr = mp3DataRecord[JWDbKeyYoutubeThumbnailMedium];
    if (!urlStr)
        urlStr = mp3DataRecord[JWDbKeyYoutubeThumbnailDefault];
    
    //    urlStr = mp3DataRecord[JWDbKeyYouTubeData][JWDbKeyYoutubeThumbnails][@"high"][@"url"];
    //        urlStr = mp3DataRecord[JWDbKeyYouTubeData][JWDbKeyYoutubeThumbnails][@"medium"][@"url"];
    //        urlStr = mp3DataRecord[JWDbKeyYouTubeData][JWDbKeyYoutubeThumbnails][@"medium"][@"url"];
    
    NSURL *imageURL = urlStr ? [NSURL URLWithString:urlStr] : nil;
//    NSLog(@"%s %@",__func__,[imageURL absoluteString]);
    return imageURL;
}


// FILE Helpers
-(NSString*)documentsDirectoryPath {
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [searchPaths objectAtIndex:0];
}

-(NSURL *)fileURLForCacheItem:(NSString*)dbkey {
    NSURL *result;
    NSString *thisfName = @"mp3file";
    NSString *thisName = [NSString stringWithFormat:@"%@_%@.mp3",thisfName,dbkey?dbkey:@""];
    NSMutableString *fname = [[self documentsDirectoryPath] mutableCopy];
    [fname appendFormat:@"/%@",thisName];
    //    NSLog(@"%s %@",__func__,fname);  // directory
    result = [NSURL fileURLWithPath:fname];
//    NSLog(@"%s FileName: %@",__func__,[result lastPathComponent]);
    return result;
}
-(void)fileSystemInfo {

    NSUInteger index = 0;
    for (id dbkey in _userOrderList) {
        NSLog(@"DISPATCH fileinfo %@",[[self fileURLForCacheItem:dbkey] lastPathComponent]);
        dispatch_async(_imageRetrievalQueue, ^{
            id fileInfo = [self fileSystemInfoForCacheItem:dbkey];
            if (fileInfo) {
                @synchronized(_mp3filesFilesData){
                    _mp3filesFilesData[dbkey] = fileInfo;
                }
            }
//            NSLog(@"%ld fileinfo",index);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView beginUpdates];
                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]]
                                      withRowAnimation:UITableViewRowAnimationNone];
                [self.tableView endUpdates];
            });
        });
        
        index++;
    }
}

-(NSDictionary *)fileSystemInfoForCacheItem:(NSString*)dbkey{
    NSDictionary *result = nil;
    NSURL *fileURL = [self fileURLForCacheItem:dbkey];
    NSError *error;
    NSDictionary *info = [[NSFileManager defaultManager] attributesOfItemAtPath:[fileURL path] error:&error];
//    NSLog(@"%s attributesOfItemAtPath %@",__func__,[fileURL lastPathComponent]);
    if (info && !error)
        result = @{@"furl":fileURL,@"fsize":info[NSFileSize]};
    return result;
}

@end







