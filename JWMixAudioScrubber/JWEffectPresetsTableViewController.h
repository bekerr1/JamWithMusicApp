//
//  JWEffectPresetsTableViewController.h
//  JamWDev
//
//  Created by brendan kerr on 3/10/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JWMixEditTableViewController.h"

@protocol JWPresetProtocol;

@interface JWEffectPresetsTableViewController : UITableViewController

@property (nonatomic) NSArray *systemDefinedpresets;
@property (nonatomic) NSMutableArray *userDefinedPresets;
@property (nonatomic) NSMutableArray *presetsGrouping;
@property (nonatomic) NSUInteger selectedPresetIndex;
@property (nonatomic) id <JWPresetProtocol> delegate;

@end

@protocol JWPresetProtocol <NSObject>

-(void)previewSelectedPresetAtIndex:(NSInteger)enumValue withStringName:(NSString *)preset;

@end
