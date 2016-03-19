//
//  JWYouTubeSearchTypingData.h
//  JamWIthT
//
//  co-created by joe and brendan kerr on 10/19/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JWYouTubeSearchTypingData : NSObject

-(void)getSearchKeywordDetailsWithString:(NSString*)searchStr
                               newSearch:(BOOL)newSearch
                            onCompletion:(void (^)(NSMutableArray* channelData,NSString *searchStr))completion;

-(void)initWebDataKeyWithSearchString:(NSString *)searchQuery newSearch:(BOOL)newSearch;

@end
