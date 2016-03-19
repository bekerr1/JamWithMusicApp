//
//  JWYouTubeVideoData.h
//  JamWIthT
//
//  co-created by joe and brendan kerr on 10/18/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^JWYouTubeVideoDataCompletionHandler)(void (^)(NSArray* videoData));

@interface JWYouTubeVideoData : NSObject

-(id)initWithVideoId:(NSString*)youTubeVideoId;
-(void)getVideoDataOnCompletion:(void (^)(NSArray* videoData))completion;
@end
