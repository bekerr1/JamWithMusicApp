//
//  JWFileController.m
//  JWMixAudioScrubber
//
//  Created by JOSEPH KERR on 1/7/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

#import "JWFileController.h"
#import "JWDBKeys.h"
@import UIKit;  // for UIImage

//#define JWSampleFileName @"trimmedMP3-45"
//#define JWSampleFileNameAndExtension @"trimmedMP3-45.m4a"

//#define JWSampleFileName @"trimmedMP3-45"
//#define JWSampleFileNameAndExtension @"trimmedMP3-45.m4a"

//#define JWSampleFileName @"AminorBackingtrackTrimmedMP3-45"
//#define JWSampleFileNameAndExtension @"AminorBackingtrackTrimmedMP3-45.m4a"

#define JWSampleFileName @"TheKillersTrimmedMP3-30"
#define JWSampleFileNameAndExtension @"TheKillersTrimmedMP3-30.m4a"

@interface JWFileController () {
    dispatch_queue_t _imageRetrievalQueue;
    dispatch_queue_t _fileInfoRetrievalQueue;
}

@property (nonatomic,readwrite) NSArray *downloadedJamTrackFiles;
@property (nonatomic,readwrite) NSArray *jamTrackFiles;
@property (nonatomic,readwrite) NSArray *mp3Files;
@property (nonatomic,readwrite) NSArray *recordingFiles;
@property (nonatomic,readwrite) NSArray *sourceFiles;
@property (nonatomic,readwrite) NSArray *trimmedFiles;

@property (nonatomic) NSMutableArray *mp3filesFilesData;

@property (nonatomic) NSMutableArray *filesData;   // holds filesystem sections
@property (nonatomic) NSMutableArray *recordingsFilesData;
@property (nonatomic) NSMutableArray *clipsFilesData;
@property (nonatomic) NSMutableArray *finalsFilesData;
@property (nonatomic) NSMutableArray *trimmedFilesData;

//@property (nonatomic) NSMutableArray *sourceFilesData;

@end


@implementation JWFileController

+ (JWFileController *)sharedInstance
{
    static dispatch_once_t singleton_queue;
    static JWFileController *sharedController = nil;
    
    dispatch_once(&singleton_queue, ^{
        sharedController = [[JWFileController alloc] init];
    });
    
    return sharedController;
}

#pragma mark - Lifecycle
-(instancetype)init {
    if (self = [super init]) {
        [self initdb];
        if (_imageRetrievalQueue == nil) {
            _imageRetrievalQueue =
            dispatch_queue_create("imageFileProcessingYoutubeMP3",
                                  dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_CONCURRENT,QOS_CLASS_UTILITY, 0));
        }
        
        if (_fileInfoRetrievalQueue == nil) {
            _fileInfoRetrievalQueue =
            dispatch_queue_create("imageProcessingSourceAudio",
                                  dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_CONCURRENT,QOS_CLASS_UTILITY, 0));
        }

    }
    return self;
}


-(NSArray *)trimmedFiles {
    return [NSArray arrayWithArray:_trimmedFilesData];
}

//-(NSArray *)downloadedJamTrackFiles {
//}
//-(NSArray *)jamTrackFiles {
//}
//-(NSArray *)mp3Files {
//}
//-(NSArray *)recordingFiles {
//}

-(void)saveMeta {
    [self saveMetaData];
}

-(void)update {
    
    [self loadAllData];
    NSLog(@"%s %ld %ld, %ld, %ld\ndownl %ld\njamtrack %ld",__func__,
          [_filesData count],
          [_recordingsFilesData count],
          [_clipsFilesData count],
          [_finalsFilesData count],
          [_downloadedJamTrackFiles count],
          [_jamTrackFiles count]
          );
}

-(void)reload {
    [self update];
}


-(void)readFsData {
    [self loadFilesystemData];
}


#pragma mark -
-(NSString*)documentsDirectoryPath {
    NSString *result = nil;
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    result = [searchPaths objectAtIndex:0];
    return result;
}

-(NSString*)sourceAudioFilesDirectoryPath {
    NSString *result = [[self documentsDirectoryPath] stringByAppendingPathComponent:@"Source"];
    return result;
}

-(NSString*)jamTracksDirectoryPath {
    NSString *result = [[self documentsDirectoryPath] stringByAppendingPathComponent:@"JamTracks"];
    return result;
}

-(NSString*)jamTracksDownloadedDirectoryPath {
    NSString *result = [[self jamTracksDirectoryPath] stringByAppendingPathComponent:@"Downloaded"];
    return result;
}

