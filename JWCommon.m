//
//  JWCommon.m
//  JWMixAudioScrubber
//
//  Created by brendan kerr on 1/7/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

#import "JWCommon.h"

@interface JWCommon()


@end
@implementation JWCommon

void drawLinearGradient(CGContextRef context, CGRect rect, CGColorRef startColor, CGColorRef endColor, float gradientOffset) {
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat locations[] = { 0.0, 1.0 };
    
    NSArray *colors = @[(__bridge id) startColor, (__bridge id) endColor];
    
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef) colors, locations);
    
    CGPoint startPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect));
    CGPoint endPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect));
    
    NSLog(@"Start Point = %@, End Point = %@, %s", NSStringFromCGPoint(startPoint), NSStringFromCGPoint(endPoint), __func__);
    
    CGContextSaveGState(context);
    CGContextAddRect(context, rect);
    CGContextClip(context);
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
    CGContextRestoreGState(context);
    
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);

    

}

-(CAGradientLayer *)getLayerLinearGradient:(CGContextRef)context inRect:(CGRect)rect withStartColor:(CGColorRef)startColor endColor:(CGColorRef)endColor {
    
    CAGradientLayer *layer = [CAGradientLayer layer];
    
    NSArray *locations = [NSArray arrayWithObjects:[NSNumber numberWithInt:0.0],[NSNumber numberWithInt:1.0], [NSNumber numberWithInt:1.0], nil];
    
    NSArray *colors = @[(__bridge id) startColor, (__bridge id) endColor];
    
    //CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef) colors, locations);
    
    //CGPoint startPoint = CGPointMake(CGRectGetMaxX(rect), CGRectGetMinY(rect));
    //CGPoint endPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect));
    
    //layer.frame = rect;
    layer.locations = locations;
    layer.colors = colors;
    //layer.startPoint = startPoint;
    //layer.endPoint = endPoint;
    
    return layer;
    
}


@end
