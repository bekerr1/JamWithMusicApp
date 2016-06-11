//
//  JWMenuTabBarController.h
//  JamWDev
//
//  Created by brendan kerr on 4/18/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JWBlockingView.h"
#import "JWContinueView.h"
#import "DetailViewController.h"

@interface JWMenuTabBarController : UITabBarController <UITabBarControllerDelegate, BlockingViewDelegate, ContinueViewDelegate, JWDetailDelegate>

@end
