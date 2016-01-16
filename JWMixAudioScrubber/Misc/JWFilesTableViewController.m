//
//  JWFilesTableViewController.m
//  JamWIthT
//
//  Created by JOSEPH KERR on 10/2/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import "JWFilesTableViewController.h"
#import "JWCurrentWorkItem.h"
@import AVKit;
@import AVFoundation;


@interface JWFilesTableViewController (){
    AVAudioEngine *_audioEngine;
    AVAudioPlayerNode *_playerNode;
}
@property (nonatomic) NSMutableArray *filesData;
@property (nonatomic) NSMutableArray *recordingsFilesData;
@property (nonatomic) NSMutableArray *mp3filesFilesData;
@property (nonatomic) NSMutableArray *clipsFilesData;
@property (nonatomic) NSMutableArray *finalsFilesData;
@end


@implementation JWFilesTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initAVAudioSession];
     self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadData];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [_playerNode stop];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view content

- (void)loadData {
    
    _filesData = [NSMutableArray new];
    _mp3filesFilesData = [NSMutableArray new];
    _recordingsFilesData = [NSMutableArray new];
    _clipsFilesData = [NSMutableArray new];
    _finalsFilesData = [NSMutableArray new];

    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSString *docsDir = [NSHomeDirectory() stringByAppendingPathComponent:  @"Documents"];
    
    NSDirectoryEnumerator *dirEnum =
    [fm enumeratorAtURL:[NSURL fileURLWithPath:docsDir] includingPropertiesForKeys:@[NSURLCreationDateKey,NSURLContentAccessDateKey] options:0 errorHandler:^BOOL(NSURL *url,NSError *error){
        return YES;
    }];
    
    
    NSURL *fileURL;
    while ((fileURL = [dirEnum nextObject])) {

        NSError *error;
        NSDictionary *info = [fm attributesOfItemAtPath:[fileURL path] error:&error];
        NSString *fname = [fileURL lastPathComponent];
        
        NSDictionary *recordInfo = @{@"furl":fileURL,@"fsize":info[NSFileSize]};
        if ([fname hasPrefix:@"mp3file_"])
        {
            [_mp3filesFilesData addObject:recordInfo];
        }
        else if ([fname hasPrefix:@"recording_"] || [fname hasPrefix:@"avrec_"])
        {
            [_recordingsFilesData addObject:recordInfo];
        }
        else if ([fname hasPrefix:@"trimmed"] || [fname hasPrefix:@"fiveSeconds"] || [fname hasPrefix:@"clip"])
        {
            [_clipsFilesData addObject:recordInfo];
        }
        else if ([fname hasPrefix:@"final"])
        {
            [_finalsFilesData addObject:recordInfo];
        }
    }
    
    
    BOOL recentsFirst = YES;
    NSArray *sortedArray = [_clipsFilesData sortedArrayUsingComparator: ^(id obj1, id obj2) {
        NSDate *createDate1;
        NSDate *createDate2;
        NSError *error;
        [(NSURL *)obj1[@"furl"] getResourceValue:&createDate1 forKey:NSURLCreationDateKey error:&error];
        [(NSURL *)obj2[@"furl"] getResourceValue:&createDate2 forKey:NSURLCreationDateKey error:&error];
        
        NSComparisonResult cresult = [createDate1 compare:createDate2];
        // simple date compare cause recents last
        if (recentsFirst) {
            // swap for Recent first
            if (cresult == NSOrderedAscending) {
                cresult = NSOrderedDescending;
            } else if (cresult == NSOrderedDescending) {
                cresult = NSOrderedAscending;
            }
        }
        
        return cresult;
    }];
    
    [_filesData addObject:_finalsFilesData];
    [_filesData addObject:_mp3filesFilesData];
    [_filesData addObject:_recordingsFilesData];
    [_filesData addObject:[sortedArray mutableCopy]];
    
    [self.tableView reloadData];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [_filesData count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_filesData[section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"JWFileItem" forIndexPath:indexPath];

    NSURL *furl = _filesData[indexPath.section][indexPath.row][@"furl"];
    NSDate *createDate;
    NSError *error;
    [furl getResourceValue:&createDate forKey:NSURLCreationDateKey error:&error];
    
    NSDateFormatter *df = [NSDateFormatter new];
    df.dateStyle = NSDateFormatterMediumStyle;
    df.timeStyle = NSDateFormatterShortStyle;
    
    NSString *fileSizeStr;
    NSNumber *fileSz = _filesData[indexPath.section][indexPath.row][@"fsize"];
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
    
    cell.textLabel.text = [furl lastPathComponent];
    
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@  %@",[df stringFromDate:createDate],fileSizeStr];
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath{
    
    if (indexPath.section == 0) {
        if (_playerNode.isPlaying) {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            [_playerNode stop];
        } else {
            if ([self playFileInEngine: _filesData[indexPath.section][indexPath.row][@"furl"]] == NO) {
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
            }
        }
    }
    else if (indexPath.section == 1) {
        
        if (_playerNode.isPlaying) {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            [_playerNode stop];
        }
        
        [self playFileUsingAVPlayer:_filesData[indexPath.section][indexPath.row][@"furl"]];

    }
    else if (indexPath.section == 2) {
        if (_playerNode.isPlaying) {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            [_playerNode stop];
        } else {
            if ([self playFileInEngine: _filesData[indexPath.section][indexPath.row][@"furl"]] == NO) {
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
            }
        }
    }
    else if (indexPath.section == 3) {
        if (_playerNode.isPlaying) {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            [_playerNode stop];
        } else {
            if ([self playFileInEngine: _filesData[indexPath.section][indexPath.row][@"furl"]] == NO) {
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
            }
        }
    }

}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        NSError *error;
        [[NSFileManager defaultManager] removeItemAtURL:_filesData[indexPath.section][indexPath.row][@"furl"] error:&error];
        [(NSMutableArray*)_filesData[indexPath.section] removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if (section == 0) {
        return @"your mixes";
    }
    else if (section == 1) {
        return @"mp3 sources";
    }
    else if (section == 2) {
        return @"recordings";
    }
    else if (section == 3) {
        return @"clips";
    }
    return nil;
}

#pragma mark -

-(void)playFileUsingAVPlayer:(NSURL*)audioFile
{
    NSLog(@"%s %@",__func__,[audioFile lastPathComponent]);
    
    AVPlayer *myPlayer = [AVPlayer playerWithURL:audioFile];
    AVPlayerViewController *playerViewController = [[AVPlayerViewController alloc] init];
    playerViewController.player = myPlayer;
    
    playerViewController.showsPlaybackControls = YES;
    
    [self presentViewController:playerViewController animated:NO completion:^{
        [myPlayer play];
    }];
}


-(BOOL)playFileInEngine:(NSURL*)audioFile
{
    BOOL result;
    NSError *error;
    AVAudioFile *file = [[AVAudioFile alloc] initForReading:audioFile error:&error];
    if ([file length] > 0) {
        _audioEngine = [AVAudioEngine new];
        AVAudioPlayerNode *player = [AVAudioPlayerNode new];
        [_audioEngine attachNode:player];

        AVAudioMixerNode *mainMixer = [_audioEngine mainMixerNode];
        
        [_audioEngine connect:player to:mainMixer format:file.processingFormat];
        error = nil;
        [_audioEngine startAndReturnError:&error];
        mainMixer.volume = 0.6;
        // attime nil play immediately
        [player scheduleFile:file atTime:nil completionHandler:nil];
        _playerNode = player;
        [player play];
        
        result = YES;
    } else {
        result = NO;
    }
    return result;

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


@end
