//
//  JWBlockingView.h
//  JamWDev
//
//  Created by brendan kerr on 4/23/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol BlockingViewDelegate <NSObject>

-(void)unblock;
-(void)stayBlockedWithMessage:(NSString *)message;

@end

@interface JWBlockingView : UIView

@property (nonatomic) UILabel *pageStatement;
@property (nonatomic) id <BlockingViewDelegate> delegate;

@end
