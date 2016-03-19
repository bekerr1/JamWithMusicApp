//
//  JWEffectsClipAudioEngine.m
//  JamWIthT
//
//  co-created by joe and brendan kerr on 10/29/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import "JWEffectsClipAudioEngine.h"
//#import "JWMixPanelViewController.h"


@interface JWEffectsClipAudioEngine() <JWEffectsHandler>
@property (strong, nonatomic) NSArray *effectnodesList; // an item for each player, another array stack of effects
@property (strong, nonatomic) NSMutableArray *effectnodes; // holds objects AudioNodes
@property (nonatomic) JWCurrentEffect currentEffect;
@end


@implementation JWEffectsClipAudioEngine

-(void)setupAVEngine {
    
    NSLog(@"%s",__func__);
    [self effectsEngineConfig];
    [self effectsEngineConfigPrepare:NO];
    
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
    
    /*  To support the instantiation of arbitrary AVAudioNode subclasses, instances are created
     externally to the engine, but are not usable until they are attached to the engine via
     the attachNode method. */

    for (id playernodeEffects in _effectnodes)
    {
        for (id effectsNode in playernodeEffects)
        {
            [self.audioEngine attachNode:effectsNode];
        }
    }
}

- (void)makeEngineConnections
{
    NSLog(@"%s",__func__);

    [super makeEngineConnections];
    
    /*  The engine will construct a singleton main mixer and connect it to the outputNode on demand,
     when this property is first accessed. You can then connect additional nodes to the mixer.
     
     By default, the mixer's output format (sample rate and channel count) will track the format
     of the output node. You may however make the connection explicitly with a different format. */
    
    // get the engine's optional singleton main mixer node
    //    AVAudioMixerNode *mainMixer = [self.audioEngine mainMixerNode];
    
    // establish a connection between nodes
    
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
    
    AVAudioMixerNode* mainMixer = [self.audioEngine mainMixerNode];
    
    // IS Only two player
    NSUInteger nNodes = [_effectnodes[0] count] + [_effectnodes[1] count];
    
    if (nNodes > 0) {

        NSUInteger index = 0; //[self makeEffectNodesConnections];
        
        for (id playernodeEffects in _effectnodes) {
            
            AVAudioMixerNode *mainMixer = [self.audioEngine mainMixerNode];
            
            // GET the player that will get the effects
            
            JWPlayerNode *playerNode;
            if (index==0) {
                playerNode = self.playerNode1;
            } else if (index==1) {
                playerNode = self.playerNode2;
            }
            
            if (self.audioBufferFromFile) {
                
                AVAudioNode *lastnode = playerNode;  // the lastnode connected
                
                for (id effectsNode in playernodeEffects) {
                    
                    [self.audioEngine  connect:lastnode to:effectsNode  format:self.audioBufferFromFile.format];
                    lastnode = effectsNode;
                }
                
                [self.audioEngine connect:lastnode to:mainMixer format:self.audioBufferFromFile.format];
                
            } else {
                NSLog(@"%s NO audioBuffer player at index %ld perhaps try using audioFile for format ",__func__,index);
            }
            
            index++;
        }
        

    } else {
        [self.audioEngine connect:self.playerNode1 to:mainMixer format:self.audioBufferFromFile.format];
    }
    
    [self.audioEngine connect:self.playerNode2 to:mainMixer format:self.fiveSecondBuffer.format];
    
}

#pragma mark -

-(NSArray *)config {
    
    return _effectnodesList;
}

-(BOOL)configChanged:(NSArray *)config {
    
    _effectnodesList = config;
    [self refreshEngineForEffectsNodeChanges];
    [self saveUserOrderedList];
    return 1;
}


//
// joe: impl nil func
-(id <JWEffectsModifyingProtocol> )effectNodeAtIndex:(NSUInteger)eindex forPlayerNodeAtIndex:(NSUInteger)pindex {
    return nil;

    
//    id node = _effectnodes[pindex][eindex];
//    return node;

}


-(id <JWEffectsModifyingProtocol> )playerNodeAtIndex:(NSUInteger)pindex {

    return nil;
    /*
     still a little sketchy asit it doesnt consult the playerList
     */
//    id <JWEffectsModifyingProtocol> result;
//    if (pindex == 0) {
//        result = self.playerNode1;
//        //        result = self.playerNodes[0];
//        
//    } else if (pindex == 1) {
//        result = self.playerNode2;
//        //        result = self.playerNodes[1];
//    }
//    return result;
}

