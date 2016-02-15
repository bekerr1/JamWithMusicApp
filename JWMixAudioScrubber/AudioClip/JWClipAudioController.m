//
//  JWClipAudioController.m
//  JamWIthT
//
//  Created by JOSEPH KERR on 9/30/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

//  from JWPlayerViewController.m the audio stuff

#import "JWClipAudioController.h"
@import AVFoundation;

@interface JWClipAudioController() {
    NSString* _trimmedMP3FileName;
    NSString* _5secondsBeforeStartFileName;
    NSString* _5secondsBeforeStartFilePath;
    NSString* _trackName;
    NSInteger _trackTimeInterval;
    BOOL exportTimmedFile;
    BOOL exportFiveSecondFile;
}
@property (nonatomic) AVURLAsset* youtubeMp3Asset;
@property (nonatomic) AVPlayerItem* playerItem;
@property (nonatomic) AVPlayer* player;
@property (nonatomic) AVAudioPlayer* audioPlayer;
@property (nonatomic) CMTime trackDuration;
@property (nonatomic) NSTimeInterval* timeInterval;
@property (nonatomic) double trackD;
@property (strong) id playerObserver;
@property (nonatomic) NSString* trimmedMP3FilePath;
@property (nonatomic) dispatch_queue_t playerObserverQueue;
@property (nonatomic) NSString* dbKey;
@end


@implementation JWClipAudioController

static void * XItemStatusContext = &XItemStatusContext;

#pragma mark - public api

-(void)initializeAudioController {
    
    if (!_trackName) {
        _trackName = @"Unknown Track Name";
    }

    _volume = 0.35;
    _trackTimeInterval = 7;
    _dbKey = [[NSUUID UUID] UUIDString];

    _trimmedMP3FileName = [NSString stringWithFormat:@"trimmedMP3_%@.m4a",_dbKey?_dbKey:@""];
    _5secondsBeforeStartFileName = [NSString stringWithFormat:@"fiveSecondsMP3_%@.m4a",_dbKey?_dbKey:@""];
    
    if (_playerObserverQueue == nil)
        _playerObserverQueue =
        dispatch_queue_create("playerObserverQueue",
                              dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL,QOS_CLASS_USER_INTERACTIVE, 0));

    [self setupAVPlayerComponents];
}


- (void)dealloc
{
    if (self.playerObserver) {
        NSLog(@"%s removeTimeObserver",__func__);
        [self.player removeTimeObserver:self.playerObserver];
        dispatch_sync(_playerObserverQueue, ^{
        });
        NSLog(@"%s removed.",__func__);
        self.playerObserver = nil;
    }
}

#pragma mark -

- (void)killPlayer {
    NSLog(@"%s",__func__);
    [self.player pause];
    [self.playerItem removeObserver:self forKeyPath:@"status" context:&XItemStatusContext];
    [self.player removeTimeObserver:self.playerObserver];
    dispatch_sync(_playerObserverQueue, ^{
    });
   self.playerObserver = nil;
}

-(void)setVolume:(float)volume {
    _volume = volume;
    if (_player) {
        _player.volume = _volume;
    }
}

- (void)ummmStopPlaying
{
    [_player pause];
}

- (void)ummmStartPlaying
{
    [_player play];
}


#pragma mark -

-(NSURL*)trimmedFileURL {
    return [NSURL fileURLWithPath:self.trimmedMP3FilePath];
}

-(NSURL*)fiveSecondFileURL {
    return [NSURL fileURLWithPath:_5secondsBeforeStartFilePath];
}

-(BOOL)timeIsValid {
    if (CMTIME_IS_INVALID(self.trackDuration)) {
        NSLog(@"invalid time");
        return NO;
    }
    return YES;
}

-(double)duration {
    double result = CMTimeGetSeconds(self.trackDuration);
    return  result;
}

-(float)trackProgress {
    CMTime time = [self.player currentTime] ;
    double progress = CMTimeGetSeconds(time) / self.duration;
    return progress;
}

#pragma mark -

-(AVURLAsset *)youtubeMp3Asset {
    
    if (!_youtubeMp3Asset) {
        _youtubeMp3Asset = [[AVURLAsset alloc] initWithURL:_sourceMP3FileURL
                                                   options:@{AVURLAssetPreferPreciseDurationAndTimingKey : @YES}];
    }
    return _youtubeMp3Asset;
}

