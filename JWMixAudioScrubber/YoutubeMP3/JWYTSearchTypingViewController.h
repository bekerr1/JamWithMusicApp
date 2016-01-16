//
//  JWYTSearchTypingViewController.h
//  JamWIthT
//
//  Created by JOSEPH KERR on 10/19/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol JWYTSearchTypingDelegate;

@interface JWYTSearchTypingViewController : UITableViewController

@property (nonatomic,weak) id <JWYTSearchTypingDelegate> delegate;

@end


@protocol JWYTSearchTypingDelegate <NSObject>
@optional
-(void)finishedTrim:(JWYTSearchTypingViewController *)controller;
-(void)finishedTrim:(JWYTSearchTypingViewController *)controller withDBKey:(NSString*)key;
-(void)finishedTrim:(JWYTSearchTypingViewController *)controller title:(NSString*)title withDBKey:(NSString*)key;
@end


