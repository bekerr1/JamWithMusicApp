//
//  JWJamSessionCoordinator.m
//  JamWDev
//
//  Created by brendan kerr on 5/13/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

/*
 
This class will handle all of the jam session code that is inside the master view controller.
 This code will coordinate the flow of jam track objects from the different tables and public domain
 to the record jam section and any other objects that handle jam sessions.
 
*/
#import "JWJamSessionCoordinator.h"
#import "JWFileManager.h"

@interface JWJamSessionCoordinator()

@property (nonatomic) NSArray *data;

@end

@implementation JWJamSessionCoordinator


-(instancetype)initWithDataSet:(NSArray *)data {
    
    if (self = [super init]) {
        self.data = data;
    }
    return self;
}


#pragma mark TRACKS FROM TABLE VIEWS

-(id)jamTrackObjectAtIndexPath:(NSIndexPath*)indexPath fromSourceStructure:(NSArray *)source {
    
    id result = nil;
    if (indexPath.section < [source count]) {
        
        id objectSection = source[indexPath.section];
        NSArray *sessionObjects = objectSection[@"sessionset"];
        if (sessionObjects) {
            
            if (indexPath.row < [sessionObjects count]) {
                NSDictionary *object = sessionObjects[indexPath.row];
                result = object;
            }
        }
    }
    
    
    return result;
}


-(NSUInteger)countEmptyRecorderNodesForJamTrackWithKey:(NSString*)key atIndexPath:(NSIndexPath *)path fromSource:(NSArray *)source {
    
    NSUInteger result = 0;
    NSDictionary *object = [self jamTrackObjectAtIndexPath:path fromSourceStructure:source];
    
    id trackNodes = object[@"trackobjectset"];
    for (id trackNode in trackNodes) {
        
        id typeValue = trackNode[@"type"];
        if (typeValue) {
            JWMixerNodeTypes nodeType = [typeValue unsignedIntegerValue];
            if (nodeType == JWMixerNodeTypePlayerRecorder) {
                id fileURL = trackNode[@"fileURL"];
                if (fileURL == nil)
                    result++;
            }
        }
    }
    
    return result;
}


#pragma mark JAM TRACK CREATION

-(NSMutableDictionary*)newTrackNodeOfType:(JWAudioNodeType)mixNodeType andFileURL:(NSURL*)fileURL withAudioFileKey:(NSString *)key {
    
    NSMutableDictionary *result = nil;
    if (mixNodeType == JWAudioNodeTypePlayer) {
        result =
        [@{@"key":[[NSUUID UUID] UUIDString],
           @"title":@"player",
           @"starttime":@(0.0),
           @"date":[NSDate date],
           @"type":@(JWAudioNodeTypePlayer)
           } mutableCopy];
    } else if (mixNodeType == JWAudioNodeTypeRecorder) {
        result =
        [@{@"key":[[NSUUID UUID] UUIDString],
           @"title":@"recorder",
           @"starttime":@(0.0),
           @"date":[NSDate date],
           @"type":@(JWAudioNodeTypeRecorder)
           } mutableCopy];
    }
    
    if (fileURL)
        result[@"fileURL"] = fileURL;
    
    if (key)
        result[@"audiofilekey"] = key;
    
    
    return result;
}




-(NSMutableDictionary*)newJamTrackObjectWithFileURL:(NSURL*)fileURL audioFileKey:(NSString *)key {
    NSMutableDictionary *result = nil;
    
    
    id track1 = [self newTrackNodeOfType:JWAudioNodeTypePlayer andFileURL:fileURL withAudioFileKey:key];
    id track2 = [self newTrackNodeOfType:JWAudioNodeTypeRecorder andFileURL:nil withAudioFileKey:key];
    
    NSMutableArray *trackObjects = [@[track1, track2] mutableCopy];
    
    result =
    [@{@"key":[[NSUUID UUID] UUIDString],
       @"titletype":@"session",
       @"title":@"New Jam Session",
       @"trackobjectset":trackObjects,
       @"date":[NSDate date],
       } mutableCopy];
    return result;
}


-(NSMutableDictionary*)newJamTrackObjectWithRecorderFileURL:(NSURL*)fileURL {
    NSMutableDictionary *result = nil;
    
    id track = [self newTrackNodeOfType:JWAudioNodeTypeRecorder andFileURL:fileURL withAudioFileKey:nil];
    
    NSMutableArray *trackObjects = [@[track] mutableCopy];
    
    result =
    [@{@"key":[[NSUUID UUID] UUIDString],
       @"titletype":@"session",
       @"title":@"New Jam Session",
       @"duration":@(0.0),
       @"trackcount":@(1),
       @"trackobjectset":trackObjects,
       @"date":[NSDate date],
       } mutableCopy];
    return result;
}


