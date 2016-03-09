//
//  CETimeCountLayer.m
//  DoubleSlider
//
//  Created by brendan kerr on 1/19/16.
//  Copyright © 2016 b3k3r. All rights reserved.
//

#import "CETimeCountLayer.h"

#define LENGTH_FROM_KNOB 40
#define TRIANGLE_HEIGHT 5
#define BOX_HEIGHT 20
#define BOX_WIDTH 10

#define FRAME_WIDTH 50
#define TRIANGLE_END FRAME_WIDTH/2
#define FRAME_HEIGHT 50

#define TEXT_CENTER_OFFSET 15
#define LABEL_CENTER_OFFSET 30


@interface CETimeCountLayer()

@property (nonatomic) CATextLayer *knobTimeText;
@property (nonatomic) NSDictionary *textAttribues;

@end
@implementation CETimeCountLayer


-(void)updateLowerKnobTimeLabel:(CALayer *)lowerKnob {
    
    //self.upperKnobTimeText setString:
    
}

-(void)updateUpperKnobTimeLabel:(CALayer *)upperKnob {
    
    
}

-(void)createText {
    
    UIFont *textFont = [UIFont systemFontOfSize:12.0];
    
    _textAttribues = [NSDictionary dictionaryWithObject:textFont forKey:@"font"];
    //[self setBackgroundColor:[UIColor redColor].CGColor];
    _knobTime = 0.0;
    _knobTimeText = [CATextLayer layer];
    [_knobTimeText setFrame:CGRectMake(0, 0, 30, 30)];
    [_knobTimeText setPosition:CGPointMake(FRAME_WIDTH/2, FRAME_HEIGHT/2 + TEXT_CENTER_OFFSET)];
    //[_knobTimeText setBackgroundColor:[UIColor blueColor].CGColor];
    [_knobTimeText setFontSize:15.0];
    [_knobTimeText setForegroundColor:[UIColor blackColor].CGColor];
    //[_knobTimeText setString:[self knobTimeString]];
    //[_knobTimeText setOpacity:0.0];
    //[_knobTimeText setString:[NSString stringWithFormat:@"%f", _knobTime]];
    [self addSublayer:_knobTimeText];

}

-(NSString *)knobTimeString {
    
    
    int secondsIn = (_knobTime * _trackDuration);
    int actualMinutes = 0;
    int actualSeconds = 0;
    
    if (secondsIn >= 60) {
        actualSeconds = secondsIn % 60;
        actualMinutes = (secondsIn - actualSeconds) / 60;
    } else {
        actualSeconds = secondsIn;
    }
    
    
    return [NSString stringWithFormat:@"%0.1d:%0.2d", actualMinutes, actualSeconds];
    
}


-(void)updateTextLayerString {
    
    [_knobTimeText setString:[self knobTimeString]];
    NSLog(@"NEW STRING %@", [self knobTimeString]);
    //[_knobTimeText setString:[NSString stringWithFormat:@"%f", _knobTime]];

    [CATransaction begin];
    [CATransaction setAnimationDuration:0.05];
    [self setPosition:CGPointMake((_lower == YES) ? _referenceObjectPosition.x - LABEL_CENTER_OFFSET : _referenceObjectPosition.x + LABEL_CENTER_OFFSET, _referenceObjectPosition.y - LENGTH_FROM_KNOB - 10)];
        [CATransaction commit];
    
}


