//
//  JWRecordJamViewController.h
//  JamWithV1.0
//
//  co-created by joe and brendan kerr on 9/15/15.
//  Copyright (c) 2015 b3k3r. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>


@protocol JWRecordJamDelegate;

@interface JWRecordJamViewController : UIViewController

@property (nonatomic,assign) id <JWRecordJamDelegate> delegate;

//-(void)setTrimmedAudioPathWith:(NSString *)trimmedFilePath;
-(void)setTrimmedAudioPathWith:(NSString *)trimmedFilePath And5SecondPathWith:(NSString* )fiveSeconds;

-(void)setTrimmedAudioURL:(NSURL *)trimmedFileURL andFiveSecondURL:(NSURL* )fiveSecondURL;

@end



@protocol JWRecordJamDelegate  <NSObject>
@optional
-(void) done;
-(void) doneGoAgain;
@end

