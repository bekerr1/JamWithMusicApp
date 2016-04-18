//
//  JWMenuTabBarController.m
//  JamWDev
//
//  Created by brendan kerr on 4/18/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

#import "JWMenuTabBarController.h"
#import "JWMixNodes.h"

@implementation JWMenuTabBarController




#pragma mark - TRACK OBJECT CREATION

/*
When you want a jam track object with a player that has valid url and an empty recorder
Most likely should be called after an audio file is clipped or audio is downloaded
 */
-(NSMutableDictionary*)newCompleteJamTrackObjectWithFileURL:(NSURL*)fileURL audioFileKey:(NSString *)key {
    NSMutableDictionary *result = nil;
    
    
    id track1 = [self newTrackObjectOfType:JWAudioNodeTypePlayer andFileURL:fileURL withAudioFileKey:key];
    id track2 = [self newTrackObjectOfType:JWAudioNodeTypeRecorder];
    
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


-(NSMutableDictionary*)newTrackObjectOfType:(JWAudioNodeType)audioNodeType andFileURL:(NSURL*)fileURL withAudioFileKey:(NSString *)key {
    
    NSMutableDictionary *result = nil;
    if (audioNodeType == JWAudioNodeTypePlayer) {
        result =
        [@{@"key":[[NSUUID UUID] UUIDString],
           @"starttime":@(0.0),
           @"date":[NSDate date],
           @"type":@(JWAudioNodeTypePlayer)
           } mutableCopy];
        
    } else if (audioNodeType == JWAudioNodeTypeRecorder) {
        result =
        [@{@"key":[[NSUUID UUID] UUIDString],
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



//Trying to deal with just valid fileURL audio or empty recorder nodes, no samples
-(NSMutableDictionary*)newTrackObjectOfType:(JWAudioNodeType)audioNodeType {
    
    NSMutableDictionary *result = nil;
    if (audioNodeType == JWAudioNodeTypePlayer) {
        //return [self newTrackObjectOfType:audioNodeType andFileURL:[self fileURLWithFileName:JWSampleFileNameAndExtension inPath:nil] withAudioFileKey:nil];
        
    } else if (audioNodeType == JWAudioNodeTypeRecorder) {
        return [self newTrackObjectOfType:audioNodeType andFileURL:nil withAudioFileKey:nil];
    }
    return result;
}






@end
