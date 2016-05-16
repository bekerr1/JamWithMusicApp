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
#import "JWMixNodes.h"
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
        
        BOOL isTrackItem = YES;;
        NSUInteger virtualRow = indexPath.row;
        
        //shouldnt be any base rows in the final table
//        NSUInteger count = [self baseRowsForSection:indexPath.section];
//        if (indexPath.row < count) {
//            isTrackItem = NO; // baserow
//        } else {
//            virtualRow -= count;
//        }
        
        if (isTrackItem) {
            // IS  ATRACK CELL not a controll cell index 0 AUDIOFILES and SEARCH
            
            id objectSection = source[indexPath.section];
            id trackObjects = objectSection[@"trackobjectset"];
            if (trackObjects) {
                NSArray *objectCollection = trackObjects;
                NSMutableDictionary *object = objectCollection[virtualRow];
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
       @"titletype":@"jamtrack",
       @"title":@"jam Track",
       @"trackobjectset":trackObjects,
       @"date":[NSDate date],
       } mutableCopy];
    return result;
}


-(NSMutableDictionary*)newJamTrackObjectWithRecorderFileURL:(NSURL*)fileURL {
    NSMutableDictionary *result = nil;
    
    id track = [self newTrackNodeOfType:JWAudioNodeTypeRecorder andFileURL:nil withAudioFileKey:nil];
    
    NSMutableArray *trackObjects = [@[track] mutableCopy];
    
    result =
    [@{@"key":[[NSUUID UUID] UUIDString],
       @"titletype":@"jamtrack",
       @"title":@"jam Track",
       @"trackobjectset":trackObjects,
       @"date":[NSDate date],
       } mutableCopy];
    return result;
}




-(NSMutableArray *)newTestJamSession {
    
    NSMutableArray *result = nil;
    NSMutableArray *jamTracks = [NSMutableArray new];
    
    //TRACK1
    NSString *track1Key = [[NSUUID UUID] UUIDString];
    NSMutableDictionary *track1 = [self newTrackNodeOfType:JWAudioNodeTypePlayer andFileURL:[[JWFileManager defaultManager] testURL:@"killersMP3"] withAudioFileKey:track1Key];
    track1[@"title"] = @"player";
    NSMutableDictionary *track2 = [self newTrackNodeOfType:JWAudioNodeTypeRecorder andFileURL:[[JWFileManager defaultManager] testURL:@"killersrecording1"] withAudioFileKey:track1Key];
    track2[@"title"] = @"player";
    
    
    NSMutableArray *trackObjects = [@[track1, track2] mutableCopy];
    
    result =
    [@{@"key":[[NSUUID UUID] UUIDString],
       @"titletype":@"session",
       @"title":@"Jam Session",
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


#pragma mark JAM TRACK LOOKUP

-(id)jamTrackObjectWithKey:(NSString*)key fromSource:(NSArray *)source {
    
    id result;
    for (id objectSection in source) {
        
        id jamTracks = objectSection[@"trackobjectset"];
        for (id jamTrack in jamTracks) {
            if ([key isEqualToString:jamTrack[@"key"]]) {
                result = jamTrack;
                break;
            }
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



@end
