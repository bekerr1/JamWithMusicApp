//
//  CERangeSlider.m
//  DoubleSlider
//
//  co-created by joe and brendan kerr on 11/27/15.
//  Copyright © 2015 b3k3r. All rights reserved.
//

#import "CERangeSlider.h"
#import "CERangeSliderTrack.h"
#import <QuartzCore/QuartzCore.h>

@implementation CERangeSlider
{
    CERangeSliderTrack* _trackLayer;
    
    float _knobWidth;
    float _useableTrackLength;
    float _previousValueDelta;
    CGPoint _previousTouchPoint;
}



//#define GENERATE_SETTER(PROPERTY, TYPE, SETTER, UPDATER) \
//- (void)SETTER:(TYPE)PROPERTY { \
//if (_##PROPERTY != PROPERTY) { \
//_##PROPERTY = PROPERTY; \
//[self UPDATER]; \
//} \
//}
//
//GENERATE_SETTER(trackHighlightColour, UIColor*, setTrackHighlightColour, redrawLayers)
//
//GENERATE_SETTER(trackOutsideColour, UIColor*, setTrackHighlightColour, redrawLayers)
//
//GENERATE_SETTER(trackColour, UIColor*, setTrackColour, redrawLayers)
//
//GENERATE_SETTER(curvaceousness, float, setCurvaceousness, redrawLayers)
//
//GENERATE_SETTER(knobColour, UIColor*, setKnobColour, redrawLayers)
//
//GENERATE_SETTER(maximumValue, float, setMaximumValue, setLayerFrames)
//
//GENERATE_SETTER(minimumValue, float, setMinimumValue, setLayerFrames)
//
//GENERATE_SETTER(lowerValue, float, setLowerValue, setLayerFrames)
//
//GENERATE_SETTER(upperValue, float, setUpperValue, setLayerFrames)

- (void) redrawLayers
{
    
    [_upperKnobLayer setNeedsDisplay];
    [_lowerKnobLayer setNeedsDisplay];
    [_trackLayer setNeedsDisplay];
}


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        //self.userInteractionEnabled = NO;
        // Initialization code
        _maximumValue = 1.0;
        _minimumValue = 0.0;
        _upperValue = 0.5;
        _lowerValue = 0.0;
        
       // _trackHighlightColour = [UIColor colorWithHue:.60 saturation:.60 brightness:.100 alpha:1.0];
        _trackColour = [UIColor colorWithWhite:1.0 alpha:1.0];
        _knobColour = [UIColor whiteColor];
        _curvaceousness = 0.0;
       // _maximumValue = 10.0;
        //_minimumValue = 0.0;
        
        _trackLayer = [CERangeSliderTrack layer];
        _trackLayer.slider = self;
        [self.layer addSublayer:_trackLayer];
        
        _lowerKnobLayer = [CERangeSliderKnob layer];
        _lowerKnobLayer.slider = self;
        _lowerKnobLayer.lowerKnob = YES;
        [self.layer addSublayer:_lowerKnobLayer];
        
        _upperKnobLayer = [CERangeSliderKnob layer];
        _upperKnobLayer.slider = self;
        _upperKnobLayer.lowerKnob = NO;
        [self.layer addSublayer:_upperKnobLayer];
        
        [self setLayerFrames];
    }
    return self;
}

- (void) setLayerFrames
{
    _trackLayer.frame = CGRectInset(self.bounds, 0, self.bounds.size.height/2.2);
    [_trackLayer setNeedsDisplay];
    
    _knobWidth = self.bounds.size.height;
    _useableTrackLength = self.bounds.size.width - _knobWidth;
    
    float upperKnobCentre = [self positionForValue:_upperValue];
    float knobOffset = 60;
    //NSLog(@"upper knob frame x Position %f", upperKnobCentre - _knobWidth / 2);
    _upperKnobLayer.frame = CGRectMake(upperKnobCentre - _knobWidth + knobOffset / 2, 0, _knobWidth * 2, _knobWidth + 5);
    _upperKnobLayer.anchorPoint = CGPointMake(0.10, 0.5);
    self.upperKnobCenterInParent = [self convertPoint:_upperKnobLayer.position toView:self.superview];
    //NSLog(@"Super Point = %@", NSStringFromCGPoint(self.upperKnobCenterInParent));

    
    float lowerKnobCentre = [self positionForValue:_lowerValue];
    _lowerKnobLayer.frame = CGRectMake(lowerKnobCentre - _knobWidth - knobOffset / 2, 0, _knobWidth * 2, _knobWidth + 5);
    _lowerKnobLayer.anchorPoint = CGPointMake(0.90, 0.5);
    self.lowerKnobCenterInParent = [self convertPoint:_lowerKnobLayer.position toView:self.superview];
    //NSLog(@"Super Point = %@", NSStringFromCGPoint(self.lowerKnobCenterInParent));
    
    [_upperKnobLayer setNeedsDisplay];
    [_lowerKnobLayer setNeedsDisplay];
    
    
}

