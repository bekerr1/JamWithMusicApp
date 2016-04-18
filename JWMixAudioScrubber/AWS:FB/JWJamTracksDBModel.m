//
//  JWJamTracksDBModel.m
//  FacebookAuth
//
//  Created by brendan kerr on 4/16/16.
//  Copyright © 2016 b3k3r. All rights reserved.
//

#import "JWJamTracksDBModel.h"
#import "AWSConfiguration.h"

@interface JWJamTracksDBModel()


//ENUM of instrument types
//@property (nonatomic) NSString *instrumentType;



@end
@implementation JWJamTracksDBModel

+ (NSString *)dynamoDBTableName {
    return DYNAMODB_JAMTRAKS_TABLE_NAME;
}

+ (NSString *)hashKeyAttribute {
    return @"UserId";
}

+ (NSString *)rangeKeyAttribute {
    return @"TrackName";
}

-(instancetype)initWithUserId:(NSString *)userid jamtrackName:(NSString *)trackName parameters:(NSDictionary *)params {
    
    if (self = [super init]) {
        self.userId = userid;
        self.trackName = trackName;
    }
    return self;
}



@end
