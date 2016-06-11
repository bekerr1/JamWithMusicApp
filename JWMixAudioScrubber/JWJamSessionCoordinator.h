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
-(id)jamTrackObjectWithKey:(NSString*)key fromSource:(NSArray *)source;
-(NSString*)preferredTitleForObject:(id)object;
-(NSUInteger)countEmptyRecorderNodesForJamTrackWithKey:(NSString*)key atIndexPath:(NSIndexPath *)path fromSource:(NSArray *)source;
-(NSString *)durationOfFirstTrackFromSession:(NSDictionary *)session;
-(NSMutableArray *)audioURLsForSession:(NSDictionary *)session;
-(NSMutableArray *)newTestJamSession;
-(NSMutableDictionary*)newJamTrackObjectWithRecorderFileURL:(NSURL*)fileURL;
-(NSMutableDictionary *)createFiveSecondPlayerNodeWithDirectory:(NSString *)fileString fromKey:(NSString*)dbKey;

@end
