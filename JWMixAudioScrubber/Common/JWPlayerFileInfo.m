//
//  JWPlayerFileInfo.m
//  JWAudio
//
//  Created by JOSEPH KERR on 11/20/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import "JWPlayerFileInfo.h"

@interface JWPlayerFileInfo ()

@property (nonatomic) float readPosition;
@property (nonatomic,readwrite) float duration;  // duration playback
@property (nonatomic,readwrite) float remainingInTrack;
@property (nonatomic,readwrite) float currentPositionIntrack;
@property (nonatomic,readwrite) float startPositionInReferencedTrack;
@property (nonatomic,readwrite) float readPositionInReferencedTrack;
@end


@implementation JWPlayerFileInfo

-(instancetype)initWithCurrentPosition:(float)currentPosition duration:(float)duration startPosition:(float)startPos
{
    if (self = [super init])
    {
        self.trackDuration = duration;
        self.startPositionInset = 0.0;
        self.endPositionInset = 0.0;
        self.trackStartPosition = startPos;
        
        [self calculateAtCurrentPosition:currentPosition];
    }
    return self;
}

-(instancetype)initWithCurrentPosition:(float)currentPosition duration:(float)duration
{
    if (self = [super init])
    {
        self.trackDuration = duration;
        self.startPositionInset = 0.0;
        self.endPositionInset = 0.0;
        self.trackStartPosition = 0.0;
        
        [self calculateAtCurrentPosition:currentPosition];
    }
    return self;
}

-(instancetype)initWithCurrentPosition:(float)currentPosition duration:(float)duration startInset:(float)sInset endInset:(float)eInset
{
    if (self = [super init])
    {
        self.trackDuration = duration;
        self.startPositionInset = sInset;
        self.endPositionInset = eInset;
        self.trackStartPosition = 0.0;
        
        [self calculateAtCurrentPosition:currentPosition];
    }
    return self;
}

-(instancetype)initWithCurrentPosition:(float)currentPosition duration:(float)duration startPosition:(float)sPos startInset:(float)sInset endInset:(float)eInset
{
    if (self = [super init])
    {
        self.trackDuration = duration;
        self.startPositionInset = sInset;
        self.endPositionInset = eInset;
        self.trackStartPosition = sPos;
        
        [self calculateAtCurrentPosition:currentPosition];
    }
    return self;
}

/*
_readPositionInReferencedTrack returns NEGATIVE when track not ready to be read
 
*/

-(void) calculateAtCurrentPosition:(float)currentPosition
{

    //-(void) calculate {
// startPosition;   fixed
// startPositionInset; fixed
// endPositionInset; fixed
// duration;   fixed
    
    _duration = _trackDuration - _endPositionInset - _startPositionInset;
    
    _currentPositionIntrack = currentPosition - _trackStartPosition;
    
    if (_currentPositionIntrack > _duration) {
        NSLog(@"%s cpos beyond length",__func__);
        _remainingInTrack = 0.0;

    }
//    else if (_currentPositionIntrack < 0) {
//        _remainingInTrack = 0.0;
//        
//    }
    else {
        _remainingInTrack = _duration - _currentPositionIntrack;
    }

    _startPositionInReferencedTrack = _trackStartPosition - _startPositionInset;
    
    if (currentPosition > _trackStartPosition) {

        _readPosition = _startPositionInset + _currentPositionIntrack; //(currentPosition - _trackStartPosition);
        // _readpos may be GREATER than track length which is a nonread

    } else {

        // LESS than _trackStartPos

        _readPosition = currentPosition - _startPositionInReferencedTrack;

        if (_startPositionInReferencedTrack < 0) {
//            _readPosition = (currentPosition + -(_startPositionInReferencedTrack));
        } else {
//            _readPosition = currentPosition - _startPositionInReferencedTrack;
        }

        if (currentPosition > _startPositionInReferencedTrack) {
            // results in positive but before Inset
        } else {
            // results in negative
        }
        
        // _readpos may be negative or lessThan inset
    }
    
    if (_remainingInTrack < 0.00001) {
        _readPositionInReferencedTrack = -1.0;
        
    } else if (_readPosition > (_startPositionInset + _duration)) {
        // beyond visible track
        _readPositionInReferencedTrack = -1.0;
        
    } else if (_readPosition < _startPositionInset){
        // before visible
        _readPositionInReferencedTrack = -1.0;
    } else {
        // negative orpositive
        _readPositionInReferencedTrack = _readPosition;
    }
    
}


@end
