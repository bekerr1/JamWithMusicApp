//
//  JWAudioEngine.m
//  
//
//  Created by JOSEPH KERR on 9/27/15.
//
//

#import "JWAudioEngine.h"

//- (void)handleInterruption:(NSNotification *)notification;
//- (void)handleRouteChange:(NSNotification *)notification;

@implementation JWAudioEngine

- (void)startEngine {
    
    NSLog(@"%s starts here",__func__);
    
    if (!self.audioEngine.isRunning) {
        NSError *error;
        NSAssert([self.audioEngine startAndReturnError:&error], @"couldn't start engine, %@", [error localizedDescription]);
    }
}


- (void)stopPlayersForInterruption
{
    NSLog(@"%s",__func__);
    // leave it to subclasses

}

- (void)createEngineAndAttachNodes
{
    NSLog(@"%s",__func__);

    /*  An AVAudioEngine contains a group of connected AVAudioNodes ("nodes"), each of which performs
     an audio signal generation, processing, or input/output task.
     
     Nodes are created separately and attached to the engine.
     
     The engine supports dynamic connection, disconnection and removal of nodes while running,
     with only minor limitations:
     - all dynamic reconnections must occur upstream of a mixer
     - while removals of effects will normally result in the automatic connection of the adjacent
     nodes, removal of a node which has differing input vs. output channel counts, or which
     is a mixer, is likely to result in a broken graph. */
    
    self.audioEngine = [[AVAudioEngine alloc] init];
    
    /*  To support the instantiation of arbitrary AVAudioNode subclasses, instances are created
     externally to the engine, but are not usable until they are attached to the engine via
     the attachNode method. */
    
    // leave it to subclasses
}

- (void)makeEngineConnections
{
    NSLog(@"%s",__func__);

    // nothing to connect here
    // leave it to subclasses
    
    
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
    
    // marimba player -> delay -> main mixer
//    [_engine connect: _marimbaPlayer to:_delay format:_marimbaLoopBuffer.format];
//    [_engine connect:_delay to:mainMixer format:_marimbaLoopBuffer.format];
//    // drum player -> reverb -> main mixer
//    [_engine connect:_drumPlayer to:_reverb format:_drumLoopBuffer.format];
//    [_engine connect:_reverb to:mainMixer format:_drumLoopBuffer.format];
//    // node tap player
//    [_engine connect:_mixerOutputFilePlayer to:mainMixer format:[mainMixer outputFormatForBus:0]];

}


-(void)logAudioFormat:(AVAudioFormat*)audio {
    NSLog(@": %@", [audio description]);
    NSLog(@" mSampleRate: %.3f", audio.streamDescription->mSampleRate);
    NSLog(@" mBitsPerChannel: %d", audio.streamDescription->mBitsPerChannel);
    NSLog(@" mChannelsPerFrame: %d", audio.streamDescription->mChannelsPerFrame);
    NSLog(@" mBytesPerFrame: %d", audio.streamDescription->mBytesPerFrame);
    NSLog(@" mBytesPerPacket: %d", audio.streamDescription->mBytesPerPacket);
    NSLog(@" mFramesPerPacket: %d", audio.streamDescription->mFramesPerPacket);
    //To determine the duration represented by one packet, use the mSampleRate field with the mFramesPerPacket field, as follows:
    //duration = (1 / mSampleRate) * mFramesPerPacket
    Float64 duration = (1.0 / audio.streamDescription->mSampleRate) * audio.streamDescription->mFramesPerPacket;
    NSLog(@" Time Duration per packet %ff",duration);
}

//    NSLog(@"File URL:          %@\n", fileURL.absoluteString);
//    NSLog(@"File format:       %@\n", audioFile.fileFormat.description);
//    NSLog(@"Processing format: %@\n", audioFile.processingFormat.description);
//    NSLog(@"Length:            %lld frames, %.3f seconds\n", (long long)fileLength, fileLength / audioFile.fileFormat.sampleRate);


#pragma mark AVAudioSession

