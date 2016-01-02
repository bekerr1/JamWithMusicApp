//
//  JWEffectsClipAudioEngine.h
//  JamWIthT
//
//  Created by brendan kerr on 10/29/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import "JWClipAudioEngine.h"
#import "JWEffectsHandler.h"

//#import "JWMixPanelViewController.h"

@interface JWEffectsClipAudioEngine  : JWClipAudioEngine  <JWEffectsHandler>

-(float)floatValue1ForPlayer:(NSUInteger)playerIndex  forEffectNodeAtIndex:(NSUInteger)index;
-(float)floatValue2ForPlayer:(NSUInteger)playerIndex  forEffectNodeAtIndex:(NSUInteger)index;
-(BOOL)boolValue1ForPlayer:(NSUInteger)playerIndex  forEffectNodeAtIndex:(NSUInteger)index;

-(BOOL)adjustFloatValue1ForPlayer:(NSUInteger)playerIndex  forEffectNodeAtIndex:(NSUInteger)index toValue:(float)value;
-(BOOL)adjustBoolValue1ForPlayer:(NSUInteger)playerIndex  forEffectNodeAtIndex:(NSUInteger)index toValue:(BOOL)value;

@end

//-(void)refreshEngineForEffectsNodeChanges;
//-(void)addEffectsToNode:(NSUInteger)node forTitle:(NSString *)title andType:(NSString *)type;