-(NSURL *)documentsFileURLWithFileName:(NSString*)name {
    NSURL *result;
    NSString *thisfName = name;//@"mp3file";
    NSString *thisName = thisfName; //[NSString stringWithFormat:@"%@_%@.mp3",thisfName,dbkey?dbkey:@""];
    NSMutableString *fname = [[self documentsDirectoryPath] mutableCopy];
    [fname appendFormat:@"/%@",thisName];
    result = [NSURL fileURLWithPath:fname];
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
    NSURL *absURL = [url absoluteURL];
//    NSLog(@"absURL = %@", absURL);
    result = url;
    return result;
}

/*
 
 ./
 Documents/Source
 Documents/JamTracks
 Documents/JamTracks/Downloaded
 
 In Documents the root directory contains files generated by the app
 JamTracks folder contains JamTracks audio files
 The Downloaded folder JamTracks folder contains JamTracks audio files
 
 */

- (void)initdb {
    
    // CREATE DIRECTORY STRUCTURE AND COPY RESOURCES
    NSString *jtDirectory = [[self documentsDirectoryPath] stringByAppendingPathComponent:@"JamTracks"];
    BOOL isDir = NO;
    if ([[NSFileManager defaultManager] fileExistsAtPath:jtDirectory isDirectory:&isDir]){
        // Exists
    } else {
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:jtDirectory withIntermediateDirectories:YES attributes:nil
                                                                                                 error:&error];
        isDir = YES;
    }
    
    if (isDir) {
        jtDirectory = [jtDirectory stringByAppendingPathComponent:@"Downloaded"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:jtDirectory isDirectory:&isDir]){
            // Exists
        } else {
            NSError *error;
            [[NSFileManager defaultManager] createDirectoryAtPath:jtDirectory withIntermediateDirectories:YES attributes:nil
                                                            error:&error];
            isDir = YES;
        }
    }
    
    // SOURCE DIRECTORY
    NSString *sourceDirectory = [self sourceAudioFilesDirectoryPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:sourceDirectory isDirectory:&isDir]){
        // Exists
    } else {
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:sourceDirectory withIntermediateDirectories:YES attributes:nil
                                                        error:&error];
        isDir = YES;
    }
    
    [self copyResources];
}


-(NSURL *)fileURLWithFileName:(NSString*)name {
    NSURL *result;
    NSString *thisfName = name;//@"mp3file";
    NSString *thisName = thisfName; //[NSString stringWithFormat:@"%@_%@.mp3",thisfName,dbkey?dbkey:@""];
    NSMutableString *fname = [[self documentsDirectoryPath] mutableCopy];
    [fname appendFormat:@"/%@",thisName];
    result = [NSURL fileURLWithPath:fname];
    return result;
}

- (void)copyResources {
    NSLog(@"%@",[self documentsDirectoryPath]);
    // Copy resoureces
    NSError *error;
    [[NSFileManager defaultManager]
     copyItemAtURL:[[NSBundle mainBundle] URLForResource:JWSampleFileName withExtension:@".m4a"]
     toURL:[self fileURLWithFileName:JWSampleFileNameAndExtension] error:&error];
    
    [[NSFileManager defaultManager]
     copyItemAtURL:[[NSBundle mainBundle] URLForResource:@"clipRecording_aminor1" withExtension:@".caf"]
     toURL:[self fileURLWithFileName:@"clipRecording_aminor1.caf"] error:&error];
    
    [[NSFileManager defaultManager]
     copyItemAtURL:[[NSBundle mainBundle] URLForResource:@"clipRecording_killers1" withExtension:@".caf"]
     toURL:[self fileURLWithFileName:@"clipRecording_killers1.caf"] error:&error];
    
    [[NSFileManager defaultManager]
     copyItemAtURL:[[NSBundle mainBundle] URLForResource:@"clipRecording_killers2" withExtension:@".caf"]
     toURL:[self fileURLWithFileName:@"clipRecording_killers2.caf"] error:&error];
}


- (void)loadAllData {
    
    [self loadFilesystemData];
    [self loadMetaData];
    
}