-(id <JWEffectsModifyingProtocol> )mixerNodeAtIndex:(NSUInteger)pindex
{
    return nil;
}

-(id <JWEffectsModifyingProtocol> )recorderNodeAtIndex:(NSUInteger)pindex
{
    return nil;

}

-(NSMutableArray *)configPlayerNodeList
{
    return nil;
}




//-(void)addEffectsToNode:(NSUInteger)node forTitle:(NSString *)title andType:(NSString *)type {
//    _effectnodesList = [self readUserOrderedList];
//    [_effectnodesList[node] addObject:
//     [@{@"title":title,
//        @"type":type
//        } mutableCopy]
//     ];
//    //TODO: enum the current effect that should be used
//    [self setCurrentEffect:self.currentEffect withStringTitle:title];
//    [self saveUserOrderedList];
//}

-(void)setCurrentEffect:(JWCurrentEffect)currentEffect withStringTitle:(NSString *)title {
    
    if ([title isEqualToString:@"Effect Reverb"]) {
        self.currentEffect = EffectReverb;
    } else if ([title isEqualToString:@"Effect EQ"]) {
        self.currentEffect = EffectEQ;
    } else if ([title isEqualToString:@"Effect Delay"]) {
        self.currentEffect = EffectDelay;
    } else if ([title isEqualToString:@"Effect Distortion"]) {
        self.currentEffect = EffectDistortion;
    }
}



-(void)refreshEngineForEffectsNodeChanges {
    
    // Detach the nodes
    
    for (id playernodeEffects in _effectnodes)
    {
        for (id effectsNode in playernodeEffects)
        {
            [self.audioEngine detachNode:effectsNode];
        }
    }

    [_effectnodes removeAllObjects];
    [self effectsEngineConfigPrepare:YES]; // YES is refresh
    
    // Attach the nodes
    for (id playernodeEffects in _effectnodes) {
        for (id effectsNode in playernodeEffects) {
            [self.audioEngine attachNode:effectsNode];
        }
    }
    
    
    // Count number of nodes across all players
    NSUInteger nNodes = 0;
    for (id playernodeEffects in _effectnodes) {
        nNodes += [playernodeEffects count];
    }
    if (nNodes > 0) {
        
        [self makeEngineConnections];
    }

    [self startEngine];

    //        [self makeEffectNodesConnections];
    // joe: done by makeEngineConnections
    //    else {
    //        AVAudioMixerNode* mainMixer = [self.audioEngine mainMixerNode];
    //        [self.audioEngine connect:self.playerNode1 to:mainMixer format:self.audioBufferFromFile.format];
    //    }
    
}

#pragma mark -

//Dont think this needs to be called from refresh, since the array is set directly
//from the delegate
-(void)effectsEngineConfig {
   
    if (_effectnodesList == nil) {
        self.effectnodesList =@[@[],@[]];
        [self saveUserOrderedList];
    }
    _effectnodesList = [self readUserOrderedList];
    
    if (_effectnodesList == nil) {
        // joe: an empty array should be fine
        self.effectnodesList =@[];
        // for two players is this
        self.effectnodesList =@[@[],@[]];

    }

    // joe: dont need these
//        [self.effectnodesList addObject:[@[] mutableCopy]];
//        [self.effectnodesList addObject:[@[] mutableCopy]];
    
//        _effectnodesList[0] =
//        [@[@{@"title":@"Effect Reverb",
//             @"type":@"effectsnodeReverbPresetMediumHall3",
//             @"value":@(0.50)
//             },
//           @{@"title":@"Effect Delay",
//             @"type":@"effectsnodeDelay",
//             @"delayvalue":@(0.50),
//             @"wetdryvalue":@(0.00)
//             }
//           ] mutableCopy];
//    }
}

-(void)effect:(NSString *)effect presetChangeTo:(NSString *)presetString {
    //TODO: protocal/delegate function that can be used to load a preset if the engine allows it
    //(not sure if you have to disconnect and load then reconnect or if you can just load
    
    
}

