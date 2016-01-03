//
//  JWEffectsClipAudioEngine.m
//  JamWIthT
//
//  Created by brendan kerr on 10/29/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import "JWMTEffectsAudioEngine.h"
#import "AVAudioUnitDelay+JW.h"
#import "AVAudioUnitReverb+JW.h"
#import "AVAudioUnitDistortion+JW.h"
#import "AVAudioPlayerNode+JW.h"
#import "AVAudioMixerNode+JW.h"
#import "JWAudioRecorderController.h"

@interface JWMTEffectsAudioEngine() <JWEffectsHandler>
@property (strong, nonatomic) NSArray *effectnodesList; // an item for each player, another array stack of effects
@property (strong, nonatomic) NSMutableArray *effectnodes; // holds objects AudioNodes
@property (nonatomic) JWCurrentEffect currentEffect;
@end


@implementation JWMTEffectsAudioEngine

-(void) setupAVEngine {

    NSLog(@"%s",__func__);
    
    // READ and initialize effects list before call super
    
    [self effectsEngineConfigPrepare:NO]; // NO refresh, is Init

    // SUPER will call createEngineAndAttachNodes and makeEngineConnections,
    // so we need to have effects ready
    
    [super setupAVEngine];
}



- (void)createEngineAndAttachNodes
{
    NSLog(@"%s",__func__);

    [super createEngineAndAttachNodes];

    /*  An AVAudioEngine contains a group of connected AVAudioNodes ("nodes"), each of which performs
     an audio signal generation, processing, or input/output task.
     
     Nodes are created separately and attached to the engine.
     
     The engine supports dynamic connection, disconnection and removal of nodes while running,
     with only minor limitations:
     - all dynamic reconnections must occur upstream of a mixer
     - while removals of effects will normally result in the automatic connection of the adjacent
     nodes, removal of a node which has differing input vs. output channel counts, or which
     is a mixer, is likely to result in a broken graph. */

    
    // for each player attach all the effect nodes
    for (NSDictionary *playerNodeInfo in self.playerNodeList) {
        
        id effectNodes = playerNodeInfo[@"effectnodes"];
        if (effectNodes) {
            
            for (id effectNode in effectNodes) {
                
                [self.audioEngine attachNode:effectNode];
            }
        }
        
    }

}

- (void)makeEngineConnections
{
    
    NSLog(@"%s",__func__);
    
    [super makeEngineConnections];
    
    // PLAYERS may already be connected to mainMixer
    // But will be attched to effects, possibly, then to mainMixer
    
    /*  The engine will construct a singleton main mixer and connect it to the outputNode on demand,
     when this property is first accessed. You can then connect additional nodes to the mixer.
     By default, the mixer's output format (sample rate and channel count) will track the format
     of the output node. You may however make the connection explicitly with a different format. */
    
    /*  Nodes have input and output buses (AVAudioNodeBus). Use connect:to:fromBus:toBus:format: to
     establish connections betweeen nodes. Connections are always one-to-one, never one-to-many or
     many-to-one.
     
     Note that any pre-existing connection(s) involving the source's output bus or the
     destination's input bus will be broken.
     
     @method connect:to:fromBus:toBus:format:
     @param node1 the source node
     @param node2 the destination node
     @param bus1 the output bus on the source node
     @param bus2 the input bus on the destination node
     @param format if non-null, the format of the source node's output bus is set to this
     format. In all cases, the format of the destination node's input bus is set to
     match that of the source node's output bus. */
    
    //for (id playernodeEffects in _effectnodes) {
    // GET the player that will get the effects
    
    
    //        if ([self.playerNodes count] > index) {
    //            playerNode = self.playerNodes[index];
    //        }
    
    NSUInteger index = 0;
    AVAudioMixerNode *mainMixer = [self.audioEngine mainMixerNode];
    
    for (NSDictionary *playerNodeInfo in self.playerNodeList) {
        
        JWPlayerNode *playerNode = playerNodeInfo[@"player"];
        
        // GET the buffer (for format) that will play in the effects

//        AVAudioPCMBuffer *audioBuffer = [self audioBufferForPlayerNodeAtIndex:index];
        AVAudioFile *audioFile = playerNodeInfo[@"audiofile"];

        if (audioFile) {
            
            id effectNodes = playerNodeInfo[@"effectnodes"];
            if (effectNodes) {
                
                AVAudioNode *lastnode = playerNode;  // the lastnode connected
                
                for (id effectNode in effectNodes) {
                    
                    [self.audioEngine  connect:lastnode to:effectNode  format:audioFile.processingFormat];
                    lastnode = effectNode;
                }
                [self.audioEngine connect:lastnode to:mainMixer format:audioFile.processingFormat];

            }
            
        } else {
            NSLog(@"%s NO audioBuffer player at index %ld perhaps try using audioFile for format ",__func__,(unsigned long)index);
        }

        index++;
    }
    
    
}