- (void)loadFilesystemData {

    _filesData = [NSMutableArray new];
    _mp3filesFilesData = [NSMutableArray new];
    _recordingsFilesData = [NSMutableArray new];
    _clipsFilesData = [NSMutableArray new];
    _finalsFilesData = [NSMutableArray new];
    _trimmedFilesData = [NSMutableArray new];

//    _sourceFilesData = [NSMutableArray new];
    
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
        NSError *error;
        NSDictionary *info = [fm attributesOfItemAtPath:[fileURL path] error:&error];
        
        if (info[NSFileType] == NSFileTypeDirectory) {
            // SKIP Directory
        } else {
            NSString *fname = [fileURL lastPathComponent];
            NSDictionary *recordInfo = @{@"furl":fileURL,@"fsize":info[NSFileSize]};
            
            if ([fname hasPrefix:@"mp3file_"])
            {
                [_mp3filesFilesData addObject:recordInfo];
            }
            else if ([fname hasPrefix:@"recording_"] || [fname hasPrefix:@"avrec_"])
            {
                [_recordingsFilesData addObject:recordInfo];
            }
            else if ([fname hasPrefix:@"clip"])
            {
                [_clipsFilesData addObject:recordInfo];
            }
            else if ([fname hasPrefix:@"trimmed"])
            {
                [_trimmedFilesData addObject:recordInfo];
            }
            else if ([fname hasPrefix:@"final"])
            {
                [_finalsFilesData addObject:recordInfo];
            }
            
        }
    }
    

//    else if ([fname hasPrefix:@"trimmed"] || [fname hasPrefix:@"fiveSeconds"] )
//    {
//        [_trimmedFilesData addObject:recordInfo];
//    }

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
    
    // SOURCE Directory
    
    NSMutableArray *sourceFiles = [NSMutableArray new];

    dirEnum = [fm enumeratorAtURL:[NSURL fileURLWithPath:[self sourceAudioFilesDirectoryPath]]
       includingPropertiesForKeys:@[NSURLCreationDateKey,NSURLContentAccessDateKey]
                          options:NSDirectoryEnumerationSkipsSubdirectoryDescendants
                     errorHandler:^BOOL(NSURL *url,NSError *error){
                              return YES;
                          }];
    
    while ((fileURL = [dirEnum nextObject])) {
        NSError *error;
        NSDictionary *info = [fm attributesOfItemAtPath:[fileURL path] error:&error];
        NSString *fname = [fileURL lastPathComponent];
        if ([fname isEqualToString:@".DS_Store"]) {
            // SKIP
        } else {
            NSDictionary *recordInfo = @{@"furl":fileURL,@"fsize":info[NSFileSize]};
            [sourceFiles addObject:recordInfo];
        }
    }
    
    _sourceFiles = [NSArray arrayWithArray:sourceFiles];

    
    // JAMTRACKS DOWNLOAD Directory
    NSMutableArray *downloadedFiles = [NSMutableArray new];
    dirEnum = [fm enumeratorAtURL: [NSURL fileURLWithPath:[self jamTracksDownloadedDirectoryPath]]
       includingPropertiesForKeys:@[NSURLCreationDateKey,NSURLContentAccessDateKey]
                          options:NSDirectoryEnumerationSkipsSubdirectoryDescendants
                     errorHandler:^BOOL(NSURL *url,NSError *error){
                         return YES;
                     }];
    
    while ((fileURL = [dirEnum nextObject])) {
        NSError *error;
        NSDictionary *info = [fm attributesOfItemAtPath:[fileURL path] error:&error];
        NSString *fname = [fileURL lastPathComponent];
        if ([fname isEqualToString:@".DS_Store"]) {
            // SKIP
        } else {
            NSDictionary *recordInfo = @{@"furl":fileURL,@"fsize":info[NSFileSize]};
            [downloadedFiles addObject:recordInfo];
        }
    }
    
    _downloadedJamTrackFiles = [NSArray arrayWithArray:downloadedFiles];


    // JAMTRACKS Directory
    NSMutableArray *jamTrackFiles = [NSMutableArray new];
    dirEnum = [fm enumeratorAtURL:[NSURL fileURLWithPath:[self jamTracksDirectoryPath]]
       includingPropertiesForKeys:@[NSURLCreationDateKey,NSURLContentAccessDateKey]
                options:NSDirectoryEnumerationSkipsSubdirectoryDescendants
           errorHandler:^BOOL(NSURL *url,NSError *error){
        return YES;
    }];
    
    while ((fileURL = [dirEnum nextObject])) {
        NSError *error;
        NSString *fname = [fileURL lastPathComponent];
        NSDictionary *info = [fm attributesOfItemAtPath:[fileURL path] error:&error];
        if (info[NSFileType] == NSFileTypeDirectory  || [fname isEqualToString:@".DS_Store"]) {
            // SKIP Directory
        } else {
            NSDictionary *recordInfo = @{@"furl":fileURL,@"fsize":info[NSFileSize]};
            [jamTrackFiles addObject:recordInfo];
        }
    }
    
    _jamTrackFiles = [NSArray arrayWithArray:jamTrackFiles];
    


    [_filesData addObject:_finalsFilesData];
    [_filesData addObject:_mp3filesFilesData];
    [_filesData addObject:_recordingsFilesData];
    [_filesData addObject:[sortedClipsArray mutableCopy]];
}


