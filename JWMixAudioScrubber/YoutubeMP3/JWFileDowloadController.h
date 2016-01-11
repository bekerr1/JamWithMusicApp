//
//  JWFileDowloadController.h
//  JamWIthT
//
//  Created by JOSEPH KERR on 10/21/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^JWFileDowloadCompletionHandler)(NSURL *downloadedFileURL, NSString *dbkey);
typedef void (^JWFileDowloadProgressHandler)(float progress);

@interface JWFileDowloadController : NSObject
-(void)dowloadFileWithURL:(NSURL *)targetURL;
-(void)dowloadFileWithURL:(NSURL *)targetURL onCompletion:(JWFileDowloadCompletionHandler)completion;
-(void)dowloadFileWithURL:(NSURL *)targetURL onProgress:(JWFileDowloadProgressHandler)progress onCompletion:(JWFileDowloadCompletionHandler)completion;
-(void)dowloadFileWithURL:(NSURL *)targetURL withDBKey:(NSString*)dbKey onProgress:(JWFileDowloadProgressHandler)progress onCompletion:(JWFileDowloadCompletionHandler)completion;

-(void)cancel;
@end

// VALID for mats for specifying block paramaters
//withCompletion:(void (^)())completion;
//- (void)something:(JWClipAudioCompletionHandler)completion;
//(void (^)(CMTime time))block
//typedef void (^AVAudioNodeCompletionHandler)(void);
//onCompletion:(void (^)(NSMutableArray* channelData,NSString *searchStr))completion;
//typedef void (^JWFileDowloadCompletionHandler)(void);

