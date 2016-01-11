//
//  JWFileDowloadController.m
//  JamWIthT
//
//  Created by JOSEPH KERR on 10/21/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import "JWFileDowloadController.h"
@import UIKit;

@interface JWFileDowloadController () <NSURLSessionDownloadDelegate> {
    JWFileDowloadCompletionHandler completionBlock;
    JWFileDowloadProgressHandler progressBlock;
    NSString* _dbKey;
}
@property (nonatomic) NSURLSessionDownloadTask *downloadTask;
@end


@implementation JWFileDowloadController

-(void)dowloadFileWithURL:(NSURL *)targetURL {
    NSURLSessionConfiguration* defualtSession = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession* session = [NSURLSession sessionWithConfiguration:defualtSession delegate:self delegateQueue:nil];
    
    _downloadTask = [session downloadTaskWithURL:targetURL];
    [[UIApplication sharedApplication]setNetworkActivityIndicatorVisible:YES];
    
    [_downloadTask resume];
}

-(void)cancel {
    NSLog(@"%s",__func__);

    [_downloadTask cancel];
    
    [[UIApplication sharedApplication]setNetworkActivityIndicatorVisible:NO];
}

-(void)dowloadFileWithURL:(NSURL *)targetURL onCompletion:(JWFileDowloadCompletionHandler)completion {
    completionBlock = completion;
    [self dowloadFileWithURL:targetURL];
}

-(void)dowloadFileWithURL:(NSURL *)targetURL onProgress:(JWFileDowloadProgressHandler)progress onCompletion:(JWFileDowloadCompletionHandler)completion {
    completionBlock = completion;
    progressBlock = progress;
    [self dowloadFileWithURL:targetURL];
}

-(void)dowloadFileWithURL:(NSURL *)targetURL withDBKey:(NSString*)dbKey onProgress:(JWFileDowloadProgressHandler)progress onCompletion:(JWFileDowloadCompletionHandler)completion {
    completionBlock = completion;
    progressBlock = progress;
    _dbKey = dbKey;
//    NSLog(@"%s\nDOWNLOADURL\n%@",__func__,[targetURL absoluteString]);
    [self dowloadFileWithURL:targetURL];
}

#pragma mark - urlsession delegate

- (void)URLSession:(NSURLSession * _Nonnull)session
      downloadTask:(NSURLSessionDownloadTask * _Nonnull)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    float percentComplete = 0.0f;
    if (totalBytesExpectedToWrite > 0)
        percentComplete = (float)totalBytesWritten/totalBytesExpectedToWrite;
    
    float result = (float)percentComplete;
    if (progressBlock) {
        progressBlock(result);
    }

}

- (void)URLSession:(NSURLSession * _Nonnull)session
      downloadTask:(NSURLSessionDownloadTask * _Nonnull)downloadTask
didFinishDownloadingToURL:(NSURL * _Nonnull)location
{
    [[UIApplication sharedApplication]setNetworkActivityIndicatorVisible:NO];

    if (completionBlock) {
        completionBlock(location,_dbKey);
    }
}


@end
