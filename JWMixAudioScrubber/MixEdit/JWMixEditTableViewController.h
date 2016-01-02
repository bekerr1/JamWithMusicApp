//
//  JWMixEditTableViewController.h
//  JamWIthT
//
//  Created by JOSEPH KERR on 10/15/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JWEffectsHandler.h"

@protocol JWMixEditDelegate;


@interface JWMixEditTableViewController : UITableViewController

@property (weak) id <JWMixEditDelegate> delegateMixEdit;
@property (nonatomic) id <JWEffectsHandler> effectsHandler;
-(void)refresh;

// deprecated
//@property (nonatomic, readonly) CurrentEffect currentEffect;
//@property (nonatomic) BOOL newConfig;
//@property (nonatomic) BOOL effectChosen;
-(void)refreshNewConfig;
@end

//-(void)expandCellAtSection:(NSUInteger)section andRow:(NSUInteger)row;


@protocol JWMixEditDelegate <NSObject>
@optional
- (void)doneWithMixEdit:(JWMixEditTableViewController*)mixEdit;
- (id <JWEffectsModifyingProtocol>) mixNodeControllerForScrubber;
- (void)recordAtNodeIndex:(NSUInteger)index;
@end


