//
//  JWFileManager.m
//  JamWDev
//
//  Created by brendan kerr on 4/18/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

#import "JWFileManager.h"
#import "JWJamSessionCoordinator.h"
#import "JWDBKeys.h"
#import "JWMixNodes.h"

@interface JWFileManager() {
    dispatch_queue_t _imageRetrievalQueue;
    dispatch_queue_t _fileInfoRetrievalQueue;
}
@property id lockFiles;
@property (nonatomic,readwrite) NSArray *downloadedJamTrackFiles;
@property (nonatomic,readwrite) NSArray *jamTrackFiles;
@property (nonatomic,readwrite) NSArray *mp3Files;
@property (nonatomic,readwrite) NSArray *recordingFiles;
@property (nonatomic,readwrite) NSArray *sourceFiles;
@property (nonatomic,readwrite) NSArray *trimmedFiles;
@property (nonatomic) NSMutableArray *mp3filesFilesData;
@property (nonatomic) NSMutableArray *recordingsFilesData;
@property (nonatomic) NSMutableArray *clipsFilesData;
@property (nonatomic) NSMutableArray *finalsFilesData;
@property (nonatomic) NSMutableArray *trimmedFilesData;
@property (nonatomic) NSMutableDictionary *dbMetaData;
@property (nonatomic) NSMutableArray *homeObjects;
@property (nonatomic) JWJamSessionCoordinator *coordination;
@end


#define TESTING

@implementation JWFileManager

+ (instancetype)defaultManager {
    static JWFileManager *_defaultManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _defaultManager = [JWFileManager new];
        [_defaultManager readHomeMenuLists];
        [_defaultManager serializeInJamTracks];
    });
    return _defaultManager;
}



-(instancetype)init {
    if (self = [super init]) {
        [self initdb];
        _testTrackDocumentURLs = [NSMutableDictionary new];
        _coordination = [JWJamSessionCoordinator new];
        if (_imageRetrievalQueue == nil)
            _imageRetrievalQueue =
            dispatch_queue_create("imageFileProcessingYoutubeMP3",
                                  dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_CONCURRENT,QOS_CLASS_UTILITY, 0));
        
        if (_fileInfoRetrievalQueue == nil)
            _fileInfoRetrievalQueue =
            dispatch_queue_create("imageProcessingSourceAudio",
                                  dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_CONCURRENT,QOS_CLASS_UTILITY, 0));
        
        _dbMetaData = [NSMutableDictionary new];
    }
    
    return self;
}






//FOR testing, creating test audio files at urls
#ifdef TESTING


-(NSString*)sourceAudioFilesDirectoryPath {
    return [[self documentsDirectoryPath] stringByAppendingPathComponent:@"Source"];
}


- (void)copyResources {
    
    NSLog(@"%@",[self documentsDirectoryPath]);
    NSError *error;
    NSURL *fileURL = nil;
    
    fileURL = [[NSBundle mainBundle] URLForResource:@"TheKillersTrimmedMP3-30" withExtension:@".m4a"];
    [[NSFileManager defaultManager] copyItemAtURL:fileURL
                                            toURL:[self fileURLWithFileName:[fileURL lastPathComponent]] error:&error];
    
    _testTrackDocumentURLs[@"killersMP3"] = fileURL;
    
    
    //not used, dont like this backing track or what i recorded
/*    fileURL = [[NSBundle mainBundle] URLForResource:@"AminorBackingtrackTrimmedMP3-45" withExtension:@".m4a"];
    [[NSFileManager defaultManager] copyItemAtURL:fileURL
                                            toURL:[self fileURLWithFileName:[fileURL lastPathComponent]]
                                            error:&error];
    
    //NSLog(@"File url: %@", [[self fileURLWithFileName:[fileURL lastPathComponent]] absoluteString]);
    
    fileURL = [[NSBundle mainBundle] URLForResource:@"clipRecording_aminor1" withExtension:@".caf"];
    [[NSFileManager defaultManager] copyItemAtURL:fileURL
                                            toURL:[self fileURLWithFileName:[fileURL lastPathComponent]]
                                            error:&error];
    
    //NSLog(@"File url: %@", [[self fileURLWithFileName:[fileURL lastPathComponent]] absoluteString]);  */
    
    fileURL = [[NSBundle mainBundle] URLForResource:@"clipRecording_killers1" withExtension:@".caf"];
    [[NSFileManager defaultManager] copyItemAtURL:fileURL
                                            toURL:[self fileURLWithFileName:[fileURL lastPathComponent]]
                                            error:&error];
    _testTrackDocumentURLs[@"killersrecording1"] = fileURL;
    
    
    fileURL = [[NSBundle mainBundle] URLForResource:@"clipRecording_killers2" withExtension:@".caf"];
    [[NSFileManager defaultManager] copyItemAtURL:fileURL
                                            toURL:[self fileURLWithFileName:[fileURL lastPathComponent]]
                                            error:&error];
    _testTrackDocumentURLs[@"killersrecording2"] = fileURL;
    
}



