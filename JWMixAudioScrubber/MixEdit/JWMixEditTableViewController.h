//
//  JWMixEditTableViewController.h
//  JamWIthT
//
//  co-created by joe and brendan kerr on 10/15/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JWEffectsHandler.h"

@protocol JWMixEditDelegate;


@interface JWMixEditTableViewController : UITableViewController 

@property (weak) id <JWMixEditDelegate> delegateMixEdit;
@property (nonatomic) id <JWEffectsHandler> effectsHandler;
@property (nonatomic) NSUInteger selectedNodeIndex;
-(void)refresh;
@end


@protocol JWMixEditDelegate <NSObject>
@optional
- (id <JWEffectsModifyingProtocol>) mixNodeControllerForScrubber;
- (void)recordAtNodeIndex:(NSUInteger)index;
- (void)doneWithMixEdit:(JWMixEditTableViewController*)mixEdit;
- (id <JWEffectsModifyingProtocol>) trackNodeControllerForNodeAtIndex:(NSUInteger)index;
-(void)previewSelectedPresetAtIndex:(NSInteger)enumValue effectAtIndex:(NSUInteger)effect playerNodeIndex:(NSUInteger)pn;
-(void)changeToPresetAtIndex:(NSInteger)index effectAtIndex:(NSUInteger)effect playerNodeIndex:(NSUInteger)pn;
-(void)stopAudioForPresets;

@end



