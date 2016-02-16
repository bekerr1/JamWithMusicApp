//
//  JWFileTransferActivity.h
//  JamWDev
//
//  Created by JOSEPH KERR on 1/30/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JWFileTransferActivity : UIActivity
@property (nonatomic) NSURL*fileURL;
@property (nonatomic,weak) UIView *view;
@property (nonatomic,weak) UIActivityViewController *activityVC;
@end
