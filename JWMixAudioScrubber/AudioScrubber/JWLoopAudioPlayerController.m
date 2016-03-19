//
//  JWLoopAudioPlayerController.m
//  JWAudioScrubber
//
//  co-created by joe and brendan kerr on 1/1/16.
//  Copyright © 2016 b3k3r. All rights reserved.
//

#import "JWLoopAudioPlayerController.h"

@implementation JWLoopAudioPlayerController

-(void) initializePlayerControllerWith:(id)svc and:(id)pvc {
    
    [super initializePlayerControllerWithScrubber:svc playerControls:pvc mixEdit:nil];
}

@end
