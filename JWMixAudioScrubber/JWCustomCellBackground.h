//
//  JWCustomCellBackground.h
//  JWMixAudioScrubber
//
//  co-created by joe and brendan kerr on 1/7/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JWCommon.h"

@protocol JWGradientOffSetDelegate;

@interface JWCustomCellBackground : UIView
@property (nonatomic,weak) id <JWGradientOffSetDelegate> delegate;
@property (nonatomic) JWCommon *com;

-(void)adjustGOffsetVolume:(UISlider *)sender;

@end


@protocol JWGradientOffSetDelegate <NSObject>

-(NSUInteger)sliderGradientOffset;

@end
