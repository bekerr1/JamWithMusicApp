//
//  MasterViewController.h
//  JWAudioScrubber
//
//  Created by brendan kerr on 12/25/15.
//  Copyright © 2015 b3k3r. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DetailViewController;

@interface MasterViewController : UITableViewController

@property (strong, nonatomic) DetailViewController *detailViewController;

-(void)performNewJamTrack:(NSURL*)fileURL;


@end





/*
 LOG SELECT JT
 
 SET TRACKSET
 INITAVSESSION
 SCRUBBER RESET AND AUDIO ENGINE PLAY ALL

 
-- FIRST SELECT JT
 2016-01-14 17:03:09.567 JamWDev[515:151263] -[DetailViewController dealloc]
 2016-01-14 17:03:09.654 JamWDev[515:151263] -[DetailViewController viewDidLoad]
 BACK AND SELECT AGAIN
 2016-01-14 17:05:21.869 JamWDev[519:152179] -[DetailViewController dealloc]
 2016-01-14 17:05:21.871 JamWDev[519:152179] -[JWAudioEngine dealloc]
 2016-01-14 17:05:21.924 JamWDev[519:152179] -[DetailViewController viewDidLoad]
-- BACK AND SELECT AGAIN
 2016-01-14 17:05:21.869 JamWDev[519:152179] -[DetailViewController dealloc]
 2016-01-14 17:05:21.871 JamWDev[519:152179] -[JWAudioEngine dealloc]
 2016-01-14 17:05:21.924 JamWDev[519:152179] -[DetailViewController viewDidLoad]
-- BACK AND SELECT AGAIN
 2016-01-14 17:05:21.869 JamWDev[519:152179] -[DetailViewController dealloc]
 2016-01-14 17:05:21.871 JamWDev[519:152179] -[JWAudioEngine dealloc]
 2016-01-14 17:05:21.924 JamWDev[519:152179] -[DetailViewController viewDidLoad]

 
---------
 
 2016-01-14 17:03:09.567 JamWDev[515:151263] -[DetailViewController dealloc]
 2016-01-14 17:03:09.654 JamWDev[515:151263] -[DetailViewController viewDidLoad]
 
SET TRACKSET
 2016-01-14 17:03:09.740 JamWDev[515:151263] -[JWScrubberController reset]
 2016-01-14 17:03:09.751 JamWDev[515:151263] -[JWAudioPlayerController setTrackSet:]
 2016-01-14 17:03:09.751 JamWDev[515:151263] node type 2 title track  fname TheKillersTrimmedMP3-30.m4a
 2016-01-14 17:03:09.752 JamWDev[515:151263] node type 3 title track recorder  fname nofilurl
 INITAVSESSION
 2016-01-14 17:03:10.011 JamWDev[515:151263]  MicrophoneBuiltIn
 2016-01-14 17:03:10.012 JamWDev[515:151263]  found AVAudioSessionPortBuiltInMic MicrophoneBuiltIn
 2016-01-14 17:03:10.015 JamWDev[515:151263] Current Route:
 
 2016-01-14 17:03:10.015 JamWDev[515:151263] <AVAudioSessionRouteDescription: 0x160a05a50,
 inputs = (
 "<AVAudioSessionPortDescription: 0x15c6b56e0, type = MicrophoneBuiltIn; name = iPhone Microphone; UID = Built-In Microphone; selectedDataSource = Bottom>"
 );
 outputs = (
 "<AVAudioSessionPortDescription: 0x15c6d42c0, type = Speaker; name = Speaker; UID = Speaker; selectedDataSource = (null)>"
 )>
 2016-01-14 17:03:10.016 JamWDev[515:151263] Input Channels: 1
 2016-01-14 17:03:10.016 JamWDev[515:151263] Max Number of Inputs: 1
 2016-01-14 17:03:10.016 JamWDev[515:151263] Output Channels: 1
 2016-01-14 17:03:10.016 JamWDev[515:151263] Max Number of Outputs: 1
 2016-01-14 17:03:10.047 JamWDev[515:151263] Audio files cannot be non-interleaved. Ignoring setting AVLinearPCMIsNonInterleaved YES.
 2016-01-14 17:03:10.048 JamWDev[515:151263] Audio files cannot be non-interleaved. Ignoring setting AVLinearPCMIsNonInterleaved YES.
 2016-01-14 17:03:10.049 JamWDev[515:151517] Route change:
 2016-01-14 17:03:10.049 JamWDev[515:151517]      CategoryChange
 2016-01-14 17:03:10.049 JamWDev[515:151517]  New Category: AVAudioSessionCategoryPlayAndRecord
 2016-01-14 17:03:10.049 JamWDev[515:151517] Previous route:
 2016-01-14 17:03:10.050 JamWDev[515:151517] <AVAudioSessionRouteDescription: 0x15c625650,
 inputs = (
 "<AVAudioSessionPortDescription: 0x15c625210, type = MicrophoneBuiltIn; name = iPhone Microphone; UID = Built-In Microphone; selectedDataSource = Front>"
 );
 outputs = (
 "<AVAudioSessionPortDescription: 0x15c6228a0, type = Speaker; name = Speaker; UID = Speaker; selectedDataSource = (null)>"
 )>
 2016-01-14 17:03:10.061 JamWDev[515:151263] -[JWMTAudioEngine createEngineAndAttachNodes] audioPlayerNode ATTACH
 2016-01-14 17:03:10.061 JamWDev[515:151263] -[JWMTAudioEngine createEngineAndAttachNodes] audioPlayerNode ATTACH
 2016-01-14 17:03:10.128 JamWDev[515:151263] -[JWMTAudioEngine makeEngineConnections] NO audioBuffer player at index 1 perhaps try using audioFile for format
 2016-01-14 17:03:10.128 JamWDev[515:151263] -[JWAudioEngine startEngine] starts here
 
 
 SCRUBBER RESET AND AUDIO ENGINE PLAY ALL

 2016-01-14 17:03:10.220 JamWDev[515:151263] -[JWScrubberController reset]
 2016-01-14 17:03:10.386 JamWDev[515:151263] usePlayerScrubber for recorderplayer NO at index 1
 2016-01-14 17:03:10.387 JamWDev[515:151263] -[JWMTAudioEngine activePlayerNodes] 0 activeNodes
 2016-01-14 17:03:10.387 JamWDev[515:151263] No Active player nodes to stop.
 2016-01-14 17:03:10.387 JamWDev[515:151263] -[JWMTAudioEngine scheduleAllWithOptions:insetSeconds:recording:] 0.000 secondsin  node count 2
 2016-01-14 17:03:10.445 JamWDev[515:151263] FileLength: 1323000  30.000 seconds. Buffer length 1323000
 2016-01-14 17:03:10.448 JamWDev[515:151263] -[AVAudioPlayerNode(JW) floatValue1] get volume 0.50
 2016-01-14 17:03:10.449 JamWDev[515:151263] -[AVAudioPlayerNode(JW) floatValue1] get volume 0.50
 2016-01-14 17:03:10.479 JamWDev[515:151263] -[AVAudioPlayerNode(JW) floatValue2] get pan 0.00
 2016-01-14 17:03:10.479 JamWDev[515:151263] -[AVAudioPlayerNode(JW) floatValue2] get pan 0.00
 2016-01-14 17:03:10.479 JamWDev[515:151263] -[AVAudioMixerNode(JW) floatValue1] get outputVolume 1.00
 2016-01-14 17:03:10.482 JamWDev[515:151263] -[AVAudioMixerNode(JW) floatValue2] get pan 0.00
 2016-01-14 17:03:10.483 JamWDev[515:151263] -[JWScrubberController floatValue1] get backlight 0.50
 2016-01-14 17:03:10.719 JamWDev[515:151263] -[JWMTAudioEngine playAllActivePlayerNodes] audioPlayerNode PLAY

 
 
 
 BACK AND SELECT AGAIN
 
 2016-01-14 17:05:21.869 JamWDev[519:152179] -[DetailViewController dealloc]
 2016-01-14 17:05:21.871 JamWDev[519:152179] -[JWAudioEngine dealloc]
 2016-01-14 17:05:21.924 JamWDev[519:152179] -[DetailViewController viewDidLoad]
 
 SET TRACKSET

 2016-01-14 17:05:21.961 JamWDev[519:152179] -[JWScrubberController reset]
 2016-01-14 17:05:21.971 JamWDev[519:152179] -[JWAudioPlayerController setTrackSet:]
 2016-01-14 17:05:21.971 JamWDev[519:152179] node type 2 title track  fname TheKillersTrimmedMP3-30.m4a
 2016-01-14 17:05:21.972 JamWDev[519:152179] node type 3 title track recorder  fname nofilurl
 INITAVSESSION
 2016-01-14 17:05:22.037 JamWDev[519:152179]  MicrophoneBuiltIn
 2016-01-14 17:05:22.037 JamWDev[519:152179]  found AVAudioSessionPortBuiltInMic MicrophoneBuiltIn
 2016-01-14 17:05:22.039 JamWDev[519:152179] Current Route:
 
 2016-01-14 17:05:22.040 JamWDev[519:152179] <AVAudioSessionRouteDescription: 0x12f5d1e30,
 inputs = (
 "<AVAudioSessionPortDescription: 0x12f5de9d0, type = MicrophoneBuiltIn; name = iPhone Microphone; UID = Built-In Microphone; selectedDataSource = Bottom>"
 );
 outputs = (
 "<AVAudioSessionPortDescription: 0x12f5b2280, type = Speaker; name = Speaker; UID = Speaker; selectedDataSource = (null)>"
 )>
 2016-01-14 17:05:22.040 JamWDev[519:152179] Input Channels: 1
 2016-01-14 17:05:22.040 JamWDev[519:152179] Max Number of Inputs: 1
 2016-01-14 17:05:22.041 JamWDev[519:152179] Output Channels: 1
 2016-01-14 17:05:22.041 JamWDev[519:152179] Max Number of Outputs: 1
 2016-01-14 17:05:22.077 JamWDev[519:152179] Audio files cannot be non-interleaved. Ignoring setting AVLinearPCMIsNonInterleaved YES.
 2016-01-14 17:05:22.077 JamWDev[519:152179] Audio files cannot be non-interleaved. Ignoring setting AVLinearPCMIsNonInterleaved YES.
 2016-01-14 17:05:22.088 JamWDev[519:152399] Route change:
 2016-01-14 17:05:22.088 JamWDev[519:152399]      CategoryChange
 2016-01-14 17:05:22.091 JamWDev[519:152399]  New Category: AVAudioSessionCategoryPlayAndRecord
 2016-01-14 17:05:22.091 JamWDev[519:152399] Previous route:
 2016-01-14 17:05:22.091 JamWDev[519:152399] <AVAudioSessionRouteDescription: 0x12f5cbcd0,
 inputs = (
 "<AVAudioSessionPortDescription: 0x133230a10, type = MicrophoneBuiltIn; name = iPhone Microphone; UID = Built-In Microphone; selectedDataSource = Bottom>"
 );
 outputs = (
 "<AVAudioSessionPortDescription: 0x12f5bb7d0, type = Speaker; name = Speaker; UID = Speaker; selectedDataSource = (null)>"
 )>
 2016-01-14 17:05:22.093 JamWDev[519:152399] Route change:
 2016-01-14 17:05:22.094 JamWDev[519:152399]      CategoryChange
 2016-01-14 17:05:22.096 JamWDev[519:152179] -[JWMTAudioEngine createEngineAndAttachNodes] audioPlayerNode ATTACH
 2016-01-14 17:05:22.096 JamWDev[519:152179] -[JWMTAudioEngine createEngineAndAttachNodes] audioPlayerNode ATTACH
 2016-01-14 17:05:22.111 JamWDev[519:152399]  New Category: AVAudioSessionCategoryPlayAndRecord
 2016-01-14 17:05:22.112 JamWDev[519:152399] Previous route:
 2016-01-14 17:05:22.119 JamWDev[519:152399] <AVAudioSessionRouteDescription: 0x133158c00,
 inputs = (
 "<AVAudioSessionPortDescription: 0x12f6383c0, type = MicrophoneBuiltIn; name = iPhone Microphone; UID = Built-In Microphone; selectedDataSource = Bottom>"
 );
 outputs = (
 "<AVAudioSessionPortDescription: 0x133134ec0, type = Receiver; name = Receiver; UID = Built-In Receiver; selectedDataSource = (null)>"
 )>
 2016-01-14 17:05:22.164 JamWDev[519:152179] -[JWMTAudioEngine makeEngineConnections] NO audioBuffer player at index 1 perhaps try using audioFile for format
 2016-01-14 17:05:22.164 JamWDev[519:152179] -[JWAudioEngine startEngine] starts here
 
 SCRUBBER RESET AND AUDIO ENGINE PLAY ALL
 2016-01-14 17:05:22.253 JamWDev[519:152179] -[JWScrubberController reset]
 2016-01-14 17:05:22.418 JamWDev[519:152179] usePlayerScrubber for recorderplayer NO at index 1
 2016-01-14 17:05:22.419 JamWDev[519:152179] -[JWMTAudioEngine activePlayerNodes] 0 activeNodes
 2016-01-14 17:05:22.419 JamWDev[519:152179] No Active player nodes to stop.
 2016-01-14 17:05:22.419 JamWDev[519:152179] -[JWMTAudioEngine scheduleAllWithOptions:insetSeconds:recording:] 0.000 secondsin  node count 2
 2016-01-14 17:05:22.491 JamWDev[519:152179] FileLength: 1323000  30.000 seconds. Buffer length 1323000
 2016-01-14 17:05:22.495 JamWDev[519:152179] -[AVAudioPlayerNode(JW) floatValue1] get volume 0.50
 2016-01-14 17:05:22.495 JamWDev[519:152179] -[AVAudioPlayerNode(JW) floatValue1] get volume 0.50
 2016-01-14 17:05:22.495 JamWDev[519:152179] -[AVAudioPlayerNode(JW) floatValue2] get pan 0.00
 2016-01-14 17:05:22.496 JamWDev[519:152179] -[AVAudioPlayerNode(JW) floatValue2] get pan 0.00
 2016-01-14 17:05:22.496 JamWDev[519:152179] -[AVAudioMixerNode(JW) floatValue1] get outputVolume 1.00
 2016-01-14 17:05:22.499 JamWDev[519:152179] -[AVAudioMixerNode(JW) floatValue2] get pan 0.00
 2016-01-14 17:05:22.501 JamWDev[519:152179] -[JWScrubberController floatValue1] get backlight 0.50
 2016-01-14 17:05:22.746 JamWDev[519:152179] -[JWMTAudioEngine playAllActivePlayerNodes] audioPlayerNode PLAY
 2016-01-14 17:05:24.575 JamWDev[519:152179] -[JWAudioPlayerController stop]
 2016-01-14 17:05:24.576 JamWDev[519:152179] -[JWMTAudioEngine stopAllActivePlayerNodes] audioPlayerNode STOP
 2016-01-14 17:05:24.581 JamWDev[519:152390] Audio Completed for playerAtIndex 0
 
 
 

 */

