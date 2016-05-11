//
//  JWAWSIdentityManager.h
//  JamWDev
//
//  Created by brendan kerr on 4/2/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AWSConfiguration.h"
#import <AWSCore/AWSCore.h>
#import <AWSCognito/AWSCognito.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

@interface JWAWSIdentityManager : NSObject

@property (atomic, copy) AWSContinuationBlock completionHandler;
@property (nonatomic) NSString *userID;

+ (instancetype)sharedInstance;

- (NSString *)identityId;


- (void)FBLogin;
-(void)facebookLogout;
- (BOOL)isLoggedInWithFacebook;
- (void)completeFBLogin;
- (void)completeFBLoginWithCompletion:(AWSContinuationBlock)completion;

@end
