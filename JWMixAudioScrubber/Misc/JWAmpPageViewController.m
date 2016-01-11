//
//  JWAmpPageViewController.m
//  JamWIthT
//
//  Created by JOSEPH KERR on 10/8/15.
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
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor yellowColor];
    
    _numberOfPages = 4;
    self.dataSource = self;
    self.delegate = self;
    
    selectedPageIndex = [JWCurrentWorkItem sharedInstance].currentAmpImageIndex;

    UIViewController *result = [self viewControllerAtIndex:selectedPageIndex];
    [self  setViewControllers:@[result] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:^(BOOL fini){}];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [JWCurrentWorkItem sharedInstance].currentAmpImageIndex = selectedPageIndex;
}


#pragma mark helper

#define kRoundedCornerRadius    10

- (UIViewController * _Nullable)viewControllerAtIndex:(NSUInteger)index {
    UIViewController *result;
    JWAmpItemViewController *avc = [self.storyboard instantiateViewControllerWithIdentifier:@"JWAmpView"];
    [avc.view setNeedsLayout];
    
//    jwframesandscreens - 1
//    jwfullamps - 3
//    jwjustscreensandlogos - 2
    avc.ampImageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"jwfullamps - %ld",index+1]];
    
    avc.pageIndex = index;
    result = avc;
    return result;
}


#pragma mark page view datasource

- (UIViewController * _Nullable)pageViewController:(UIPageViewController * _Nonnull)pageViewController
                viewControllerBeforeViewController:(UIViewController * _Nonnull)viewController
{
    UIViewController *result;
    NSUInteger sourcePage = [(JWAmpItemViewController *)viewController pageIndex];
    NSLog(@"%s %ld",__func__,sourcePage);
    NSUInteger targetPage;
    if (sourcePage > 0) {
        targetPage = sourcePage -1;
        result = [self viewControllerAtIndex:targetPage];
        NSLog(@"%s t %ld",__func__,targetPage);

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
    NSLog(@"%s %ld",__func__,sourcePage);
    NSUInteger targetPage;
    if (sourcePage < _numberOfPages -1) {
        targetPage = sourcePage +1;
        result = [self viewControllerAtIndex:targetPage];
        NSLog(@"%s t %ld",__func__,targetPage);
    } else {
        result = nil;
    }
    
    return result;
}

#pragma mark page view delegate

- (void)pageViewController:(UIPageViewController * _Nonnull)pageViewController
        didFinishAnimating:(BOOL)finished
   previousViewControllers:(NSArray<UIViewController *> * _Nonnull)previousViewControllers
       transitionCompleted:(BOOL)completed
{
    
    if (completed) {
        selectedPageIndex = [(JWAmpItemViewController *)pageViewController.viewControllers[0] pageIndex];
        NSLog(@"%s selectedPageIndex %ld  info [f%@  c%@]",__func__,selectedPageIndex,@(finished),@(completed));

        [JWCurrentWorkItem sharedInstance].currentAmpImageIndex = selectedPageIndex;
        // Post so others know
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"DidSelectAmpImage" object:self userInfo:@{@"index":@(selectedPageIndex)}];
        });
        
        // save for restarts - last item used
        [[NSUserDefaults standardUserDefaults] setValue:@(selectedPageIndex) forKey:@"currentAmp"];
    }
}


-(void)viewDidLayoutSubviews
{
    BOOL addTo = NO;
    if (_gradient == nil) {
        addTo = YES;
    }
    self.gradient = [self  gradientForView];
    
    if (addTo) {
        [self.view.layer insertSublayer:_gradient atIndex:0];
    }
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



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end



//        [self viewControllerAtIndex:targetPage];
//        JWAmpItemViewController *avc = [self.storyboard instantiateViewControllerWithIdentifier:@"JWAmpView"];
//        [avc.view setNeedsLayout];
//        avc.ampImageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"jwscreensandcontrols - %ld",targetPage+1]];
//        avc.pageIndex = targetPage;
//        result = avc;


//    JWAmpItemViewController *avc = [self.storyboard instantiateViewControllerWithIdentifier:@"JWAmpView"];
//    [avc.view setNeedsLayout];
//    avc.ampImage = [UIImage imageNamed:[NSString stringWithFormat:@"jwscreensandcontrols - %ld",selectedPageIndex + 1]];
//    avc.pageIndex = selectedPageIndex;

