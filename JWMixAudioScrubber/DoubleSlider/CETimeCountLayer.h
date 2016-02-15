//
//  CETimeCountLayer.h
//  DoubleSlider
//
//  Created by brendan kerr on 1/19/16.
//  Copyright © 2016 b3k3r. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

@interface CETimeCountLayer : CAShapeLayer //<KnobUpdateDelegate>

@property (nonatomic) CGPoint referenceObjectPosition;
@property (nonatomic) CGRect referenceObjectFrame;
@property (nonatomic) float knobTime;
@property (nonatomic) float trackDuration;
@property (nonatomic) BOOL lower;

-(void)createText;
-(void)updateTextLayerString;

@end
