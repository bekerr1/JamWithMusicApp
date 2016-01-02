//
//  JWPlayerControlsProtocol.h
//  JWAudioScrubber
//
//  Created by brendan kerr on 12/27/15.
//  Copyright © 2015 b3k3r. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, PlayerControllerState) {
    JWPlayerStateRoot = 1,
    JWPlayerStatePlayFromPos,
    JWPlayerStateSetToPos,
    JWPlayerStateSetToBeg,
    JWPlayerStateRecFromPos
    
};

@protocol JWPlayerControlsProtocol <NSObject>

-(void)play;
-(void)rewind;
-(void)pause;
-(void)record;

@end
