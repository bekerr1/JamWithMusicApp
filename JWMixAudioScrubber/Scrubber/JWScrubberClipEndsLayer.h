//
//  JWScrubberClipEndsLayer.h
//  JamWIthT
//
//  Created by JOSEPH KERR on 11/1/15.
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

-(instancetype)initWithKind:(JWScrubberClipEndsKind)kind;

@property (nonatomic) JWScrubberClipEndsKind kind;
@property (nonatomic) UIColor *color;
-(void)render;

@end
