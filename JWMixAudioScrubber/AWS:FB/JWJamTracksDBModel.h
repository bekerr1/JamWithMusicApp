//
//  JWJamTracksDBModel.h
//  FacebookAuth
//
//  Created by brendan kerr on 4/16/16.
//  Copyright © 2016 b3k3r. All rights reserved.
//

#import <AWSDynamoDB/AWSDynamoDB.h>

@interface JWJamTracksDBModel : AWSDynamoDBObjectModel <AWSDynamoDBModeling>

@property (nonatomic) NSString *UserId;
@property (nonatomic) NSString *TrackName;

-(instancetype)initWithUserId:(NSString *)userid jamtrackName:(NSString *)trackName parameters:(NSDictionary *)params;

@end