-(void)effectsEngineConfigPrepare:(BOOL)isRefresh {
    
    // Containers for real AVAudioNode objects
    self.effectnodes = [@[] mutableCopy];
    [self.effectnodes addObject:[@[] mutableCopy]];
    [self.effectnodes addObject:[@[] mutableCopy]];
    
    for (NSDictionary *effect in _effectnodesList[0]) {
        
        NSString *effectKind = effect[@"type"];
        NSString *effectTitle = effect[@"title"];
        
        
        if ([effectTitle isEqualToString:@"Effect Reverb"]) {
            
            AVAudioUnitReverb   *reverb = [AVAudioUnitReverb new];
            
            if ([effectKind isEqualToString:@"effectsnodeReverbPresetSmallRoom"]) {
                [reverb loadFactoryPreset:AVAudioUnitReverbPresetSmallRoom];
            } else if ([effectKind isEqualToString:@"effectsnodeReverbPresetMediumRoom"]) {
                [reverb loadFactoryPreset:AVAudioUnitReverbPresetMediumRoom];
            } else if ([effectKind isEqualToString:@"effectsnodeReverbPresetLargeRoom"]) {
                [reverb loadFactoryPreset:AVAudioUnitReverbPresetLargeRoom];
            } else if ([effectKind isEqualToString:@"effectsnodeReverbPresetMediumHall"]) {
                [reverb loadFactoryPreset:AVAudioUnitReverbPresetMediumHall];
            } else if ([effectKind isEqualToString:@"effectsnodeReverbPresetLargeHall"]) {
                [reverb loadFactoryPreset:AVAudioUnitReverbPresetLargeHall];
            } else if ([effectKind isEqualToString:@"effectsnodeReverbPresetPlate"]) {
                [reverb loadFactoryPreset:AVAudioUnitReverbPresetPlate];
            } else if ([effectKind isEqualToString:@"effectsnodeReverbPresetMediumChamber"]) {
                [reverb loadFactoryPreset:AVAudioUnitReverbPresetMediumChamber];
            } else if ([effectKind isEqualToString:@"effectsnodeReverbPresetLargeChamber"]) {
                [reverb loadFactoryPreset:AVAudioUnitReverbPresetLargeChamber];
            } else if ([effectKind isEqualToString:@"effectsnodeReverbPresetLargeRoom2"]) {
                [reverb loadFactoryPreset:AVAudioUnitReverbPresetLargeRoom2];
            } else if ([effectKind isEqualToString:@"effectsnodeReverbPresetMediumHall2"]) {
                [reverb loadFactoryPreset:AVAudioUnitReverbPresetMediumHall2];
            } else if ([effectKind isEqualToString:@"effectsnodeReverbPresetMediumHall3"]) {
                [reverb loadFactoryPreset:AVAudioUnitReverbPresetMediumHall3];
            } else if ([effectKind isEqualToString:@"effectsnodeReverbPresetLargeHall2"]) {
                [reverb loadFactoryPreset:AVAudioUnitReverbPresetLargeHall2];
            } else {
                // Unknown
                [reverb loadFactoryPreset:AVAudioUnitReverbPresetMediumHall3];
            }
            
            if (isRefresh) {
                reverb.wetDryMix = 55;
            }
            
            [_effectnodes[0] addObject:reverb];
            
        } else if ([effectTitle isEqualToString:@"Effect Delay"]) {
            
            AVAudioUnitDelay   *delay = [AVAudioUnitDelay new];
            delay.delayTime = 0.5;
            delay.wetDryMix = 0.0;
            
            //            if (isRefresh) {
            //                delay.wetDryMix = 0.33;
            //            } else {
            //                delay.wetDryMix = 0.0;
            //            }
            
            [_effectnodes[0] addObject:delay];
        } else if ([effectTitle isEqualToString:@"Effect EQ"]) {
            
            
        } else if ([effectTitle isEqualToString:@"Effect Distortion"]) {
            
//            if ([effectKind isEqualToString:@"AVAudioUnitDistortionPresetDrumsBitBrush"]) {
//                AVAudioUnitDistortionPresetDrumsBitBrush
//            } else if (effectKind isEqualToString:@"AVAudioUnitDistortionPresetDrumsBitBrush") {
//                AVAudioUnitDistortionPresetDrumsBitBrush
//            } else if (effectKind isEqualToString:@"AVAudioUnitDistortionPresetDrumsBitBrush") {
//                AVAudioUnitDistortionPresetDrumsBitBrush
//            } else if (effectKind isEqualToString:@"AVAudioUnitDistortionPresetDrumsBitBrush") {
//                AVAudioUnitDistortionPresetDrumsBitBrush
//            } else if (effectKind isEqualToString:@"AVAudioUnitDistortionPresetDrumsBitBrush") {
//                AVAudioUnitDistortionPresetDrumsBitBrush
//            } else if (effectKind isEqualToString:@"AVAudioUnitDistortionPresetDrumsBitBrush") {
//                AVAudioUnitDistortionPresetDrumsBitBrush
//            } else if (effectKind isEqualToString:@"AVAudioUnitDistortionPresetDrumsBitBrush") {
//                AVAudioUnitDistortionPresetDrumsBitBrush
//            } else if (effectKind isEqualToString:@"AVAudioUnitDistortionPresetDrumsBitBrush") {
//                AVAudioUnitDistortionPresetDrumsBitBrush
//            } else if (effectKind isEqualToString:@"AVAudioUnitDistortionPresetDrumsBitBrush") {
//                AVAudioUnitDistortionPresetDrumsBitBrush
//            } else if (effectKind isEqualToString:@"AVAudioUnitDistortionPresetDrumsBitBrush") {
//                AVAudioUnitDistortionPresetDrumsBitBrush
//            } else if (effectKind isEqualToString:@"AVAudioUnitDistortionPresetDrumsBitBrush") {
//                AVAudioUnitDistortionPresetDrumsBitBrush
//            }
            
//            AVAudioUnitDistortionPresetDrumsBitBrush
//            AVAudioUnitDistortionPresetDrumsBufferBeats
//            AVAudioUnitDistortionPresetDrumsLoFi
//            AVAudioUnitDistortionPresetMultiBrokenSpeaker
//            AVAudioUnitDistortionPresetMultiCellphoneConcert
//            AVAudioUnitDistortionPresetMultiDecimated1
//            AVAudioUnitDistortionPresetMultiDecimated2
//            AVAudioUnitDistortionPresetMultiDecimated3
//            AVAudioUnitDistortionPresetMultiDecimated4
//            AVAudioUnitDistortionPresetMultiDistortedFunk
//            AVAudioUnitDistortionPresetMultiDistortedCubed
//            AVAudioUnitDistortionPresetMultiDistortedSquared
//            AVAudioUnitDistortionPresetMultiEcho1
//            AVAudioUnitDistortionPresetMultiEcho2
//            AVAudioUnitDistortionPresetMultiEchoTight1
//            AVAudioUnitDistortionPresetMultiEchoTight2
//            AVAudioUnitDistortionPresetMultiEverythingIsBroken
//            AVAudioUnitDistortionPresetSpeechAlienChatter
//            AVAudioUnitDistortionPresetSpeechCosmicInterference
//            AVAudioUnitDistortionPresetSpeechGoldenPi
//            AVAudioUnitDistortionPresetSpeechRadioTower
//            AVAudioUnitDistortionPresetSpeechWaves
            
            
        }
    }
    
}




