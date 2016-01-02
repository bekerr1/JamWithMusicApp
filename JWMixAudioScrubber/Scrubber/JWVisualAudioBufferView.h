//
//  VisualAudioBufferView.h
//  AVAEMixerSample
//
//  Created by JOSEPH KERR on 9/19/15.
//  Copyright (c) 2015 apple. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JWScrubber.h"



@interface JWVisualAudioBufferView : UIView {
    @public
    CGFloat loudest;
}

-(instancetype)initWithSamples:(NSArray*)samples1 samples2:(NSArray*)samples2 samplingOptions:(SamplingOptions)options;

@property (nonatomic) NSArray *samples;
@property (nonatomic) NSArray *samples2;
@property (nonatomic) NSArray *samplesAverages;
@property (nonatomic) NSArray *samplesAverages2;

@property (nonatomic) NSUInteger bufferSeqNumber;

@property (nonatomic) VABKindOptions kindOptions;
@property (nonatomic) VABLayoutOptions layoutOptions;
@property (nonatomic) SamplingOptions samplingOptions;

@property (assign) BOOL recording;
@property (assign) BOOL darkBackGround;

@property (nonatomic) NSString *notifString;

@property (nonatomic) UIColor *colorForTopPeak;
@property (nonatomic) UIColor *colorForTopAvg;
@property (nonatomic) UIColor *colorForTopNoAvg;
@property (nonatomic) UIColor *colorForBottomPeak;
@property (nonatomic) UIColor *colorForBottomAvg;
@property (nonatomic) UIColor *colorForBottomNoAvg;
@end