//NSArray *playernodeEffects = _effectnodes[index];
//            AVAudioNode *lastnode = playerNode;  // the lastnode connected//
//            for (id effectsNode in playernodeEffects) {//
//                [self.audioEngine  connect:lastnode to:effectsNode  format:audioBuffer.format];
//                lastnode = effectsNode;
//            }//
//            [self.audioEngine connect:lastnode to:mainMixer format:audioBuffer.format];

#pragma mark - Effects handler protocol

-(NSMutableArray *)configPlayerNodeList
{
    return self.playerNodeList;
}


-(NSArray *)config {
    
    return nil;
}

-(BOOL)configChanged:(NSArray *)config {
    
//    _effectnodesList = config;

    [self refreshEngineForEffectsNodeChanges];
    
    [self saveUserOrderedList];
    
    return 1;
}


// joe: impl nil func

-(id <JWEffectsModifyingProtocol> )effectNodeAtIndex:(NSUInteger)eindex forPlayerNodeAtIndex:(NSUInteger)pindex {
    
    id <JWEffectsModifyingProtocol> result = nil;
    
    if ([self.playerNodeList count] > pindex) {

        id effectNodes = self.playerNodeList[pindex][@"effectnodes"];
        if (effectNodes && [effectNodes count] > eindex) {
            result = effectNodes[eindex];
        }
    }

    return result;
}

-(id <JWEffectsModifyingProtocol> )playerNodeAtIndex:(NSUInteger)pindex {
    
    
    id <JWEffectsModifyingProtocol> result;
    
    if ([self.playerNodeList count] > pindex) {
        result = self.playerNodeList[pindex][@"player"];
    }
    
    return result;
}

-(id <JWEffectsModifyingProtocol> )mixerNodeAtIndex:(NSUInteger)pindex
{
    return [self.audioEngine mainMixerNode];
}

-(id <JWEffectsModifyingProtocol> )recorderNodeAtIndex:(NSUInteger)pindex
{

    id <JWEffectsModifyingProtocol> result;
    if (pindex < [self.playerNodeList count]) {
        NSDictionary *playerNodeInfo = self.playerNodeList[pindex];
        JWMixerNodeTypes nodeType = [self typeForNodeAtIndex:pindex];

        // PLAYER RECORDER
        if (nodeType == JWMixerNodeTypePlayerRecorder) {
            id rc = playerNodeInfo[@"recorderController"];
            if (rc) {
                result = (JWAudioRecorderController*)rc;
            }
        }
    }

    return result;
}


#pragma mark -

-(void)refreshEngineForEffectsNodeChanges {

    // Detach the nodes

    
    for (NSMutableDictionary *playerNode in self.playerNodeList) {
        for (id effectsNode in playerNode[@"effectsnodes"]) {
            [self.audioEngine detachNode:effectsNode];
        }
        [playerNode removeObjectForKey:@"effectsnodes"];
    }

    [self effectsEngineConfigPrepare:YES]; // YES is refresh
    
    // Attach the nodes
    for (NSDictionary *playerNodeInfo in self.playerNodeList) {
        
        id effectNodes = playerNodeInfo[@"effectnodes"];
        if (effectNodes) {
            
            for (id effectNode in effectNodes) {
                
                [self.audioEngine attachNode:effectNode];
            }
        }
        
    }
    
    [self makeEngineConnections];
    [self startEngine];
}



//Dont think this needs to be called from refresh, since the array is set directly
//from the delegate
// joe: Yes lets use this for startup here, AE will provide the config

//Effects config
-(void)effectsEngineConfigPrepare:(BOOL)isRefresh {
    
    
    for (NSMutableDictionary *playerNodeInfo in self.playerNodeList) {
        
        NSMutableArray *effectNodes = [@[] mutableCopy];
        NSArray *effects = playerNodeInfo[@"effects"];
        
        for (NSDictionary *effect in effects) {
            
            JWEffectNodeTypes effectKind = [effect[@"type"] unsignedIntegerValue];
            //NSString *effectTitle = effect[@"title"];
            
            id fx;
            if (effectKind == JWEffectNodeTypeReverb) {
                fx = (AVAudioUnitReverb *) [self reverbEffectWith:effect];
                
            } else if (effectKind == JWEffectNodeTypeDelay) {
                fx = (AVAudioUnitDelay *) [self delayEffectWith:effect];
                
            } else if (effectKind == JWEffectNodeTypeDistortion) {
                fx = (AVAudioUnitDistortion *) [self distortionEffectWith:effect];
                
            } else if (effectKind == JWEffectNodeTypeEQ) {
                fx = (AVAudioUnitEQ *) [self eqEffectWith:effect    ];
                
            } else
                NSLog(@"No effect Found. %s", __func__);
            
            if (fx) {
                [effectNodes addObject:fx];
            } else {
                NSLog(@"effect not added %s", __func__);
            }
            
            
            
        }
        playerNodeInfo[@"effectnodes"] = effectNodes;
    }
    
}