-(void)drawInContext:(CGContextRef)ctx {
    
    self.opacity = 1.0;
    NSLog(@"%s", __func__);
    
    if (self.referenceObjectPosition.x > 0 ) {
        
        //NSLog(@"Position is %@ and anchor point is %@.", NSStringFromCGPoint(self.position), NSStringFromCGPoint(self.anchorPoint));
        
        //[self setAnchorPoint:CGPointMake(_referenceObjectPosition.x, _referenceObjectPosition.y - LENGTH_FROM_KNOB - 10)];
        //NSLog(@"Made inside draw block.");
        //NSLog(@"Reference OBJ Position: %@", NSStringFromCGPoint(self.referenceObjectPosition));
        
        
        CGMutablePathRef path = CGPathCreateMutable();
        //CGRect rect1 = CGContextGetClipBoundingBox(ctx);
        //CGRect rect2 = CGContextGetPathBoundingBox(ctx);
        
       // NSLog(@"rect1 = %@", NSStringFromCGRect(rect1));
        
        //Move to point that represents tip of triangle
        //NSLog(@"Start at point %@", NSStringFromCGPoint(CGPointMake(_referenceObjectPosition.x, _referenceObjectPosition.y - LENGTH_FROM_KNOB)));
        CGPathMoveToPoint(path, NULL, (_lower == YES) ? FRAME_WIDTH : 0, FRAME_HEIGHT);
        
        
        //Move to point that represents the left bottom corner or triangle/box
        //NSLog(@"Then Go to point %@", NSStringFromCGPoint(CGPointMake(_referenceObjectPosition.x - _referenceObjectFrame.size.height/2, _referenceObjectPosition.y - LENGTH_FROM_KNOB - TRIANGLE_HEIGHT)));
        CGPathAddLineToPoint(path, NULL, TRIANGLE_END, FRAME_HEIGHT - TRIANGLE_HEIGHT);
        
        CGPathAddLineToPoint(path, NULL, (_lower == YES) ? 0 : FRAME_WIDTH, FRAME_HEIGHT - TRIANGLE_HEIGHT);
        
        //Move to point that represents the top left corner of box
        //NSLog(@"Then Go to point %@", NSStringFromCGPoint(CGPointMake(_referenceObjectPosition.x - _referenceObjectFrame.size.height/2, _referenceObjectPosition.y - LENGTH_FROM_KNOB -TRIANGLE_HEIGHT - BOX_HEIGHT)));
        CGPathAddLineToPoint(path, NULL, (_lower == YES) ? 0 : FRAME_WIDTH, FRAME_HEIGHT - TRIANGLE_HEIGHT - BOX_HEIGHT);
        
        
        //Move to point that represents the top right corner of box
        //NSLog(@"Then Go to point %@", NSStringFromCGPoint(CGPointMake(_referenceObjectPosition.x + _referenceObjectFrame.size.height/2, _referenceObjectPosition.y - LENGTH_FROM_KNOB - TRIANGLE_HEIGHT - BOX_HEIGHT)));
        CGPathAddLineToPoint(path, NULL, (_lower == YES) ? FRAME_WIDTH : 0, FRAME_HEIGHT - TRIANGLE_HEIGHT - BOX_HEIGHT);
        
        
        //Move to point that represents the bottom right corner of triangle/box
        //NSLog(@"Then Go to point %@", NSStringFromCGPoint(CGPointMake(_referenceObjectPosition.x + _referenceObjectFrame.size.height/2, _referenceObjectPosition.y - LENGTH_FROM_KNOB - TRIANGLE_HEIGHT)));
        //CGPathAddLineToPoint(path, NULL, (_lower == YES) ? FRAME_WIDTH : 0, FRAME_HEIGHT - TRIANGLE_HEIGHT);
        
        
        //Move back to start point (top of triangle)
        //NSLog(@"Then Go to point %@", NSStringFromCGPoint(CGPointMake(_referenceObjectPosition.x + _referenceObjectFrame.size.height/2, _referenceObjectPosition.y - LENGTH_FROM_KNOB)));
        CGPathMoveToPoint(path, NULL, (_lower == YES) ? FRAME_WIDTH : 0, FRAME_HEIGHT);
        
        
//        UIBezierPath *knobPath = [UIBezierPath bezierPathWithCGPath:path];
//        
//        // 1) fill - with a subtle shadow
//        CGContextSetShadowWithColor(ctx, CGSizeMake(0, 1), 1.0, [UIColor grayColor].CGColor);
//        CGContextSetFillColorWithColor(ctx, [UIColor grayColor].CGColor);
//        CGContextAddPath(ctx, knobPath.CGPath);
//        CGContextFillPath(ctx);

        
        //Attach to shape layer and set layer settings, add to layer as sublayer
        [self setPath:path];
        [self setFillColor:[UIColor whiteColor].CGColor];
        [self setStrokeColor:[UIColor blackColor].CGColor];
        
//        UIGraphicsPushContext(ctx);
//        NSString *timeString = [NSString stringWithFormat:@"%f", _knobTime];
//        [timeString drawAtPoint:CGPointMake(_referenceObjectPosition.x, _referenceObjectPosition.y - LENGTH_FROM_KNOB - 10) withAttributes:nil];
//        UIGraphicsPopContext();
        
        //CGContextAddPath(ctx, path);
        CGPathRelease(path);
    } else {
        
        NSLog(@"No Object to Reference.");
    }
    
}

@end
