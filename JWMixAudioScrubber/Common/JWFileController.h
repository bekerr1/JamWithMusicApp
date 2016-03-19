//
//  JWFileController.h
//  JWMixAudioScrubber
//
//  co-created by joe and brendan kerr on 1/7/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

#import <Foundation/Foundation.h>
@import UIKit;

typedef void (^JWFileImageCompletionHandler)(UIImage *image); //  block (^JWClipExportAudioCompletionHandler)(void);


@interface JWFileController : NSObject

+ (JWFileController *)sharedInstance;

-(void)update;
-(void)reload;
-(void)readFsData;
-(void)saveMeta;
-(void)saveUserList;

-(double)audioLengthForFileWithName:(NSString*)fileName;

-(NSString*)dbKeyForFileName:(NSString*)fileName;

// returns records URLs and size for Files arrays
@property (nonatomic,readonly) NSArray *downloadedJamTrackFiles;
@property (nonatomic,readonly) NSArray *jamTrackFiles;
@property (nonatomic,readonly) NSArray *mp3Files;
@property (nonatomic,readonly) NSArray *recordingFiles;
@property (nonatomic,readonly) NSArray *trimmedFiles;
@property (nonatomic,readonly) NSArray *sourceFiles;

@property (strong, nonatomic) NSMutableDictionary *linksDirector;
@property (strong, nonatomic) NSMutableDictionary *mp3FilesInfo;
@property (strong, nonatomic) NSMutableDictionary *mp3FilesDescriptions;
@property (strong, nonatomic) NSMutableArray *userOrderList;  // dbkey

-(NSURL *)fileURLForCacheItem:(NSString*)dbkey;

-(NSURL *)processInBoxItem:(NSURL*)fileURL options:(id)options;

-(NSString*)audioFileFormatStringForFile:(NSURL*)fileURL;
-(NSString*)audioFileProcessingFormatStringForFile:(NSURL*)fileURL;


@end
