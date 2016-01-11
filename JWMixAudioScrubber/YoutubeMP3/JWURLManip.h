//
//  JWURLManip.h
//  JamWithV1.0
//
//  Created by brendan kerr on 9/4/15.
//  Copyright (c) 2015 b3k3r. All rights reserved.
///Projects/brendan/jamwith/JamWIthT/JamWIthT/JWURLManip.h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol JWURLManipDelegate;

@interface JWURLManip : NSObject <
NSURLSessionDelegate,
NSURLSessionTaskDelegate,
NSURLSessionDataDelegate,
NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@property (nonatomic, assign) id <JWURLManipDelegate> delegate;
@property (nonatomic) NSMutableData* mp3Data;
@property (nonatomic) NSMutableData* accumulatedWebData;
@property (nonatomic) NSURL* audioConverterURL;
@property (nonatomic) NSString* youTubeURLReplaceString; // = @"https: //youtu.be/LfeNhwnO8hw";
@property (nonatomic) NSString* dbkey;  // used by YoutubeMP3 to save the file correctly
@property (nonatomic) NSString* youTubeLinkURL;

-(void)setupSession;
-(void)startWebSessionWithURL:(NSURL *)url;
-(void)startWebSession;

//-(void)getDownloadLinkWithContentsOfWebView:(UIWebView *)webView;
-(BOOL)downloadLinkWithContentsOfWebView:(UIWebView *)webView;
@end

@protocol  JWURLManipDelegate <NSObject>

-(void)didRetrieveFile:(JWURLManip *)URLManip;
-(void)didObtainLink:(JWURLManip *)URLManip linkToMP3String:(NSString*)linkStr;
@end



// IOS9
//In the app's info.plist, NSAppTransportSecurity [Dictionary] needs to have a key NSAllowsArbitraryLoads [Boolean] to be set to YES or Meteor needs to use https for its localhost server soon. (From Page 26

// http: //stackoverflow.com/questions/32631184/the-resource-could-not-be-loaded-because-the-app-transport-security-policy-requi


//@protocol  WebTimelineDelegate <NSObject>
//-(void)startWebSessionWithURL:(NSURL *)url;
//-(void)getDownloadLinkWithContentsOfWebView:(UIWebView *)webView;
//-(BOOL)downloadLinkWithContentsOfWebView:(UIWebView *)webView;
//@end




