//
//  JWScrubberGradientLayer.m
//  JamWIthT
//
//  co-created by joe and brendan kerr on 11/1/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import "JWScrubberGradientLayer.h"

@interface JWScrubberGradientLayer ()
@property (nonatomic) CAGradientLayer* coverGradient;  // possibility for sublayer effects
@end


@implementation JWScrubberGradientLayer

//-(instancetype)initWithLayer:(id)layer{
//    if (self = [super initWithLayer:layer]) {
//    }
//    return self;
//}

-(instancetype)initWithKind:(JWScrubberGradientKind)kind
{
    if (self = [super init]) {
        _kind = kind;
    }
    return self;
}

-(void)render
{
    if (_kind == JWScrubberGradientKindTopToBottom) {
        self.locations = @[@(_breakingPoint1)];
        self.colors = @[(__bridge id)_color1.CGColor,
                        (__bridge id)_color2.CGColor,
                        ];
    }
    
    if (_kind == JWScrubberGradientKindBottomToTop) {
        self.locations = @[@(1 - _breakingPoint1),];
        self.colors = @[(__bridge id)_color2.CGColor,
                        (__bridge id)_color1.CGColor,
                        ];
    }
    
    if (_kind == JWScrubberGradientKindCentered) {
        
        CGFloat spread = _centeredSpacingSpread/2;

        self.locations = @[@(_breakingPoint1), @(.500 - spread), @(.500 +spread),@(1 - _breakingPoint1)];
        self.colors = @[(__bridge id)_color1.CGColor,
                        (__bridge id)_color2.CGColor,
                        (__bridge id)_color2.CGColor,
                        (__bridge id)_color1.CGColor
                        ];
    }
    
    if (_kind == JWScrubberGradientKindCenteredBreaking) {
        
        // uses two break points (paired top and bottom and a centered spread
        // uses three colors
        
        CGFloat spread = _centeredBreakingCenterSpread/2;

        CGFloat center = 0.5000f;

        self.locations = @[@(_breakingPoint1),@(_breakingPoint2),
                           @(center - spread),@(center + spread),
                           @(1 - _breakingPoint2),@(1 - _breakingPoint1)
                           ];
        
        self.colors = @[(__bridge id)_color1.CGColor,
                        (__bridge id)_color2.CGColor,
                        (__bridge id)_color3.CGColor,
                        (__bridge id)_color3.CGColor,
                        (__bridge id)_color2.CGColor,
                        (__bridge id)_color1.CGColor
                        ];
        
        
        /*
         
         NOTES - computing movement of gradient
         .12
            .23
         .35
            .06
         .41  = .500 - .09
         
         Reduce Top - Moves Center up
         
         100% of .500
         -1 to 1   starts at Zero Center 
         -1 moves center to top
         -.5 moves center half way to top
         
         center starts at .5 and is reduced and approaches zero
         
         center - spread =spreadpoint
         
         .23 + .06 = .29
         
         SP  spreadpoint .41
         SPA spreadpoint amount is reduced by a factor 0 - 1.0
         SD  spreaddistance = spreadpoint - 0

         factor = .1 .041
         factor = .5
         factor x spreaddistance = .205
         factor = .9 .369
         FSD the factored spreaddistance is obtained by first reducing the firstbreakpoint until zero then
         the secondbreakpoint
         
         .12 , .35  as bp1 and bp2 and SD .41
         
         
         
         .9 .369 - .35 = .019
         
        factor of TOTAL = .2926829268 >> breakingpointfactor = .12 / .41  factor of TOTAL = .2926829268
         x * .41 =  .29268
         X = 0.71385 = .29268 / .41
         .6 .246
         
         .5 .205 - .35 =
         
         
         USE breakingpointfactor to determine SDfactorOfTotal = .71385
         
         if (FSD > SDfactorOfTotal)
          reduce breakpoint1
           .35 + y = FSD
           y = FSD - .35
           y= .06
           bp1 = y
         else{
           bp1 = 0.0
         .35
         bp2 =
         
         
           reduce
         }
         
         
         
         
         
         
         */
    }
}



