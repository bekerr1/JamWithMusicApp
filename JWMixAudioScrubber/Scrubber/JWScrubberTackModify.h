//
//  JWScrubberTackModify.h
//  JamWDev
//
//  Created by JOSEPH KERR on 1/12/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JWEffectsModifyingProtocol.h"

@protocol JWScrubberTackModifyDelegate;

@interface JWScrubberTackModify : NSObject <JWEffectsModifyingProtocol>

@property NSUInteger track;
@property (nonatomic,weak) id <JWScrubberTackModifyDelegate> delegate;
@end


@protocol JWScrubberTackModifyDelegate <NSObject>
-(void)volumeAdjusted:(JWScrubberTackModify*)controller forTrack:(NSUInteger)index withValue:(float)value;
-(void)panAdjusted:(JWScrubberTackModify*)controller forTrack:(NSUInteger)index withValue:(float)value;

@end