-(void)setupAVPlayerComponents {
    
    for (AVAssetTrack* track in self.youtubeMp3Asset.tracks)
    {
        NSLog(@"Asset Track: %@", track);
    }
    
    self.playerItem = [AVPlayerItem playerItemWithAsset:self.youtubeMp3Asset];
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    _player.volume = _volume; // 0.25; // Doesnt need to be blasting

    [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionInitial context:&XItemStatusContext];
}


-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    //WHEN STATUS CHANGES TO READY TO PLAY
    if (context == &XItemStatusContext) {
        
        AVPlayer* thePlayer = (AVPlayer *)object;
        
        if ([thePlayer status] == AVPlayerStatusReadyToPlay) {
            
            NSLog(@"AVPlayerStatusReadyToPlay");

            self.trackDuration = [[[[[self.playerItem tracks] objectAtIndex:0] assetTrack] asset] duration];
            
            float dur = CMTimeGetSeconds(self.trackDuration);
            
            [_delegate playerPlayStatusReady:dur];

            [self playWithObserver];
            
        } else if ([thePlayer status] == AVPlayerStatusFailed) {
            NSLog(@"AVPlayerStatusFailed");
        } else if ([thePlayer status] == AVPlayerStatusUnknown) {
            NSLog(@"AVPlayerStatusUnknown");
        } else {
            NSLog(@"AVPlayerStatusReallyUnknown");
        }
    }
}

//            //GET DURATION FOR FIRST TIME HERE------------------------------------------------------
//            //self.trackD = CMTimeGetSeconds([[[[[self.playerItem tracks] objectAtIndex:0] assetTrack] asset] duration]);


- (void)seekToTime:(float)seconds
{
    [self.player seekToTime:CMTimeMakeWithSeconds(seconds,NSEC_PER_SEC)];
}

- (void)prepareToClipAudio
{
    [self.player pause];
    NSLog(@"%s removeTimeObserver",__func__);
    [self.player removeTimeObserver:self.playerObserver];
    NSLog(@"%s removed",__func__);
    self.playerObserver = nil;
}

-(void)goAgain
{
    [self playWithObserver];
}

-(void)playWithObserver {
    
    __weak JWClipAudioController *weakself = self;
    
    self.playerObserver =
    [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(0.175, NSEC_PER_SEC)
                                              queue:_playerObserverQueue
                                         usingBlock:^(CMTime time) {
                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                 [weakself.delegate periodicUpdatesToPlayer];
                                             });
                                         }];
    [self.player play];
}


#pragma mark - Export

-(void)exportAudioSectionStart:(float)exportStartTime end:(float)exportEndTime fiveSecondsBefore:(float)fiveSecondsBefore withCompletion:(JWClipExportAudioCompletionHandler)completion

