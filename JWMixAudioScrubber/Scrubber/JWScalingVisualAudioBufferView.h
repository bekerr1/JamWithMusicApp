//
//  JWScalingVisualAudioBufferView.h
//  JamWIthT
//
//  Created by JOSEPH KERR on 10/17/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import "JWVisualAudioBufferView.h"


@interface JWScalingVisualAudioBufferView : JWVisualAudioBufferView

@property (nonatomic) CGFloat scale;

-(instancetype)initWithSamples:(NSArray*)samples1 samples2:(NSArray*)samples2 samplingOptions:(SamplingOptions)options;

- (void)scaleSamples;

@end
