//
//  CERangeSliderTrack.h
//  DoubleSlider
//
//  Created by brendan kerr on 1/18/16.
//  Copyright © 2016 b3k3r. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "CERangeSlider.h"

@class CERangeSlider;

@interface CERangeSliderTrack : CALayer

@property (weak) CERangeSlider* slider;

@end