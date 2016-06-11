//
//  JWTransitionHandler.m
//  JamWDev
//
//  Created by brendan kerr on 5/23/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

#import "JWTransitionHandler.h"

@implementation JWTransitionHandler

-(NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    
    return 0.5;
}

-(void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    
    UIViewController *from = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    
    UIViewController *to = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    
}

@end
