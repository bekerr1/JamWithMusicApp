//
//  JWURLManip.m
//  JamWithV1.0
//
//  co-created by joe and brendan kerr on 9/4/15.
//  Copyright (c) 2015 b3k3r. All rights reserved.
//

#import "JWURLManip.h"

@interface JWURLManip()
@property (nonatomic) NSURLSession* session;
@property (nonatomic) NSURLSessionDataTask* dataTaskSession;
@property (nonatomic) NSMutableString* accumulatedWebDataAsString;
@property (nonatomic) NSMutableString* mp3DataAsString;
@property (nonatomic) NSOperationQueue* downloadOperationQueue;
@property (nonatomic) NSMutableDictionary* linkRegistry;
@end


@implementation JWURLManip

typedef NS_ENUM(NSInteger, WebViewTimeline) {
    kReplaceURL,
    kDownloadFile,
    kProcessComplete
};
WebViewTimeline timeLine;


#pragma mark - LAZY INSTANTIATION

-(NSURL *)audioConverterURL {
    if (!_audioConverterURL) {
        _audioConverterURL = [NSURL URLWithString:@"http://www.youtube-mp3.org"];
    }
    return _audioConverterURL;
}

-(NSMutableData *)accumulatedWebData {
    if (!_accumulatedWebData) {
        _accumulatedWebData = [NSMutableData  data];
    }
    return _accumulatedWebData;
    
}

//starts the webSession
-(void)setupSessionWithController:(UIViewController *)vc {
    self.session =
    [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                  delegate:self
                             delegateQueue:[NSOperationQueue mainQueue]];
}

-(void)setupSession {
    self.downloadOperationQueue = [[NSOperationQueue alloc] init];
    self.downloadOperationQueue.qualityOfService = NSOperationQualityOfServiceUtility;
   
    self.session =
    [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                  delegate:self
                             delegateQueue:[NSOperationQueue mainQueue]];

//                             delegateQueue:_downloadOperationQueue];
}


#pragma mark - UTILITY METHODS

//Utility methods************************************************************************************
-(NSMutableString *)convertData:(NSData *)data ToString:(NSMutableString *)string {
    
    NSLog(@"Data Converted To String");
    string = [[NSMutableString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    return string;
}
-(NSMutableData *)convertString:(NSString *)string ToData:(NSMutableData *)data {
    
    NSLog(@"String Converted To Data");
    data = (NSMutableData *)[string dataUsingEncoding:NSUTF8StringEncoding];
    return data;
}
-(void)replaceCharactersAtStartRange:(NSRange)startRange UntilCharacter:(NSString *)stopString WithCharacters:(NSString *)replaceString {
    
    int i = 1;
    int j = i - 1;
    NSString* begginingString = [self.accumulatedWebDataAsString substringWithRange:NSMakeRange(startRange.location + startRange.length , i)];
    
    while (![[begginingString substringFromIndex:j] isEqualToString:stopString]) {
        i++;
        j++;
        begginingString = [self.accumulatedWebDataAsString substringWithRange:NSMakeRange(startRange.location + startRange.length, i)];
    }
    
    [self.accumulatedWebDataAsString replaceCharactersInRange:NSMakeRange(startRange.location + startRange.length, j) withString:replaceString];
    
//    NSLog(@"%@", self.accumulatedWebDataAsString);
    
}

//Utility methods************************************************************************************

//Searches through the webdata string the first time its brought in and inserts the correct youtube url

-(void)populateWebData:(NSString *)stringToSearch {
    
    timeLine = kReplaceURL;
    NSString* disabledHTML = @"<input type=\"submit\" id=\"submit\" value=\"Convert Video\" ";
    NSRange startDisabledHTML = [stringToSearch rangeOfString:disabledHTML];
    
    if (startDisabledHTML.location == NSNotFound){
//    if (startDisabledHTML == {NSNotFound,0} ) {
//    if ([startDisabledHTML isEmpty] ) {

        NSLog(@"%s Not FOUND",__func__);
        return;
    }
    
    
    [self replaceCharactersAtStartRange:startDisabledHTML UntilCharacter:@"/" WithCharacters:@""];
    
    
    NSString* startVideoValueText = @"<input type=\"text\" id=\"youtube-url\" value=\"";

    NSString* youTubeReplaceString = @"https://youtu.be/LfeNhwnO8hw";
    
    if (!_youTubeLinkURL) {

        // Eagles Takeit easy
        // https: //youtu.be/LfeNhwnO8hw
        youTubeReplaceString = @"https://youtu.be/LfeNhwnO8hw";

    }

    if (_youTubeURLReplaceString){
        youTubeReplaceString = _youTubeURLReplaceString;
    }
    
    self.youTubeLinkURL = youTubeReplaceString;
    
    NSString *youtubeVideoID = [youTubeReplaceString lastPathComponent];
    
    NSLog(@"%s YOUTUBE VIDEO %@",__func__,youtubeVideoID);
    
    NSRange startYoutubeValueRange = [stringToSearch rangeOfString:startVideoValueText];
    
    [self replaceCharactersAtStartRange:startYoutubeValueRange UntilCharacter:@"\"" WithCharacters:youTubeReplaceString];
    
    self.accumulatedWebData = [self convertString:self.accumulatedWebDataAsString ToData:self.accumulatedWebData];
    
}

#pragma mark - NSURLSESSION DELEGATES

//    NSLog(@"Session %@, Data Task %@\n", session, dataTask);

-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [self.accumulatedWebData appendData:data];
}

-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    
    if (!error && timeLine == kReplaceURL) {
        NSLog(@"Completed with no Errors");
        
        self.accumulatedWebDataAsString = [self convertData:self.accumulatedWebData ToString:self.accumulatedWebDataAsString];
        
        [self populateWebData:self.accumulatedWebDataAsString];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"URLSessionComplete" object:nil];
        
        
    } else {
        NSLog(@"Error Message %@", error);
    }
    
}

