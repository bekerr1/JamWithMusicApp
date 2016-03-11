//
//  JWYoutubeMP3ConvertController.m
//  JamWIthT
//
//  Created by JOSEPH KERR on 10/21/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import "JWYoutubeMP3ConvertController.h"
#import <UIKit/UIKit.h>
#import "JWURLManip.h"

@interface JWYoutubeMP3ConvertController () <JWURLManipDelegate,UIWebViewDelegate>
@property (nonatomic) JWURLManip* urlSession;
@property (strong, nonatomic) UIWebView *webView;
@property (nonatomic) NSUInteger loadCount;
@property (nonatomic,assign) BOOL hasLink;
@property (nonatomic) NSMutableData* mp3Data;
@property (nonatomic) NSString* youtubeString;
@property (nonatomic) NSString* youtubeVideoId;
@property (nonatomic) NSURL *currentMP3FileURL;
@property (nonatomic) NSURL *youTubeLinkURL;
@end


@implementation JWYoutubeMP3ConvertController

-(instancetype)initWithWebview:(UIWebView*)webView andDelegate:(id <JWYoutubeMP3ConvertDelegate>) delegate {

    if (self = [super init]) {
        _delegate = delegate;
        [self initialzeConvertControllerWithWebView:webView];
    }
    return self;
}

- (void)initialzeConvertControllerWithWebView:(UIWebView*)webView {

    self.webView = webView;
    _loadCount = 0;
    _hasLink = NO;

    [[NSNotificationCenter  defaultCenter] addObserver:self selector:@selector(initiateWebView:) name:@"URLSessionComplete" object:nil];
}

#pragma mark -

-(JWURLManip *)urlSession {
    if (!_urlSession)
        _urlSession = [[JWURLManip alloc] init];
    return _urlSession;
}

#pragma mark -

-(void)prepareToBeginNewSessionWithLinkURL:(NSURL*)linkURL forDbKey:(NSString*)dbkey {
    // calle before setupSession
    self.webView.delegate = nil;
    self.urlSession.delegate = nil;
    self.urlSession = nil;
    _dbkey = dbkey;
    _youTubeLinkURL = linkURL;
    _loadCount = 0;
    _hasLink = NO;
    [self.urlSession setupSession];
    self.urlSession.delegate = self;
    self.urlSession.youTubeURLReplaceString = [_youTubeLinkURL absoluteString];
    self.urlSession.dbkey = _dbkey;
}

-(void) startSession {
    self.webView.delegate = self;
    [self.urlSession startWebSession];
}

- (void)reconvert{
    // Re Convert
    if (self.urlSession.youTubeLinkURL) {
        self.urlSession.youTubeURLReplaceString = self.urlSession.youTubeLinkURL;
        [self newSessionWithLinkURLString:self.urlSession.youTubeURLReplaceString dbKey:_dbkey];
    } else {
        NSLog(@"%s no link URL available",__func__);
    }
}

#pragma mark -

//-(void)setUrlSessionYoutubeString:(NSString *)youtubeString videoId:(NSString *)videoId
//{
//    NSLog(@"%s %@ %@",__func__,youtubeString,videoId );
//    _youtubeVideoId = videoId;
//    _youtubeString = youtubeString;
//}


-(void) newSessionWithLinkURLString:(NSString*)linkURLStr dbKey:(NSString*)dbkey
{
    NSLog(@"%s %@",__func__,linkURLStr);
    if (!linkURLStr)
        return;
    
    [self prepareToBeginNewSessionWithLinkURL:[NSURL URLWithString:linkURLStr] forDbKey:dbkey];
    [self startSession];
}

#pragma mark - webview

-(void)initiateWebView:(NSNotification*)noti {
    
    [_delegate didInitiateWebView:self];
    [_delegate conversionProgress1:self];
    
    [self.webView loadData:self.urlSession.accumulatedWebData MIMEType:nil textEncodingName:nil baseURL:self.urlSession.audioConverterURL];
    
    [_delegate didInitiateWebView2:self];
}

