//
//  JWAWSIdentityManager.m
//  JamWDev
//
//  Created by brendan kerr on 4/2/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

#import "JWAWSIdentityManager.h"

#define TESTING
@interface JWAWSIdentityManager() <FBSDKLoginButtonDelegate> {
    
}

@property (nonatomic) AWSCognitoCredentialsProvider *credentialsProvider;
@property (strong, nonatomic) FBSDKLoginManager *facebookLogin;

@end

@implementation JWAWSIdentityManager



+ (instancetype)sharedInstance {
    static JWAWSIdentityManager *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [JWAWSIdentityManager new];
    });
    return _sharedInstance;
}



#pragma mark - AWS Credentials

- (void)initializeClients:(NSDictionary *)logins {
    NSLog(@"initializing clients...%s", __func__);
    [AWSLogger defaultLogger].logLevel = AWSLogLevelVerbose;
    
    self.credentialsProvider = [[AWSCognitoCredentialsProvider alloc] initWithRegionType:AMAZON_COGNITO_REGION identityId:nil identityPoolId:AMAZON_COGNITO_IDENTITY_POOL_ID logins:logins];
    
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AMAZON_COGNITO_REGION credentialsProvider:self.credentialsProvider];
    
    AWSServiceManager.defaultServiceManager.defaultServiceConfiguration = configuration;
    //return [self.credentialsProvider getIdentityId];
}



-(void)completeLogin:(NSDictionary *)logins withCompletion:(AWSContinuationBlock)completetion {
    NSLog(@"%s", __func__);
    //AWSTask *task;
    if (self.credentialsProvider == nil) {
        NSLog(@"Provider was nil.");
        [self initializeClients:logins];
        [self finalizeLoginWithCompletion:completetion];
        
    }
    else {
        NSLog(@"Provider existed.");

    }
    
}


-(void)finalizeLoginWithCompletion:(AWSContinuationBlock)completion {
    
    self.completionHandler = completion;
    
    [[[self.credentialsProvider getIdentityId] continueWithBlock:^id(AWSTask *task) {
        
        if(!task.error){
            NSLog(@"Checking for New Device.");
            //if we have a new device token register it
            __block NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            __block NSData *currentDeviceToken = [userDefaults objectForKey:@"DeviceToken"];
            __block NSString *currentDeviceTokenString = (currentDeviceToken == nil)? nil : [currentDeviceToken base64EncodedStringWithOptions:0];
            
            if(currentDeviceToken != nil && ![currentDeviceTokenString isEqualToString:[userDefaults stringForKey:@"CognitoDeviceToken"]]){
                [[[AWSCognito defaultCognito] registerDevice:currentDeviceToken] continueWithBlock:^id(AWSTask *task) {
                    if(!task.error){
                        NSLog(@"Registering Device.");
                        [userDefaults setObject:currentDeviceTokenString forKey:@"CognitoDeviceToken"];
                        [userDefaults synchronize];
                    }
                    return nil;
                }];
            }
            
            
        }
        return nil;
        
    }] continueWithBlock:self.completionHandler];
}

#pragma mark - Cognito Profile


- (NSString *)identityId {

    return self.credentialsProvider.identityId;
}



#pragma mark - Facebook



- (void)reloadFBSession {
    
    if ([FBSDKAccessToken currentAccessToken]) {
        [self completeFBLogin];
    }
}


//call this after fb button call completes with a good result
- (void)completeFBLoginWithCompletion:(AWSContinuationBlock)completion {
    
    //self.keychain[FB_PROVIDER] = @"YES";
    [self completeLogin:@{@"graph.facebook.com":[FBSDKAccessToken currentAccessToken].tokenString} withCompletion:completion];
    
}


//Use this when using a custom button for fb login.  if the faebooksdkButton is used, this
//method does not need to be used as the facebook button does it for you
- (void)FBLogin {
    
    if ([FBSDKAccessToken currentAccessToken]) {
        [self completeFBLogin];
        return;
    }
    
    if (!self.facebookLogin)
        self.facebookLogin = [FBSDKLoginManager new];
    
    [self.facebookLogin logInWithReadPermissions:nil fromViewController:nil handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
        
        if (error) {
            //Error message
        } else if (result.isCancelled) {
            // Login canceled, do nothing
        } else {
            [self completeFBLogin];
        }
    }];
    
}


- (BOOL)isLoggedInWithFacebook {
    //BOOL loggedIn = NO;
    NSDictionary *logs = self.credentialsProvider.logins;
    NSLog(@"%@", [logs description]);
    return [FBSDKAccessToken currentAccessToken] != nil;
    
}

-(void)facebookLogout {
    
    [[FBSDKLoginManager new] logOut];
}


#pragma mark -



-(void)storeUserDataAtSet:(NSString *)dataSet withKey:(NSString *)key withValue:(NSString *)value {
    
    // Initialize the Cognito Sync client
    AWSCognito *syncClient = [AWSCognito defaultCognito];
    
    // Create a record in a dataset and synchronize with the server
    AWSCognitoDataset *dataset = [syncClient openOrCreateDataset:dataSet];
    [dataset setString:value forKey:key];
    [[dataset synchronize] continueWithBlock:^id(AWSTask *task) {

        if (task.error) {
            //Handle
        }
        
        return nil;
    }];
}



@end





//1
//        [AWSServiceConfiguration addGlobalUserAgentProductToken:AWS_MOBILEHUB_USER_AGENT];
//
//        self.credentialsProvider =[[AWSCognitoCredentialsProvider alloc] initWithRegionType:AMAZON_COGNITO_REGION
//                                                                                 identityId:nil
//                                                                             identityPoolId:AMAZON_COGNITO_IDENTITY_POOL_ID
//                                                                    identityProviderManager:self];
//
//        AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AMAZON_COGNITO_REGION
//                                                                             credentialsProvider:self.credentialsProvider];