- (void)initAVAudioSession
{
    // For complete details regarding the use of AVAudioSession see the AVAudioSession Programming Guide
    // https://developer.apple.com/library/ios/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/Introduction/Introduction.html
    
    // Configure the audio session
    AVAudioSession *sessionInstance = [AVAudioSession sharedInstance];
    NSError *error;
    
    // set the session category
    //    bool success = [sessionInstance setCategory:AVAudioSessionCategoryPlayback error:&error];
    
    bool success = [sessionInstance setCategory:AVAudioSessionCategoryPlayAndRecord
                                    withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:&error];
    
    if (!success) NSLog(@"Error setting AVAudioSession category! %@\n", [error localizedDescription]);
    
    double hwSampleRate = 44100.0;
    success = [sessionInstance setPreferredSampleRate:hwSampleRate error:&error];
    if (!success) NSLog(@"Error setting preferred sample rate! %@\n", [error localizedDescription]);
    
    NSTimeInterval ioBufferDuration = 0.0029;
    success = [sessionInstance setPreferredIOBufferDuration:ioBufferDuration error:&error];
    if (!success) NSLog(@"Error setting preferred io buffer duration! %@\n", [error localizedDescription]);
    
    // add interruption handler
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleInterruption:)
                                                 name:AVAudioSessionInterruptionNotification
                                               object:sessionInstance];
    
    // we don't do anything special in the route change notification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleRouteChange:)
                                                 name:AVAudioSessionRouteChangeNotification
                                               object:sessionInstance];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleMediaServicesReset:)
                                                 name:AVAudioSessionMediaServicesWereResetNotification
                                               object:sessionInstance];
    
    // activate the audio session
    success = [sessionInstance setActive:YES error:&error];
    if (!success) NSLog(@"Error setting session active! %@\n", [error localizedDescription]);
    
    NSArray* inputs = sessionInstance.availableInputs;
    AVAudioSessionPortDescription* builtInMicrophone;
    for (AVAudioSessionPortDescription* input in inputs) {
        NSLog(@" %@", input.portType);
        if ([input.portType isEqualToString:@"MicrophoneBuiltIn"]) {
            builtInMicrophone = input;
        }
    }
    
    [sessionInstance setPreferredInput:builtInMicrophone error:&error];
    
    AVAudioSessionRouteDescription* currentRoute = sessionInstance.currentRoute;
    NSLog(@"Current Route:\n ");
    NSLog(@"%@", currentRoute);
    
    NSUInteger numberOfInputs = sessionInstance.maximumInputNumberOfChannels;
    NSUInteger numberOfOutputs = sessionInstance.maximumOutputNumberOfChannels;
    NSLog(@"Input Channels: %li", (long)sessionInstance.inputNumberOfChannels);
    NSLog(@"Max Number of Inputs: %lu", (unsigned long)numberOfInputs);
    NSLog(@"Output Channels: %li", (long)sessionInstance.outputNumberOfChannels);
    NSLog(@"Max Number of Outputs: %lu", (unsigned long)numberOfOutputs);
}


- (void)handleInterruption:(NSNotification *)notification
{
    UInt8 theInterruptionType = [[notification.userInfo valueForKey:AVAudioSessionInterruptionTypeKey] intValue];
    
    NSLog(@"Session interrupted > --- %s ---\n", theInterruptionType == AVAudioSessionInterruptionTypeBegan ? "Begin Interruption" : "End Interruption");
    
    if (theInterruptionType == AVAudioSessionInterruptionTypeBegan) {
//        //        [_drumPlayer stop];
//        //        [_marimbaPlayer stop];
//        [_micPlayer stop];
//        [self stopPlayingRecordedFile];
//        [self stopRecordingMixerOutput];
        
        [self stopPlayersForInterruption];
        
        if ([self.delegate respondsToSelector:@selector(engineWasInterrupted)]) {
            [self.delegate engineWasInterrupted];
        }
    }
    if (theInterruptionType == AVAudioSessionInterruptionTypeEnded) {
        // make sure to activate the session
        NSError *error;
        bool success = [[AVAudioSession sharedInstance] setActive:YES error:&error];
        if (!success) NSLog(@"AVAudioSession set active failed with error: %@", [error localizedDescription]);
        
        // start the engine once again
        [self startEngine];
    }
}

- (void)handleRouteChange:(NSNotification *)notification
{
    UInt8 reasonValue = [[notification.userInfo valueForKey:AVAudioSessionRouteChangeReasonKey] intValue];
    AVAudioSessionRouteDescription *routeDescription = [notification.userInfo valueForKey:AVAudioSessionRouteChangePreviousRouteKey];
    
    NSLog(@"Route change:");
    switch (reasonValue) {
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            NSLog(@"     NewDeviceAvailable");
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            NSLog(@"     OldDeviceUnavailable");
            break;
        case AVAudioSessionRouteChangeReasonCategoryChange:
            NSLog(@"     CategoryChange");
            NSLog(@" New Category: %@", [[AVAudioSession sharedInstance] category]);
            break;
        case AVAudioSessionRouteChangeReasonOverride:
            NSLog(@"     Override");
            break;
        case AVAudioSessionRouteChangeReasonWakeFromSleep:
            NSLog(@"     WakeFromSleep");
            break;
        case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory:
            NSLog(@"     NoSuitableRouteForCategory");
            break;
        default:
            NSLog(@"     ReasonUnknown");
    }
    
    NSLog(@"Previous route:\n");
    NSLog(@"%@", routeDescription);
}

- (void)handleMediaServicesReset:(NSNotification *)notification
{
    // if we've received this notification, the media server has been reset
    // re-wire all the connections and start the engine
    NSLog(@"Media services have been reset!");
    NSLog(@"Re-wiring connections and starting once again");
    
    [self createEngineAndAttachNodes];
    [self initAVAudioSession];
    [self makeEngineConnections];
    [self startEngine];
    
    // post notification
    if ([self.delegate respondsToSelector:@selector(engineConfigurationHasChanged)]) {
        [self.delegate engineConfigurationHasChanged];
    }
}

@end