#endif


#pragma mark CREATION/LOAD

- (void)initdb {
    
    // CREATE DIRECTORY STRUCTURE AND COPY RESOURCES
    NSString *jtDirectory = [[self documentsDirectoryPath] stringByAppendingPathComponent:@"JamSessions"];
    BOOL isDir = NO;
    if ([[NSFileManager defaultManager] fileExistsAtPath:jtDirectory isDirectory:&isDir]){
        // Exists
    } else {
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:jtDirectory
                                  withIntermediateDirectories:YES attributes:nil
                                                        error:&error];
    }
    jtDirectory = [jtDirectory stringByAppendingPathComponent:@"SourceAudioJamTrackDownloads"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:jtDirectory isDirectory:&isDir]){
        // Exists
    } else {
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:jtDirectory
                                  withIntermediateDirectories:YES attributes:nil
                                                        error:&error];
    }
    jtDirectory = [[self documentsDirectoryPath] stringByAppendingPathComponent:@"UserJamTrackDownloads"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:jtDirectory isDirectory:&isDir]){
        // Exists
    } else {
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:jtDirectory
                                  withIntermediateDirectories:YES attributes:nil
                                                        error:&error];
    }
    jtDirectory = [[self documentsDirectoryPath] stringByAppendingPathComponent:@"OtherDownloads"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:jtDirectory isDirectory:&isDir]){
        // Exists
    } else {
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:jtDirectory
                                  withIntermediateDirectories:YES attributes:nil
                                                        error:&error];
    }
    jtDirectory = [[self documentsDirectoryPath] stringByAppendingPathComponent:@".trash"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:jtDirectory isDirectory:&isDir]){
        // Exists
    } else {
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:jtDirectory
                                  withIntermediateDirectories:YES attributes:nil
                                                        error:&error];
    }
    // SOURCE DIRECTORY
    NSString *sourceDirectory = [self sourceAudioFilesDirectoryPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:sourceDirectory isDirectory:&isDir]){
        // Exists
    } else {
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:sourceDirectory withIntermediateDirectories:YES attributes:nil
                                                        error:&error];
    }
    
    [self copyResources];
}


