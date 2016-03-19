//
//  JWFileTransferActivity.h
//  JamWDev
//
//  co-created by joe and brendan kerr on 1/30/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JWFileTransferActivity : UIActivity
@property (nonatomic) NSURL*fileURL;
@property (nonatomic,weak) UIView *view;
@property (nonatomic,weak) UIActivityViewController *activityVC;
@end