-(NSMutableDictionary *)createFiveSecondPlayerNodeWithDirectory:(NSString *)fileString fromKey:(NSString*)dbKey {
    
    if (dbKey == nil) {
        NSLog(@"No Key To Create File String.");
        return nil;
    }
    NSURL *validURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/fiveSecondsMP3_%@.m4a",fileString, dbKey]];
    NSLog(@"Valid URL? %@", [validURL absoluteString]);
    NSFileManager *quickManager = [NSFileManager defaultManager];
    
    if (![quickManager fileExistsAtPath:[validURL path]]) {
        NSLog(@"No Valid URL To Create File String URL.");
        return nil;
    }
    
    
    NSMutableDictionary *fiveSecondNode =
    [@{
       @"title" : @"fivesecondnode",
       @"type" : @(JWAudioNodeTypeFiveSecondPlayer),
       @"volumevalue" : @(0.0),
       @"fileURLString" : [NSString stringWithFormat:@"%@/fiveSecondsMP3_%@.m4a",fileString, dbKey]
       } mutableCopy];
    
    return fiveSecondNode;
}




-(NSMutableArray *)newTestJamSession {
    
    NSMutableArray *result = nil;
    NSMutableArray *jamTracks = [NSMutableArray new];
    
    //TRACK1
    NSString *track1Key = [[NSUUID UUID] UUIDString];
    NSMutableDictionary *track1 = [self newTrackNodeOfType:JWAudioNodeTypePlayer andFileURL:[[JWFileManager defaultManager] testURL:@"killersMP3"] withAudioFileKey:track1Key];
    track1[@"title"] = @"player";
    track1[@"duration"] = @(45);
    NSMutableDictionary *track2 = [self newTrackNodeOfType:JWAudioNodeTypeRecorder andFileURL:[[JWFileManager defaultManager] testURL:@"killersrecording1"] withAudioFileKey:track1Key];
    track2[@"title"] = @"player";
    
    
    NSMutableArray *trackObjects = [@[track1, track2] mutableCopy];
    
    result =
    [@{@"key":[[NSUUID UUID] UUIDString],
       @"titletype":@"session",
       @"title":@"Killers Jam Session",
       @"author":@"Brendan Kerr",
       @"duration":@(0.45),
       @"trackcount":@(2),
       @"trackobjectset":trackObjects,
       @"date":[NSDate date],
       } mutableCopy];
    
    
    [jamTracks insertObject:result atIndex:0];
    
    return jamTracks;
    
    
}

/*
Jam Session Cell Data:
Title
Created By
Genre
Track Type
Number of Tracks Allowed
Key
Instrument
*/

-(NSMutableDictionary *)finalizeCreation:(NSMutableDictionary *)starter addOn:(NSMutableDictionary *)addTo {
    
    NSMutableDictionary *result = [NSMutableDictionary new];
    
    [result addEntriesFromDictionary:starter];
    [result addEntriesFromDictionary:addTo];
    
    return result;
}

//#define TESTING
#ifdef TESTING

-(NSMutableArray*)newJamTracks {
    NSMutableArray *result = nil;
    NSMutableArray *jamTracks = [NSMutableArray new];
    NSURL *fileURL;
    NSMutableDictionary *track1;
    NSMutableDictionary *track2;
    
    // JAMTRACK 1
    NSMutableDictionary *jamTrack1 = [self newJamTrackObject];
    jamTrack1[@"title"] = @"Brendans mix The killers";
    
    track1 = jamTrack1[@"trackobjectset"][0];
    fileURL = [self fileURLWithFileName:@"TheKillersTrimmedMP3-30.m4a" inPath:@[]];
    track1[@"fileURL"] = fileURL;
    
    track2 = jamTrack1[@"trackobjectset"][1];
    fileURL = [self fileURLWithFileName:@"clipRecording_killers1.caf" inPath:@[]];
    track2[@"fileURL"] = fileURL;
    
    
    // JAMTRACK 2
    NSMutableDictionary *jamTrack2 = [self newJamTrackObject];
    jamTrack2[@"title"] = @"Brendans mix Aminor1";
    
    track1 = jamTrack2[@"trackobjectset"][0];
    fileURL = [self fileURLWithFileName:@"AminorBackingtrackTrimmedMP3-45.m4a" inPath:@[]];
    track1[@"fileURL"] = fileURL;
    
    track2 = jamTrack2[@"trackobjectset"][1];
    fileURL = [self fileURLWithFileName:@"clipRecording_aminor1.caf" inPath:@[]];
    track2[@"fileURL"] = fileURL;
    
    
    [jamTracks insertObject:jamTrack2 atIndex:0];
    [jamTracks insertObject:jamTrack1 atIndex:0];
    
    result = jamTracks;
    
    return result;
}