#pragma mark - adjustments to nodes

-(float)floatValue1ForPlayer:(NSUInteger)playerIndex  forEffectNodeAtIndex:(NSUInteger)index
{
    float result = 0.0f;
    
    NSString *nodetype = _effectnodesList[playerIndex][index][@"type"];
    BOOL isReverb = YES;
    NSRange r = [nodetype rangeOfString:@"effectsnodeReverb"];
    if (r.location == NSNotFound)
        isReverb = NO;
    
    if (isReverb) {
        id node = _effectnodes[playerIndex][index];
        result = [(AVAudioUnitReverb*)node wetDryMix]/100.0f;
    } else  if ([nodetype isEqualToString:@"effectsnodeDelay"]) {
        id node = _effectnodes[playerIndex][index];
        result = [(AVAudioUnitDelay*)node wetDryMix]/100.0f;
    } else {
        result = NO;
    }
    
    return result;
}


-(float)floatValue2ForPlayer:(NSUInteger)playerIndex  forEffectNodeAtIndex:(NSUInteger)index
{
    float result = 0.0f;
    return result;
}

-(BOOL)boolValue1ForPlayer:(NSUInteger)playerIndex  forEffectNodeAtIndex:(NSUInteger)index
{
    BOOL result = NO;
    NSString *nodetype = _effectnodesList[playerIndex][index][@"type"];
    
    BOOL isReverb = YES;
    NSRange r = [nodetype rangeOfString:@"effectsnodeReverb"];
    if (r.location == NSNotFound)
        isReverb = NO;
    
    if (isReverb) {
        id node = _effectnodes[playerIndex][index];
        result = [(AVAudioUnitReverb*)node bypass];
    } else  if ([nodetype isEqualToString:@"effectsnodeDelay"]) {
        id node = _effectnodes[playerIndex][index];
        result = [(AVAudioUnitDelay*)node bypass];
    } else {
        result = NO;
    }
    
    return result;
}


