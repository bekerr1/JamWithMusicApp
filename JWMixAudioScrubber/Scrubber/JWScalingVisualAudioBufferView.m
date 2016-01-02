//
//  JWScalingVisualAudioBufferView.m
//  JamWIthT
//
//  Created by JOSEPH KERR on 10/17/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import "JWScalingVisualAudioBufferView.h"

@interface JWScalingVisualAudioBufferView ()
@property (nonatomic) NSMutableArray *scaledSamples;
@end


@implementation JWScalingVisualAudioBufferView

-(instancetype)init {
    if (self = [super init]) {
        _scale = 1.0;
    }
    return self;
}


//bufferView.samples = samples;
//bufferView.samples2 = samples2;
//bufferView.recording = NO;
//bufferView.backgroundColor = [UIColor clearColor];

-(instancetype)initWithSamples:(NSArray*)samples1 samples2:(NSArray*)samples2 samplingOptions:(SamplingOptions)options {
    if (self = [super initWithSamples:samples1 samples2:samples2 samplingOptions:options]) {
        _scale = 1.0;
    }
    return self;
}

- (void)scaleSamples {
    if (_scale > 1.0f) {
        [self scaleSamplesUp];
    } else if (_scale < 1.0f) {
        [self scaleSamplesDown];
    }
}

- (void)scaleSamplesDown {
    NSUInteger sampleCount = [self.samples count];
    NSUInteger scaledSamplesCount = sampleCount * _scale;
    NSUInteger avgCount = sampleCount / scaledSamplesCount;
    // Remove samples by averaging
    _scaledSamples = [@[] mutableCopy];
    
    NSUInteger count = 0;
    CGFloat sum = 0.0;
    
    for (id sample in self.samples) {
        CGFloat sampleValue = [(NSNumber*)sample floatValue];
        if (count < avgCount) {
            sum+=sampleValue;
            count++;
        } else {
            CGFloat avgSampleValue = sum / count;
            [_scaledSamples addObject:@(avgSampleValue)];
            sum=0.0;
            count=0;
        }
    }
    
    if (count > 0) {
        CGFloat avgSampleValue = sum / count;
        [_scaledSamples addObject:@(avgSampleValue)];
    }
    
//    NSLog(@"%s samples %ld targetscaled %ld actual %ld avgCount %ld",__func__,sampleCount,scaledSamplesCount, [_scaledSamples count],avgCount);
    
}


- (void)scaleSamplesUp {
    
    NSUInteger sampleCount = [self.samples count];
    NSUInteger scaledSamplesCount = sampleCount * _scale;

    // Add samples by averaging
    _scaledSamples = [@[] mutableCopy];
    
    NSArray *scalingSamples = [NSArray arrayWithArray:self.samples];
    NSUInteger count = 0;
    CGFloat sum = 0.0;
    NSUInteger avgCount = 2;
    NSUInteger nSamples = 0;
    
    while (nSamples < scaledSamplesCount) {
        
        // Kepp dividing and averaging until desirec results achieved
        
        for (id sample in scalingSamples) {
            
            CGFloat sampleValue = [(NSNumber*)sample floatValue];
            count++;
            
            if (nSamples < scaledSamplesCount) {

                sum+=sampleValue;

                if (count < avgCount) {
                    [_scaledSamples addObject:@(sampleValue)];
                    nSamples++;
                } else {
                    
                    CGFloat avgSampleValue = sum / avgCount;
                    
                    [_scaledSamples addObject:@(avgSampleValue)];
                    nSamples++;
                    [_scaledSamples addObject:@(sampleValue)];
                    nSamples++;

                    sum = 0.0;
                    count = 0;
                }
                
            } else {
                break;
            }
        }
        
        if (nSamples < scaledSamplesCount) {
            scalingSamples = [NSArray arrayWithArray:self.scaledSamples];
        }
    }
    
//    NSLog(@"%s samples %ld targetscaled %ld actual %ld avgCount %ld",__func__,sampleCount,scaledSamplesCount, [_scaledSamples count],avgCount);
    
//    for (id sample in self.samples) {
//        CGFloat sampleValue = [(NSNumber*)sample floatValue];
//        NSLog(@"%s sample %.4f",__func__,sampleValue);
//    }
//    for (id sample in _scaledSamples) {
//        CGFloat sampleValue = [(NSNumber*)sample floatValue];
//        NSLog(@"%s scaled %.4f",__func__,sampleValue);
//    }
    
}

// ===================================================
//
// ===================================================

