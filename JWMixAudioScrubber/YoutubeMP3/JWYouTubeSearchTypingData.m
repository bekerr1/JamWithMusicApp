//
//  JWYouTubeSearchTypingData.m
//  JamWIthT
//
//  Created by JOSEPH KERR on 10/19/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//


/*
This class uses the YouTube API to search for videos that match certian criteria.  Basically all this class does is perform a
HTTP GET request on the googleapis/youtube URL and once the request is complete and an HTTP Response of 200 is achieved
(success), a completion block is called and the JSON style data that is recieved is placed in an array of dictionaries.

*/

#import "JWYouTubeSearchTypingData.h"


@interface JWYouTubeSearchTypingData() {
    id _nextPageToken;
}
@property (nonatomic) NSString* apiKey;
@property (nonatomic) NSString* searchString;
@property (nonatomic) NSArray* desiredChannelsArray;
@property (nonatomic) NSInteger channelIndex;
@property (nonatomic) NSMutableArray* searchResults;
@property (nonatomic) NSMutableDictionary* channelData;
@property (nonatomic) NSUInteger totalResults;
@end


@implementation JWYouTubeSearchTypingData

-(NSMutableArray *)searchResults {
    if (! _searchResults) {
        _searchResults = [NSMutableArray new];
    }
    return _searchResults;
}


-(void)initWebDataKeyWithSearchString:(NSString *)searchQuery newSearch:(BOOL)newSearch {
    self.apiKey = [NSString stringWithFormat:@"AIzaSyDZX_Y5M0XIp69bPqOwM0fezYpSwQ2oUdg"];
    self.searchString = searchQuery;
    if (newSearch) {
        _totalResults = 0;
        [_searchResults removeAllObjects];
        _nextPageToken = nil;
    }
    
}

-(void)performGetRequestTo:(NSURL *)targetURL completionHandler:(void (^)(NSData * data, NSURLResponse* response, NSError* error))completion {
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:targetURL];
    request.HTTPMethod = @"GET";
    
    NSURLSessionConfiguration* defualtSession = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession* session = [NSURLSession sessionWithConfiguration:defualtSession];
    NSURLSessionDataTask* task = [session dataTaskWithRequest:request completionHandler:^(NSData* data, NSURLResponse* response, NSError* error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSHTTPURLResponse* HTTPcode = (NSHTTPURLResponse*) response;
            NSLog(@"HTTP Status Code = %ld", (long)HTTPcode.statusCode);
            completion(data, response, error);
        });
    }];
    
    [task resume];
}


// Here, we pass the raw searchstring not the modified one so we can give it back on completion to identify if it
// is part of the current search
// Before while typing A B C      a search for [A] [AB] [ABC] get initiated and return 15 results
// a search already commenced may be stale by the time of reaponse

-(void)getSearchKeywordDetailsWithString:(NSString*)searchStr newSearch:(BOOL)newSearch onCompletion:(void (^)(NSMutableArray* channelData,NSString* searchStr))completion{
    
    NSString* urlString;
    
    NSLog(@"_nextPageToken %@",_nextPageToken ? @"NEXTPAGE" : @"NEW SEARCH");
    
    if (newSearch) {
        [_searchResults removeAllObjects];
        _nextPageToken = nil;
    }
    
    if (!_nextPageToken) {
        urlString = [NSString stringWithFormat:@"https://www.googleapis.com/youtube/v3/search?part=snippet&q=%@&key=%@&type=video",
                     self.searchString, self.apiKey];
    }
    else {
        urlString = [NSString stringWithFormat:@"https://www.googleapis.com/youtube/v3/search?part=snippet&q=%@&key=%@&type=video&pageToken=%@",
                     self.searchString, self.apiKey, (NSString*)_nextPageToken];
    }
    
    NSURL* targetURL = [NSURL URLWithString:urlString];
    
    [self performGetRequestTo:targetURL completionHandler:^(NSData* data, NSURLResponse* HTTPResponse, NSError* error) {
        
        if ([HTTPResponse isKindOfClass:[NSHTTPURLResponse class]]) {
            NSHTTPURLResponse* HTTPcode = (NSHTTPURLResponse*) HTTPResponse;
            if (HTTPcode.statusCode == 200 && !error) {
                
                NSMutableArray *result = [@[] mutableCopy];
                
                id responseData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                
//                id pageToken =[responseData objectForKey:@"nextPageToken"];
//                id kind =[responseData objectForKey:@"kind"];
//                NSLog(@"response kind %@",[kind description]);
//                NSLog(@"response pageToken %@",[pageToken description]);

                id pageInfo =[responseData objectForKey:@"pageInfo"];

                NSUInteger resultsPerPage = [pageInfo[@"resultsPerPage"] unsignedIntegerValue];
//                NSUInteger totalResults = [pageInfo[@"totalResults"] unsignedIntegerValue];
                NSUInteger lastOfPageIndex = resultsPerPage -1;

//                NSLog(@"resultsPerPage %ld  totalResults %ld",resultsPerPage,totalResults);
                
                _nextPageToken = [responseData valueForKey:@"nextPageToken"];
                
                NSArray *items = [responseData objectForKey:@"items"];
                
                NSUInteger counter = 0;

                NSUInteger minimumResults = 14;

                BOOL resultsAdded = NO;
                
                for (id item in items) {
                    
                    NSMutableDictionary *singleItemResult = [@{} mutableCopy];
                    singleItemResult[@"ytvideoid"] = item[@"id"][@"videoId"];   //  key videoID  == ytvideoid
                    singleItemResult[@"videoTitle"] = item[@"snippet"][@"title"];
                    singleItemResult[@"thumbnail"] = item[@"snippet"][@"thumbnails"][@"default"][@"url"];
                    
                    [result addObject:singleItemResult];
                    
                    // check last item on page
                    
                    NSUInteger totalResultsSoFar = self.searchResults.count + result.count;
                    
                    // NSLog(@"totalResultsSoFar %ld",totalResultsSoFar);
                    
                    if (counter == lastOfPageIndex ){
                        resultsAdded = YES;
                        [_searchResults addObjectsFromArray:result];

                        if (totalResultsSoFar < minimumResults) {
                            NSLog(@"LAST of Page and CONTINUE results");
                            [self getSearchKeywordDetailsWithString:(NSString*)searchStr newSearch:(BOOL)NO onCompletion:completion];
                            
                            //                        [self getSearchKeywordDetailsWithCompletion:completion];
                            //                    [self performSelector:@selector(getSearchKeywordDetailsWithCompletion:) withObject:completion];

                        } else {
                            NSLog(@"LAST of Page and RETURN results");
                            completion(_searchResults,searchStr);
                        }
                    }
                    
                    counter++;
                    if (counter < resultsPerPage) {
                        continue;
                    } else {
                        break;
                    }
                    
                }  // for

                if (!resultsAdded) {
                    [_searchResults addObjectsFromArray:result];
                }
                
            } else {
                NSLog(@"HTTP Status Code = %ld", (long)HTTPcode.statusCode);
                NSLog(@"Error while loading channel details: %@", error);
            }
        }
        
//        NSLog(@"Completed Task");
    }];
    
    
}

