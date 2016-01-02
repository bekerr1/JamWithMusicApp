//
//  JWMixNodes.h
//  JamWIthT
//
//  Created by JOSEPH KERR on 11/11/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#ifndef JWMixNodes_h
#define JWMixNodes_h

/*
 JWMixerNodeTypes
 
 Each player node has a type and can be processed differently by type
 
 JWMixerNodeTypeNone           - a null player (NOT impl)
 JWMixerNodeTypePlayer         - a player only
 JWMixerNodeTypePlayerRecorder - a player and recorder
 JWMixerNodeTypeMixerPlayer    - a player to play mixer output
 JWMixerNodeTypeMixerPlayerRecorder  - a player and recorder to play/Record mixer output NOT USED
 */

typedef NS_ENUM(NSInteger, JWMixerNodeTypes) {
    JWMixerNodeTypeNone     =1,
    JWMixerNodeTypePlayer,
    JWMixerNodeTypePlayerRecorder,
    JWMixerNodeTypeMixerPlayer,
    JWMixerNodeTypeMixerPlayerRecorder
};

typedef NS_ENUM(NSUInteger, JWEffectNodeTypes) {
    JWEffectNodeTypeReverb,
    JWEffectNodeTypeDelay,
    JWEffectNodeTypeEQ,
    JWEffectNodeTypeDistortion
};


#endif/* JWMixNodes_h */
