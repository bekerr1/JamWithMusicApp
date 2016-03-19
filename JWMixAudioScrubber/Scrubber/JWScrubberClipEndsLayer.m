//
//  JWScrubberClipEndsLayer.m
//  JamWIthT
//
//  co-created by joe and brendan kerr on 11/1/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import "JWScrubberClipEndsLayer.h"

@implementation JWScrubberClipEndsLayer

-(instancetype)initWithLayer:(id)layer
{
    if (self = [super initWithLayer:layer]) {
    }
    return self;
}

-(instancetype)initWithKind:(JWScrubberClipEndsKind)kind
{
    if (self = [super init]) {
        _kind = kind;
    }
    return self;
}

#pragma mark -

-(void)render {

    if (_kind == JWScrubberClipEndsKindLeft) {
        CGColorRef startColorRef = _color.CGColor;
        CGColorRef endColorRef = [UIColor clearColor].CGColor;
        self.colors = @[(__bridge id)startColorRef, (__bridge id)endColorRef];
        self.startPoint = CGPointMake(0.95, 0.5);
        self.endPoint = CGPointMake(0.99, 0.5);
    }

    if (_kind == JWScrubberClipEndsKindRight) {
        CGColorRef startColorRef = [UIColor clearColor].CGColor;
        CGColorRef endColorRef = _color.CGColor;
        self.colors = @[(__bridge id)startColorRef, (__bridge id)endColorRef];
        self.startPoint = CGPointMake(0.01, 0.5);
        self.endPoint = CGPointMake(.05, 0.5);
    }
}

@end
