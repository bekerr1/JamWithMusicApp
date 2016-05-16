//
//  JWFileManager.h
//  JamWDev
//
//  Created by brendan kerr on 4/18/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JWFileManager : NSObject

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
@property (nonatomic) NSMutableDictionary *testTrackDocumentURLs;
@property (strong, nonatomic) NSMutableArray *userOrderList;  // dbkey

+(instancetype) defaultManager;
-(void)readHomeMenuLists;

-(void)update;
-(void)reload;
-(void)readFsData;
-(void)saveMeta;
-(void)saveUserList;

-(NSMutableArray *)homeItemsList;
-(NSURL *)testURL:(NSString *)stringID;

@end
