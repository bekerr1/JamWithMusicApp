//
//  JWSourceAudioFilesTableViewController.m
//  JamWIthT
//
//  Created by JOSEPH KERR on 10/4/15.
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

@end


@implementation JWSourceAudioFilesTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.clearsSelectionOnViewWillAppear = NO;
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    if (_imageRetrievalQueue == nil) {
        _imageRetrievalQueue =
        dispatch_queue_create("imageProcessingSourceAudio",
                              dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_CONCURRENT,QOS_CLASS_UTILITY, 0));
    }
    if (_allFiles)
        _allFilesSections = @[@[],@[]];  // 2 empties

    [self loadData];

}

//-(void)viewWillAppear:(BOOL)animated {
//    [super viewWillAppear:animated];
//}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Call the Load data , not at viewDidload, here after the view has appeared
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
    [self saveUserOrderedList];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view content

// A listener when other update mp3Info
-(void)mp3InfoHasBeenUpadated:(NSNotification*)noti
{
    [self loadData];
}


- (void)loadData {
    
    _mp3FilesInfo = [[JWFileController sharedInstance] mp3FilesInfo];

    _mp3filesFilesData = [NSMutableDictionary new];  // fs info

    self.images = [@{} mutableCopy];

    [[JWFileController sharedInstance] readFsData];
    
    if (_allFiles) {
        _allFilesSections = @[
                              [[JWFileController sharedInstance] sourceFiles],
                              [[JWFileController sharedInstance] jamTrackFiles],
                              [[JWFileController sharedInstance] downloadedJamTrackFiles]
                              ];

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
        
        for (id dbkey in _userOrderList) {
            
            id mp3DataRecord = _mp3FilesInfo[dbkey];
            
            //        NSLog(@"%@",[mp3DataRecord description]);
            NSString *youtubeVideoId = mp3DataRecord[JWDbKeyYouTubeData][JWDbKeyYouTubeDataVideoId];
            NSString *imageURLStr = mp3DataRecord ? mp3DataRecord[JWDbKeyYouTubeData][JWDbKeyYoutubeThumbnails][@"default"][@"url"] : nil;
            NSURL *imageURL = imageURLStr ? [NSURL URLWithString:imageURLStr] : nil;
            
            NSLog(@"DISPATCH %@ %@",youtubeVideoId,[imageURL absoluteString]);
            
            dispatch_async(_imageRetrievalQueue, ^{
                UIImage* youtubeThumb = [UIImage imageWithData:[NSData dataWithContentsOfURL:imageURL]];
                @synchronized(_images){
                    self.images[dbkey] = youtubeThumb;
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    //NSLog(@"index %ld %@ %@",index,youtubeVideoId,[imageURL absoluteString]);
                    
                    [self.tableView beginUpdates];
                    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]]
                                          withRowAnimation:UITableViewRowAnimationFade];
                    [self.tableView endUpdates];
                });
            });
            
            index++;
        }


        
    }

    

    [self.tableView reloadData];

    return;
    
//    [self readMetaData];
//    [self readUserOrderedList];
//    _mp3filesFilesData = [NSMutableDictionary new];

//    if (_userOrderList == nil) {
//        NSLog(@"%s no userlist, creating new one from dictionary keys",__func__ );
//        _userOrderList = [NSMutableArray arrayWithArray:[_mp3FilesInfo allKeys]];
//        
//    } else {
//        // add items to end of userlist that are not in
//        
//        for (NSString *item in [_mp3FilesInfo allKeys] ) {
//            NSUInteger index = [_userOrderList indexOfObject:item];
//            if (index == NSNotFound) {
//                NSLog(@"%s add new item to user list",__func__);
//                [_userOrderList addObject:item];
//            }
//        }
//    }
//    [self.tableView reloadData];

    // Get the images and file Info Asynchrounously dont delay

