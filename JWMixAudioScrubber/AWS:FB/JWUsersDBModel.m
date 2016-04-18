//
//  JWUsersDBModel.m
//  FacebookAuth
//
//  Created by brendan kerr on 4/10/16.
//  Copyright © 2016 b3k3r. All rights reserved.
//

#import "JWUsersDBModel.h"
#import "AWSConfiguration.h"

@implementation JWUsersDBModel

+ (NSString *)dynamoDBTableName {
    return DYNAMODB_USERS_TABLE_NAME;
}

+ (NSString *)hashKeyAttribute {
    return @"UserId";
}

-(instancetype)initWithUserId:(NSString *)userID suppliedUserName:(NSString *)supplied facebookName:(NSString*)fbName {
    
    if (self = [super init]) {
        
        self.UserId = userID;
        self.suppliedUserName = supplied;
        self.facebookProfileName = fbName;
    }
    
    return self;
}



@end