- (void)loadMetaData {
    [self readMetaData];
    [self readUserOrderedList];
}


#pragma mark -

-(NSArray*)trimFileKeysForCacheItem:(NSString*)key {
    
    NSMutableArray *fileItems = [NSMutableArray new];
    
    id mp3DataRecord = _mp3FilesInfo[key];
    if (mp3DataRecord) {
        id trimmedFilesValue = mp3DataRecord[@"trimmedfilekeys"];
        if (trimmedFilesValue){
            
            for (id trimKey in trimmedFilesValue) {
                NSString *fname = [NSString stringWithFormat:@"trimmedMP3_%@.m4a",trimKey ? trimKey : @""];
                NSURL *fileURL = [self fileURLWithFileName:fname];
                [fileItems addObject:fileURL];
            }
        }
    }
    
    return [NSArray arrayWithArray:fileItems];
}

-(void)imageForCacheItem:(NSString*)key onCompletion:(JWFileImageCompletionHandler)completion {
    
    id mp3DataRecord = _mp3FilesInfo[key];
    if (mp3DataRecord) {
        NSString *imageURLStr = mp3DataRecord[JWDbKeyYoutubeThumbnailMedium];
        if (imageURLStr) {
            NSURL *imageURL = [NSURL URLWithString:imageURLStr];
            dispatch_async(_imageRetrievalQueue, ^{
                UIImage* youtubeImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:imageURL]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completion) {
                        completion(youtubeImage);
                    }
                });
            });
        } else {
            if (completion)
                completion(nil);
        }
    } else {
        if (completion)
            completion(nil);
    }
}

-(void)bestImageForCacheItem:(NSString*)key onCompletion:(JWFileImageCompletionHandler)completion {
    
    id mp3DataRecord = _mp3FilesInfo[key];
    if (mp3DataRecord) {
        NSURL *imageURL = [self bestImageURLForMP3Record:mp3DataRecord];
        if (imageURL) {
            dispatch_async(_imageRetrievalQueue, ^{
                UIImage* youtubeImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:imageURL]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completion) {
                        completion(youtubeImage);
                    }
                });
            });
        } else {
            if (completion)
                completion(nil);
        }
    } else {
        if (completion)
            completion(nil);
    }
}

-(NSURL*)imageURLForCacheItem:(NSString*)key {
    NSURL *result = nil;
    id mp3DataRecord = _mp3FilesInfo[key];
    if (mp3DataRecord) {
        
        NSString *imageURLStr = mp3DataRecord[JWDbKeyYoutubeThumbnailMedium];
        if (imageURLStr) {
            result  = [NSURL URLWithString:imageURLStr];
        }
    }
    return result;
}

-(NSURL*)bestImageURLForMP3Record:(NSDictionary*)mp3DataRecord {
    if (mp3DataRecord == nil) {
        return nil;
    }
    id urlStr;
    //    urlStr = mp3DataRecord[JWDbKeyYoutubeThumbnailMaxres];
    //    if (!urlStr)
    urlStr = mp3DataRecord[JWDbKeyYoutubeThumbnailHigh];
    if (!urlStr)
        urlStr = mp3DataRecord[JWDbKeyYoutubeThumbnailMedium];
    if (!urlStr)
        urlStr = mp3DataRecord[JWDbKeyYoutubeThumbnailDefault];
    
    NSURL *imageURL = urlStr ? [NSURL URLWithString:urlStr] : nil;
    
    NSLog(@"%s %@",__func__,[imageURL absoluteString]);
    return imageURL;
}

-(NSString*)videoTitleForCacheItem:(NSString*)key {
    NSString *result = nil;
    id mp3DataRecord = _mp3FilesInfo[key];
    if (mp3DataRecord) {
        
        id ytData = mp3DataRecord[JWDbKeyYouTubeData];
        if (ytData) {
            result = ytData[JWDbKeyYouTubeTitle];
        }
    }
    return result;
}


-(NSURL *)fileURLForCacheItem:(NSString*)dbkey {
    NSURL *result;
    NSString *thisfName = @"mp3file";
    NSString *thisName = [NSString stringWithFormat:@"%@_%@.mp3",thisfName,dbkey?dbkey:@""];
    
    NSMutableString *fname = [[self documentsDirectoryPath] mutableCopy];
    [fname appendFormat:@"/%@",thisName];
    
    result = [NSURL fileURLWithPath:fname];
    
    return result;
}