{
    exportTimmedFile = NO;
    exportFiveSecondFile = NO;
    
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *outputURL = paths[0];
    NSFileManager *manager = [NSFileManager defaultManager];

    // TRIMMED FILE export session

    AVAssetExportSession* exportSession1 = [AVAssetExportSession exportSessionWithAsset:self.youtubeMp3Asset presetName:AVAssetExportPresetAppleM4A];
    
    for (NSString* filetype in exportSession1.supportedFileTypes) {
        if ([filetype isEqualToString:AVFileTypeAppleM4A]) {
            exportSession1.outputFileType = AVFileTypeAppleM4A;
            break;
        }
    }
    
    // configure the session

    {
        //Export the entire bit of audio they want to play over (15, 30, 45, or 1 minute)

        NSString *trOutputURL = [outputURL stringByAppendingPathComponent:_trimmedMP3FileName];
        // Remove Existing File
        [manager removeItemAtPath:trOutputURL error:nil];
        
        self.trimmedMP3FilePath = trOutputURL;
        NSURL* trimmedURL = [NSURL fileURLWithPath:self.trimmedMP3FilePath];
        
        exportSession1.outputURL = trimmedURL;
        exportSession1.outputFileType = AVFileTypeAppleM4A;
        
        //AVFileTypeAppleM4A
        CMTime startTime = CMTimeMakeWithSeconds((int)exportStartTime, NSEC_PER_SEC);
        CMTime endTime = CMTimeMakeWithSeconds((int)exportEndTime, NSEC_PER_SEC);
        
        NSLog(@"Start Time in seconds: %f, End Time in seconds: %f", CMTimeGetSeconds(startTime), CMTimeGetSeconds(endTime));
        exportSession1.timeRange = CMTimeRangeFromTimeToTime (startTime, endTime);
        //Export 5 seconds before for the fade in audio
    }
    
    // FIVE SECOND FILE export session
    
    AVAssetExportSession* exportSession2 = [AVAssetExportSession exportSessionWithAsset:self.youtubeMp3Asset presetName:AVAssetExportPresetAppleM4A];
    
    for (NSString* filetype in exportSession2.supportedFileTypes) {
        if ([filetype isEqualToString:AVFileTypeAppleM4A]) {
            exportSession2.outputFileType = AVFileTypeAppleM4A;
            break;
        }
    }

    // configure the session

    {
        NSString *fsOutputURL = [outputURL stringByAppendingPathComponent:_5secondsBeforeStartFileName];
        // Remove Existing File
        [manager removeItemAtPath:fsOutputURL error:nil];
        
        _5secondsBeforeStartFilePath = fsOutputURL;
        NSURL* trimmedURL = [NSURL fileURLWithPath:_5secondsBeforeStartFilePath];
        
        exportSession2.outputURL = trimmedURL;
        exportSession2.outputFileType = AVFileTypeAppleM4A;
        
        CMTime startTime = CMTimeMakeWithSeconds((int)fiveSecondsBefore, NSEC_PER_SEC);
        CMTime endTime = CMTimeMakeWithSeconds((int)exportStartTime, NSEC_PER_SEC);
        
        NSLog(@"Start Time in seconds: %f, End Time in seconds: %f", CMTimeGetSeconds(startTime), CMTimeGetSeconds(endTime));
        exportSession2.timeRange = CMTimeRangeFromTimeToTime (startTime, endTime);
    }
    
    NSLog(@"Starting Export Trimmed File");
    
    [exportSession1 exportAsynchronouslyWithCompletionHandler:^(void) {
        // Export ended for some reason. Check in status
        NSString* message;
        switch (exportSession1.status) {
            case AVAssetExportSessionStatusFailed:
                message = [NSString stringWithFormat:@"Export failed. Error: %@", exportSession1.error.description];
                break;
            case AVAssetExportSessionStatusCompleted:
                message = [NSString stringWithFormat:@"Export completed for file: "];
                break;
            case AVAssetExportSessionStatusCancelled:
                message = [NSString stringWithFormat:@"Export cancelled!"];
                break;
            default:
                message = [NSString stringWithFormat:@"Export unhandled status: %ld", (long)exportSession1.status];
                break;
        }
        
        if (exportSession1.status == AVAssetExportSessionStatusCompleted) {
            [self completedExportTrimmedFile:completion];
        } else {
            NSLog(@"%@", message);
        }
    }];
    
    
    NSLog(@"Starting Export FiveSecond File");
    
    [exportSession2 exportAsynchronouslyWithCompletionHandler:^(void) {
        // Export ended for some reason. Check in status
        NSString* message;
        switch (exportSession2.status) {
            case AVAssetExportSessionStatusFailed:
                message = [NSString stringWithFormat:@"Export failed. Error: %@", exportSession2.error.description];
                break;
            case AVAssetExportSessionStatusCompleted:
                message = [NSString stringWithFormat:@"Export completed for file: "];
                break;
            case AVAssetExportSessionStatusCancelled:
                message = [NSString stringWithFormat:@"Export cancelled!"];
                break;
            default:
                message = [NSString stringWithFormat:@"Export unhandled status: %ld", (long)exportSession2.status];
                break;
        }

        if (exportSession2.status == AVAssetExportSessionStatusCompleted) {
            [self completedExportFiveSecondFile:completion];
        } else {
            NSLog(@"%@", message);
        }
    }];

}

-(void)completedExportTrimmedFile:(JWClipExportAudioCompletionHandler)completion {
    NSLog(@"%s",__func__);
    exportTimmedFile = YES;
    if (exportTimmedFile && exportFiveSecondFile)
    {
        completion(self.dbKey);
    }
}

-(void)completedExportFiveSecondFile:(JWClipExportAudioCompletionHandler)completion {
    NSLog(@"%s",__func__);
    exportFiveSecondFile = YES;
    if (exportTimmedFile && exportFiveSecondFile)
    {
        completion(self.dbKey);
    }
}

@end



