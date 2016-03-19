//
//  JWAmpPageViewController.m
//  JamWIthT
//
//  co-created by joe and brendan kerr on 10/8/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

// Notifications Posted:
// postNotificationName:@"DidSelectAmpImage" object:@(selectedPageIndex)
//

#import "JWAmpPageViewController.h"
#import "JWAmpItemViewController.h"
#import "JWCurrentWorkItem.h"
@import QuartzCore;


@interface JWAmpPageViewController  ()<UIPageViewControllerDataSource,UIPageViewControllerDelegate> {
    NSUInteger selectedPageIndex;
}
@property (nonatomic,assign) NSUInteger numberOfPages;
@property (nonatomic) CAGradientLayer *gradient;
@end


@implementation JWAmpPageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor yellowColor];
    _numberOfPages = 4;
    self.dataSource = self;
    self.delegate = self;
    selectedPageIndex = [JWCurrentWorkItem sharedInstance].currentAmpImageIndex;

    [self  setViewControllers:@[[self viewControllerAtIndex:selectedPageIndex]]
                    direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:^(BOOL fini){}];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [JWCurrentWorkItem sharedInstance].currentAmpImageIndex = selectedPageIndex;
}


#pragma mark page view delgate and datasource

- (UIViewController * _Nullable)pageViewController:(UIPageViewController * _Nonnull)pageViewController
                viewControllerBeforeViewController:(UIViewController * _Nonnull)viewController
{
    UIViewController *result;
    NSUInteger sourcePage = [(JWAmpItemViewController *)viewController pageIndex];
    NSUInteger targetPage;
    if (sourcePage > 0) {
        targetPage = sourcePage -1;
        result = [self viewControllerAtIndex:targetPage];
    } else {
        result = nil;
    }
    
    return result;
}

- (UIViewController * _Nullable)pageViewController:(UIPageViewController * _Nonnull)pageViewController
                 viewControllerAfterViewController:(UIViewController * _Nonnull)viewController
{
    UIViewController *result;
    NSUInteger sourcePage = [(JWAmpItemViewController *)viewController pageIndex];
    NSUInteger targetPage;
    if (sourcePage < _numberOfPages -1) {
        targetPage = sourcePage +1;
        result = [self viewControllerAtIndex:targetPage];
    } else {
        result = nil;
    }
    
    return result;
}


- (void)pageViewController:(UIPageViewController * _Nonnull)pageViewController
        didFinishAnimating:(BOOL)finished
   previousViewControllers:(NSArray<UIViewController *> * _Nonnull)previousViewControllers
       transitionCompleted:(BOOL)completed
{
    
    if (completed) {
        selectedPageIndex = [(JWAmpItemViewController *)pageViewController.viewControllers[0] pageIndex];

        [JWCurrentWorkItem sharedInstance].currentAmpImageIndex = selectedPageIndex;
        // Post so others know
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"DidSelectAmpImage"
                                                                object:self
                                                              userInfo:@{@"index":@(selectedPageIndex)}];
        });
        
        // save for restarts - last item used
        [[NSUserDefaults standardUserDefaults] setValue:@(selectedPageIndex) forKey:@"currentAmp"];
    }
}

#pragma mark -

- (void)viewDidLayoutSubviews {
    BOOL addTo = NO;
    if (_gradient == nil) {
        addTo = YES;
    }
    self.gradient = [self  gradientForView];
    
    if (addTo) {
        [self.view.layer insertSublayer:_gradient atIndex:0];
    }
}

#pragma mark helper

- (CAGradientLayer*)gradientForView {
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

// jwframesandscreens - 1 jwfullamps - 3 jwjustscreensandlogos - 2

- (UIViewController * _Nullable)viewControllerAtIndex:(NSUInteger)index {
    UIViewController *result;
    JWAmpItemViewController *avc = [self.storyboard instantiateViewControllerWithIdentifier:@"JWAmpView"];
    
    [avc.view setNeedsLayout];
    
    avc.ampImageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"jwfullamps - %lu",index+1]];
    avc.pageIndex = index;
    result = avc;
    return result;
}


@end