//gets files with certain prefixes and puts them into these mutable arrays.  certain arrays are sorted by date where most recent entries are first.
- (void)loadFilesystemData {
    
    // SYSTEM GENERATED files
    
    _mp3filesFilesData = [NSMutableArray new];
    _recordingsFilesData = [NSMutableArray new];
    _clipsFilesData = [NSMutableArray new];
    _finalsFilesData = [NSMutableArray new];
    _trimmedFilesData = [NSMutableArray new];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // DOCUMENTS Directory
    NSDirectoryEnumerator *dirEnum = [fm enumeratorAtURL:[NSURL fileURLWithPath:[self documentsDirectoryPath]]
                              includingPropertiesForKeys:@[NSURLCreationDateKey,NSURLContentAccessDateKey]
                                                 options:NSDirectoryEnumerationSkipsSubdirectoryDescendants
                                            errorHandler:^BOOL(NSURL *url,NSError *error){
                                                return YES;
                                            }];
    NSURL *fileURL;
    while ((fileURL = [dirEnum nextObject])) {
        NSLog(@"current Directory: %@, last component %@", [fileURL absoluteString], [fileURL lastPathComponent]);
        NSError *error;
        NSDictionary *info = [fm attributesOfItemAtPath:[fileURL path] error:&error];
        
        if (info[NSFileType] == NSFileTypeDirectory) {
            // SKIP Directory
        } else {
            NSString *fname = [fileURL lastPathComponent];
            NSDictionary *recordInfo = @{@"furl":fileURL,@"fsize":info[NSFileSize]};
            
            if ([fname hasPrefix:@"mp3file_"]) {
                [_mp3filesFilesData addObject:recordInfo];
            }
            else if ([fname hasPrefix:@"recording_"] || [fname hasPrefix:@"avrec_"]){
                [_recordingsFilesData addObject:recordInfo];
            }
            else if ([fname hasPrefix:@"clip"]) {
                [_clipsFilesData addObject:recordInfo];
            }
            else if ([fname hasPrefix:@"trimmed"]) {
                [_trimmedFilesData addObject:recordInfo];
            }
            else if ([fname hasPrefix:@"final"]) {
                [_finalsFilesData addObject:recordInfo];
            }
            
        }
    }
    
    //    else if ([fname hasPrefix:@"trimmed"] || [fname hasPrefix:@"fiveSeconds"] )
    //        [_trimmedFilesData addObject:recordInfo];
    
    BOOL recentsFirst = YES;
    NSArray *sortedClipsArray = [_clipsFilesData sortedArrayUsingComparator: ^(id obj1, id obj2) {
        NSDate *createDate1;
        NSDate *createDate2;
        NSError *error;
        [(NSURL *)obj1[@"furl"] getResourceValue:&createDate1 forKey:NSURLCreationDateKey error:&error];
        [(NSURL *)obj2[@"furl"] getResourceValue:&createDate2 forKey:NSURLCreationDateKey error:&error];
        
        NSComparisonResult cresult = [createDate1 compare:createDate2];
        // simple date compare cause recents last
        if (recentsFirst) {
            // swap for Recent first
            if (cresult == NSOrderedAscending) {
                cresult = NSOrderedDescending;
            } else if (cresult == NSOrderedDescending) {
                cresult = NSOrderedAscending;
            }
        }
        
        return cresult;
    }];
    
    _clipsFilesData = [sortedClipsArray mutableCopy];
    
    
    recentsFirst = YES;
    sortedClipsArray = [_trimmedFilesData sortedArrayUsingComparator: ^(id obj1, id obj2) {
        NSDate *createDate1;
        NSDate *createDate2;
        NSError *error;
        [(NSURL *)obj1[@"furl"] getResourceValue:&createDate1 forKey:NSURLCreationDateKey error:&error];
        [(NSURL *)obj2[@"furl"] getResourceValue:&createDate2 forKey:NSURLCreationDateKey error:&error];
        
        NSComparisonResult cresult = [createDate1 compare:createDate2];
        // simple date compare cause recents last
        if (recentsFirst) {
            // swap for Recent first
            if (cresult == NSOrderedAscending) {
                cresult = NSOrderedDescending;
            } else if (cresult == NSOrderedDescending) {
                cresult = NSOrderedAscending;
            }
        }
        
        return cresult;
    }];
    
    _trimmedFilesData = [sortedClipsArray mutableCopy];
    
    // THIS ENDS SYSTEM GENERATED POPULATION CODE
    
    
    _sourceFiles = [self readDirectory:[self sourceAudioFilesDirectoryPath]];
    
    _jamTrackFiles = [self readDirectory:[self jamTracksDirectoryPath]];
    
    _downloadedJamTrackFiles = [self readDirectory:[self jamTracksDownloadedDirectoryPath]];
    
}




-(NSMutableArray*)newHomeMenuLists {
    NSMutableArray *result =
    [@[
       
       //source audio will be determined by the tab the user is currently in
       //       [@{
       //          @"title":@"Source Audio",
       //          @"type":@(JWHomeSectionTypeYoutube)
       //          } mutableCopy],
       [@{
          
          //Will be used to give user their saved/unfinished jam sessions
          @"title":@"Jam Sessions",
          @"type":@(JWSectionTypeHome),
          @"trackobjectset":[_coordination newTestJamSession],
          } mutableCopy],

       
       //Will be supplied by an s3 bucket, Not used
       //       [@{
       //          @"title":@"Provided JamTracks",
       //          @"type":@(JWHomeSectionTypePreloaded),
       //          @"trackobjectset":[self newProvidedJamTracks],
       //          } mutableCopy],
       [@{
          
          //Will be used when user downloads somone elses jam track
          @"title":@"Downloaded Jam Tracks",
          @"type":@(JWSectionTypeHome),
          @"trackobjectset":[_coordination newTestJamSession],
          } mutableCopy],

       //This could be turned into a right nav button since the '+' will probably go away in the tab bar implementation
//       [@{
//          
//          //will be used for settings and files user sets
//          @"title":@"Settings And Files",
//          @"type":@(JWSectionTypeProfile),
//          } mutableCopy],
//       
//       
       
       //Will not be used, the user will be prompted to sign in when they need to
       //       [@{
       //
       //          @"title":@"User",
       //          @"type":@(JWHomeSectionTypeUser)
       //          } mutableCopy],
       ] mutableCopy
     ];
    
    return result;
}


#pragma mark READING


