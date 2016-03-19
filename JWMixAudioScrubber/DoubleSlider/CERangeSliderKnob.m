//
//  CERangeSliderKnob.m
//  DoubleSlider
//
//  co-created by joe and brendan kerr on 1/18/16.
//  Copyright © 2016 b3k3r. All rights reserved.
//

#import "CERangeSliderKnob.h"

@implementation CERangeSliderKnob

- (void)drawInContext:(CGContextRef)ctx
{
    CGRect sourceRect;
    
    if (_lowerKnob)
        sourceRect = CGRectMake(self.frame.size.width - 20, 0, 20, self.frame.size.height);
     else
        sourceRect = CGRectMake(0, 0, 20, self.frame.size.height);
    
    
    CGRect knobFrame = CGRectInset(sourceRect, 2.0, 2.0);
    
    //[self setBackgroundColor:[UIColor whiteColor].CGColor];
    UIBezierPath *knobPath = [UIBezierPath bezierPathWithRoundedRect:knobFrame
                                                        cornerRadius:knobFrame.size.height * self.slider.curvaceousness / 2.0];
    
    // 1) fill - with a subtle shadow
    CGContextSetShadowWithColor(ctx, CGSizeMake(0, 1), 1.0, [UIColor grayColor].CGColor);
    CGContextSetFillColorWithColor(ctx, self.slider.knobColour.CGColor);
    CGContextAddPath(ctx, knobPath.CGPath);
    CGContextFillPath(ctx);
    
    // 2) outline
//    CGContextSetStrokeColorWithColor(ctx, [UIColor grayColor].CGColor);
//    CGContextSetLineWidth(ctx, 0.5);
//    CGContextAddPath(ctx, knobPath.CGPath);
//    CGContextStrokePath(ctx);
    
    
    // 3) inner gradient
//    CGRect rect = CGRectInset(knobFrame, 2.0, 2.0);
//    UIBezierPath *clipPath = [UIBezierPath bezierPathWithRoundedRect:rect
//                                                        cornerRadius:rect.size.height * self.slider.curvaceousness / 2.0];
    
//    CGGradientRef myGradient;
//    CGColorSpaceRef myColorspace;
//    size_t num_locations = 2;
//    CGFloat locations[2] = { 0.0, 1.0 };
//    CGFloat components[8] = { 0.0, 0.0, 0.0 , 0.15,  // Start color
//        0.0, 0.0, 0.0, 0.05 }; // End color
    
//    myColorspace = CGColorSpaceCreateDeviceRGB();
//    myGradient = CGGradientCreateWithColorComponents (myColorspace, components,
//                                                      locations, num_locations);
//    
//    CGPoint startPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect));
//    CGPoint endPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect));
//    
//    CGContextSaveGState(ctx);
//    CGContextAddPath(ctx, clipPath.CGPath);
//    CGContextClip(ctx);
//    CGContextDrawLinearGradient(ctx, myGradient, startPoint, endPoint, 0);
//    
//    CGGradientRelease(myGradient);
//    CGColorSpaceRelease(myColorspace);
//    CGContextRestoreGState(ctx);
    
    // 4) highlight
    if (self.highlighted)
    {
        // fill
        CGContextSetFillColorWithColor(ctx, [UIColor colorWithWhite:0.0 alpha:0.1].CGColor);
        CGContextAddPath(ctx, knobPath.CGPath);
        CGContextFillPath(ctx);
    }
    
    if (!self.enabled) {
        self.opacity = 0.3;
    } else {
        self.opacity = 1.0;
    }
}

@end