// ============================================
//
//  REFERENCE Not Used
//  Methods below are not used
// ============================================

    //    if (_coverGradient == nil) {
    //        _coverGradient = [CAGradientLayer new];
    //        [self insertSublayer:_coverGradient atIndex:0];

    //    CGFloat offestHeader = 10/(CGRectGetHeight(self.frame)) + 0.04;// + .0;
    //    CGFloat bottomOffestHeader = 1- offestHeader;
    //    _coverGradient.locations = @[@(offestHeader),@(offestHeader+.14),
    //                                 @(.41),@(.59),
    //                                 @(bottomOffestHeader - .14),@(bottomOffestHeader)];
    //
    //    // Clear to reveal background color
    //    _coverGradient.colors = @[
    //                              (__bridge id)[UIColor blackColor].CGColor,
    //                              (__bridge id)[[UIColor blueColor] colorWithAlphaComponent:0.7].CGColor,
    //                              (__bridge id)[UIColor clearColor].CGColor,
    //                              (__bridge id)[UIColor clearColor].CGColor,
    //                              (__bridge id)[[UIColor blueColor] colorWithAlphaComponent:0.7].CGColor,
    //                              (__bridge id)[UIColor blackColor].CGColor,
    //                              ];



#pragma mark Sop Play Record
-(void) drawGradientOptionPlayForView:(CAGradientLayer*)gradient frame:(CGRect) gradientFrame{
    gradient.frame = gradientFrame;
    CGFloat offestHeader = 10/(CGRectGetHeight(gradientFrame));
    CGFloat bottomOffestHeader = 1- offestHeader;
    gradient.locations = @[@(offestHeader),@(.50),@(bottomOffestHeader)];
    gradient.colors = @[(__bridge id)[[UIColor blackColor] colorWithAlphaComponent:1.0].CGColor,
                        (__bridge id)[[UIColor blueColor] colorWithAlphaComponent:.8].CGColor,
                        (__bridge id)[[UIColor blackColor] colorWithAlphaComponent:1.0].CGColor
                        ];
    
    //    gradient.colors = @[(__bridge id)[UIColor blackColor].CGColor,
    //                        (__bridge id)[UIColor blueColor].CGColor,
    //                        (__bridge id)[UIColor blackColor].CGColor
    //    ];
    
    
    //    (__bridge id)[[UIColor blueColor] colorWithAlphaComponent:0.4].CGColor,
    
}
-(void) drawGradientOptionRecordingForView:(CAGradientLayer*)gradient frame:(CGRect) gradientFrame{
    //    gradientFrame.origin = CGPointZero;
    gradient.frame = gradientFrame;
    CGFloat offestHeader = 30/(CGRectGetHeight(gradientFrame));
    CGFloat bottomOffestHeader = 1 - (30/(CGRectGetHeight(gradientFrame)));
    gradient.locations = @[@(offestHeader),@(bottomOffestHeader)];
    gradient.colors = @[(__bridge id)[UIColor blackColor].CGColor,
                        (__bridge id)[[UIColor redColor] colorWithAlphaComponent:0.6].CGColor,
                        (__bridge id)[UIColor blackColor].CGColor ];
}
-(void) drawGradientOptionStopPlayForView:(CAGradientLayer*)gradient frame:(CGRect) gradientFrame{
    //    gradientFrame.origin = CGPointZero;
    gradient.frame = gradientFrame;
    CGFloat offestHeader = 85/(CGRectGetHeight(gradientFrame));
    CGFloat bottomOffestHeader = 1 - (10/(CGRectGetHeight(gradientFrame)));
    gradient.locations = @[@(offestHeader),@(bottomOffestHeader - .15),@(bottomOffestHeader)];
    gradient.colors = @[(__bridge id)[UIColor blackColor].CGColor,
                        (__bridge id)[UIColor darkGrayColor].CGColor,
                        (__bridge id)[[UIColor whiteColor] colorWithAlphaComponent:0.6].CGColor,
                        (__bridge id)[UIColor blackColor].CGColor];
}

#pragma mark other grads