-(void)readMetaData {
    _linksDirector = [[NSMutableDictionary alloc] initWithContentsOfURL:
                      [NSURL fileURLWithPath:[[self documentsDirectoryPath] stringByAppendingPathComponent:(NSString*)JWDbKeyLinksDirectoryFileName]]];
    
    NSMutableDictionary *mp3Dict = [[NSMutableDictionary alloc] initWithContentsOfURL:
                                    [NSURL fileURLWithPath:[[self documentsDirectoryPath] stringByAppendingPathComponent:(NSString*)JWDbKeyMP3InfoFileName]]];
    _mp3FilesInfo = [@{} mutableCopy];
    for (id key in [mp3Dict allKeys]) {
        _mp3FilesInfo[key] = [mp3Dict[key] mutableCopy];
    }
    
    //    _mp3FilesInfo = [[NSMutableDictionary alloc] initWithContentsOfURL:
    //                     [NSURL fileURLWithPath:[[self documentsDirectoryPath] stringByAppendingPathComponent:(NSString*)JWDbKeyMP3InfoFileName]]];
    
    NSLog(@"%s LINKSCOUNT [%lu]  MP3INFOCOUNT [%ld]",__func__,(unsigned long)[_linksDirector count],(unsigned long)[_mp3FilesInfo count]);
}



-(void)readHomeMenuLists {
    _homeObjects = [[NSMutableArray alloc] initWithContentsOfURL:[self fileURLWithFileName:@"homeObjects"]];
    NSLog(@"home Controller URL: %@", [self fileURLWithFileName:@"homeObjects"]);
    [self serializeInJamTracks];
    //    NSLog(@"%s homeObjects %@",__func__,[_homeControllerSections description]);
    NSLog(@"%s HOMEOBJECTS [%ld]",__func__,(unsigned long)[_homeObjects count]);
}




#pragma mark - WRITING

-(void)saveMetaData {
    [_linksDirector writeToURL:
     [NSURL fileURLWithPath:[[self documentsDirectoryPath] stringByAppendingPathComponent:(NSString*)JWDbKeyLinksDirectoryFileName]] atomically:YES];
    
    [_mp3FilesInfo writeToURL:[NSURL fileURLWithPath:[[self documentsDirectoryPath] stringByAppendingPathComponent:(NSString*)JWDbKeyMP3InfoFileName]] atomically:YES];
    
    NSLog(@"%s LINKSCOUNT [%ld]  MP3INFOCOUNT [%ld]",__func__,(unsigned long)[_linksDirector count],(unsigned long)[_mp3FilesInfo count]);
    //    NSLog(@"\n%s\nLINKS\n%@\nMP3INFO\n%@",__func__,[_linksDirector description],[_mp3FilesInfo description]);
}


-(void)saveHomeMenuLists {
    [self serializeOutJamTracks];
    //    NSLog(@"%s homeObjects %@",__func__,[_homeControllerSections description]);
    [_homeObjects writeToURL:[self fileURLWithFileName:@"homeObjects"] atomically:YES];
    [self serializeInJamTracks];
    NSLog(@"%s HOMEOBJECTS [%ld]",__func__,(unsigned long)[_homeObjects count]);
}


#pragma mark SERIALIZE

-(void)serializeInJamTrackNode:(id)jamTrackNode {
    id fileRelativePath = jamTrackNode[@"fileRelativePath"];
    if (fileRelativePath)
        jamTrackNode[@"fileURL"] =[self fileURLWithRelativePathName:fileRelativePath];
}



-(void)serializeInJamTracks {
    for (id objectSection in _homeObjects) {
        id jamTracksInSection = objectSection[@"trackobjectset"];
        for (id jamTrack in jamTracksInSection) {
            id jamTrackNodes = jamTrack[@"trackobjectset"];
            for (id jamTrackNode in jamTrackNodes) {
                [self serializeInJamTrackNode:jamTrackNode];
            }
        }
    }
}


-(void)serializeOutJamTrackNode:(id)jamTrackNode {
    id furl = jamTrackNode[@"fileURL"];
    if (furl) {
        jamTrackNode[@"fileRelativePath"] = [(NSURL*)furl relativePath];
        [jamTrackNode removeObjectForKey:@"fileURL"];
    } else {
        //        NSLog(@"%s NO FURL %@",__func__,[jamTrackNode description]);
    }
}

//-(void)serializeOutJamTrackNodeWithKey:(NSString*)key {
//    id jamTrackNode = [self jamTrackNodeObjectForKey:key];
//    [self serializeOutJamTrackNode:jamTrackNode];
//}

