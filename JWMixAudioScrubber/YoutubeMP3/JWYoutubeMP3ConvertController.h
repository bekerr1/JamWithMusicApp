//
//  JWYoutubeMP3ConvertController.h
//  JamWIthT
//
//  co-created by joe and brendan kerr on 10/21/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import <Foundation/Foundation.h>
@import UIKit;

@protocol  JWYoutubeMP3ConvertDelegate;


@interface JWYoutubeMP3ConvertController : NSObject

@property (nonatomic, assign) id <JWYoutubeMP3ConvertDelegate> delegate;
@property (nonatomic) NSString* dbkey;  // used by YoutubeMP3 to save the file correctly

-(instancetype)initWithWebview:(UIWebView*)webView andDelegate:(id <JWYoutubeMP3ConvertDelegate>) delegate;

-(void)initialzeConvertControllerWithWebView:(UIWebView*)webView;
-(void)prepareToBeginNewSessionWithLinkURL:(NSURL*)linkURL forDbKey:(NSString*)dbkey;
-(void)startSession;
-(void)reconvert;
-(void)newSessionWithLinkURLString:(NSString*)linkURLStr dbKey:(NSString*)dbkey;

@end


@protocol  JWYoutubeMP3ConvertDelegate <NSObject>
@optional
-(void)didRetrieveFile:(JWYoutubeMP3ConvertController *)controller;
-(void)didObtainLink:(JWYoutubeMP3ConvertController *)controller linkToMP3String:(NSString*)linkStr;
-(void)didInitiateWebView:(JWYoutubeMP3ConvertController *)controller ;
-(void)didInitiateWebView2:(JWYoutubeMP3ConvertController *)controller ;
-(void)conversionProgress:(JWYoutubeMP3ConvertController *)controller progress:(float)progress;
-(void)webViewDidFinishFirstLoad;
-(void)foundLinkInWebView;
-(void)didSaveFileDataForDbKey:(NSString*)dbkey;
-(void)conversionProgress2:(JWYoutubeMP3ConvertController *)controller;
-(void)conversionProgress1:(JWYoutubeMP3ConvertController *)controller;
@end
