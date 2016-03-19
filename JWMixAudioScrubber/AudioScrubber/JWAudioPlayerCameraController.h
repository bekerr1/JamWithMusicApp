//
//  JWAudioPlayerCameraController.h
//  JamWDev
//
//  co-created by joe and brendan kerr on 1/16/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

#import "JWAudioPlayerController.h"


@interface JWAudioPlayerCameraController : JWAudioPlayerController <JWScrubberControllerDelegate>

@property (nonatomic) AVCaptureMovieFileOutput *videoMovie;
@property (nonatomic) NSDictionary *videoSettings;

-(void) initializePlayerControllerWithScrubber:(id)svc playerControles:(id)pvc withCompletion:(JWPlayerCompletionHandler)completion;

@end
