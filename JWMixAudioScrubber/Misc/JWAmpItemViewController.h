//
//  JWAmpItemViewController.h
//  JamWIthT
//
//  co-created by joe and brendan kerr on 10/8/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JWAmpItemViewController : UIViewController
@property (strong, nonatomic) IBOutlet UIImageView *ampImageView;
@property (nonatomic,strong) UIImage *ampImage;
@property (nonatomic,assign) NSUInteger pageIndex;
@end
