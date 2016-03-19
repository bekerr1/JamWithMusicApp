//
//  JWEffectsClipAudioEngine.m
//  JamWIthT
//
//  co-created by joe and brendan kerr on 10/29/15.
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
//@property (nonatomic) NSMutableDictionary *userDelayPresets;
//@property (nonatomic) NSMutableDictionary *userEQPresets;
@end


@implementation JWMTEffectsAudioEngine

-(void)setEngineEffectsDelegate:(id<JWMTEffectsAudioEngineDelegate>)engineEffectsDelegate {

    _engineEffectsDelegate = engineEffectsDelegate;
    self.engineDelegate = engineEffectsDelegate;
}


-(void) setupAVEngine {

    // READ and initialize effects list before call super
    
    [self effectsEngineConfigPrepare:NO]; // NO refresh, is Init

    // SUPER will call createEngineAndAttachNodes and makeEngineConnections,
    // so we need to have effects ready
    
    [super setupAVEngine];
}

- (void)createEngineAndAttachNodes
{
    [super createEngineAndAttachNodes];

    /*  An AVAudioEngine contains a group of connected AVAudioNodes ("nodes"), each of which performs
     an audio signal generation, processing, or input/output task.
     
     Nodes are created separately and attached to the engine.
     */
    
    
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
    
    [super makeEngineConnections];
    
    // PLAYERS may already be connected to mainMixer
    // But will be attched to effects, possibly, then to mainMixer
    
    /*  The engine will construct a singleton main mixer and connect it to the outputNode on demand,
     when this property is first accessed. You can then connect additional nodes to the mixer.
     By default, the mixer's output format (sample rate and channel count) will track the format
     of the output node. You may however make the connection explicitly with a different format. */
    
    NSUInteger index = 0;
    AVAudioMixerNode *mainMixer = [self.audioEngine mainMixerNode];
    
    for (NSDictionary *playerNodeInfo in self.playerNodeList) {
        
        JWPlayerNode *playerNode = playerNodeInfo[@"player"];
        
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
//            NSLog(@"%s NO audioBuffer player at index %ld perhaps try using audioFile for format ",__func__,(unsigned long)index);
        }

        index++;
    }
    
}


#pragma mark - Effects handler protocol

-(NSMutableArray *)configPlayerNodeList {
    return self.playerNodeList;
}

-(NSArray *)config {
    
    return nil;
}

-(BOOL)configChanged:(NSArray *)config {
    
    [self refreshEngineForEffectsNodeChanges];
//    [self saveUserOrderedList];
    return YES;
}



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
    
    if ([self.playerNodeList count] > pindex)
        result = self.playerNodeList[pindex][@"player"];
    
    return result;
}

-(id <JWEffectsModifyingProtocol> )mixerNodeAtIndex:(NSUInteger)pindex {
    return [self.audioEngine mainMixerNode];
}

-(id <JWEffectsModifyingProtocol> )recorderNodeAtIndex:(NSUInteger)pindex {
    id <JWEffectsModifyingProtocol> result;
    if (pindex < [self.playerNodeList count]) {
        NSDictionary *playerNodeInfo = self.playerNodeList[pindex];
        JWMixerNodeTypes nodeType = [self typeForNodeAtIndex:pindex];

        // PLAYER RECORDER
        if (nodeType == JWMixerNodeTypePlayerRecorder) {
            id rc = playerNodeInfo[@"recorderController"];
            if (rc)
                result = (JWAudioRecorderController*)rc;
        }
    }

    return result;
}

-(NSArray *)stringRepresentedReverbPreset {
    
    NSArray *reverb = [NSArray arrayWithObjects:@"Small Room", @"Medium Room", @"Large Room", @"Medium Hall", @"Large Hall", @"Plate", @"Medium Chamber", @"Large Chamber", @"Cathedral", @"Large Room 2", @"Medium Hall 2", @"Medium Hall 3", @"Large Hall 2", nil];
    
    return reverb;
}

-(NSArray *)stringRepresentedDistortionPresets {
    
    NSArray *distortion = [NSArray arrayWithObjects:@"Drums Bit Brush", @"Drums Buffer Beats", @"Drums LoFi", @"Broken Speaker", @"Cellphone", @"Decimated 1", @"Decimated 2", @"Decimated 3", @"Decimated 4", @"Distorted Funk", @"Distorted^3", @"Distorted^2", @"Echo 1", @"Echo 2", @"Echo Tight 1", @"Echo Tight 2", @"Everything Is Broken", @"Alien Chatter", @"Cosmic Interface", @"Golden π", @"Radio Tower", @"Waves", nil];
    
    return distortion;
    
}

#pragma mark - User defined presets (part of effects handler)


