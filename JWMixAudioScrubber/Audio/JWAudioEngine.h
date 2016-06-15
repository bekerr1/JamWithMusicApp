//
//  JWAudioEngine.h
//  
//
//  co-created by joe and brendan kerr on 9/27/15.
//
//
@import Foundation;
@import AVFoundation;

@protocol JWAudioEngineDelegate;

@interface JWAudioEngine : NSObject
@property (nonatomic) AVAudioEngine* audioEngine;
@property (weak) id <JWAudioEngineDelegate> delegate;

@property (nonatomic) AVAudioPlayerNode* primaryPlayerNode;  // a primary player for all subclasses to use

- (void)initAVAudioSession;
- (void)createEngineAndAttachNodes;
- (void)makeEngineConnections;
- (void)startEngine;
-(BOOL)engineRunning;
- (void)stopPlayersForInterruption;
// helper
- (void)logAudioFormat:(AVAudioFormat*)audio;
@end


@protocol JWAudioEngineDelegate <NSObject>
@optional
- (void)engineWasInterrupted;
- (void)engineConfigurationHasChanged;
@end


