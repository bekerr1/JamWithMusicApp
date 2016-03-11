//
//  JWEffectsClipAudioEngine.h
//  JamWIthT
//
//  Created by brendan kerr on 10/29/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import "JWMTAudioEngine.h"
#import "JWEffectsHandler.h"

@protocol JWMTEffectsAudioEngineDelegate;

@interface JWMTEffectsAudioEngine  : JWMTAudioEngine  <JWEffectsHandler>

-(BOOL)addEffect:(JWEffectNodeTypes)effect toPlayerNodeID:(NSString *)selectedTrackID;

@property (nonatomic,weak) id <JWMTEffectsAudioEngineDelegate> engineEffectsDelegate;

@end


@protocol JWMTEffectsAudioEngineDelegate  <JWMTAudioEngineDelgegate>
@optional
-(void)effectsChanged:(NSArray*)effects inNodeAtIndex:(NSUInteger)nodeIndex;

-(void)effectsChanged:(NSArray*)effects inNodeWithKey:(NSString*)nodeKey;

@end
