//
//  JWRangeSliderViewController.h
//  JamWDev
//
//  co-created by joe and brendan kerr on 1/23/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CERangeSlider.h"
#import "CETimeCountLayer.h"

@interface JWRangeSliderViewController : UIViewController

@property (nonatomic) CERangeSlider *rangeSlider;
@property (nonatomic) CETimeCountLayer* lowerTimeCount;
@property (nonatomic) CETimeCountLayer* upperTimeCount;
@property (nonatomic) BOOL currentlyPanning;
@property (nonatomic) BOOL custom;
@property (nonatomic) BOOL preview;

-(void)updateDuration;
-(void)updateLabelPositionForSeek;
-(void)showHideLabels;
-(void)showLabels;
-(void)hideLabels;

@end
