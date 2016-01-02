//
//  JWPulseLightView.m
//  JamWIthT
//
//  Created by JOSEPH KERR on 11/2/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import "JWPulseLightView.h"
#import <QuartzCore/QuartzCore.h>

@implementation JWPulseLightView


-(instancetype)init {
    if (self = [super init]) {
        
    }
    
    return self;
}



- (void)drawRect:(CGRect)rect {

    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);

    
    CGContextMoveToPoint(ctx, 20, 20);
    CGContextAddLineToPoint(ctx, 40, 80);
    CGContextSetStrokeColorWithColor(ctx, [UIColor clearColor].CGColor);
    
    CGContextDrawPath(ctx, kCGPathStroke);
    
    CGRect crect =CGRectMake(0, 30 , 10, 30);
    
    //    NSLog(@"%s\nclip\n%@\nfrom%@\bbox%@",__func__, NSStringFromCGRect(rect),NSStringFromCGRect(self.frame),NSStringFromCGRect(cliprect));
    
    
    CGContextClearRect(ctx, crect);
    CGContextRestoreGState(ctx);
    
    
}



@end
