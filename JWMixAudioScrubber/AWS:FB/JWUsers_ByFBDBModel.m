//
//  JWUsers_ByFBDBModel.m
//  JamWDev
//
//  Created by brendan kerr on 5/10/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

#import "JWUsers_ByFBDBModel.h"

@implementation JWUsers_ByFBDBModel

+(NSString *)dynamoDBTableName {
    return @"Users_ByFBName";
}

+(NSString *)hashKeyAttribute {
    return @"Facebook";
}

+(NSString *)rangeKeyAttribute {
    return @"UserName";
}

-(instancetype)initWithFacebookName:(NSString *)fbName username:(NSString *)username params:(NSDictionary *)parameters {
    
    if (self = [super init]) {
        
        self.Facebook = fbName;
        self.UserName = username;
        self.parameters = parameters;
    }
    return self;
}

-(instancetype)initWithFacebookName:(NSString *)fbName username:(NSString *)username userID:(NSString *)userID {
    
    if (self = [super init]) {
        
        self.Facebook = fbName;
        self.UserName = username;
        self.userID = userID;
    }
    return self;
}





@end