-(NSMutableArray*)newProvidedJamTracks {
    NSMutableArray *result = nil;
    result =[@[
               [self newJamTrackObject],
               [self newJamTrackObject]
               ] mutableCopy];
    return result;
}



#endif





#pragma mark JAM TRACK LOOKUP


//Accounts for session set
-(id)jamTrackObjectWithKey:(NSString*)key fromSource:(NSArray *)source {
    
    id result;
    for (id objectSection in source) {
        
        id sessions = objectSection[@"sessionset"];
        for (id session in sessions) {
            
            id trackset = session[@"trackobjectset"];
            for (id track in trackset) {
                if ([key isEqualToString:track[@"key"]]) {
                    result = track;
                    break;
                }
                if (result)
                    break;
            }
            if (result)
                break;
        }
        if (result)
            break;
    }
    return result;
}

// returns a jamTrack that contains a tracknode that matches key
-(id)jamTrackObjectContainingNodeKey:(NSString*)key fromSource:(NSArray *)source {
    
    id result;
    for (id objectSection in source) {
        
        id jamTracks = objectSection[@"trackobjectset"];
        for (id jamTrack in jamTracks) {
            id trackNodes = jamTrack[@"trackobjectset"];
            for (id trackNode in trackNodes) {
                if ([key isEqualToString:trackNode[@"key"]]) {
                    result = jamTrack; // // jamtrack containing node key
                    break;
                }
            }
            if (result)
                break;
        }
        if (result)
            break;
    }
    
    return result;
}


// returns a trackNode
-(id)jamTrackNodeObjectForKey:(NSString*)key fromSource:(NSArray *)source {
    
    id result;
    for (id objectSection in source) {
        
        id jamTracks = objectSection[@"trackobjectset"];
        for (id jamTrack in jamTracks) {
            id trackNodes = jamTrack[@"trackobjectset"];
            for (id trackNode in trackNodes) {
                if ([key isEqualToString:trackNode[@"key"]]) {
                    result = trackNode; // jamtrack node
                    break;
                }
            }
            if (result)
                break;
        }
        if (result)
            break;
    }
    return result;
}


-(NSString*)preferredTitleForObject:(id)object {
    NSString *result;
    id userTitleValue = object[@"usertitle"];
    id titleValue = object[@"title"];
    
    if (userTitleValue) {
        result = userTitleValue;
    } else {
        if (titleValue)
            result = titleValue;
        else
            result = @"";
    }
    
    return result;
}


-(NSString *)durationOfFirstTrackFromSession:(NSDictionary *)session {
    
    NSString *result = nil;
    NSArray *trackSet = session[@"trackobjectset"];
    NSDictionary *firstTrack = trackSet[0];
    CGFloat duration = [firstTrack[@"duration"] doubleValue];
    NSInteger durationRoundedUp = (NSInteger)ceil(duration);
    
    if (duration < 10) {
        result = [NSString stringWithFormat:@":0%ld", (long)durationRoundedUp];
    } else if (duration < 60) {
        result = [NSString stringWithFormat:@":%ld", (long)durationRoundedUp];
    } else {
        result = [NSString stringWithFormat:@"1:00"];
    }
    return result;
}


-(NSMutableArray *)audioURLsForSession:(NSDictionary *)session {
    NSLog(@"%s", __func__);
    
    NSMutableArray *result = [NSMutableArray new];
    NSArray *tracks = session[@"trackobjectset"];
    
    for (NSDictionary *track in tracks) {
        
        NSURL *fileURL = track[@"fileURL"];
        if (fileURL) {
            NSLog(@"fileURL: %@", fileURL);
            [result addObject:fileURL];
        }
    }
    return result;
}


-(NSIndexPath*)indexPathOfJamTrackCacheItem:(NSString*)key fromSource:(id)source {
    NSUInteger sectionIndex = 0;
    NSUInteger index = 0;
    BOOL found = NO;
    
    for (id objectSection in source) {
        id sessionSetInSection = objectSection[@"sessionset"];
        index = 0; // new section
        for (id session in sessionSetInSection) {
            
            if ([key isEqualToString:session[@"key"]]) {
                found=YES;
                break;
            }
            index++;
        }
        if (found)
            break;
        
        sectionIndex++;
    }
    
    return [NSIndexPath indexPathForRow:index inSection:sectionIndex];
}





