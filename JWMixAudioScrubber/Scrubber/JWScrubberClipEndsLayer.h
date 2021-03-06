//
//  JWScrubberClipEndsLayer.h
//  JamWIthT
//
//  co-created by joe and brendan kerr on 11/1/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
@import UIKit;

typedef NS_ENUM(NSInteger, JWScrubberClipEndsKind) {
    JWScrubberClipEndsKindNone = 1,
    JWScrubberClipEndsKindLeft,
    JWScrubberClipEndsKindRight
};


@interface JWScrubberClipEndsLayer : CAGradientLayer

@property (nonatomic) JWScrubberClipEndsKind kind;
@property (nonatomic) UIColor *color;

-(instancetype)initWithKind:(JWScrubberClipEndsKind)kind;
-(void)render;

@end
