//
//  JWBlockingView.m
//  JamWDev
//
//  Created by brendan kerr on 4/23/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

#import "JWBlockingView.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

@interface JWBlockingView() <FBSDKLoginButtonDelegate>

@property (nonatomic) UILabel *blockingStatement;
@property (nonatomic) UILabel *unblockError;
@property (nonatomic) FBSDKLoginButton *loginButton;

@end
@implementation JWBlockingView

#define FBSDKBUTTON_Y_OFFSET 30
#define LABEL_WIDTH_OFFSET 50
#define LABEL_HEIGHT 200
#define PAGESTATEMENT_HEIGHT 180
#define BLOCKINGSTATEMENT_HEIGHT 280
#define CENTER_X self.center.x

-(instancetype)initWithFrame:(CGRect)frame {
    
    if (self = [super initWithFrame:frame]) {
        //Do stuff
        
        //Labels
        self.pageStatement = [[UILabel alloc]
                              initWithFrame:CGRectMake(0, 0, self.frame.size.width - LABEL_WIDTH_OFFSET, LABEL_HEIGHT)];
        self.pageStatement.textAlignment = NSTextAlignmentCenter;
        self.pageStatement.lineBreakMode = NSLineBreakByWordWrapping;
        self.pageStatement.textColor = [UIColor whiteColor];
        self.pageStatement.numberOfLines = 0;
        self.pageStatement.alpha = 1.0;
        
        self.blockingStatement = [[UILabel alloc]
                                  initWithFrame:CGRectMake(0, 0, self.frame.size.width - LABEL_WIDTH_OFFSET, LABEL_HEIGHT)];
        self.blockingStatement.textAlignment = NSTextAlignmentCenter;
        self.blockingStatement.lineBreakMode = NSLineBreakByWordWrapping;
        self.blockingStatement.textColor = [UIColor whiteColor];
        self.blockingStatement.numberOfLines = 0;
        self.blockingStatement.alpha = 1.0;
        
        [self.blockingStatement setText:@"You must register through Facebook to acess this content"];
        
        self.pageStatement.center = CGPointMake(CENTER_X, PAGESTATEMENT_HEIGHT);
        self.blockingStatement.center = CGPointMake(CENTER_X, BLOCKINGSTATEMENT_HEIGHT);
        
        [self addSubview:self.pageStatement];
        [self addSubview:self.blockingStatement];
        
        
        //FBSDKBUTTON
        self.loginButton = [FBSDKLoginButton new];
        NSArray *readPermissions = @[@"public_profile", @"email", @"user_actions.music"];
        [self.loginButton setReadPermissions:readPermissions];
        self.loginButton.center = CGPointMake(self.center.x, self.center.y + FBSDKBUTTON_Y_OFFSET);
        self.loginButton.alpha = 1.0;
        [self addSubview:self.loginButton];
        self.loginButton.delegate = self;

        
    }
    return self;
}


-(void)loginButton:(FBSDKLoginButton *)loginButton didCompleteWithResult:(FBSDKLoginManagerLoginResult *)result error:(NSError *)error {
    
    if (error || result.isCancelled) {
        NSLog(@"%@", (error != nil) ? [error description] : @"Cancelled");
        [_delegate stayBlockedWithMessage:(error != nil) ? [error description] : @"Request Cancelled"];
    } else {
        NSLog(@"Token recived.");
        [_delegate unblock];
    }
    
}

-(void)loginButtonDidLogOut:(FBSDKLoginButton *)loginButton {
    
}



@end
