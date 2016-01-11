//
//  JWAmpItemViewController.m
//  JamWIthT
//
//  Created by JOSEPH KERR on 10/8/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import "JWAmpItemViewController.h"
@import QuartzCore;

@interface JWAmpItemViewController ()
@property (nonatomic) CAGradientLayer *gradient;
@end


#define kRoundedCornerRadius    12

@implementation JWAmpItemViewController


- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder: aDecoder];
    if (self) {
//        UIBezierPath *fillPath = [UIBezierPath bezierPathWithRoundedRect: self.view.bounds byRoundingCorners:(UIRectCorner)(UIRectCornerTopLeft | UIRectCornerTopRight) cornerRadii:CGSizeMake(kRoundedCornerRadius, kRoundedCornerRadius)];
//        CAShapeLayer *pathLayer = [[CAShapeLayer alloc] init];
//        pathLayer.path = fillPath.CGPath;
//        pathLayer.frame = fillPath.bounds;
//        self.view.layer.mask = pathLayer;
        
    }
    return self;
}


-(void)setAmpImage:(UIImage *)ampImage
{
    self.ampImageView.image = ampImage;
    
}

//-(UIImage*)ampImage {
//    return self.ampImageView.image;
//}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidLayoutSubviews
{
    
//    BOOL addTo = NO;
//    if (_gradient == nil) {
//        addTo = YES;
//    }
//    self.gradient = [self  gradientForView];
//    
//    if (addTo) {
//        [self.view.layer insertSublayer:_gradient atIndex:0];
//    }

}


-(CAGradientLayer*) gradientForView {
    CAGradientLayer* gradient = [CAGradientLayer new];
    CGRect gradientFrame = self.view.frame;
    
    gradientFrame.origin = CGPointZero;
    gradient.frame = gradientFrame;
    CGColorRef startColorRef = [UIColor clearColor].CGColor;
    CGColorRef endColorRef = [UIColor blackColor].CGColor;
    gradient.colors = @[(__bridge id)startColorRef, (__bridge id)endColorRef];
    gradient.startPoint = CGPointMake(0.5, 0.2330);
    gradient.endPoint = CGPointMake(0.5, 0.75);
    return gradient;
}

-(CAGradientLayer*) gradientOption2ForView{
    CAGradientLayer* gradient = [CAGradientLayer new];
    CGRect gradientFrame = self.view.frame;
    gradientFrame.origin = CGPointZero;
    gradient.frame = gradientFrame;
    gradient.locations = @[@(0.60),@(0.70),@(0.80)];
    
    gradient.colors = @[
                        (__bridge id)[UIColor blackColor].CGColor,
                        (__bridge id)[[UIColor cyanColor] colorWithAlphaComponent:0.7].CGColor,
                        (__bridge id)[UIColor blackColor].CGColor,
                        ];
    return gradient;
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
