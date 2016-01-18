//
//  JWSourceAudioFilesTableViewController.h
//  JamWIthT
//
//  Created by JOSEPH KERR on 10/4/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol JWSourceAudioFilesDelegate;

@interface JWSourceAudioFilesTableViewController : UITableViewController
@property (nonatomic,weak) id <JWSourceAudioFilesDelegate> delegate;
@property (nonatomic) BOOL previewMode;  // set to yes to simply play on selection and not proceed
@property (nonatomic) BOOL allFiles;  // supports allFiles vs user organized
@end


@protocol JWSourceAudioFilesDelegate <NSObject>
-(void)loadDataWithCompletion:(void (^)())completion;
-(void)loadDataAllWithCompletion:(void (^)())completion;

@optional
-(void)finishedTrim:(JWSourceAudioFilesTableViewController *)controller;
-(void)finishedTrim:(JWSourceAudioFilesTableViewController *)controller withDBKey:(NSString*)key;
-(void)finishedTrim:(JWSourceAudioFilesTableViewController *)controller title:(NSString*)title withDBKey:(NSString*)key;
@end
