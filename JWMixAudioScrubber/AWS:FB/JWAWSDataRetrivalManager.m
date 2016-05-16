//
//  JWAWSDataRetrivalManager.m
//  JamWDev
//
//  Created by brendan kerr on 4/23/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

#import "JWAWSDataRetrivalManager.h"
#import "JWUsers_ByFBDBModel.h"
#import "JWUsersDBModel.h"
#import <AWSDynamoDB/AWSDynamoDB.h>

/*
 
 Guidlines for Scan and Query - http://docs.aws.amazon.com/amazondynamodb/latest/developerguide/QueryAndScanGuidelines.html
 Query Expression Doc - http://docs.aws.amazon.com/AWSiOSSDK/latest/Classes/AWSDynamoDBQueryExpression.html#//api/name/keyConditionExpression
 Scan Expression Doc - http://docs.aws.amazon.com/AWSiOSSDK/latest/Classes/AWSDynamoDBScanExpression.html#//api/name/filterExpression
 
 */

@interface JWAWSDataRetrivalManager()

@property (nonatomic) dispatch_queue_t userSearchQueue;
@property (nonatomic) UIActivityIndicatorView *activity;

@end
@implementation JWAWSDataRetrivalManager

-(instancetype)init {
    
    if (self = [super init]) {
        self.userSearchQueue = dispatch_queue_create("userSearchQueue", dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, 0));
        
        self.activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    }
    return self;
}

-(void)updateCurrentSearch:(NSString *)string {
    
    dispatch_async(self.userSearchQueue, ^() {
        [self queryDynamoDBUsingString:string];
    });
}


/* 
 When performing a scan, dynamo will return all items 
 Want to limit scans performed
 
 
 */

-(void)scanDynamoDBUsingString:(NSString *)string {
    
    AWSDynamoDBObjectMapper *dynamoDBObjectMapper = [AWSDynamoDBObjectMapper
                                                     defaultDynamoDBObjectMapper];
    AWSDynamoDBScanExpression *scanExpression = [AWSDynamoDBScanExpression new];
    scanExpression.expressionAttributeValues = @{@":search_val" : string};
    scanExpression.projectionExpression = @"facebookProfileName, suppliedUserName";
    scanExpression.limit = @10;
    
    [[dynamoDBObjectMapper scan:[JWUsersDBModel class]
                     expression:scanExpression]
     continueWithBlock:^id(AWSTask *task) {
         if (task.error) {
             NSLog(@"The request failed. Error: [%@]", task.error);
         }
         if (task.exception) {
             NSLog(@"The request failed. Exception: [%@]", task.exception);
         }
         if (task.result) {
             AWSDynamoDBPaginatedOutput *paginatedOutput = task.result;
             for (JWUsersDBModel *user in paginatedOutput.items) {
                 //Do something with book.
             }
         }
         return nil;
     }];

    
}

-(void)queryDynamoDBUsingString:(NSString *)string {
    
    
    if (![string  isEqual: @""]) {
        NSLog(@"Query %s", __func__);
        AWSDynamoDBObjectMapper *dynamoDBObjectMapper = [AWSDynamoDBObjectMapper
                                                         defaultDynamoDBObjectMapper];
        AWSDynamoDBQueryExpression *queryExpression = [AWSDynamoDBQueryExpression new];
        
        //queryExpression.expressionAttributeValues = @{@":search_val":string};
        queryExpression.hashKeyAttribute = @"Facebook";
        queryExpression.hashKeyValues = string;
//        queryExpression.hashKeyValues = @"begins_with(Facebook, :search_val)";
//        queryExpression.rangeKeyConditionExpression = @"begins_with(Facebook, :search_val)";
        
        [[dynamoDBObjectMapper query:[JWUsers_ByFBDBModel class]
                          expression:queryExpression]
         continueWithBlock:^id(AWSTask *task) {
             if (task.error) {
                 NSLog(@"The request failed. Error: [%@]", task.error);
             }
             if (task.exception) {
                 NSLog(@"The request failed. Exception: [%@]", task.exception);
             }
             if (task.result) {
                 NSLog(@"Completed with success");
             }
             return nil;
         }];
        

    }
    
}



@end
