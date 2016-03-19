//
//  JWClipAudioController.h
//  JamWIthT
//
//  co-created by joe and brendan kerr on 9/30/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^JWClipAudioCompletionHandler)(void);
typedef void (^JWClipExportAudioCompletionHandler)(NSString *key);
@protocol JWClipAudioDelegate;


@interface JWClipAudioController : NSObject
@property (nonatomic,assign) id <JWClipAudioDelegate> delegate;
@property (nonatomic) NSURL* sourceMP3FileURL;
@property (nonatomic,readonly) NSURL* trimmedFileURL;
@property (nonatomic,readonly) NSURL* fiveSecondFileURL;
@property (nonatomic,readonly) double duration;
@property (nonatomic,readonly) BOOL timeIsValid;
@property (nonatomic,readonly) float trackProgress;
@property (nonatomic) float volume;

- (void)initializeAudioController;
- (void)exportAudioSectionStart:(float)exportStartTime end:(float)exportEndTime
              fiveSecondsBefore:(float)fiveSecondsBefore
                 withCompletion:(JWClipExportAudioCompletionHandler)completion;

- (void)prepareToClipAudio;
- (void)seekToTime:(float)seconds;
- (void)goAgain;
- (void)ummmStopPlaying;
- (void)ummmStartPlaying;
- (void)killPlayer;
@end


@protocol JWClipAudioDelegate <NSObject>
@optional
-(void)playerPlayStatusReady:(float)duration;
-(void)periodicUpdatesToPlayer;
-(void)exportDidFinsish;
-(void)playerPlayStatusReady;
@end