-(void)addUserDefinedPresetAtIndex:(NSUInteger)eff selectedTrack:(NSUInteger)selected forEffectType:(NSUInteger)et withPresetName:(NSString *)preset {
    
    NSDictionary *effectAtIndex = self.playerNodeList[selected][@"effects"][eff];
    NSDictionary *userPreset = [[NSMutableDictionary alloc] init];
    
    if (et == JWEffectNodeTypeDelay) {
        
        NSUInteger feedback = [effectAtIndex[@"feedback"] integerValue];
        NSUInteger delaytime = [effectAtIndex[@"delaytime"] integerValue];
        NSUInteger lowpasscutoff = [effectAtIndex[@"lowpasscutoff"] integerValue];
        
        userPreset = [@{
                        @"effecttype" : @(JWEffectNodeTypeDelay),
                        @"feedback" : @(feedback), //from -100 to 100 percent
                        @"delaytime" : @(delaytime), //from 0 to 2 seconds
                        @"lowpasscutoff" : @(lowpasscutoff), //from 10 hz to sampleRate / 2
                        @"presetname" : preset
                        } copy];
        
    } else if (et == JWEffectNodeTypeEQ) {
        
        
    }
    
    self.playerNodeList[selected][@"userpresets"] = userPreset;
}


-(NSString *)stringPresetForEffectWithNode:(NSInteger)node effectAt:(NSInteger)effect {
    
    NSDictionary *effectAt = self.playerNodeList[node][@"effects"][effect];
    JWEffectNodeTypes effectType = [effectAt[@"type"] integerValue];
    
    
    if (effectType == JWEffectNodeTypeReverb) {
        AVAudioUnitReverbPreset factory = [effectAt[@"factorypreset"] integerValue];
        return [self stringRepresentedReverbPreset][factory];
        
    } else if (effectType == JWEffectNodeTypeDistortion) {
        AVAudioUnitDistortionPreset factory = [effectAt[@"factorypreset"] integerValue];
        return [self stringRepresentedDistortionPresets][factory];
        
    } else if (effectType == JWEffectNodeTypeDelay) {
        return @"No Presets Set";
    } else if (effectType == JWEffectNodeTypeEQ) {
        return @"No Presets Set";
    }
    return @"";
}





#pragma mark -

//@"title" : @"Delay",
//@"feedback" : @(50), //from -100 to 100 percent
//@"delaytime" : @(1), //from 0 to 2 seconds
//@"lowpasscutoff" : @(1500) //from 10 hz to sampleRate / 2

//@"title" : @"Reverb",
//@"factorypreset" : @(AVAudioUnitReverbPresetMediumHall)

//@"title" : @"Distortion",
//@"factorypreset" : @(AVAudioUnitDistortionPresetDrumsBitBrush),
//@"pregain" : @(0.0)


-(void)updatePlayerNodeListEffectParameters {
    
    for (int i = 0; i < [self.playerNodeList count]; i++) {
        
        NSArray *effectNodes = self.playerNodeList[i][@"effectnodes"];
        NSMutableArray *effects = self.playerNodeList[i][@"effects"];
        
        if ([effectNodes count] > 0) {
            
                for (int j = 0; j < [effects count] - 1; j++) {
                    
                    JWEffectNodeTypes type = [effects[j][@"type"] unsignedIntegerValue];
                    switch (type) {
                        case JWEffectNodeTypeReverb:
                            
                            effects[j][@"wetdry"] = @([effectNodes[j] floatValue1]);
                            break;
                            
                        case JWEffectNodeTypeDelay:
                            
                            effects[j][@"wetdry"] = @([effectNodes[j] floatValue1]);
                            effects[j][@"feedback"] = @([effectNodes[j] floatValue2]);
                            effects[j][@"lowpasscutoff"] = @([effectNodes[j] floatValue3]);
                            
                            break;
                            
                        case JWEffectNodeTypeDistortion:
                            
                            effects[j][@"wetdry"] = @([effectNodes[j] floatValue1]);
                            effects[j][@"pregain"] = @([effectNodes[j] floatValue2]);
                            
                            break;
                            
                        case JWEffectNodeTypeEQ:
                            
                            break;
                            
                        default:
                            break;
                    }
            }
        }
    }
    
}



