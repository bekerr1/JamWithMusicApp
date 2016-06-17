//
//  JWAudioRecorderController.h
//  JamWIthT
//
//  co-created by joe and brendan kerr on 11/6/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

/*
 JWAudioRecorderController
 
 encapsulates AVAudioRecorder function.  Uses one AVAudioRecorder to record to file
 each recording creates a new file.  metering is used to provide visual out from the recorder
 
 initializeController - alloc a new recorder and prepare.  generates new output file
 record - begins recording and starts metering if on
 stopRecording - stops recording
 registerController - upon recording and metering enabled the controller passed here 
     will be sent messages at inetrvals
 recording - tells whether is recording
     initializeController resets to NO
 hasRecorded - whether a single file has been recorded, that is 'record' then 'stopRecording'
     initializeController resets to NO
 */
#import <Foundation/Foundation.h>
#import "JWScrubberController.h"
#import "JWEffectsModifyingProtocol.h"

@interface JWAudioRecorderController : NSObject <JWEffectsModifyingProtocol>

-(instancetype)initWithMetering:(BOOL)metering;

@property (nonatomic) NSURL* micOutputFileURL;
@property (nonatomic) BOOL metering;
@property (nonatomic, readonly) BOOL hasRecorded;
@property (nonatomic, readonly) BOOL recording;
@property (nonatomic, readonly) NSString *recordingId;

-(NSTimeInterval)currentTime;

-(void)initializeController;
-(void)record;
-(void)stopRecording;
-(void)registerController:(id <JWScrubberBufferControllerDelegate> )myScrubberContoller
              withTrackId:(NSString*)trackId
        forPlayerRecorder:(NSString*)player;

@end
