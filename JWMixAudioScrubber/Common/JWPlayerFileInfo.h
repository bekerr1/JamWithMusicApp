//
//  JWPlayerFileInfo.h
//  JWAudio
//
//  Created by JOSEPH KERR on 11/20/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 Given a track with durationRawTrack
 A clip from that track can be obtained using insets startPositionInset and endPositionInset
 
 startPositionInset - seconds into raw track to begin playback (Clip Left)
 endPositionInset - seconds into raw track from end playback will end (Clip Right)
 
 method calculateAtCurrentPosition will take a current position of all tracks
 startPosition is set to the start position when playback should start
 startPosition GREATER than currentPos  == the track has not begun play
 startPosition EQUAL to currentPos == the track begins to play
 startPosition LESS than currentPos == the track is being played
 startPosition + durationPlayback LESS than currentPos == track is done playing
 
 duration is computed by subtracting insets (both start and end)
 set These ...
 - trackStartPosition
 - trackDuration
 - startPositionInset
 - endPositionInset
 
 and get these (with currentPosition)
 - duration
 - remainingInTrack
 - currentPositionIntrack
 - startPositionInReferencedTrack
 - readPositionInReferencedTrack
 
 Use readPosition to read AudioFile at psotion for a duration
 */


@interface JWPlayerFileInfo : NSObject

// fixed
@property (nonatomic) float trackStartPosition;
@property (nonatomic) float trackDuration;  // raw track length (unclipped)
@property (nonatomic) float startPositionInset;
@property (nonatomic) float endPositionInset;

-(instancetype)initWithCurrentPosition:(float)currentPosition duration:(float)duration;
-(instancetype)initWithCurrentPosition:(float)currentPosition duration:(float)duration
                         startPosition:(float)startPos;

-(instancetype)initWithCurrentPosition:(float)currentPosition duration:(float)duration
                         startPosition:(float)sPos
                            startInset:(float)sInset
                              endInset:(float)eInset;

-(instancetype)initWithCurrentPosition:(float)currentPosition duration:(float)duration
                            startInset:(float)sInset
                              endInset:(float)eInset;

// computed
@property (nonatomic,readonly) float duration;  // duration playback
@property (nonatomic,readonly) float remainingInTrack;
@property (nonatomic,readonly) float currentPositionIntrack;
@property (nonatomic,readonly) float startPositionInReferencedTrack;
@property (nonatomic,readonly) float readPositionInReferencedTrack;

-(void) calculateAtCurrentPosition:(float)currentPos;

@end