#pragma mark - Effects Creator


-(AVAudioUnitEffect *)reverbEffectWith:(NSDictionary *)params {
    NSLog(@"%s Effect Created. %@", __func__, [params description]);
    
    AVAudioUnitEffect *effect = nil;
    
    id value = params[@"factorypreset"];
    if (value) {
        
        AVAudioUnitReverbPreset factoryPreset = [params[@"factorypreset"] integerValue];
        AVAudioUnitReverb *reverb = [AVAudioUnitReverb new];
        [reverb loadFactoryPreset:factoryPreset];
        
        effect = reverb;
    }
    
    
    return effect;
}

-(AVAudioUnitEffect *)delayEffectWith:(NSDictionary *)params {
    NSLog(@"%s Effect Created. %@", __func__, [params description]);
    AVAudioUnitEffect *effect = nil;
    NSTimeInterval delayTime = 0.0;
    float feedback = 0.0;
    float lpc = 0.0;
    
    id delayValue = params[@"delaytime"];
    if (delayValue) {
         delayTime = [delayValue doubleValue];
    }
    
    id feedbackValue = params[@"feedback"];
    if (feedbackValue) {
         feedback = [feedbackValue floatValue];
    }
    
    id lowpasscut = params[@"lowpasscutoff"];
    if (lowpasscut) {
        lpc = [lowpasscut floatValue];
    }
    
    AVAudioUnitDelay *delay = [AVAudioUnitDelay new];
    delay.delayTime = delayTime;
    delay.feedback = feedback;
    delay.lowPassCutoff = lpc;
    effect = delay;
    
    return effect;
}

-(AVAudioUnitEffect *)distortionEffectWith:(NSDictionary *)params {
   NSLog(@"%s Effect Created. %@", __func__, [params description]);
    AVAudioUnitEffect *effect;
    AVAudioUnitDistortion *distortion = [AVAudioUnitDistortion new];
    
    float preGain = 0.0;
    
    id value = params[@"factorypreset"];
    if (value) {
        AVAudioUnitDistortionPreset factoryPreset = [value integerValue];
        [distortion loadFactoryPreset:factoryPreset];
    }
    
    id gain = params[@"pregain"];
    if (gain) {
        preGain = [gain floatValue];
    }
    
    distortion.preGain = preGain;
    effect = distortion;
    
    return effect;
    
}

-(AVAudioUnitEffect *)eqEffectWith:(NSDictionary *)params {
    NSLog(@"%s Effect Created. %@", __func__, [params description]);
    AVAudioUnitEffect *effect;
    AVAudioUnitEQ *eq = [[AVAudioUnitEQ alloc] initWithNumberOfBands:2];

    if (eq == nil) {
        
    }

    
    
    return effect;
    
}


#pragma mark -

-(NSString*)documentsDirectoryPath {
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [searchPaths objectAtIndex:0];
}

-(void)saveUserOrderedList {
    NSString *fpath = [[self documentsDirectoryPath] stringByAppendingPathComponent:@"mixereffects.dat"];
    [_effectnodesList writeToURL:[NSURL fileURLWithPath:fpath] atomically:YES];
    
    NSLog(@"\n%s\nmixereffects.dat\n%@",__func__,[_effectnodesList description]);
}

// joe: is not mutable
-(NSArray *)readUserOrderedList {
    NSString *fpath = [[self documentsDirectoryPath] stringByAppendingPathComponent:@"mixereffects.dat"];
//    NSMutableArray* effectsNodeList = [[NSMutableArray alloc] initWithContentsOfURL:[NSURL fileURLWithPath:fpath]];
    // joe: is not mutable
    NSArray* effectsNodeList = [[NSArray alloc] initWithContentsOfURL:[NSURL fileURLWithPath:fpath]];
    
    NSLog(@"\n%s\nmixereffects.dat\n%@",__func__,[effectsNodeList description]);
    return effectsNodeList;
}


@end


