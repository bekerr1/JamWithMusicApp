//
//  CERangeSlider.h
//  DoubleSlider
//
//  co-created by joe and brendan kerr on 11/27/15.
//  Copyright © 2015 b3k3r. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CERangeSliderKnob.h"

@class CERangeSliderKnob;

@interface CERangeSlider : UIControl

@property (nonatomic) float maximumValue;
@property (nonatomic) float minimumValue;
@property (nonatomic) float upperValue;
@property (nonatomic) float lowerValue;
@property (nonatomic) float maxAllowedInterval;
@property (nonatomic) float trackDuration;
@property (nonatomic) BOOL dragOnLower;
@property (nonatomic) BOOL animateToClear;

@property (nonatomic) UIColor* trackColour;
@property (nonatomic) UIColor* trackHighlightColour;
@property (nonatomic) UIColor* trackOutsideColour;
@property (nonatomic) UIColor* knobColour;
@property (nonatomic) float curvaceousness;

@property (nonatomic) CERangeSliderKnob *lowerKnobLayer;
@property (nonatomic) CERangeSliderKnob *upperKnobLayer;
@property (nonatomic) CGPoint lowerKnobCenterInParent;
@property (nonatomic) CGPoint upperKnobCenterInParent;

- (float) positionForValue:(float)value;
- (void) redrawLayers;
- (void) setLayerFrames;
-(void)setMaxAllowedInterval:(float)maxAllowedInterval usingDuration:(float)trackDuration;

@end
