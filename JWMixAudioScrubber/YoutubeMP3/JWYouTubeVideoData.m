//
//  JWYouTubeVideoData.m
//  JamWIthT
//
//  Created by JOSEPH KERR on 10/18/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

/*
 
 This class uses the YouTube API to search for videos that match certian criteria.  Basically all this class does is perform a
 HTTP GET request on the googleapis/youtube URL and once the request is complete and an HTTP Response of 200 is achieved
 (success), a completion block is called and the JSON style data that is recieved is placed in an array of dictionaries.
 */

#import "JWYouTubeVideoData.h"

@interface JWYouTubeVideoData() {
    id _nextPageToken;
}
@property (nonatomic) NSString* apiKey;
@property (nonatomic) NSString* youtubeVideoId;
@end

const NSString *JWDbKeyYouTubeDataVideoId = @"ytvideoid";
const NSString *JWDbKeyYoutubeDataDescription = @"ytdescription";
const NSString *JWDbKeyYoutubeDataLocalized = @"ytlocalized";
const NSString *JWDbKeyYoutubeDataTitle = @"yttitle";


@implementation JWYouTubeVideoData

-(id)initWithVideoId:(NSString*)youTubeVideoId {
    if (self = [super init]) {
        self.youtubeVideoId = [youTubeVideoId copy];
        self.apiKey = [NSString stringWithFormat:@"AIzaSyDZX_Y5M0XIp69bPqOwM0fezYpSwQ2oUdg"];
    }
    return self;
}


-(void)performGetRequestTo:(NSURL *)targetURL
         completionHandler:(void (^)(NSData * data, NSURLResponse* response, NSError* error))completion
{
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


-(void)getVideoDataOnCompletion:(void (^)(NSArray* videoData))completion {
    
    NSString* urlString = [[NSString alloc] init];
    if (!_nextPageToken) {
        
        urlString = [NSString stringWithFormat:@"https://www.googleapis.com/youtube/v3/videos?part=snippet&id=%@&key=%@&type=video",
                     self.youtubeVideoId , self.apiKey];
        
        NSLog(@"%@",urlString);
        
        //        urlString = [NSString stringWithFormat:@"https://www.googleapis.com/youtube/v3/search?part=snippet&q=%@&key=%@&type=video", self.searchString, self.apiKey];
    }
    
    NSURL* targetURL = [NSURL URLWithString:urlString];
    
    [self performGetRequestTo:targetURL completionHandler:^(NSData* data, NSURLResponse* HTTPResponse, NSError* error) {

        NSArray *result;

        if ([HTTPResponse isKindOfClass:[NSHTTPURLResponse class]]) {
            NSHTTPURLResponse* HTTPcode = (NSHTTPURLResponse*) HTTPResponse;
            
            if (HTTPcode.statusCode == 200 && !error) {
                id responseData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                
                NSArray *items = [responseData objectForKey:@"items"];

                NSDictionary *item = items[0];
                NSMutableDictionary *singleItemResult = [@{} mutableCopy];

                singleItemResult[@"ytvideoid"] = item[@"id"];
                singleItemResult[@"ytdescription"] = item[@"snippet"][@"description"];
                singleItemResult[@"ytlocalized"] = item[@"snippet"][@"localized"];
                singleItemResult[@"yttitle"] = item[@"snippet"][@"title"];
                singleItemResult[@"ytthumbnails"] = item[@"snippet"][@"thumbnails"];
                _nextPageToken = item[@"nextPageToken"];
                
                result = @[[NSDictionary dictionaryWithDictionary:singleItemResult]];
                
            } else {
                NSLog(@"HTTP Status Code = %ld", (long)HTTPcode.statusCode);
                NSLog(@"Error while loading channel details: %@", error);
                
                result = @[@{@"statuscode":@(HTTPcode.statusCode),
                             @"error":[error description]
                             }];
            }
            
        } else {
            result = @[@{@"statuscode":@(999)}];
        }

//        NSLog(@"%s %@",__func__,[result description]);

        completion (result);

    }];
    
}


@end

// -----------------------------
// REFRENCE heres what the data looks like
// -----------------------------

//    HTTP Status Code = 200
//    2015-10-18 01:47:48.733 JamWIthTJoe[89448:7914667] {
//        etag = "\"fpJ9onbY0Rl_LqYLG6rOCJ9h9N8/iJw5OzlYuUqgC0mY1eq9kzDpcVA\"";
//        items =     (
//                     {
//                         etag = "\"fpJ9onbY0Rl_LqYLG6rOCJ9h9N8/jGZRLfp36ASnaK_GuHEPvX4STC0\"";
//                         id = ye5BuYf8q4o;
//                         kind = "youtube#video";
//                         snippet =             {
//                             categoryId = 10;
//                             channelId = UCqkAwCmVaHlj3xXBbDhlFLQ;
//                             channelTitle = ShawnxXxMichaels;
//                             defaultAudioLanguage = en;
//                             description = "Lynyrd Skynyrd - Sweet Home Alabama";
//                             liveBroadcastContent = none;
//                             localized =                 {
//                                 description = "Lynyrd Skynyrd - Sweet Home Alabama";
//                                 title = "Lynyrd Skynyrd - Sweet Home Alabama";
//                             };
//                             publishedAt = "2008-08-15T10:38:32.000Z";
//                             tags =                 (
//                                                     rock,
//                                                     classical,
//                                                     country,
//                                                     world,
//                                                     music,
//                                                     lynyrd,
//                                                     skynyrd,
//                                                     sweet,
//                                                     home,
//                                                     alabama
//                                                     );
//                             thumbnails =                 {
//                             default =                     {
//                                 height = 90;
//                                 url = "https://i.ytimg.com/vi/ye5BuYf8q4o/default.jpg";
//                                 width = 120;
//                             };
//                                 high =                     {
//                                     height = 360;
//                                     url = "https://i.ytimg.com/vi/ye5BuYf8q4o/hqdefault.jpg";
//                                     width = 480;
//                                 };
//                                 medium =                     {
//                                     height = 180;
//                                     url = "https://i.ytimg.com/vi/ye5BuYf8q4o/mqdefault.jpg";
//                                     width = 320;
//                                 };
//                             };
//                             title = "Lynyrd Skynyrd - Sweet Home Alabama";
//                         };
//                     }
//                     );
//        kind = "youtube#videoListResponse";
//        pageInfo =     {
//            resultsPerPage = 1;
//            totalResults = 1;
//        };
//    }


