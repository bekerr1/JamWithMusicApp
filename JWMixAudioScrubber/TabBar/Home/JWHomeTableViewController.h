//
//  JWHomeTableViewController.h
//  JamWDev
//
//  Created by brendan kerr on 4/17/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, JWSectionType) {
    
    JWSectionTypeSessions = 0,
    JWSectionTypeDownloadedTracks
    
};
@interface JWHomeTableViewController : UITableViewController

@property (nonatomic) NSMutableArray *homeControllerData;
@property (nonatomic) NSMutableDictionary *homeControllerList;

@end
