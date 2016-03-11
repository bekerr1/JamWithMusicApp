//
//  JWCustomCellBackground.m
//  JWMixAudioScrubber
//
//  Created by brendan kerr on 1/7/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

#import "JWCustomCellBackground.h"
#include <math.h>


@interface JWCustomCellBackground()

@property (nonatomic) float gradientOffset;
@property (nonatomic) CAGradientLayer *glayer;


@end
@implementation JWCustomCellBackground




-(instancetype)init {
    
    if (self = [super init]) {
        
        _com = [[JWCommon alloc] init];
        _gradientOffset = 100;
        //self.opaque = NO;
        //self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.55];
        
        
    }
    
    return self;
}
//-(instancetype)initWithDelegate:(id)cellfy {
//    
//    if (self = [super init]) {
//        
//        self.delegate = cellfy;
//    }
//    
//    return self;
//}
//-(void) drawRect: (CGRect) rect
//{
//    CGContextRef context = UIGraphicsGetCurrentContext();
//    
//    UIColor * redColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0];
//    
//    CGContextSetFillColorWithColor(context, redColor.CGColor);
//    CGContextFillRect(context, self.bounds);
//}

-(void)adjustGOffsetVolume:(UISlider *)sender {

    // UNUSED warnings
//    float sliderMin = sender.minimumValue;
//    float sliderMax = sender.maximumValue;
    
    [_glayer setOpacity:1.0];
    
    //[self setGradientOffset:sender.value];
    //[self setNeedsDisplay];
    //NSLog(@"Slider value change called from custom. %f, %f", sliderMin, sliderMax);
    
}

-(void) drawRect: (CGRect) rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    UIColor * blackColor = [[UIColor blackColor] colorWithAlphaComponent:0.0];
    UIColor * lightGrayColor = [UIColor colorWithRed:230.0/255.0 green:230.0/255.0 blue:230.0/255.0 alpha:0.2];
    
    // UNUSED CGRect paperRect = self.bounds;
    //NSLog(@"Rect Size %@", NSStringFromCGRect(paperRect));
    
    //drawLinearGradient(context, paperRect, blackColor.CGColor, lightGrayColor.CGColor, _gradientOffset);
    
    _glayer = [_com getLayerLinearGradient:context inRect:rect withStartColor:blackColor.CGColor endColor:lightGrayColor.CGColor];
    
    CGRect glayerFrame = self.frame;
    glayerFrame.size.height *= 3;
    _glayer.frame = glayerFrame;
    _glayer.transform = CATransform3DMakeRotation(80.0 / 180.0 * M_PI, 0.0, 0.0, 1.0);
    //[self.layer addSublayer:_glayer];
    
    NSLog(@"Rect Size %@", NSStringFromCGRect(glayerFrame));
    
    //NSLog(@"Layers position %@", NSStringFromCGPoint(_glayer.position));
    //[_com drawLinearGradient:context inRect:paperRect wihtStartColor:blackColor.CGColor endColor:lightGrayColor.CGColor];
}



-(void)setGradientOffset:(float)gradientOffset { 
    
    
    _gradientOffset = gradientOffset;
    
    NSArray *colors = @[(__bridge id)[[UIColor blackColor] colorWithAlphaComponent:0.0].CGColor, (__bridge id) [UIColor colorWithRed:230.0/255.0 green:230.0/255.0 blue:230.0/255.0 alpha:_gradientOffset].CGColor];
    
// UNUSED    NSArray *locations = [NSArray arrayWithObjects:[NSNumber numberWithInt:0.0],[NSNumber numberWithInt:1.0 - _gradientOffset], nil];
    
    CATransform3D transfrom = CATransform3DMakeRotation(80.0 + (-_gradientOffset) * 50 / 180.0 * M_PI/3, 0.0, 0.0, 1.0);
    
    
    CABasicAnimation *basic = [CABasicAnimation animationWithKeyPath:@"position"];
    //[basic setValue:@"positionAnim" forKeyPath:@"name"];
    [basic setFromValue:[[_glayer presentationLayer] valueForKey:@"position"]];
    [basic setToValue:[NSValue valueWithCGPoint:CGPointMake((gradientOffset * 150) + 100, 0)]];
    //basic.byValue = [NSValue valueWithCGPoint:CGPointMake(10, 0)];
    [basic setDuration:0.50];
    //[basic setTimingFunction:kCAMediaTimingFunctionEaseOut];
    //basic.delegate = self;
    [_glayer addAnimation:basic forKey:@"position"];
    [_glayer setPosition:CGPointMake((gradientOffset * 150) + 100, 0)];
    
    
    CABasicAnimation *basic2 = [CABasicAnimation animationWithKeyPath:@"colors"];
    [basic2 setFromValue:[[_glayer presentationLayer] valueForKey:@"colors"]];
    [basic2 setToValue:colors];
    [basic2 setDuration:0.10];
    [basic2 setRemovedOnCompletion:YES];
    [_glayer addAnimation:basic2 forKey:@"animateGradient"];
    [_glayer setValue:colors forKeyPath:@"colors"];
    
    
//    CABasicAnimation *basic3 = [CABasicAnimation animationWithKeyPath:@"locations"];
//    [basic3 setToValue:locations];
//    [basic3 setDuration:0.1];
//    [_glayer addAnimation:basic3 forKey:@"animateLocation"];
//    [_glayer setValue:locations forKeyPath:@"locations"];
    
    //NSLog(@"GradientOffset %f, Position %@", (float)gradientOffset, NSStringFromCGPoint(CGPointMake((gradientOffset * 100) + 200, 0)));
    
    CABasicAnimation *basic4 = [CABasicAnimation animationWithKeyPath:@"transform"];
    [basic4 setFromValue:[[_glayer presentationLayer] valueForKey:@"transform"]];
    [basic4 setToValue:[NSValue valueWithCATransform3D:transfrom]];
    [basic4 setDuration:1.0];
    [_glayer addAnimation:basic4 forKey:@"transfromAnim"];
    [_glayer setValue:[NSValue valueWithCATransform3D:transfrom] forKey:@"transform"];
    
    
    
    //[_glayer setOpacity:0.0];
    

    
}

-(void)sliderDidFinish:(id)sender {
    NSLog(@"%s", __func__);
    CABasicAnimation *basic5 = [CABasicAnimation animationWithKeyPath:@"opacity"];
    [basic5 setFromValue:[NSNumber numberWithFloat:1.0]];
    [basic5 setToValue:[NSNumber numberWithFloat:0.0]];
    [basic5 setDuration:3.0];
    [_glayer addAnimation:basic5 forKey:@"opacityAnim"];
    //[_glayer setOpacity:0.0];
}

//-(void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
//    
//    if ([[anim valueForKey:@"name"] isEqualToString:@"positionAnim"]) {
//        NSLog(@"%s", __func__);
//        _glayer.position = CGPointMake((_gradientOffset * 200) + 100, 0);
//    }
//    
//    
//}



@end