-(NSNumber*)fileSizeForCacheItem:(NSString*)dbKey {

        NSNumber *result;
//        @synchronized(_mp3filesFilesData){
//            result = _mp3filesFilesData[dbKey][@"fsize"];
//        }

//NSString *fileSizeStr; // = [self fileSizeStr:fileSzNumber];
//if (fileSizeStr == nil)
//fileSizeStr = @"";


    return result;
}
-(NSString*)fileSizeStrForCacheItem:(NSString*)dbKey {
        
        NSString *result;
//        @synchronized(_mp3filesFilesData){
//            fileSzNumber = _mp3filesFilesData[dbKey][@"fsize"];
//        }
    
        NSString *fileSizeStr; // = [self fileSizeStr:fileSzNumber];
        if (fileSizeStr == nil)
            fileSizeStr = @"";
    return result;

}

-(NSString *)fileSizeStr:(NSNumber*) fileSzNumber{
    NSString *result = nil;
    
    NSUInteger byteSize = [fileSzNumber unsignedLongLongValue];
    if (byteSize > (1024 * 1024))
        result = [NSString stringWithFormat:@"%.2f mb",byteSize/(1024.0f * 1024.0f)];
    else if (byteSize > 1024)
        result = [NSString stringWithFormat:@"%.2f kb",byteSize/1024.0f];
    else
        result = [NSString stringWithFormat:@"%ld bytes",byteSize];
    
    return result;
}


#pragma mark - save retrieve metadata

-(void)saveMetaData {
    [_linksDirector writeToURL:
     [NSURL fileURLWithPath:[[self documentsDirectoryPath] stringByAppendingPathComponent:(NSString*)JWDbKeyLinksDirectoryFileName]] atomically:YES];
    [_mp3FilesInfo writeToURL:[NSURL fileURLWithPath:[[self documentsDirectoryPath] stringByAppendingPathComponent:(NSString*)JWDbKeyMP3InfoFileName]] atomically:YES];
    
    NSLog(@"%sLINKSCOUNT[%ld] MP3INFOCOUNT[%ld]",__func__,[_linksDirector count],[_mp3FilesInfo count]);
    //    NSLog(@"\n%s\nLINKS\n%@\nMP3INFO\n%@",__func__,[_linksDirector description],[_mp3FilesInfo description]);
}
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
    
    
    NSLog(@"%sLINKSCOUNT[%ld] MP3INFOCOUNT[%ld]",__func__,[_linksDirector count],[_mp3FilesInfo count]);
    //    NSLog(@"\n%s\nLINKS\n%@\nMP3INFO\n%@",__func__,[_linksDirector description],[_mp3FilesInfo description]);
}


-(void)saveDescriptions {
    [_mp3FilesDescriptions writeToURL:[NSURL fileURLWithPath:[[self documentsDirectoryPath] stringByAppendingPathComponent:@"mp3descriptions.dat"]] atomically:YES];
    NSLog(@"%sMP3DESCRIPCOUNT[%ld]",__func__,[_mp3FilesDescriptions count]);
}
-(void)readDescriptions {
    _mp3FilesDescriptions = [[NSMutableDictionary alloc] initWithContentsOfURL:
                             [NSURL fileURLWithPath:[[self documentsDirectoryPath] stringByAppendingPathComponent:@"mp3descriptions.dat"]]];
    NSLog(@"%sMP3DESCRIPCOUNT[%ld]",__func__,[_mp3FilesDescriptions count]);
}


-(void)saveUserOrderedList {
    [_userOrderList writeToURL:
     [NSURL fileURLWithPath:[[self documentsDirectoryPath] stringByAppendingPathComponent:(NSString*)JWDbKeyUserOrderedListFileName]]
                    atomically:YES];
    
    NSLog(@"%sUSERLISTCOUNT[%ld] MP3DESCRIPCOUNT[%ld]",__func__,[_userOrderList count],[_mp3FilesDescriptions count]);
    
    //    NSLog(@"%sUSERLISTCOUNT[%ld]",__func__,[_userOrderList count]);
    //    NSLog(@"\n%s\nUSERLIST\n%@",__func__,[_userOrderList description]);
}
-(void)readUserOrderedList {
    _userOrderList = [[NSMutableArray alloc] initWithContentsOfURL:
                      [NSURL fileURLWithPath:[[self documentsDirectoryPath] stringByAppendingPathComponent:(NSString*)JWDbKeyUserOrderedListFileName]]];
    NSLog(@"%sUSERLISTCOUNT[%ld]",__func__,[_userOrderList count]);
    //    NSLog(@"\n%s\nUSERLIST\n%@",__func__,[_userOrderList description]);
}





@end
