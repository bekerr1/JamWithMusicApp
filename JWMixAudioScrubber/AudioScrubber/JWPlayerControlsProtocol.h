//
//  JWPlayerControlsProtocol.h
//  JWAudioScrubber
//
//  co-created by joe and brendan kerr on 12/27/15.
//  Copyright © 2015 b3k3r. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, PlayerControllerState) {
    JWPlayerStatePlayFromBeg = 1,
    JWPlayerStatePlayFromPos,
    JWPlayerStateSetToPos,
    JWPlayerStateSetToBeg,
    JWPlayerStateRecFromPos,
    JWPlayerStatePlayFiveSecondAudio, 
    JWPlayerStateScrubbAudioFromPosMoment,
    JWPlayerStateSetPlayToPos,
    JWPlayerStateScrubbAudioPreviewMoment


};

@protocol JWPlayerControlsProtocol <NSObject>

-(void)play;
-(void)rewind;
-(void)pause;
-(void)record;
-(void)dismissCamera;

@end
