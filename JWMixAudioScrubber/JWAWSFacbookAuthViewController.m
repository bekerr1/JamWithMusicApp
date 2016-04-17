//
//  JWAWSFacbookAuthViewController.m
//  JamWDev
//
//  Created by brendan kerr on 4/8/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

#import "JWAWSFacbookAuthViewController.h"
#import "JWAWSIdentityManager.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

@interface JWAWSFacbookAuthViewController() <FBSDKLoginButtonDelegate>

@property (nonatomic) JWAWSIdentityManager *identity;

@end
@implementation JWAWSFacbookAuthViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    FBSDKLoginButton *loginButton = [[FBSDKLoginButton alloc] init];
    loginButton.center = self.view.center;
    [self.view addSubview:loginButton];
    loginButton.delegate = self;
}

-(void)loginButton:(FBSDKLoginButton *)loginButton didCompleteWithResult:(FBSDKLoginManagerLoginResult *)result error:(NSError *)error {
    
    NSLog(@"result: %@", result.token);
}




@end
