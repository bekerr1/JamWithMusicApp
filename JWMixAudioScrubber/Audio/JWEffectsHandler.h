//
//  EffectsHandler.h
//  JamWIthT
//
//  Created by brendan kerr on 11/2/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JWEffectsModifyingProtocol.h"

@protocol JWEffectsHandler <NSObject>

-(NSArray *)config;
-(BOOL)configChanged:(NSArray *)config;
// joe: index index , needs two sep names
-(id <JWEffectsModifyingProtocol> )effectNodeAtIndex:(NSUInteger)eindex forPlayerNodeAtIndex:(NSUInteger)pindex;
// joe: added method to obtain player nodes
-(id <JWEffectsModifyingProtocol> )playerNodeAtIndex:(NSUInteger)pindex;
-(id <JWEffectsModifyingProtocol> )mixerNodeAtIndex:(NSUInteger)pindex;
-(id <JWEffectsModifyingProtocol> )recorderNodeAtIndex:(NSUInteger)pindex;

-(NSMutableArray *)configPlayerNodeList;

@end

typedef NS_ENUM(NSUInteger, JWCurrentEffect) {
    
    EffectReverb,
    EffectDelay,
    EffectEQ,
    EffectDistortion
    
};