-(BOOL)adjustFloatValue1ForPlayer:(NSUInteger)playerIndex  forEffectNodeAtIndex:(NSUInteger)index toValue:(float)value
{
    BOOL result = YES;
    
    NSString *nodetype = _effectnodesList[playerIndex][index][@"type"];
    BOOL isReverb = YES;
    NSRange r = [nodetype rangeOfString:@"effectsnodeReverb"];
    if (r.location == NSNotFound)
        isReverb = NO;
    
    if (isReverb) {
        // value1 for REVERB  wetdry
        id node = _effectnodes[playerIndex][index];
        //        NSLog(@"%s reverb %ld %.3f",__func__,index,value);
        [(AVAudioUnitReverb*)node setWetDryMix:value*100.0f];
    } else  if ([nodetype isEqualToString:@"effectsnodeDelay"]) {
        id node = _effectnodes[playerIndex][index];
        //        NSLog(@"%s delay %ld %.3f",__func__,index,value);
        // value1 for DELAY  wetdry
        [(AVAudioUnitDelay*)node setWetDryMix:value*100.0f];
    } else {
        result = NO;
    }
    return result;
}

-(BOOL)adjustFloatValue2ForPlayer:(NSUInteger)playerIndex  forEffectNodeAtIndex:(NSUInteger)index toValue:(float)value
{
    BOOL result = YES;
    
    NSString *nodetype = _effectnodesList[playerIndex][index][@"type"];
    if ([nodetype isEqualToString:@"effectsnodeReverb"]) {
        // NONE
    } else  if ([nodetype isEqualToString:@"effectsnodeDelay"]) {
        // value1 for REVERB  wetdry
        // NONE
    } else {
        result = NO;
    }
    return result;
}

-(BOOL)adjustBoolValue1ForPlayer:(NSUInteger)playerIndex  forEffectNodeAtIndex:(NSUInteger)index toValue:(BOOL)value
{
    BOOL result = YES;
    NSString *nodetype = _effectnodesList[playerIndex][index][@"type"];
    
    BOOL isReverb = YES;
    NSRange r = [nodetype rangeOfString:@"effectsnodeReverb"];
    if (r.location == NSNotFound)
        isReverb = NO;
    
    if (isReverb) {
        // value1 for REVERB  wetdry
        id node = _effectnodes[playerIndex][index];
        
        [(AVAudioUnitReverb*)node setBypass:value];
    } else  if ([nodetype isEqualToString:@"effectsnodeDelay"]) {
        // value1 for DELAY  wetdry
        id node = _effectnodes[playerIndex][index];
        
        [(AVAudioUnitDelay*)node setBypass:value];
    } else {
        result = NO;
    }
    return result;
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






//    -(void)makeEffectNodesConnections {
//        NSUInteger nNodes = [_effectnodes[0] count];
//        if (nNodes > 0) {
//
//            AVAudioMixerNode* mainMixer = [self.audioEngine mainMixerNode];
//            NSUInteger effectIndex = 0;
//            AVAudioNode *node = _effectnodes[0][effectIndex];
//
//            [self.audioEngine  connect: self.playerNode1 to:node  format:self.audioBufferFromFile.format];
//
//            AVAudioNode *lastnode = node;
//
//            if (++effectIndex < nNodes) {
//                node = _effectnodes[0][effectIndex];
//                [self.audioEngine  connect: lastnode to:node format:self.audioBufferFromFile.format];
//                lastnode = node;
//            }
//            if (++effectIndex < nNodes) {
//                node = _effectnodes[0][effectIndex];
//                [self.audioEngine  connect: lastnode to:node format:self.audioBufferFromFile.format];
//                lastnode = node;
//            }
//            if (++effectIndex < nNodes) {
//                node = _effectnodes[0][effectIndex];
//                [self.audioEngine  connect: lastnode to:node format:self.audioBufferFromFile.format];
//                lastnode = node;
//            }
//
//            [self.audioEngine connect:lastnode to:mainMixer format:self.audioBufferFromFile.format];
//        }
//    }