// return the section array of jamtracks that contain this jam track

//-(NSMutableArray*)jamTracksWithJamTrackKey:(NSString*)key {
//    
//    NSMutableArray * result;
//    NSIndexPath *itemIndexPath = [self indexPathOfJamTrackCacheItem:key];
//    
//    if (itemIndexPath) {
//        id objectSection = _homeControllerSections[itemIndexPath.section];
//        result = objectSection[@"trackobjectset"];
//    }
//    
//    return result;
//}

/*
 -(NSMutableDictionary*)newTrackObjectOfType:(JWMixerNodeTypes)mixNodeType {
 
 NSMutableDictionary *result = nil;
 if (mixNodeType == JWMixerNodeTypePlayer) {
 return [self newTrackObjectOfType:mixNodeType andFileURL:[self fileURLWithFileName:JWSampleFileNameAndExtension inPath:nil] withAudioFileKey:nil];
 
 } else if (mixNodeType == JWMixerNodeTypePlayerRecorder) {
 return [self newTrackObjectOfType:mixNodeType andFileURL:nil withAudioFileKey:nil];
 }
 return result;
 }
 
 -(NSMutableDictionary*)newTrackObject {
 NSMutableDictionary *result = nil;
 NSURL *fileURL = [self fileURLWithFileName:JWSampleFileNameAndExtension inPath:nil];
 result =
 [@{@"key":[[NSUUID UUID] UUIDString],
 @"title":@"track",
 @"starttime":@(0.0),
 @"date":[NSDate date],
 @"fileURL":fileURL,
 @"type":@(JWMixerNodeTypePlayer)
 } mutableCopy];
 
 return result;
 }
 
 
 -(NSMutableArray*)newTrackObjectSet {
 NSMutableArray *result = nil;
 NSURL *fileURL = [self fileURLWithFileName:JWSampleFileNameAndExtension inPath:nil];
 
 NSMutableDictionary * fileReference =
 [@{@"duration":@(0),
 @"startinset":@(0.0),
 @"endinset":@(0.0),
 } mutableCopy];
 result =[@[
 [@{@"key":[[NSUUID UUID] UUIDString],
 @"title":@"track",
 @"starttime":@(0.0),
 @"referencefile": fileReference,
 @"date":[NSDate date],
 @"fileURL":fileURL,
 @"type":@(JWMixerNodeTypePlayer)
 } mutableCopy],
 [@{@"key":[[NSUUID UUID] UUIDString],
 @"title":@"track",
 @"starttime":@(0.0),
 @"date":[NSDate date],
 @"type":@(JWMixerNodeTypePlayerRecorder)
 } mutableCopy]
 ] mutableCopy];
 
 return result;
 }
 
 -(NSMutableDictionary*)newJamTrackObject {
 NSMutableDictionary *result = nil;
 
 id track1 = [self newTrackObjectOfType:JWMixerNodeTypePlayer];
 id track2 = [self newTrackObjectOfType:JWMixerNodeTypePlayerRecorder];
 
 NSMutableArray *trackObjects = [@[track1, track2] mutableCopy];
 
 result =
 [@{@"key":[[NSUUID UUID] UUIDString],
 @"titletype":@"jamtrack",
 @"title":@"jam Track",
 @"trackobjectset":trackObjects,
 @"date":[NSDate date],
 } mutableCopy];
 return result;
 }
 
 
 */
//-(NSMutableArray*)newDownloadedJamTracks {
//
//    NSMutableArray *result = [NSMutableArray new];
//    for (id fileInfo in [[JWFileController sharedInstance] downloadedJamTrackFiles]) {
//        NSLog(@"%s %@",__func__,[fileInfo[@"furl"] lastPathComponent]);
//
//        NSURL *fileURL = [self fileURLWithFileFlatFileURL:fileInfo[@"furl"]];
//
//        //TODO: not sure if the key parameter is needed here
//        [result addObject:[self newJamTrackObjectWithFileURL:fileURL audioFileKey:nil]];
//    }
//
//    return result;
//}
//-(id)jamTrackObjectWithKey:(NSString*)key fromSource:(NSArray *)source {
//
//    id result;
//    for (id objectSection in source) {
//
//        id jamTracks = objectSection[@"trackobjectset"];
//        for (id jamTrack in jamTracks) {
//            if ([key isEqualToString:jamTrack[@"key"]]) {
//                result = jamTrack;
//                break;
//            }
//        }
//        if (result)
//            break;
//    }
//    return result;
//}




@end