-(void)setMaxAllowedInterval:(float)maxAllowedInterval usingDuration:(float)trackDuration {
    
    float adjustedTimeInterval = maxAllowedInterval / trackDuration;
    _maxAllowedInterval = adjustedTimeInterval;
    _upperValue = _lowerValue + _maxAllowedInterval;
    _trackDuration = trackDuration;
    [self setLayerFrames];
}


- (float) positionForValue:(float)value
{
    
    NSLog(@"Current Value position: %f using useable track length of %f", _useableTrackLength * (value - _minimumValue) /
          (_maximumValue - _minimumValue) + (_knobWidth / 2), _useableTrackLength);
    
    return _useableTrackLength * (value - _minimumValue) /
    (_maximumValue - _minimumValue) + (_knobWidth / 2);
}


- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    NSLog(@"first Touch. %s", __func__);
    _previousTouchPoint = [touch locationInView:self];
    _animateToClear = !_animateToClear;
    
    // hit test the knob layers
    if(CGRectContainsPoint(_lowerKnobLayer.frame, _previousTouchPoint))
    {
        _lowerKnobLayer.highlighted = YES;
        _dragOnLower = YES;
        [_lowerKnobLayer setNeedsDisplay];
    }
    else if(CGRectContainsPoint(_upperKnobLayer.frame, _previousTouchPoint))
    {
        _upperKnobLayer.highlighted = YES;
        _dragOnLower = NO;
        [_upperKnobLayer setNeedsDisplay];
    }
    
    return _upperKnobLayer.highlighted || _lowerKnobLayer.highlighted;
}

#define BOUND(VALUE, UPPER, LOWER)	MIN(MAX(VALUE, LOWER), UPPER)

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint touchPoint = [touch locationInView:self];
    _animateToClear = YES;
    // 1. determine by how much the user has dragged
    float delta = touchPoint.x - _previousTouchPoint.x;
    float valueDelta = (_maximumValue - _minimumValue) * delta / _useableTrackLength;
    
    _previousTouchPoint = touchPoint;
    _previousValueDelta = valueDelta;
    
    // 2. update the values
    if (_lowerKnobLayer.highlighted) {
        
        _lowerValue += valueDelta;
        
        if (valueDelta < 0) {
            
            NSLog(@"LOWERKNOBUpper minus Lower At %f", _upperValue - _lowerValue);
            if (_upperValue - _lowerValue > _maxAllowedInterval || _upperValue - _lowerValue == 0) {
                _upperKnobLayer.highlighted = YES;
            }

        }
        
        if (_upperKnobLayer.enabled) {
            _lowerValue = BOUND(_lowerValue, _upperValue, _minimumValue);
        } else {
            _upperKnobLayer.highlighted = YES;
            _lowerValue = BOUND(_lowerValue, _maximumValue, _minimumValue);
        }
        
        [_upperKnobLayer setNeedsDisplay];
        
    }
    
    if (_upperKnobLayer.highlighted) {
        
        _upperValue += valueDelta;
        
        if (valueDelta > 0) {
            
            NSLog(@"UPPERKNOBUpper minus Lower At %f and MAXINTERVAL at %f", _upperValue - _lowerValue, _maxAllowedInterval);
            if (_upperValue - _lowerValue > _maxAllowedInterval) {
                _lowerKnobLayer.highlighted = YES;
            }

        }
        
        _upperValue = BOUND(_upperValue, _maximumValue, _lowerValue);
        
        [_lowerKnobLayer setNeedsDisplay];
    }
    
    // 3. Update the UI state
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    [self setLayerFrames];
    
    [CATransaction commit];
    
    [self sendActionsForControlEvents:UIControlEventValueChanged];
    
    return YES;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    NSLog(@"%s", __func__);
    [self sendActionsForControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
    
}

-(void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSLog(@"%s", __func__);
}


@end