#pragma mark - WEB TIMELINE DELEGATES

-(void)startWebSessionWithURL:(NSURL *)url {
    
    self.dataTaskSession = [self.session dataTaskWithURL:self.audioConverterURL];
    [self.dataTaskSession resume];
}

-(void)startWebSession {
    self.dataTaskSession = [self.session dataTaskWithURL:self.audioConverterURL];
    [self.dataTaskSession resume];
}


// not used
//-(void)getDownloadLinkWithContentsOfWebView:(UIWebView *)webView {
//    //     "window.alert(submitter[i]);"
//    [webView stringByEvaluatingJavaScriptFromString:@"\
//     var script =\
//     document.createElement('script');\
//     script.type = 'text/javascript';\
//     script.text = \"function getLink() {\
//     var submitter = document.getElementsByTagName('a');\
//     var theLink = submitter[0];\
//     for (var i = 0; i < submitter.length; i++) {\
//     var submitterString = submitter[i].toString();\
//     if (submitter[i].style.display === '' && submitterString.length > 80){\
//     theLink = submitterString;\
//     }}\
//     return theLink;\
//     }\";\
//     document.getElementsByTagName('head')[0].appendChild(script);\
//     "];
//    NSString* dlLink = [webView stringByEvaluatingJavaScriptFromString:@"getLink();"];
//    if ([dlLink isEqualToString:@""]) {
//        NSLog(@"Empty DownloadLink Alert, trying to call GetDownloadLink Again");
////        [self getDownloadLinkWithContentsOfWebView:webView];
////        [self performSelectorOnMainThread:@selector(getDownloadLinkWithContentsOfWebView:) withObject:webView waitUntilDone:NO];
//    } else {
//        NSLog(@"Sussesful Download Link, -----TRING TO BEGIN DOWNLOADING-----");
////        NSURL* downloadLink = [NSURL URLWithString:dlLink];
//        [_delegate didObtainLink:self linkToMP3String:dlLink];
//        // TODO: understand
////        [self startDownloadingLinkWithURL:downloadLink];
//    }
//}


-(BOOL)downloadLinkWithContentsOfWebView:(UIWebView *)webView {
    
    BOOL result = NO;
    //     "window.alert(submitter[i]);"
    
    [webView stringByEvaluatingJavaScriptFromString:@"\
     var script = document.createElement('script'); \
     script.type = 'text/javascript'; \
     script.text = \"function getLink() \
     { \
     var submitter = document.getElementsByTagName('a'); \
     var theLink = submitter[0]; \
     for (var i = 0; i < submitter.length; i++) { \
     var submitterString = submitter[i].toString(); \
     if (submitter[i].style.display === '' && submitterString.length > 80){ \
     theLink = submitterString;\
     }}\
     return theLink;\
     }\";\
     document.getElementsByTagName('head')[0].appendChild(script);\
     "];
    
    
    NSString* dlLink = [webView stringByEvaluatingJavaScriptFromString:@"getLink();"];
    
    if ([dlLink length] > 0) {
        NSLog(@"Sussesful Download Link");
        [_delegate didObtainLink:self linkToMP3String:dlLink];
        result = YES;
    } else {
        NSLog(@"Empty DownloadLink");
    }
    
    return result;
}


//[_delegate didObtainLink:self linkToMP3String:dlLink];
//
////        [self startDownloadingLinkWithURL:[NSURL URLWithString:dlLink]];


#pragma mark - DOWNLOADING DELEGATES

