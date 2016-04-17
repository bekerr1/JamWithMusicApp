//
//  JWUserController.m
//  JamWDev
//
//  Created by brendan kerr on 3/31/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

#import "JWUserController.h"
#import "JWUserConstants.h"
#import <AVFoundation/AVFoundation.h>

NSString * const kRootURL = @"https://amber-torch-5644.firebaseio.com";
NSString * const kUsersSection = @"users";
NSString * const kUsersMusicFiles = @"jamfiles";

@interface JWUserController() {
    
}

@property (nonatomic) Firebase *rootReference;
@property (nonatomic) Firebase *userReference;

@end

@implementation JWUserController



-(instancetype)init {
    
    if (self = [super init]) {
        //Initialize
        self.rootReference = [[Firebase alloc] initWithUrl:kRootURL];
        self.userReference = [self.rootReference childByAppendingPath:kUsersSection];
    }
    
    return self;
}



-(BOOL)createNewUserWithUserName:(NSString *)name password:(NSString *)pass {
    
    BOOL __block newUserPass = NO;
    
    Firebase *usersRef = [self.rootReference childByAppendingPath:kUsersSection];
    Firebase *newUserRef = [usersRef childByAppendingPath:name];
    
    NSDictionary *newUser = @{
                              @"username" : name,
                              @"password" : pass
                              
                              };
    
    //TODO: need to check if the username is already created
    //Do there here...
    
    [newUserRef setValue:newUser withCompletionBlock:^(NSError *error, Firebase *ref) {
       
        if (error) {
            NSLog(@"Could not create new user.");
        } else {
            NSLog(@"New user created!");
            newUserPass = YES;
        }
    }];
    
    return newUserPass;
    
}


//-(BOOL)addJamTrack:(AVAudioFile *)audioFile atUserName:(NSString *)userName {
//    
//    
//}
//
//
//-(NSDictionary *)getJamTracksForUser:(NSString *)userName {
//    
//    
//}

@end




//-(NSString *)rootURLString {
//
//    if (!_rootURLString) {
//        _rootURLString = @"https://amber-torch-5644.firebaseio.com";
//    }
//
//    return _rootURLString;
//}

