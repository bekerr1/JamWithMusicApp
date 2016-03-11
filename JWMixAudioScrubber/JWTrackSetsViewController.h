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
@property (weak, nonatomic) id <JWTrackSetsProtocol> delegate;
-(void)setTrackSet:(id)trackSet;
@end


@protocol JWTrackSetsProtocol <NSObject>

-(void)trackSets:(JWTrackSetsViewController*)controller saveJamTrackWithKey:(NSString*)key;
-(NSString*)trackSets:(JWTrackSetsViewController*)controller titleForSection:(NSUInteger)section;
-(NSString*)trackSets:(JWTrackSetsViewController*)controller titleDetailForSection:(NSUInteger)section;
-(NSString*)trackSets:(JWTrackSetsViewController*)controller titleForJamTrackKey:(NSString*)key;
-(id)addTrackNode:(id)controller toJamTrackWithKey:(NSString*)key;
-(void)userAudioObtainedInNodeWithKey:(NSString*)nodeKey recordingId:(NSString*)rid;
-(void)effectsChanged:(NSArray*)effects inNodeWithKey:(NSString*)nodeKey;

@optional

-(void)addTrack:(JWTrackSetsViewController*)controller cachKey:(NSString*)key;

-(NSString*)trackSets:(JWTrackSetsViewController*)controller titleForTrackAtIndex:(NSUInteger)index
           inJamTrackWithKey:(NSString*)key;

-(void)save:(JWTrackSetsViewController*)controller;

@end
