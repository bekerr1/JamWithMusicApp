//
//  DetailViewController.h
//  JWAudioScrubber
//
//  Created by brendan kerr on 12/25/15.
//  Copyright © 2015 b3k3r. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol JWDetailDelegate;

@interface DetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;
@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@property (weak, nonatomic) id <JWDetailDelegate> delegate;
@end

@protocol JWDetailDelegate <NSObject>
-(void)itemChanged:(DetailViewController*)controller;
-(void)itemChanged:(DetailViewController*)controller cachKey:(NSString*)key;
-(void)save:(DetailViewController*)controller cachKey:(NSString*)key;
-(void)addTrack:(DetailViewController*)controller cachKey:(NSString*)key;
-(NSArray*)tracks:(DetailViewController*)controller cachKey:(NSString*)key;
@end

@protocol JWAudioControlsDelegate <NSObject>



@end
