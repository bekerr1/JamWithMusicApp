//
//  JWCurrentWorkItem.h
//  JamWIthT
//
//  Created by JOSEPH KERR on 9/29/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum AudioOrigins {
    YouTubeOrigin = 1,
    JamSiteOrigin,
    LooperOrigin,
    UserRecordedOrigin
} AudioOrigin;


@interface JWCurrentWorkItem : NSObject

+ (JWCurrentWorkItem *)sharedInstance;

@property (nonatomic) NSURL *currentAudioFileURL;
@property (nonatomic) NSString* currentAudioTitle;
@property (nonatomic) AudioOrigin currentAudioOrigin;
@property (nonatomic) NSUInteger currentAmpImageIndex;

@property (nonatomic) NSURL *currentTrimmedAudioFileURL;
@property (nonatomic) NSURL *jamSiteOriginAudioFileURL;
@property (nonatomic) NSMutableArray *looperOriginAudioFileURLs;  // array of NSURLs
@property (nonatomic) NSMutableArray *userRecordedOriginAudioFileURLs;  // array of NSURLs

@property (nonatomic) NSDate *timeStamp;

@end