-(void)serializeOutJamTracks {
    for (id objectSection in _homeObjects) {
        id jamTracksInSection = objectSection[@"trackobjectset"];
        for (id jamTrack in jamTracksInSection) {
            id jamTrackNodes = jamTrack[@"trackobjectset"];
            for (id jamTrackNode in jamTrackNodes) {
                [self serializeOutJamTrackNode:jamTrackNode];
            }
        }
    }
}


#pragma mark FILE URL UTILITIES

-(NSURL *)fileURLWithFileName:(NSString*)name {
    return [self fileURLWithFileName:name inPath:nil];
}

-(NSURL *)fileURLWithRelativePathName:(NSString*)pathName {
    NSURL *result;
    NSURL *baseURL = [NSURL fileURLWithPath:[self documentsDirectoryPath]];
    NSURL *url = [NSURL fileURLWithPath:pathName relativeToURL:baseURL];
    result = url;
    return result;
}


-(NSURL *)fileURLWithFileFlatFileURL:(NSURL*)flatURL{
    NSString *fileName = [flatURL lastPathComponent];
    NSArray *pathComponents = [flatURL pathComponents];
    __block NSUInteger indexToDocuments = 0;
    [pathComponents enumerateObjectsWithOptions:NSEnumerationReverse
                                     usingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                                         if ([obj isEqualToString:@"Documents"]) {
                                             indexToDocuments = idx;
                                             *stop = YES;
                                         }
                                     }];
    
    NSMutableArray *pathFromDocuments = [NSMutableArray new];
    // Iterate one past Documents til count -1 end slash
    for (NSUInteger i = (indexToDocuments + 1); i <  ([pathComponents count] - 1); i++) {
        [pathFromDocuments addObject:pathComponents[i]];
    }
    
    NSURL *result = [self fileURLWithFileName:fileName  inPath:pathFromDocuments];
    return result;
}



-(NSURL *)fileURLWithFileName:(NSString*)name inPath:(NSArray*)pathComponents{
    NSURL *result;
    NSURL *baseURL = [NSURL fileURLWithPath:[self documentsDirectoryPath]];
    NSString *pathString = @"";
    for (id path in pathComponents) {
        pathString = [pathString stringByAppendingPathComponent:path];
    }
    pathString = [pathString stringByAppendingPathComponent:name];
    NSURL *url = [NSURL fileURLWithPath:pathString relativeToURL:baseURL];
    result = url;
    return result;
}

-(NSString*)documentsDirectoryPath {
    NSString *result = nil;
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    result = [searchPaths objectAtIndex:0];
    return result;
}


#pragma mark DIRECTORIES

-(NSString*)jamTracksDirectoryPath {
    return [[self documentsDirectoryPath] stringByAppendingPathComponent:@"JamSessions"];
}

-(NSString*)jamTracksDownloadedDirectoryPath {
    return [[self jamTracksDirectoryPath] stringByAppendingPathComponent:@"UserJamTrackDownloads"];
}


-(NSArray*)readDirectory:(NSString*)directoryPath {
    
    NSMutableArray *result = [NSMutableArray new];
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSDirectoryEnumerator *dirEnum = [fm enumeratorAtURL:[NSURL fileURLWithPath:directoryPath]
                              includingPropertiesForKeys:@[NSURLCreationDateKey,NSURLContentAccessDateKey]
                                                 options:NSDirectoryEnumerationSkipsSubdirectoryDescendants
                                            errorHandler:^BOOL(NSURL *url,NSError *error){
                                                return YES;
                                            }];
    
    NSURL *fileURL;
    
    while ((fileURL = [dirEnum nextObject])) {
        NSError *error;
        NSDictionary *info = [fm attributesOfItemAtPath:[fileURL path] error:&error];
        NSString *fname = [fileURL lastPathComponent];
        if (info[NSFileType] == NSFileTypeDirectory  || [fname isEqualToString:@".DS_Store"]) {
            // SKIP
        } else {
            NSDictionary *recordInfo = @{@"furl":fileURL,@"fsize":info[NSFileSize]};
            [result addObject:recordInfo];
        }
    }
    
    return [NSArray arrayWithArray:result];
}


#pragma mark GIVERS

-(NSURL *)testURL:(NSString *)stringID {
    
    return _testTrackDocumentURLs[stringID];
}


-(NSMutableArray *)homeItemsList {
    //sets _homeobjects to the file contents of homeobjects
    [self readHomeMenuLists];
    if (!_homeObjects) {
        _homeObjects = [self newHomeMenuLists];
    }
    
    return _homeObjects;
}




@end
