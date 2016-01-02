//
//  JWScrubberGradientLayer.h
//  JamWIthT
//
//  Created by JOSEPH KERR on 11/1/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
@import UIKit;

//typedef NS_ENUM(NSInteger, JWScrubberGradientKind) {
//    JWScrubberGradientKindNone = 1,
//    JWScrubberGradientKindPlay,
//    JWScrubberGradientKindPause,
//    JWScrubberGradientKindStop,
//    JWScrubberGradientKindRecord
//};

typedef NS_ENUM(NSInteger, JWScrubberGradientKind) {
    JWScrubberGradientKindNone = 1,
    JWScrubberGradientKindTopToBottom,  // one breaking point two colors
    JWScrubberGradientKindBottomToTop,  // one breaking point two colors
    JWScrubberGradientKindCentered,     // one breaking point two colors
    JWScrubberGradientKindCenteredBreaking,     // two breaking point 3 colors
};


@interface JWScrubberGradientLayer : CAGradientLayer

-(instancetype)initWithKind:(JWScrubberGradientKind)kind;

@property (nonatomic) JWScrubberGradientKind kind;

@property (nonatomic) UIColor *color1;
@property (nonatomic) UIColor *color2;
@property (nonatomic) UIColor *color3;

@property (nonatomic) CGFloat breakingPoint1;
@property (nonatomic) CGFloat breakingPoint2;
@property (nonatomic) CGFloat centeredSpacingSpread;

@property (nonatomic) CGFloat centeredBreakingCenterSpread;

-(void)render;


@end
