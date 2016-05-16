//
//  JWJamSessionCoordinator.h
//  JamWDev
//
//  Created by brendan kerr on 5/13/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface JWJamSessionCoordinator : NSObject

//Initialize this controller with a data source where all
-(instancetype)initWithDataSet:(NSArray *)data;
//- (instancetype) init __attribute__((unavailable("Must use initWithDataSet: instead.")));

-(id)jamTrackObjectAtIndexPath:(NSIndexPath*)indexPath fromSourceStructure:(NSArray *)structure;

-(NSMutableArray *)newTestJamSession;

@end