#pragma mark webview delegate

-(void)webViewDidFinishLoad:(UIWebView *)webView {
    
    //    NSLog(@"%s ",__func__);
    
    _loadCount++;
    
    if (_loadCount == 1) {
        _hasLink = NO;
        [_delegate webViewDidFinishFirstLoad];

        // First load begin convert
        
        [webView stringByEvaluatingJavaScriptFromString:@"var script = document.createElement('script');\
         script.type = 'text/javascript';\
         script.text = \"function submitFunction() \
         {\
         var submitter = document.getElementById('submit');\
         submitter.click();\
         }\";\
         document.getElementsByTagName('head')[0].appendChild(script);\
         "];
        
        [webView stringByEvaluatingJavaScriptFromString:@"submitFunction();"];
        

        [_delegate conversionProgress2:self];
        
    } else if (_hasLink == NO) {
        
        NSLog(@"%s %lu ",__func__,(unsigned long)_loadCount);
     }
    
    if (!_hasLink && [self.urlSession downloadLinkWithContentsOfWebView:self.webView]) {

        [_delegate foundLinkInWebView];
        _hasLink = YES;
    }
    
}

#pragma mark - URLManip delegate

-(void)didRetrieveFile:(JWURLManip *)URLManip
{
    [self saveFileData:URLManip.mp3Data fordbkey:URLManip.dbkey];

    [_delegate didRetrieveFile:self];
}
    
-(void)didObtainLink:(JWURLManip *)URLManip linkToMP3String:(NSString*)linkStr {
    
//    NSLog(@"%s\n%@",__func__,linkStr);
    
    [_delegate didObtainLink:self linkToMP3String:linkStr];
}

#pragma mark - File Name and Save methods

// saveFileData methods used by URLmanip download, not JWFileDownload

-(void)saveFileData:(NSData*)mp3Data fordbkey:(NSString*)dbkey {
    
    NSURL *fileUrl = [self fileURLForCacheItem:dbkey];
    
    self.currentMP3FileURL = fileUrl;
    
    BOOL success = [mp3Data writeToURL:fileUrl atomically:YES];
    if (success) {
        
        [_delegate didSaveFileDataForDbKey:dbkey];
        
        NSLog(@"\nSAVED\n%@",[_currentMP3FileURL lastPathComponent]);
    }
}


-(NSURL *)fileURLForCacheItem:(NSString*)dbkey {
    
    NSURL *result;
    NSString *thisfName = @"mp3file";
    NSString *thisName = [NSString stringWithFormat:@"%@_%@.mp3",thisfName,dbkey?dbkey:@""];
    
    NSMutableString *fname = [[self documentsDirectoryPath] mutableCopy];
    [fname appendFormat:@"/%@",thisName];
    
    result = [NSURL fileURLWithPath:fname];
    NSLog(@"%s FileName: %@",__func__,[result lastPathComponent]);
    
    return result;
}

-(NSString*)documentsDirectoryPath{
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [searchPaths objectAtIndex:0];
}

@end



//    _loadCount = 0;
//    _hasLink = NO;
//    self.webView.delegate = self;
//    self.urlSession.dbkey = dbkey;
//    self.urlSession.youTubeURLReplaceString = linkURLStr;
//    self.urlSession.delegate = self;
//    [self.urlSession setupSession];
//    // Start the WebSession
//    [self.urlSession startWebSessionWithURL:self.urlSession.audioConverterURL];


//    self.urlSession.dbkey = _dbkey;
//    self.urlSession.youTubeURLReplaceString = linkURLStr;
//    self.urlSession.delegate = self;
//    [self.urlSession setupSession];
// starts a previoously configured session prepareToBeginNewSessionWithLinkURL
//    [self.urlSession startWebSessionWithURL:self.urlSession.audioConverterURL];






