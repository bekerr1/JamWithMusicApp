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

@property (nonatomic) NSMutableDictionary *linksDirector;
@property (nonatomic) NSMutableDictionary *mp3FilesInfo;
@property (nonatomic) NSMutableDictionary *mp3FilesDescriptions;
@property (nonatomic) NSMutableDictionary *testTrackDocumentURLs;
@property (nonatomic) NSMutableArray *userOrderList;  // dbkey

+(instancetype) defaultManager;
-(void)readHomeMenuLists;
-(void)saveHomeMenuLists;
-(void)updateHomeObjectsAndSave:(NSMutableArray *)newHomeObjectArr;
-(void)update;
-(void)reload;
-(void)readFsData;
-(void)saveMeta;
-(void)saveUserList;

-(NSMutableArray *)homeItemsList;
-(NSURL *)testURL:(NSString *)stringID;

-(NSURL *)fileURLWithFileName:(NSString*)name;
-(NSURL *)fileURLWithFileName:(NSString*)name inPath:(NSArray*)pathComponents;

-(NSString*)documentsDirectoryPath;

@end
