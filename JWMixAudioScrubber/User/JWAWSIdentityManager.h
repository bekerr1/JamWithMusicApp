//
//  JWAWSIdentityManager.h
//  JamWDev
//
//  Created by brendan kerr on 4/2/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JWAWSIdentityManager : NSObject

+ (instancetype)sharedInstance;

- (void)FBLogin;
- (BOOL)isLoggedInWithFacebook;

@end
