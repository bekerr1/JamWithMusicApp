//
//  JWUsersDBModel.h
//  FacebookAuth
//
//  Created by brendan kerr on 4/10/16.
//  Copyright © 2016 b3k3r. All rights reserved.
//

#import <AWSDynamoDB/AWSDynamoDB.h>

@interface JWUsersDBModel : AWSDynamoDBObjectModel <AWSDynamoDBModeling>

@property (nonatomic, strong) NSString *UserId;
@property (nonatomic, strong) NSString *suppliedUserName;
@property (nonatomic, strong) NSString *facebookProfileName;

-(instancetype)initWithUserId:(NSString *)userID
             suppliedUserName:(NSString *)supplied
                 facebookName:(NSString*)fbName;

@end
