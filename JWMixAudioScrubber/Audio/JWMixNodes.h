//
//  JWMixNodes.h
//  JamWIthT
//
//  co-created by joe and brendan kerr on 11/11/15.
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

//New enum with correct wording and all values are used
typedef NS_ENUM(NSInteger, JWAudioNodeType) {
    JWAudioNodeTypeNone     =1,
    JWAudioNodeTypePlayer,
    JWAudioNodeTypeRecorder,
    JWAudioNodeTypeFiveSecondPlayer,
    JWAudioNodeTypeVideo
};

//Old ENUM that was worded wrong and has some unnessesary values (only around becuase master)
typedef NS_ENUM(NSInteger, JWMixerNodeTypes) {
    JWMixerNodeTypeNone     =1,
    JWMixerNodeTypePlayer,
    JWMixerNodeTypePlayerRecorder,
    JWMixerNodeTypeMixerPlayer,
    JWMixerNodeTypeMixerPlayerRecorder,
    JWMixerNodeTypeFiveSecondPlayer,
    JWMixerNodeTypeVideo
};


typedef NS_ENUM(NSUInteger, JWEffectNodeTypes) {
    JWEffectNodeTypeReverb,
    JWEffectNodeTypeDelay,
    JWEffectNodeTypeEQ,
    JWEffectNodeTypeDistortion
};

#endif/* JWMixNodes_h */