-(void) drawGradientOptionPlayHorizontalPulse:(CAGradientLayer*)gradient frame:(CGRect) gradientFrame{
    NSLog(@"%s",__func__);
    gradientFrame.origin = CGPointZero;
    gradient.frame = gradientFrame;
    gradient.locations = @[@(0.10),@(0.38),@(0.5),@(0.62),@(0.90)];
    gradient.colors = @[
                        (__bridge id)[UIColor blackColor].CGColor,
                        (__bridge id)[[UIColor blueColor] colorWithAlphaComponent:0.8].CGColor,
                        (__bridge id)[UIColor colorWithWhite:.85 alpha:0.3].CGColor,
                        (__bridge id)[[UIColor blueColor] colorWithAlphaComponent:0.8].CGColor,
                        (__bridge id)[UIColor blackColor].CGColor,
                        ];
}

// nice light strip
//    gradient.locations = @[@(0.40),@(0.5),@(0.60)];
//    gradient.colors = @[(__bridge id)[UIColor blackColor].CGColor,
//                        (__bridge id)[UIColor colorWithWhite:.7 alpha:0.5].CGColor,
//                        (__bridge id)[UIColor blackColor].CGColor ];

//    gradient.colors = @[(__bridge id)[UIColor blackColor].CGColor,
//                        (__bridge id)[UIColor colorWithWhite:.7 alpha:0.8].CGColor,
//                        (__bridge id)[UIColor blackColor].CGColor ];



// and some other gradients
-(void) drawGradientOption3ForView:(CAGradientLayer*)gradient frame:(CGRect) gradientFrame{
    gradientFrame.origin = CGPointZero;
    gradient.frame = gradientFrame;
    CGFloat offestHeader = 30/(CGRectGetHeight(gradientFrame));
    CGFloat bottomOffestHeader = 1- (30/(CGRectGetHeight(gradientFrame)));
    gradient.locations = @[@(offestHeader),@(bottomOffestHeader)];
    gradient.colors = @[(__bridge id)[UIColor blackColor].CGColor,
                        (__bridge id)[[UIColor blueColor] colorWithAlphaComponent:06].CGColor,
                        (__bridge id)[UIColor blackColor].CGColor];
}
-(void)drawGradientOptionForRecordView:(CAGradientLayer*)gradient frame:(CGRect) gradientFrame{
    gradientFrame.origin = CGPointZero;
    gradient.frame = gradientFrame;
    gradient.locations = @[@(0.60),@(0.70),@(0.80)];
    gradient.colors = @[(__bridge id)[UIColor blackColor].CGColor,
                        (__bridge id)[[UIColor redColor] colorWithAlphaComponent:0.7].CGColor,
                        (__bridge id)[UIColor blackColor].CGColor];
}
-(CAGradientLayer*) gradientForView {
    CAGradientLayer* gradient = [CAGradientLayer new];
    CGRect gradientFrame = self.frame;
    gradientFrame.origin = CGPointZero;
    gradient.frame = gradientFrame;
    CGColorRef startColorRef = [UIColor redColor].CGColor;
    CGColorRef endColorRef = [UIColor greenColor].CGColor;
    gradient.colors = @[(__bridge id)startColorRef, (__bridge id)endColorRef];
    gradient.startPoint = CGPointMake(0.5, 0.0330);
    gradient.endPoint = CGPointMake(0.5, 0.95);
    return gradient;
}


//        self.gradientPulseLeft = [self  gradientForVerticalPulseLeft:gfr];
//        self.gradientPulseRight = [self  gradientForVerticalPulseRight:gfr];
//            [self.view.layer insertSublayer:_gradientPulseRight atIndex:0];
//            [self.view.layer insertSublayer:_gradientPulseLeft atIndex:0];
//        self.gradientPulseLeft.backgroundColor = [UIColor clearColor].CGColor;
//        self.gradientPulseRight.backgroundColor = [UIColor clearColor].CGColor;

//            [self drawGradientVerticalPulseLeft:_gradientPulseLeft frame:gfr];
//            _gradientPulseLeft.position = gcenter;
//
//            [self drawGradientVerticalPulseRight:_gradientPulseRight frame:gfr];
//            _gradientPulseRight.position = gcenter;
//
//            // midgradient horizontal
//
//            // [self draw
@end