- (void)drawRect:(CGRect)rect {
    
    if (_scale > 1.10f  || _scale < 0.90f) {
        
        // Continue with this drawrect
        
    } else {
        [super drawRect:rect];
        return;
    }
    
    if (self.scaledSamples == nil) {
        [super drawRect:rect];
        return;
    }

    BOOL darkBackGround = YES;
    BOOL mirror = NO; //self.options & configOptionMirrored;
    BOOL onCenter = YES; // TODO: make option  self.options & configOptionCentered;

    //Get the CGContext from this view
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGFloat barWidth = 4.0f;
    if (mirror) {
        barWidth = barWidth/2.0;
    }
    //Set the width of the pen mark
    CGContextSetLineWidth(context, barWidth);
    
    CGPoint center = CGPointMake(self.bounds.size.width/2,self.bounds.size.height/2);
    CGFloat effectiveHeight =  self.bounds.size.height/2 * .90f;  // padding
    
    if (self.scaledSamples) {
        
        NSUInteger sampleCount = [self.scaledSamples count];
        
        if (self.recording) {
            CGContextSetStrokeColorWithColor(context, darkBackGround ?
                                             [UIColor colorWithWhite:.88f alpha:0.88f].CGColor :
                                             [UIColor darkGrayColor].CGColor);
        } else {
            
//            CGContextSetStrokeColorWithColor(context, darkBackGround ?
//                                             [[UIColor cyanColor] colorWithAlphaComponent:0.75f].CGColor :
//                                             [[UIColor blueColor] colorWithAlphaComponent:1.0f].CGColor);
            
            CGContextSetStrokeColorWithColor(context, darkBackGround ?
                                             [[UIColor cyanColor] colorWithAlphaComponent:0.95f].CGColor :
                                             [[UIColor blueColor] colorWithAlphaComponent:1.0f].CGColor);

        }
        
        NSUInteger  spacerCount = (sampleCount+1); // leading and trailing [ ^| ^ | ^ | ^ | ^ ]

        CGFloat spacerSize = .6f * spacerCount;
        
        if (self.recording)
            spacerSize = .97f * spacerCount;
        else {
            // playback
            
            if (_scale > 2.6) {
                spacerSize = 1.2f * spacerCount;
            } else if (_scale > 1.8) {
               spacerSize = .98f * spacerCount;
            } else if (_scale > 1.2) {
                spacerSize = .90f * spacerCount;
            } else {
                if (_scale < 0.49) {
                    spacerSize = .52f * spacerCount;
                } else if (_scale < 0.9) {
                    spacerSize = .67f * spacerCount;
                } else {
                    // drop thru value
                    spacerSize = .88f * spacerCount;
                }
            }
        }
        
        
        CGFloat width = CGRectGetWidth(self.bounds);
        
        barWidth = (width - spacerSize) / sampleCount;

//        if (mirror)
//            barWidth = barWidth * .85f;
        //CGFloat yDrawline = onCenter ? center.y : 0.00f;
        
        CGContextSetLineWidth(context, barWidth);
        NSUInteger sampleNumber = 0;
        CGFloat fcount = sampleCount;
        
        if (self.samplingOptions & SamplingOptionDualChannel) {
            
            // use 2 channels channel 1 top

            // Assumes mirrired is NO
            // Channel1
            for (NSNumber *sample in self.scaledSamples) {
                
                sampleNumber++;
                CGFloat sampleValue = [sample floatValue] * effectiveHeight;
                if ([sample floatValue] < 0.050) {
                    sampleValue = 0.05f * effectiveHeight;
                }
                
                CGFloat markPoint  =  sampleNumber/fcount * width - (1.0/fcount * width)/2 ;
                
                if (onCenter) {
                    CGContextMoveToPoint(context, markPoint, center.y);
                    CGContextAddLineToPoint(context, markPoint,center.y - sampleValue);

//                    CGContextMoveToPoint(context, markPoint , center.y - sampleValue );
//                    CGContextAddLineToPoint(context, markPoint, center.y);

//                    if (mirror)
//                        CGContextAddLineToPoint(context, markPoint, center.y + sampleValue);
                    
                } else {
                    CGContextMoveToPoint(context, markPoint , effectiveHeight);
                    CGContextAddLineToPoint(context, markPoint, sampleValue);
                }
                
                
                CGContextStrokePath(context);
            }
            
            for (NSNumber *sample in self.samples2) {
                
                sampleNumber++;
                CGFloat sampleValue = [sample floatValue] * effectiveHeight;
                if ([sample floatValue] < 0.050) {
                    sampleValue = 0.05f * effectiveHeight;
                }
                
                CGFloat markPoint  =  sampleNumber/fcount * self.bounds.size.width - (1.0/fcount * self.bounds.size.width)/2 ;
                
                if (onCenter) {
                    CGContextMoveToPoint(context, markPoint, center.y);
                    CGContextAddLineToPoint(context, markPoint,center.y + sampleValue);

//                    CGContextMoveToPoint(context, markPoint , center.y - sampleValue );
//                    CGContextAddLineToPoint(context, markPoint, center.y + sampleValue);

//                    if (mirror)
//                    else
//                        CGContextAddLineToPoint(context, markPoint, center.y);
                    
                } else {
                    CGContextMoveToPoint(context, markPoint , effectiveHeight);
                    CGContextAddLineToPoint(context, markPoint, sampleValue);
                }
                
                CGContextStrokePath(context);
            }

            
        } else {
            // Just one channel
            for (NSNumber *sample in self.scaledSamples) {
                
                sampleNumber++;
                CGFloat sampleValue = [sample floatValue] * effectiveHeight;
                if ([sample floatValue] < 0.050) {
                    sampleValue = 0.05f * effectiveHeight;
                }
                
                CGFloat markPoint  =  sampleNumber/fcount * self.bounds.size.width - (1.0/fcount * self.bounds.size.width)/2 ;
                
                if (onCenter) {
                    CGContextMoveToPoint(context, markPoint , center.y - sampleValue );
                    
                    if (mirror)
                        CGContextAddLineToPoint(context, markPoint, center.y + sampleValue);
                    else
                        CGContextAddLineToPoint(context, markPoint, center.y);
                    
                } else {
                    CGContextMoveToPoint(context, markPoint , effectiveHeight);
                    CGContextAddLineToPoint(context, markPoint, sampleValue);
                }
                
                CGContextStrokePath(context);
            }
        }
        
    }
    
    //Draw it
    
//    [super drawRect:rect];
    
}

@end


//    // Draw a line
//    //Start at this point
//    CGContextMoveToPoint(context, 10.0, 30.0);
//
//    //Give instructions to the CGContext
//    //(move "pen" around the screen)
//    CGContextAddLineToPoint(context, 310.0, 30.0);
//    CGContextAddLineToPoint(context, 310.0, 90.0);
//    CGContextAddLineToPoint(context, 10.0, 90.0);