//    [self fileSystemInfo];
//
//    self.images = [@{} mutableCopy];
    
    
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
    
    if (_allFiles) {
        NSDictionary *fileInfo =_allFilesSections[indexPath.section][indexPath.row];
        NSURL *furl = fileInfo[@"furl"];
        NSDate *createDate;
        NSError *error;
        [furl getResourceValue:&createDate forKey:NSURLCreationDateKey error:&error];
        
        df.dateStyle = NSDateFormatterMediumStyle;
        df.timeStyle = NSDateFormatterShortStyle;
        
        NSString *fileSizeStr;
        NSNumber *fileSz = fileInfo[@"fsize"];
        if (fileSz) {
            NSUInteger byteSize = [fileSz unsignedLongLongValue];
            
            if (byteSize > (1024 * 1024))
                fileSizeStr = [NSString stringWithFormat:@"%.2f mb",byteSize/(1024.0f * 1024.0f)];
            else if (byteSize > 1024)
                fileSizeStr = [NSString stringWithFormat:@"%.2f kb",byteSize/1024.0f];
            else
                fileSizeStr = [NSString stringWithFormat:@"%ld bytes",byteSize];
            
        } else {
            fileSizeStr = @"";
        }
        
        fileExtension = [furl pathExtension];
        
        cell.textLabel.text = [furl lastPathComponent];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@  %@",
                                     fileExtension, [df stringFromDate:createDate], fileSizeStr];
        
        imageIcon = [UIImage imageNamed:@"iconmusic120pad"];
        
    } else {
        
        df.dateStyle = NSDateFormatterShortStyle;
        df.timeStyle = NSDateFormatterMediumStyle;

        NSString *dbKey = _userOrderList[indexPath.row];
        
        NSDate *dateCreated = _mp3FilesInfo[dbKey][JWDbKeyCreationDate];
        @synchronized(_images){
            imageIcon = self.images[dbKey];
        }
        if (imageIcon== nil)
            imageIcon = [UIImage imageNamed:@"iconmusic120"];

        //        NSNumber *fileSzNumber;
//        @synchronized(_mp3filesFilesData){
//            fileSzNumber = _mp3filesFilesData[dbKey][@"fsize"];
//        }
//        
        NSString *fileSizeStr; // = [self fileSizeStr:fileSzNumber];
        if (fileSizeStr == nil)
            fileSizeStr = @"";
        
        NSURL *furl = [[JWFileController sharedInstance] fileURLForCacheItem:dbKey];
        fileExtension = [furl pathExtension];

        cell.textLabel.text = _mp3FilesInfo[dbKey][JWDbKeyYouTubeData][JWDbKeyYouTubeTitle];
        
        NSString *detailText = [NSString stringWithFormat:@"%@ %@  %@ %@",
                                fileExtension,
                                [df stringFromDate:dateCreated],
                                fileSizeStr,[_mp3FilesInfo[dbKey] valueForKey:@"linkstr"]];
        
        cell.detailTextLabel.text = detailText;
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return 50;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath{
    
    NSURL *fileURL;
    if (_allFiles) {
        fileURL = _allFilesSections[indexPath.section][indexPath.row][@"furl"];
    } else {
        fileURL = [self fileURLForCacheItem:_userOrderList[indexPath.row]];
    }
    self.selectedIndexPath  = indexPath;
    
    if (_previewMode) {
        // NOT Selecting to advance to Clipper, but to simply play
        // Perhaps using Detail accessory to allow the other function when preview is ON and OFF
        BOOL playUsingEngine = NO;
        
        // Start And Stop

        if (playUsingEngine) {
            
            [tableView deselectRowAtIndexPath:indexPath animated:YES];

            // AVAudioEngine
            if (_playerNode.isPlaying) {
                [_playerNode stop];
            } else {
                [self playFileInEngine: fileURL];
            }
            
        } else {
            // AVPLayer
            if (_playerNode.isPlaying) {
                [_playerNode stop];
            }
            
            [self playFileUsingAVPlayer:fileURL];
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
            self.selectedCacheItemKey = @"source";
            [self performSegueWithIdentifier:@"JWSourceAllFilesToClipSegue" sender:self];
        } else {
            self.selectedCacheItemKey = _userOrderList[indexPath.row];
            [self performSegueWithIdentifier:@"JWSourceFilesToClipSegue" sender:self];

        }

    }
    
}


- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    NSString *titleStr;

    if (_allFiles) {
        if (section == 0) {
            titleStr = [NSString stringWithFormat:@"Source Audio  %ld Files",[_allFilesSections[section] count]];
        } else if (section == 1) {
            titleStr = [NSString stringWithFormat:@"JamTrack Audio %ld Files",[_allFilesSections[section] count]];
        } else if (section == 2) {
            titleStr = [NSString stringWithFormat:@"JamTrack Downloaded %ld Files",[_allFilesSections[section] count]];
        }
        
    } else {
        if (_userOrderList) {
            titleStr = [NSString stringWithFormat:@"Your Source Audio %ld Files",[_userOrderList count]];
        } else {
            titleStr = @"Your Source Audio Files";
        }
    }
    return titleStr;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

// Override to support editing the table view.
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
                                  [[JWFileController sharedInstance] downloadedJamTrackFiles]
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
                [self saveMetaData];
            }
            [_userOrderList removeObjectAtIndex:indexPath.row];
            
            [self saveUserOrderedList];
        }
        

        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
     
     id moveObject = _userOrderList[fromIndexPath.row];
     
     [_userOrderList removeObjectAtIndex:fromIndexPath.row];
     [_userOrderList insertObject:moveObject atIndex:toIndexPath.row];
     
     [self saveUserOrderedList];
 }

// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}


#pragma mark -

-(void)playFileUsingAVPlayer:(NSURL*)audioFile {
    NSLog(@"%s %@",__func__,[audioFile lastPathComponent]);
    
    AVPlayer *myPlayer = [AVPlayer playerWithURL:audioFile];
    AVPlayerViewController *playerViewController = [[AVPlayerViewController alloc] init];
    playerViewController.player = myPlayer;
    
    playerViewController.showsPlaybackControls = YES;
    [self presentViewController:playerViewController animated:NO completion:^{
        [myPlayer play];
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

#pragma mark -

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSLog(@"%s",__func__);
    
//    JWSourceAllFilesToClipSegue
    if ([segue.identifier isEqualToString:@"JWSourceFilesToClipSegue"]) {

        JWClipAudioViewController *clipController = (JWClipAudioViewController*)segue.destinationViewController;

        NSString *dbKey = _userOrderList[_selectedIndexPath.row];
        UIImage* youtubeImage = self.images[dbKey];

        id mp3DataRecord = _mp3FilesInfo[dbKey];
        NSString *title = mp3DataRecord ? mp3DataRecord[JWDbKeyYouTubeData][JWDbKeyYouTubeTitle] : @"unknown";
        
        clipController.trackName = title;
        clipController.thumbImage = youtubeImage;  // start with the thumb

        // Get a Higherresolution and deliver when available dont delay presentation by waiting for the image to download

        id urlStr;
//        urlStr = mp3DataRecord[JWDbKeyYouTubeData][JWDbKeyYoutubeThumbnails][@"maxres"][@"url"];
        urlStr = mp3DataRecord[JWDbKeyYouTubeData][JWDbKeyYoutubeThumbnails][@"high"][@"url"];
        if (!urlStr)
            urlStr = mp3DataRecord[JWDbKeyYouTubeData][JWDbKeyYoutubeThumbnails][@"medium"][@"url"];
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


#pragma mark - JWCLipAudioViewDelegate

// passes the new key for the trimmed files
-(void)finishedTrim:(JWClipAudioViewController *)controller withDBKey:(NSString*)key {
    
    NSString *title;
    NSURL *fileURL;
    id mp3DataRecord = _mp3FilesInfo[_selectedCacheItemKey];
    if (mp3DataRecord) {
        id trimmedFilesValue = mp3DataRecord[@"trimmedfilekeys"];
        if (trimmedFilesValue){
            [(NSMutableArray*)trimmedFilesValue addObject:key];
        } else {
            mp3DataRecord[@"trimmedfilekeys"] = [@[key] mutableCopy];
        }
        
        id ytData = mp3DataRecord[JWDbKeyYouTubeData];
        if (ytData) {
            id titleValue = ytData[JWDbKeyYouTubeTitle];
            if (titleValue)
                title = titleValue;
        }
        
    } else {
  
        if (_allFiles) {
            fileURL = _allFilesSections[_selectedIndexPath.section][_selectedIndexPath.row][@"furl"];
            title = [[fileURL lastPathComponent] stringByDeletingPathExtension];
        } else {
            fileURL = [self fileURLForCacheItem:_userOrderList[_selectedIndexPath.row]];
        }
    }


    if ([_delegate respondsToSelector:@selector(finishedTrim:title:withDBKey:)]) {
        [_delegate finishedTrim:self title:title withDBKey:key];
    }

}


#pragma mark helpers

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
                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
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

#pragma mark save and retrieve

-(void)saveMetaData {
    [_mp3FilesInfo writeToURL:[NSURL fileURLWithPath:
                               [[self documentsDirectoryPath] stringByAppendingPathComponent:(NSString*)JWDbKeyMP3InfoFileName]]
                   atomically:YES];
    NSLog(@"%sMP3INFOCOUNT[%ld]",__func__,[_mp3FilesInfo count]);
//    NSLog(@"\n%s\nMP3INFO\n%@",__func__,[_mp3FilesInfo description]);
}
-(void)readMetaData {
    _mp3FilesInfo = [[NSMutableDictionary alloc] initWithContentsOfURL:
                     [NSURL fileURLWithPath:
                      [[self documentsDirectoryPath] stringByAppendingPathComponent:(NSString*)JWDbKeyMP3InfoFileName]]];
    NSLog(@"%sMP3INFOCOUNT[%ld]",__func__,[_mp3FilesInfo count]);
//    NSLog(@"\n%s\nMP3INFO\n%@",__func__,[_mp3FilesInfo description]);
}


-(void)saveDescriptions {
    [_mp3FilesDescriptions writeToURL:[NSURL fileURLWithPath:[[self documentsDirectoryPath] stringByAppendingPathComponent:@"mp3descriptions.dat"]] atomically:YES];
    NSLog(@"%sMP3DESCRIPCOUNT[%ld]",__func__,[_mp3FilesDescriptions count]);
}
-(void)readDescriptions {
    _mp3FilesDescriptions = [[NSMutableDictionary alloc] initWithContentsOfURL:
                             [NSURL fileURLWithPath:[[self documentsDirectoryPath] stringByAppendingPathComponent:@"mp3descriptions.dat"]]];
    NSLog(@"%sMP3DESCRIPCOUNT[%ld]",__func__,[_mp3FilesDescriptions count]);
}


-(void)saveUserOrderedList {
    [_userOrderList writeToURL:
     [NSURL fileURLWithPath:[[self documentsDirectoryPath] stringByAppendingPathComponent:(NSString*)JWDbKeyUserOrderedListFileName]]
                    atomically:YES];
    
    NSLog(@"%sUSERLISTCOUNT[%ld] MP3DESCRIPCOUNT[%ld]",__func__,[_userOrderList count],[_mp3FilesDescriptions count]);

//    NSLog(@"%sUSERLISTCOUNT[%ld]",__func__,[_userOrderList count]);
//    NSLog(@"\n%s\nUSERLIST\n%@",__func__,[_userOrderList description]);
}
-(void)readUserOrderedList {
    _userOrderList = [[NSMutableArray alloc] initWithContentsOfURL:
                      [NSURL fileURLWithPath:[[self documentsDirectoryPath] stringByAppendingPathComponent:(NSString*)JWDbKeyUserOrderedListFileName]]];
    NSLog(@"%sUSERLISTCOUNT[%ld]",__func__,[_userOrderList count]);
//    NSLog(@"\n%s\nUSERLIST\n%@",__func__,[_userOrderList description]);
}



-(void)convertDescriptions {
    for (id dbkey in [_mp3FilesInfo allKeys]) {
        [self convertDescription:dbkey];
    }
    for (id dbkey in [_mp3FilesInfo allKeys]) {
        NSLog(@"%s\n%@\nrecord\n%@",__func__,dbkey,[_mp3FilesInfo[dbkey] description]);
    }
//    [self saveMetaData];
}

-(void)convertDescription:(NSString*)dbkey {
    // Remove the description from ytdata before adding to _mp3Info
    NSMutableDictionary *ytdata = [_mp3FilesInfo[dbkey][JWDbKeyYouTubeData] mutableCopy];
    if (ytdata) {
//        NSLog(@"%s\nytdata record before\n%@",__func__,[ytdata description]);
        id ytdescription = ytdata[JWDbKeyYoutubeDataDescription];
        id ytlocalized = ytdata[JWDbKeyYoutubeDataLocalized];
        if (ytdescription || ytlocalized) {
            NSMutableDictionary *mp3DescriptionRecord = [@{} mutableCopy];
            if (ytdescription) {
                mp3DescriptionRecord[JWDbKeyYoutubeDataDescription] = ytdescription;
            }
            if (ytlocalized) {
                mp3DescriptionRecord[JWDbKeyYoutubeDataLocalized] = ytlocalized;
            }
            mp3DescriptionRecord[JWDbKeyYouTubeDataVideoId] = ytdata[JWDbKeyYouTubeDataVideoId];
//            NSLog(@"%s\ndescription record\n%@",__func__,[mp3DescriptionRecord description]);
            NSString*descriptionKey = [[NSUUID UUID] UUIDString];
            _mp3FilesDescriptions[descriptionKey] = mp3DescriptionRecord;
            [ytdata removeObjectForKey:JWDbKeyYoutubeDataDescription];
            [ytdata removeObjectForKey:JWDbKeyYoutubeDataLocalized];
            // add the crossreference
            ytdata[@"ytdescriptionskey"] = descriptionKey;
            NSLog(@"%s\nytdata record after\n%@",__func__,[ytdata description]);
//            NSLog(@"%s\ndescription accessed\n%@",__func__,[ytdata[descriptionKey] description]);
            _mp3FilesInfo[dbkey][JWDbKeyYouTubeData]=ytdata;
//            NSLog(@"%s\ndescription accessed\n%@",__func__,[_mp3FilesDescriptions[descriptionKey] description]);
        } else {
            NSLog(@"%s NO DESCRIPTION DATA - RECORD GOOD",__func__);
        }
    } else {
        NSLog(@"%s NO YT DATA ",__func__);
    }
}


@end




//    BOOL recentsFirst = YES;
//    NSArray *sortedArray = [_mp3filesFilesData sortedArrayUsingComparator: ^(id obj1, id obj2) {
//        NSDate *createDate1;
//        NSDate *createDate2;
//        NSError *error;
//        [(NSURL *)obj1[@"furl"] getResourceValue:&createDate1 forKey:NSURLCreationDateKey error:&error];
//        [(NSURL *)obj2[@"furl"] getResourceValue:&createDate2 forKey:NSURLCreationDateKey error:&error];
//
//        NSComparisonResult cresult = [createDate1 compare:createDate2];
//        // simple date compare cause recents last
//        if (recentsFirst) {
//            // swap for Recent first
//            if (cresult == NSOrderedAscending) {
//                cresult = NSOrderedDescending;
//            } else if (cresult == NSOrderedDescending) {
//                cresult = NSOrderedAscending;
//            }
//        }
//
//        return cresult;
//    }];
//    _mp3filesFilesData = [sortedArray mutableCopy];




