//
//  JWUsers_ByFBDBModel.h
//  JamWDev
//
//  Created by brendan kerr on 5/10/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

#import <AWSDynamoDB/AWSDynamoDB.h>

@interface JWUsers_ByFBDBModel : AWSDynamoDBObjectModel <AWSDynamoDBModeling>

@property (nonatomic) NSString *fbName;
@property (nonatomic) NSString *username;
@property (nonatomic) NSString *userID;
@property (nonatomic) NSDictionary *parameters;

-(instancetype)initWithFacebookName:(NSString *)fbName username:(NSString *)username params:(NSDictionary *)parameters;
-(instancetype)initWithFacebookName:(NSString *)fbName username:(NSString *)username userID:(NSString *)userID;

@end
