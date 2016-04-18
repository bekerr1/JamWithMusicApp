//
//  JWAWSDynamoDBManager.h
//  FacebookAuth
//
//  Created by brendan kerr on 4/10/16.
//  Copyright © 2016 b3k3r. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AWSDynamoDB/AWSDynamoDB.h>
#import "JWUsersDBModel.h"
#import "JWJamTracksDBModel.h"

@protocol JWDynamoDBResultDelegate;

@interface JWAWSDynamoDBManager : NSObject

@property (nonatomic) NSArray *userTrackList;
@property (nonatomic) id <JWDynamoDBResultDelegate> delegateDB;

+ (instancetype)sharedInstance;

-(void)createNewUserWithId:(NSString *)userID suppliedUserName:(NSString *)username faceBookName:(NSString *)fbName;
-(void)createNewUserWithId:(NSString *)userID otherParameters:(NSDictionary *)params;
-(void)createNewJamTrackForUser:(NSString *)userID jamtrackName:(NSString *)trackName parameters:(NSDictionary *)params;
-(void)uploadObjectTo:(NSString *)bucket usingIdentifier:(NSString *)fileNameString fromLocation:(NSURL *)fileLocation completionHandler:(void (^)(id))completion;
-(void)downLoadObjectFrom:(NSString *)bucket objectWithName:(NSString *)fileNameString toLoacation:(NSURL *)fileLocation completionHandler:(void (^)(id))completion;

@end


@protocol JWDynamoDBResultDelegate <NSObject>

-(void)dynamoDBReturnedFromQueryWith:(NSArray *)output;


@end
