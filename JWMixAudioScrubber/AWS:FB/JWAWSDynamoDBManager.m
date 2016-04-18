//
//  JWAWSDynamoDBManager.m
//  FacebookAuth
//
//  Created by brendan kerr on 4/10/16.
//  Copyright © 2016 b3k3r. All rights reserved.
//

#import "JWAWSDynamoDBManager.h"
#import <AWSS3/AWSS3.h>
#import "AWSConfiguration.h"


@interface JWAWSDynamoDBManager()



@end


@implementation JWAWSDynamoDBManager


+ (instancetype)sharedInstance {
    static JWAWSDynamoDBManager *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [JWAWSDynamoDBManager new];
    });
    return _sharedInstance;
}


#pragma mark - GENERAL DB CALLS

-(void)saveNewObjectToDynamoDB:(AWSDynamoDBObjectModel *)newUser {
    
    AWSDynamoDBObjectMapper *objectMapper = [AWSDynamoDBObjectMapper defaultDynamoDBObjectMapper];
    [[objectMapper save:newUser] continueWithBlock:^id(AWSTask *task) {
        
        if (task.error) {
            NSLog(@"Error");
            
        } else if (task.exception) {
            NSLog(@"exception.");
        }
        
        if (task.result) {
            NSLog(@"Got a result. %s", __func__);
        }
        
        return nil;
    }];
}

-(void)queryDatabase:(Class)databaseClass hashKeyAttribute:(NSString *)key attributeValues:(id)values {
    
    AWSDynamoDBQueryExpression *query = [AWSDynamoDBQueryExpression new];
    query.hashKeyAttribute = key;
    query.hashKeyValues = values;
    
    [self queryTable:databaseClass withExpression:query];
    
}

-(void)queryTable:(Class)databaseClass withExpression:(AWSDynamoDBQueryExpression *)query {
    
    AWSDynamoDBObjectMapper *objectMapper = [AWSDynamoDBObjectMapper defaultDynamoDBObjectMapper];
    [[objectMapper query:databaseClass expression:query] continueWithBlock:^id (AWSTask *task) {
        
        if (task.error) {
            NSLog(@"Error");
            
        } else if (task.exception) {
            NSLog(@"exception.");
        }
        
        if (task.result) {
            NSLog(@"Got a result. %s", __func__);
            AWSDynamoDBPaginatedOutput *paginatedOutput = task.result;
            [self.delegateDB dynamoDBReturnedFromQueryWith:paginatedOutput.items];
        }
        
        return nil;
    }];

    
}


#pragma mark - APP SPECIFIC DB CALLS

-(void)createNewUserWithId:(NSString *)userID suppliedUserName:(NSString *)username faceBookName:(NSString *)fbName {
    
    JWUsersDBModel *newUser = [[JWUsersDBModel alloc] initWithUserId:userID suppliedUserName:username facebookName:fbName];
    [self saveNewObjectToDynamoDB:newUser];
}


//UserID and jamtrackname are required and other parameters are optional
-(void)createNewJamTrackForUser:(NSString *)userID jamtrackName:(NSString *)trackName parameters:(NSDictionary *)params {
    
    JWJamTracksDBModel *newTrack = [[JWJamTracksDBModel alloc] initWithUserId:userID jamtrackName:trackName parameters:params];
    [self saveNewObjectToDynamoDB:newTrack];
    
}




#pragma mark - S3 
//Because Dynamo and s3 will be working closely together, for now i will inclue all s3
//methods in this class


-(void)downLoadObjectFrom:(NSString *)bucket objectWithName:(NSString *)fileNameString toLoacation:(NSURL *)fileLocation completionHandler:(void (^)(id))completion {
    
    NSString *fileLocationString = @"";
    // Construct the NSURL for the download location.
    NSString *downloadingFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:fileLocationString];
    NSURL *downloadingFileURL = [NSURL fileURLWithPath:downloadingFilePath];
    
    // Create transferManager and Construct the download request.
    AWSS3TransferManager *transferManager = [AWSS3TransferManager defaultS3TransferManager];
    AWSS3TransferManagerDownloadRequest *downloadRequest = [AWSS3TransferManagerDownloadRequest new];
    
    downloadRequest.bucket = AMAZON_S3_BUCKET_NAME;
    downloadRequest.key = fileNameString;
    downloadRequest.downloadingFileURL = (fileLocation == nil) ? downloadingFileURL : fileLocation;
    
    // Download the file.
    [[transferManager download:downloadRequest]
     continueWithExecutor:[AWSExecutor mainThreadExecutor]
     withBlock:^id(AWSTask *task) {
         if (task.error){
             if ([task.error.domain isEqualToString:AWSS3TransferManagerErrorDomain]) {
                 switch (task.error.code) {
                     case AWSS3TransferManagerErrorCancelled:
                     case AWSS3TransferManagerErrorPaused:
                         break;
                         
                     default:
                         NSLog(@"Error: %@", task.error);
                         break;
                 }
             } else {
                 // Unknown error.
                 NSLog(@"Error: %@", task.error);
             }
         }
         
         if (task.result) {
             AWSS3TransferManagerDownloadOutput *downloadOutput = task.result;
             //File downloaded successfully.
             completion(downloadOutput);
         }
         return nil;
     }];
    
}
     


-(void)uploadObjectTo:(NSString *)bucket usingIdentifier:(NSString *)fileNameString fromLocation:(NSURL *)fileLocation completionHandler:(void (^)(id))completion {
    
    AWSS3TransferManager *transferManager = [AWSS3TransferManager defaultS3TransferManager];
    AWSS3TransferManagerUploadRequest *uploadRequest = [AWSS3TransferManagerUploadRequest new];
    
    uploadRequest.bucket = AMAZON_S3_BUCKET_NAME;
    uploadRequest.key = fileNameString;
    uploadRequest.body = fileLocation;

    
    [[transferManager upload:uploadRequest]
     continueWithExecutor:[AWSExecutor mainThreadExecutor]
     withBlock:^id(AWSTask *task) {
         if (task.error) {
             if ([task.error.domain isEqualToString:AWSS3TransferManagerErrorDomain]) {
                 switch (task.error.code) {
                     case AWSS3TransferManagerErrorCancelled:
                     case AWSS3TransferManagerErrorPaused:
                         break;
                         
                     default:
                         NSLog(@"Error: %@", task.error);
                         break;
                 }
             } else {
                 // Unknown error.
                 NSLog(@"Error: %@", task.error);
             }
         }
         
         if (task.result) {
             AWSS3TransferManagerUploadOutput *uploadOutput = task.result;
             // The file uploaded successfully.
             completion(uploadOutput);
         }
         return nil;
     }];

}




@end





//UserID is required, other parameters are optional
//-(void)createNewUserWithId:(NSString *)userID otherParameters:(NSDictionary *)params {
//
//    NSString *supplied = params[suppliedUsernameKey];
//    NSString *fb = params[facebookNameKey];
//
//    JWUsersDBModel *newUser = [[JWUsersDBModel alloc] initWithUserId:userID suppliedUserName:supplied facebookName:fb];
//    [self saveNewUserToDynamoDB:newUser];
//
//
//}

