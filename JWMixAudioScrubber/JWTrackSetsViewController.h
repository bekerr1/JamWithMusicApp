//
//  JWTrackSetsViewController.h
//  JWMixAudioScrubber
//
//  Created by JOSEPH KERR on 1/7/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol JWTrackSetsProtocol;

@interface JWTrackSetsViewController : UITableViewController

-(void)setTrackSet:(id)trackSet;

@property (weak, nonatomic) id <JWTrackSetsProtocol> delegate;
@end


@protocol JWTrackSetsProtocol <NSObject>
-(void)save:(JWTrackSetsViewController*)controller;
-(NSString*)trackSets:(JWTrackSetsViewController*)controller titleForSection:(NSUInteger)section;
-(NSString*)trackSets:(JWTrackSetsViewController*)controller titleDetailForSection:(NSUInteger)section;
@end
