//
//  JWCommon.h
//  JWMixAudioScrubber
//
//  Created by brendan kerr on 1/7/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface JWCommon : NSObject



@property (nonatomic) NSUInteger gradientOffset;

//'-(void)drawLinearGradient:(CGContextRef)context inRect:(CGRect)rect wihtStartColor:(CGColorRef)startColor endColor:(CGColorRef)endColor;

-(CAGradientLayer *)getLayerLinearGradient:(CGContextRef)context inRect:(CGRect)rect withStartColor:(CGColorRef)startColor endColor:(CGColorRef)endColor;

void drawLinearGradient(CGContextRef context, CGRect rect, CGColorRef startColor, CGColorRef endColor, float gradientOffset);
void setNewGradientOffset(NSUInteger offset);

@end


