//
//  JWEffectsClipAudioEngine.h
//  JamWIthT
//
//  Created by brendan kerr on 10/29/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import "JWMTAudioEngine.h"
#import "JWEffectsHandler.h"

@interface JWMTEffectsAudioEngine  : JWMTAudioEngine  <JWEffectsHandler>

-(BOOL)addEffect:(JWEffectNodeTypes)effect toPlayerNodeID:(NSString *)selectedTrackID;

@end