@end


//NSUInteger counter = 0;
//for (id item in items) {
//    NSMutableDictionary *singleItemResult = [@{} mutableCopy];
//    //  key videoID  == ytvideoid
//    singleItemResult[@"ytvideoid"] = item[@"id"][@"videoId"];
//    singleItemResult[@"videoTitle"] = item[@"snippet"][@"title"];
//    singleItemResult[@"thumbnail"] = item[@"snippet"][@"thumbnails"][@"default"][@"url"];
//    
//    [self.searchResults addObject:singleItemResult];
//    
//    completion(self.searchResults);
//    
//    // check last item on page
//    if (counter == lastOfPageIndex && self.searchResults.count > (2*lastOfPageIndex) ) {
//        NSLog(@"LAST of Page and RETURN results");
//        completion(self.searchResults);
//        
//    } else if (counter == lastOfPageIndex ) {
//        NSLog(@"LAST of Page and Continue results");
//        //                        [self getSearchKeywordDetailsWithCompletion:completion];
//        [self performSelector:@selector(getSearchKeywordDetailsWithCompletion:) withObject:completion];
//    }
//    
//    counter++;
//    if (counter < resultsPerPage) {
//        continue;
//    } else {
//        break;
//    }
//}

//self.channelData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
//id item = [self.channelData objectForKey:@"items"];
//
//for (int i = 0; i < 5; i++) {
//    NSMutableDictionary* desiredValues = [NSMutableDictionary new];
//    _nextPageToken = [self.channelData valueForKey:@"nextPageToken"];
//    id itemAt = item[i];
//    //                    NSLog(@"%@",[itemAt description]);
//
//    id IDAtItem_i = [itemAt objectForKey:@"id"];
//    id videoIDAt_ID_i = [IDAtItem_i objectForKey:@"videoId"];
//    [desiredValues setObject:videoIDAt_ID_i forKey:@"videoID"];
//    id snippetAt_i = [itemAt objectForKey:@"snippet"];
//    id thumbAt_snippet_i = [snippetAt_i objectForKey:@"thumbnails"];
//    id defAt_thumb_snippet_i = [thumbAt_snippet_i objectForKey:@"default"];
//    [desiredValues setObject:[defAt_thumb_snippet_i valueForKey:@"url"] forKey:@"thumbnail"];
//    
//    id titleAt_snippet_i = [snippetAt_i objectForKey:@"title"];
//    [desiredValues setObject:titleAt_snippet_i forKey:@"videoTitle"];
//    [self.channelsDataArray addObject:desiredValues];
//    NSLog(@"%@",[desiredValues description]);
//    if (i == 4 && self.channelsDataArray.count > 8) {
//        completion(self.channelsDataArray);
//    } else if (i == 4 ) {
//        [self getSearchKeywordDetailsWithCompletion:completion];
//    }