-(void)refreshEngineForEffectsNodeChanges {

    // Detach the nodes
    
    //Need to update player node list effects changes
    
    [self updatePlayerNodeListEffectParameters];

    
    for (NSMutableDictionary *playerNode in self.playerNodeList) {
        for (id effectsNode in playerNode[@"effectsnodes"])
            [self.audioEngine detachNode:effectsNode];
        
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
                fx = [self reverbEffectWith:effect];
                
            } else if (effectKind == JWEffectNodeTypeDelay) {
                fx = [self delayEffectWith:effect];
                
            } else if (effectKind == JWEffectNodeTypeDistortion) {
                fx = [self distortionEffectWith:effect];
                
            } else if (effectKind == JWEffectNodeTypeEQ) {
                fx = [self eqEffectWith:effect];
                
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


-(AVAudioUnitReverb *)reverbEffectWith:(NSDictionary *)params {
    NSLog(@"%s Effect Created. %@", __func__, [params description]);
    
    
    AVAudioUnitReverb *reverb = [AVAudioUnitReverb new];
    
    id value = params[@"factorypreset"];
    if (value) {
        
        AVAudioUnitReverbPreset factoryPreset = [params[@"factorypreset"] integerValue];
        [reverb loadFactoryPreset:factoryPreset];
        
        
    }
    float wetDry = [params[@"wetdry"] floatValue];
    if (wetDry) {
        [reverb setWetDryMix:wetDry];
    }
    
    
    return reverb;
}

-(AVAudioUnitDelay *)delayEffectWith:(NSDictionary *)params {
    NSLog(@"%s Effect Created. %@", __func__, [params description]);
    
    NSTimeInterval delayTime = 0.0;
    float feedback = 0.0;
    float lpc = 0.0;
    float wetdry = 0.0;
    
    id delayValue = params[@"delaytime"];
    if (delayValue)
         delayTime = [delayValue doubleValue];

    id feedbackValue = params[@"feedback"];
    if (feedbackValue)
         feedback = [feedbackValue floatValue];

    id lowpasscut = params[@"lowpasscutoff"];
    if (lowpasscut)
        lpc = [lowpasscut floatValue];

    id wetdryValue = params[@"wetdry"];
    if (wetdryValue)
        wetdry = [wetdryValue floatValue];

    
    AVAudioUnitDelay *delay = [AVAudioUnitDelay new];
    delay.delayTime = delayTime;
    delay.feedback = feedback;
    delay.lowPassCutoff = lpc;
    delay.wetDryMix = wetdry;
    
    return delay;
}

-(AVAudioUnitDistortion *)distortionEffectWith:(NSDictionary *)params {
//   NSLog(@"%s Effect Created. %@", __func__, [params description]);
    
    AVAudioUnitDistortion *distortion = [AVAudioUnitDistortion new];
    
    float preGain = 0.0;
    
    id value = params[@"factorypreset"];
    if (value) {
        AVAudioUnitDistortionPreset factoryPreset = [value integerValue];
        [distortion loadFactoryPreset:factoryPreset];
    }
    
    id gain = params[@"pregain"];
    if (gain)
        preGain = [gain floatValue];
    
    id wetDry = params[@"wetdry"];
    if (wetDry) {
        [distortion setWetDryMix:[wetDry floatValue]];
    }
    
    distortion.preGain = preGain;
    
    return distortion;
    
}

-(AVAudioUnitEQ *)eqEffectWith:(NSDictionary *)params {
//    NSLog(@"%s Effect Created. %@", __func__, [params description]);
    
    AVAudioUnitEQ *eq = [[AVAudioUnitEQ alloc] initWithNumberOfBands:2];

    if (eq == nil) {
        
    }
    
    
    return eq;
    
}


-(BOOL)addEffect:(JWEffectNodeTypes)effect toPlayerNodeID:(NSString *)selectedTrackID {
    
    int trackIndex = 0;
    for (int i = 0; i < [self.playerNodeList count]; i++) {
        
        NSDictionary *dictAtPn = self.playerNodeList[i];
        NSString *trackID = dictAtPn[@"trackid"];
        
        if ([trackID isEqualToString:selectedTrackID]) {
            trackIndex = i;
            break;
        }
    }
    
    NSMutableDictionary *newEffect;
    
    switch (effect) {
            
        case JWEffectNodeTypeReverb:
            
            newEffect = [@{
                       @"title" : @"Reverb",
                       @"factorypreset" : @(AVAudioUnitReverbPresetMediumHall)
                       } mutableCopy];
            break;
            
        case JWEffectNodeTypeDelay:
            
            newEffect = [@{
                           @"title" : @"Delay",
                           @"feedback" : @(50), //from -100 to 100 percent
                           @"delaytime" : @(1), //from 0 to 2 seconds
                           @"lowpasscutoff" : @(1500) //from 10 hz to sampleRate / 2
                           } mutableCopy];
            break;
            
        case JWEffectNodeTypeDistortion:
            
            newEffect = [@{
                           @"title" : @"Distortion",
                           @"factorypreset" : @(AVAudioUnitDistortionPresetDrumsBitBrush),
                           @"pregain" : @(0.0)
                           } mutableCopy];
            break;
            
        case JWEffectNodeTypeEQ:
            
            break;
            
            
        default:
            break;
    }
    
    newEffect[@"type"] = @(effect); //JWEffectType
    newEffect[@"wetdry"] = @(100); //from 0 to 100 percent
    
    NSMutableArray *effectsArray = self.playerNodeList[trackIndex][@"effects"];
    if (effectsArray) {
        [effectsArray addObject:newEffect];
    } else {
        effectsArray = [@[newEffect] mutableCopy];
        self.playerNodeList[trackIndex][@"effects"] = effectsArray;
    }
    
    // Either a new effects array was created or an effect was added to existing Array
    // Either pass up the entire array
    
    if ([_engineEffectsDelegate respondsToSelector:@selector(effectsChanged:inNodeAtIndex:)])
        [_engineEffectsDelegate effectsChanged:effectsArray inNodeAtIndex:trackIndex];

    
    [self refreshEngineForEffectsNodeChanges];
    
    return YES;
}


@end


