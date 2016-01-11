//
//  JWClipAudioViewController.h
//  JamWIthT
//
//  Created by JOSEPH KERR on 9/30/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol JWClipAudioViewDelegate;

@interface JWClipAudioViewController : UIViewController
@property (nonatomic)NSString* trackName;
@property (nonatomic)UIImage* thumbImage;
@property (nonatomic,weak) id <JWClipAudioViewDelegate> delegate;
@property (nonatomic,readonly) NSURL *trimmedURL;
@property (nonatomic,readonly) NSString *dbKey;
@end


@protocol JWClipAudioViewDelegate <NSObject>
@optional
-(void)finishedTrim:(JWClipAudioViewController *)controller;
-(void)finishedTrim:(JWClipAudioViewController *)controller withDBKey:(NSString*)key;
@end