- (void)startDownloadingLinkWithURL:(NSURL *)dlLink {
    
    NSLog(@"%s %@",__func__,[dlLink absoluteString]);

    // Create the request.
    NSURLRequest *theRequest = [NSURLRequest requestWithURL:dlLink
                                                cachePolicy:NSURLRequestUseProtocolCachePolicy
                                            timeoutInterval:60.0];
    
    // Create the NSMutableData to hold the received data.
    // receivedData is an instance variable declared elsewhere.
    self.mp3Data = [NSMutableData data];
    
    // create the connection with the request
    // and start loading the data
    NSURLConnection *theConnection=[[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    
    if (!theConnection) {
        // Release the receivedData object.
        self.mp3Data = nil;
        
        // Inform the user that the connection failed.
        NSLog(@"Connection To Recieve MP3 data failed");
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    
//    NSLog(@"%s rcvd %lu bytes",__func__,(unsigned long)[data length]);

    // Append the new data to receivedData.
    // receivedData is an instance variable declared elsewhere.
    [self.mp3Data appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // Release the connection and the data object
    // by setting the properties (declared elsewhere)
    // to nil.  Note that a real-world app usually
    // requires the delegate to manage more than one
    // connection at a time, so these lines would
    // typically be replaced by code to iterate through
    // whatever data structures you are using.
    
    self.mp3Data = nil;
    
    // inform the user
    NSLog(@"Connection failed! Error - %@ %@",
          [error localizedDescription],
          [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"%s Finished rcvd %lu bytes",__func__,(unsigned long)[self.mp3Data length]);

    // do something with the data
    // receivedData is declared as a property elsewhere
//    NSLog(@"Succeeded! Received %lu bytes of data",(unsigned long)[self.mp3Data length]);
  //  NSLog(@"MP3 Data: %@", self.mp3Data);
    
    [_delegate didRetrieveFile:self];
    
    // Release the connection and the data object
    // by setting the properties (declared elsewhere)
    // to nil.  Note that a real-world app usually
    // requires the delegate to manage more than one
    // connection at a time, so these lines would
    // typically be replaced by code to iterate through
    // whatever data structures you are using.
    //theConnection = nil;
    //receivedData = nil;
}


@end











// NSString* youTubeReplaceString = @"https://www.youtube.com/watch?v=cYh-Csp-6JU";
// Rolling stones beast of burden
// https: //youtu.be/S7qTS17SwF8
// NSString* youTubeReplaceString = @"https://youtu.be/S7qTS17SwF8";

// Wilco Monday
// https: //youtu.be/B24la7sQsCw
//NSString* youTubeReplaceString = @"https://youtu.be/B24la7sQsCw";

// CCR Fortunate son 1969
// https: //youtu.be/plj82F4kY7o
//NSString* youTubeReplaceString = @"https://youtu.be/plj82F4kY7o";

// Prince , Tom Petty While my guitar gently weeps
// https: //youtu.be/6SFNW5F8K9Y
//NSString* youTubeReplaceString = @"https://youtu.be/6SFNW5F8K9Y";

// WEEKEND  Cant feel my face
// https: //youtu.be/M5u_3C7R7PU
//NSString* youTubeReplaceString = @"https://youtu.be/M5u_3C7R7PU";


//    NSString* begginingOfBodyTag = [self.accumulatedWebDataAsString substringWithRange:NSMakeRange(startBodyValueRange.location + startBodyValueRange.length, 1)];
//    int i = 1;
//    int j = i - 1;
//    while (![[begginingOfBodyTag substringFromIndex:j] isEqualToString:@">"]) {
//        i++;
//        j++;
//        begginingOfBodyTag = [self.accumulatedWebDataAsString substringWithRange:NSMakeRange(startBodyValueRange.location + startBodyValueRange.length, i)];
//    }
//    [self.accumulatedWebDataAsString replaceCharactersInRange:NSMakeRange(startBodyValueRange.location + startBodyValueRange.length, 0)withString:bodyAdditionString];
//
//    i = 1;
//    j = i - 1;
//    NSString* begginingOfJSTag = [self.accumulatedWebDataAsString substringWithRange:NSMakeRange(startJSValueRange.location + startJSValueRange.length, 1)];
//
//
//    i = 1;
//    j = i - 1;
//    NSString* begginingOfYoutubeLink = [self.accumulatedWebDataAsString substringWithRange:NSMakeRange(startYoutubeValueRange.location + startYoutubeValueRange.length, 1)];
//
//    NSLog(@"%@", self.accumulatedWebDataAsString);
//
//    while (![[begginingOfYoutubeLink substringFromIndex:j]  isEqualToString:@"\""] ) {
//        i++;
//        j++;
//        begginingOfYoutubeLink  = [self.accumulatedWebDataAsString substringWithRange:NSMakeRange(startYoutubeValueRange.location + startYoutubeValueRange.length, i)];
//    }
//
//    [self.accumulatedWebDataAsString replaceCharactersInRange:NSMakeRange(startYoutubeValueRange.location + startYoutubeValueRange.length, j)withString:youTubeReplaceString];
//
//
//    NSLog(@"%@", self.accumulatedWebDataAsString);