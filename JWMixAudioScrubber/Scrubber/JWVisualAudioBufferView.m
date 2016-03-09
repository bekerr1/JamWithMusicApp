//
//  VisualAudioBufferView.m
//  AVAEMixerSample
//
//  Created by JOSEPH KERR on 9/19/15.
//  Copyright (c) 2015 apple. All rights reserved.
//

#import "JWVisualAudioBufferView.h"


@interface JWVisualAudioBufferView (){
 CGColorRef _colorTopPeak;
 CGColorRef _colorTopAvg;
 CGColorRef _colorTopNoAvg;
 CGColorRef _colorBottomPeak;
 CGColorRef _colorBottomAvg;
 CGColorRef _colorBottomNoAvg;
    CGFloat _panValue;  // -1.0  1.0
    CGFloat _outputValue;  // volume  0.0 - 1.0
}
@end


@implementation JWVisualAudioBufferView

-(instancetype)initWithSamples:(NSArray*)samples1 samples2:(NSArray*)samples2 samplingOptions:(SamplingOptions)options {
    if (self = [super init]) {
        self.samples = samples1;
        self.samples2 = samples2;
        self.samplingOptions = options;
        self.kindOptions = VABOptionNone;
        self.layoutOptions = VABLayoutOptionNone;
        _panValue = 0.0;
        _outputValue = 1.0;
    }
    return self;
}

-(void) dealloc
{
//    NSLog(@"%s",__func__);
    if (_notifString)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:_notifString object:nil];
    }
}


-(void)die {

    [UIView animateWithDuration:0.25 delay:0.00 options:UIViewAnimationOptionCurveLinear animations:^{
        self.alpha = 0.0;
    } completion:^(BOOL fini){
        [self removeFromSuperview];
    }];

}

-(void)setTimeToLive:(NSTimeInterval)timeToLive {
    
    [NSTimer scheduledTimerWithTimeInterval:timeToLive target:self selector:@selector(die) userInfo:nil repeats:NO];
    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeToLive * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [UIView animateWithDuration:0.25 delay:0.10 options:UIViewAnimationOptionCurveLinear animations:^{
//            self.alpha = 0.0;
//        } completion:^(BOOL fini){
//            [self removeFromSuperview];
//        }];
//    });
}

-(void)setNotifString:(NSString *)notifString
{
    if (_notifString)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:_notifString object:nil];
    }

    _notifString = notifString;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notif:) name:_notifString object:nil];
}

-(void)notif:(NSNotification*)noti
{
    id obj;
    obj = noti.userInfo[@"alpha"];
    if (obj) {
        self.alpha = [obj floatValue];
    }
    BOOL needsDisplay = NO;
    obj = noti.userInfo[@"colors"];
    if (obj) {
        [self configureColors:obj];
        needsDisplay = YES;
    }
    obj = noti.userInfo[@"layout"];
    if (obj) {
        self.layoutOptions = [obj unsignedIntegerValue];
        needsDisplay = YES;
    }
    obj = noti.userInfo[@"kind"];
    if (obj) {
        self.kindOptions = [obj unsignedIntegerValue];
        needsDisplay = YES;
    }
    obj = noti.userInfo[@"pan"];
    if (obj) {
        _panValue = [obj floatValue];
        needsDisplay = YES;
    }
    obj = noti.userInfo[@"volume"];
    if (obj) {
        _outputValue = [obj floatValue];
        needsDisplay = YES;
    }

    obj = noti.userInfo[@"remove"];
    if (obj) {
        float removeDuration = [obj floatValue];
        
        id removeDelayValue = noti.userInfo[@"removeDelay"];
        float removeDelay = 0.0;
        if (removeDelayValue)
            removeDelay = [removeDelayValue floatValue];
        
        if (removeDelay > 0.0) {
            double delayInSecs = removeDelay;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSecs * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:removeDuration animations:^{
                    self.alpha = 0.0;
                } completion:^(BOOL fini){
                    [self removeFromSuperview];
                }];
            });
        } else if (removeDuration > 0.0){
            [UIView animateWithDuration:removeDuration animations:^{
                self.alpha = 0.0;
            } completion:^(BOOL fini){
                [self removeFromSuperview];
            }];
        } else {
            [self removeFromSuperview];
        }
        needsDisplay = NO;
    }
    
    if (needsDisplay)
        [self setNeedsDisplay];
}

-(void)configureColors:(NSDictionary*)trackColors {
    id colorSpec;
    
    // TOP peak
    colorSpec = nil;
    if (trackColors)
        colorSpec = trackColors[JWColorScrubberTopPeak];
    if (colorSpec){
        _colorForTopPeak = (UIColor*)colorSpec;
    }
    // BOTTOM peak
    colorSpec = nil;
    if (trackColors)
        colorSpec = trackColors[JWColorScrubberBottomPeak];
    if (colorSpec) {
        _colorForBottomPeak = (UIColor*)colorSpec;
    }
    // TOP average
    colorSpec = nil;
    if (trackColors)
        colorSpec = trackColors[JWColorScrubberTopAvg];
    
    if (colorSpec) {
        _colorForTopAvg = (UIColor*)colorSpec;
    }
    // BOTTOM average
    colorSpec = nil;
    if (trackColors)
        colorSpec = trackColors[JWColorScrubberBottomAvg];
    
    if (colorSpec) {
        _colorForBottomAvg = (UIColor*)colorSpec;
    }
    // TOP peak no average
    colorSpec = nil;
    if (trackColors)
        colorSpec = trackColors[JWColorScrubberTopPeakNoAvg];
    
    if (colorSpec) {
        _colorForTopNoAvg = (UIColor*)colorSpec;
    }
    // BOTTOM peak no average
    colorSpec = nil;
    if (trackColors)
        colorSpec = trackColors[JWColorScrubberBottomPeakNoAvg];
    if (colorSpec) {
        _colorForBottomNoAvg = (UIColor*)colorSpec;
    }
    
    [self configureColors];
}



-(void)configureColors {
    
    if (self.colorForBottomPeak == nil) {
        _colorForBottomPeak = _colorForTopPeak;
    }
    
    if (self.colorForBottomAvg == nil) {
        _colorForBottomAvg = _colorForTopAvg;
    }


    if (self.colorForBottomNoAvg == nil) {
        if (_layoutOptions | ~VABLayoutOptionShowAverageSamples) {
            self.colorForBottomNoAvg = _colorForBottomPeak;
        } else {
            // default
            _colorForBottomNoAvg = _colorForTopNoAvg;
        }
    }

    _colorTopPeak = _colorForTopPeak.CGColor;
    _colorTopAvg = _colorForTopAvg.CGColor;
    _colorTopNoAvg = _colorForTopNoAvg.CGColor;
    _colorBottomPeak = _colorForBottomPeak.CGColor;
    _colorBottomAvg = _colorForBottomAvg.CGColor;
    _colorBottomNoAvg = _colorForBottomNoAvg.CGColor;
}


//    if (self.colorForTopPeak == nil){
//        _colorForTopPeak = _darkBackGround ?
//        [UIColor colorWithWhite:1.0 alpha:0.8] :
//        [[UIColor blueColor] colorWithAlphaComponent:1.0f];
//    }
//    if (self.colorForTopAvg == nil){
//        if (self.recording) {
//            self.colorForTopAvg = _darkBackGround ?
//            [UIColor colorWithWhite:1.0 alpha:0.50] :
//            [[UIColor blueColor] colorWithAlphaComponent:1.0f];
//        } else {
//            self.colorForTopAvg = _darkBackGround ?
//            [UIColor colorWithWhite:1.0 alpha:0.50] :
//            [[UIColor blueColor] colorWithAlphaComponent:1.0f];
//        }
//    }
//    if (self.colorForTopNoAvg == nil) {
//        // no color set
//        if (_layoutOptions | ~VABLayoutOptionShowAverageSamples) {
//            // Show averages not set use topPeak
//            self.colorForTopNoAvg = _colorForTopPeak;
//        } else {
//            // default
//            self.colorForTopNoAvg = _darkBackGround ?
//            [UIColor colorWithWhite:1.0 alpha:0.95] :
//            [[UIColor blueColor] colorWithAlphaComponent:1.0f];
//        }
//    }


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.

- (void)drawRect:(CGRect)rect {
    
    if (self.samples == nil) {
        NSLog(@"%s ERROR no samples",__func__);
        return;  // <<=== returns
        //NO Samples no draw
    }

    BOOL mirror = NO;
    BOOL onCenter = NO;
    
    if (_kindOptions == VABOptionCenterMirrored)
    {
        mirror = YES;
    }
    if (_kindOptions == VABOptionCenter || _kindOptions == VABOptionNone)
    {
        onCenter = YES;;
    }
    if (_kindOptions == VABOptionSingleChannelBottomUp || _kindOptions == VABOptionSingleChannelTopDown)
    {
        onCenter = NO;
        mirror = NO;
    }

    [self configureColors];
    
    // Setup some foundation paramaters by which the rest of draw code will use
    
    CGFloat barWidth = 4.0f;
    CGPoint center = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
    
    CGFloat effectiveHeight = 0.0f;
    
    if (onCenter) {
        // Center needs divide by 2
        effectiveHeight =  self.frame.size.height/2 * 0.94f;  // padding
    } else {
        effectiveHeight =  self.frame.size.height * 0.94f;  // padding
    }

    NSUInteger sampleCount = [self.samples count];
    NSUInteger spacerCount = (sampleCount+1); // leading and trailing [ ^| ^ | ^ | ^ | ^ ]
    CGFloat spacerSize = .6f * spacerCount;
    CGFloat width = CGRectGetWidth(self.bounds);
    barWidth = (width - spacerSize) / sampleCount;
    if (barWidth < 0.1) {
//        barWidth = 0.7;
        barWidth = 0.9;

    }

    // LETS START DRAWING
    
    //Get the CGContext from this view and save the state
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CGContextSetLineWidth(context, barWidth);
    
    CGContextSetLineCap (context,kCGLineCapRound);
    CGFloat fcount = sampleCount;

    // PAN FACTOR which incorporates _outputVolume will reduce height by a fraction of
    // panning causes output of sample on oppostit channel to be reduced
    CGFloat panFactorTop = 1.0; // left
    CGFloat panFactorBottom = 1.0; // right
    if ( _samplingOptions & SamplingOptionDualChannel &&
        !( _kindOptions == VABOptionSingleChannelBottomUp || _kindOptions == VABOptionSingleChannelTopDown ))
    {
        if (_panValue > 0.0) {
            // channel 2 boost bottom
            panFactorTop = 1.0 - _panValue;   // 1.0 - 0.2 = 0.8    - 0.3 = 0.7
            panFactorBottom = 1.0; // - panFactorTop;
        } else if (_panValue < 0.0) {
            // channel 1 boost top
            panFactorBottom = 1.0 + _panValue;   // - 0.2  + 1.0 = 0.8   - 0.3 = 0.7
            panFactorTop = 1.0; // - panFactorBottom;
        }
    }
    panFactorBottom *= _outputValue;
    panFactorTop *= _outputValue;
    
    // For two channels - channel 1 top
    // Assumes mirrired is NO - already has top and bottom info
    
    // Channel 1 - iterate  through samples stored in _samples array
    
    NSUInteger sampleNumber = 0;
    NSUInteger index = 0;
    
    for (NSNumber *sample in self.samples) {
        
        sampleNumber++; // 1 based
        
        CGFloat markPoint  =  sampleNumber/fcount * width - (1.0/fcount * width)/2 ;
        
        CGFloat sampleValue = [sample floatValue] * effectiveHeight;
        
        
        // IF we are configured to display abg samples and we do do have average samples
        
        if (_layoutOptions & VABLayoutOptionShowAverageSamples  && self.samplesAverages ) {
            
            // in the iteration over each sample we use indes to obtain the associated avgSample
            
            NSNumber *avgSample = _samplesAverages[index++];
            CGFloat avgSampleValue= [avgSample floatValue] * effectiveHeight;
            
            // avg is always shorter
            
            if (_layoutOptions & VABLayoutOptionStackAverages) {
                
                // STACK - draw in two strokes,  avg in one and the peak in another stroke
                
//                CGFloat differenceFromPeak = (sampleValue - avgSampleValue) * panFactorTop;
                
                if ([sample floatValue] < 0.05) {
                    sampleValue = 0.05f * effectiveHeight;
                    avgSampleValue = 0.05f * effectiveHeight;
//                    differenceFromPeak = 0.0000f;
                }
                
                // STEP 1 First Stroke Draw the top average to peak
                
                CGFloat sampleValueDrawHeight = (sampleValue - avgSampleValue) * panFactorTop;
                
                // With drawheight set compute the start and end points Y
                CGFloat yStart = 0;
                if (onCenter) {
                    yStart = center.y - avgSampleValue * panFactorTop;
                } else if (_kindOptions == VABOptionSingleChannelTopDown) {
                    yStart = 0 +  avgSampleValue * panFactorTop;
                } else if (_kindOptions == VABOptionSingleChannelBottomUp) {
                    yStart = effectiveHeight - avgSampleValue * panFactorTop;
                }
                
                // Endpoint.y drawing the top half from center subtract value, BottomUp sames as center
                
                CGFloat yEnd = 0;
                if (_kindOptions == VABOptionSingleChannelTopDown) {
                    yEnd = yStart + sampleValueDrawHeight;
                } else {
                    // bottom and center
                    yEnd = yStart - sampleValueDrawHeight;
                }
                
                CGPoint startp = CGPointMake(markPoint, yStart);
                CGPoint endp = CGPointMake(markPoint, yEnd);
                
                CGContextMoveToPoint(context, startp.x, startp.y);
                CGContextAddLineToPoint(context, endp.x, endp.y);
                CGContextSetStrokeColorWithColor(context, _colorTopPeak);
                CGContextStrokePath(context);
                
                
                // STEP 2 Second Stroke Draw the avg
                
                sampleValueDrawHeight = avgSampleValue  * panFactorTop;
                
                // With drawheight set compute the start and end points Y
                
                yStart = 0;
                if (onCenter) {
                    yStart = center.y;
                } else if (_kindOptions == VABOptionSingleChannelTopDown) {
                    yStart = 0;
                } else if (_kindOptions == VABOptionSingleChannelBottomUp) {
                    yStart = effectiveHeight;
                }
                
                // Endpoint.y drawing the top half from center subtract value, BottomUp sames as center
                
                if (_kindOptions == VABOptionSingleChannelTopDown) {
                    yEnd = yStart + sampleValueDrawHeight;
                } else {
                    // bottom and center
                    yEnd = yStart - sampleValueDrawHeight;
                }
                
                startp = CGPointMake(markPoint, yStart);
                endp = CGPointMake(markPoint, yEnd);
                CGContextMoveToPoint(context, startp.x, startp.y);
                CGContextAddLineToPoint(context, endp.x, endp.y);
                CGContextSetStrokeColorWithColor(context, _colorTopAvg);
                CGContextStrokePath(context);
                
            } else {
                
                // OVERLAY - DRAW The peak first and the avg overlay on top
                
                if ([sample floatValue] < 0.05) {
                    sampleValue = 0.05f * effectiveHeight;
                    avgSampleValue = 0.05f * effectiveHeight;
                }
                
                // STEP 1 First Stroke Draw the peak
                
                CGFloat sampleValueDrawHeight = sampleValue  * panFactorTop;
                
                // With drawheight set compute the start and end points Y

                CGFloat yStart = 0;
                if (onCenter) {
                    yStart = center.y;
                } else if (_kindOptions == VABOptionSingleChannelTopDown) {
                    yStart = 0;
                } else if (_kindOptions == VABOptionSingleChannelBottomUp) {
                    yStart = effectiveHeight;
                }
                
                // Endpoint.y drawing the top half from center subtract value, BottomUp sames as center
                
                CGFloat yEnd = 0;
                if (_kindOptions == VABOptionSingleChannelTopDown) {
                    yEnd = yStart + sampleValueDrawHeight;
                } else {
                    // bottom and center
                    yEnd = yStart - sampleValueDrawHeight;
                }
                
                CGPoint startp = CGPointMake(markPoint, yStart);
                CGPoint endp = CGPointMake(markPoint, yEnd);
                CGContextMoveToPoint(context, startp.x, startp.y);
                CGContextAddLineToPoint(context, endp.x, endp.y);
                CGContextSetStrokeColorWithColor(context, _colorTopPeak);
                CGContextStrokePath(context);
                
                
                // STEP 2 Second Stroke Draw the avg
                // Start draw height at the sample value
                
                sampleValueDrawHeight = avgSampleValue  * panFactorTop;
                
                // With drawheight set compute the start and end points Y
                // Same yStart
                // Endpoint.y drawing the top half from center subtract value, BottomUp sames as center
                
                if (_kindOptions == VABOptionSingleChannelTopDown) {
                    yEnd = yStart + sampleValueDrawHeight;
                } else {
                    // bottom and center
                    yEnd = yStart - sampleValueDrawHeight;
                }
                
                startp = CGPointMake(markPoint, yStart);
                endp = CGPointMake(markPoint, yEnd);
                
                CGContextMoveToPoint(context, startp.x, startp.y);
                CGContextAddLineToPoint(context, endp.x, endp.y);
                CGContextSetStrokeColorWithColor(context, _colorTopAvg);
                CGContextStrokePath(context);
            }
            
            // END Average samples
            
        } else {
            
            // DO NOT Draw Averages just Samples - One Step
            
            if ([sample floatValue] < 0.05) {
                sampleValue = 0.05f * effectiveHeight;
            }
            
            CGFloat sampleValueDrawHeight = sampleValue  * panFactorTop;
            
//            NSLog(@"draw height %.2f",sampleValueDrawHeight);

            CGFloat yStart = 0;
            if (onCenter) {
                yStart = center.y;
            } else if (_kindOptions == VABOptionSingleChannelTopDown) {
                yStart = 0;
            } else if (_kindOptions == VABOptionSingleChannelBottomUp) {
                yStart = effectiveHeight;
            } else {
                // assume bottom up
                yStart = effectiveHeight;
            }
            
            CGFloat yEnd = 0;
            if (_kindOptions == VABOptionSingleChannelTopDown) {
                yEnd = yStart + sampleValueDrawHeight;
            } else {
                // bottom and center
                yEnd = yStart - sampleValueDrawHeight;
            }
            
            CGPoint startp = CGPointMake(markPoint, yStart);
            CGPoint endp = CGPointMake(markPoint, yEnd);
            CGContextMoveToPoint(context, startp.x, startp.y);
            CGContextAddLineToPoint(context, endp.x, endp.y);
            CGContextSetStrokeColorWithColor(context, _colorTopNoAvg);
            CGContextStrokePath(context);
            
        }
        
    }  // end for each Sample
    
    // Done with TOP
    
    // Done with first channel
    
    

    // Proceed to Bottom Channel 2 if dual channel set and does not SingleChannel override  bottom or top
    
    BOOL proccedWithSecondChannel = NO;
    
    if ( _samplingOptions & SamplingOptionDualChannel) {
        proccedWithSecondChannel = YES;

        if ( _kindOptions == VABOptionSingleChannelBottomUp || _kindOptions == VABOptionSingleChannelTopDown ) {
            // Overrides whether channel 2 data exists or not
            // we do not want to show the info
            proccedWithSecondChannel = NO;
        }
    }
    
    
    if ( proccedWithSecondChannel ) {
        
        // BEGIN Bottom Channel2
        
        index   = 0;
        sampleNumber = 0;
        
        // Iterate sampls2 array for channel two samples
        
        for (NSNumber *sample in self.samples2) {
            
            sampleNumber++; // 1 based
            
            CGFloat markPoint  =  sampleNumber/fcount * width - (1.0/fcount * width)/2 ;
            CGFloat sampleValue = [sample floatValue] * effectiveHeight;
            
            // IF we are configured to display avg samples and we do do have average samples channel 2
            
            if (_layoutOptions & VABLayoutOptionShowAverageSamples  && self.samplesAverages2 ) {
                
                
                // Draw Averages with Samples

                // in the iteration over each sample we use indes to obtain the associated avgSample
                
                NSNumber *avgSample = _samplesAverages2[index++];
                
                CGFloat avgSampleValue = [avgSample floatValue] * effectiveHeight;
                
                // avg is always shorter
                
                // We have the sampleValue andthe avgSample value for channel2 - draw it
                
                if (_layoutOptions & VABLayoutOptionStackAverages) {
                    
                    // STACK - draw in two strokes,  avg in one and the peak in another stroke
                    
                    //CGFloat differenceFromPeak = (sampleValue - avgSampleValue) * panFactorBottom;
                    
                    if ([sample floatValue] < 0.05) {
                        sampleValue = 0.05f * effectiveHeight;
                        avgSampleValue = 0.05f * effectiveHeight;
//                        differenceFromPeak = 0.0000f;
                    }
                    
                    
                    // STEP 1 First Stroke Draw the top average to peak
                    
                    CGFloat sampleValueDrawHeight = (sampleValue - avgSampleValue) * panFactorBottom;
                    
                    // With drawheight set compute the start and end points Y
                    
                    CGFloat yStart = 0;
                    if (onCenter) {
                        yStart = center.y + avgSampleValue * panFactorBottom;
                    } else if (_kindOptions == VABOptionSingleChannelTopDown) {
                        yStart = 0 +  avgSampleValue * panFactorBottom;
                    } else if (_kindOptions == VABOptionSingleChannelBottomUp) {
                        yStart = effectiveHeight - avgSampleValue * panFactorBottom;
                    }
                    
                    // Endpoint.y drawing the bottom half from center add value TopDown same as center
                    
                    CGFloat yEnd = 0;
                    if (_kindOptions == VABOptionSingleChannelBottomUp) {
                        yEnd = yStart - sampleValueDrawHeight;
                    } else {
                        // top and center
                        yEnd = yStart + sampleValueDrawHeight;
                    }
                    
                    CGPoint startp = CGPointMake(markPoint, yStart);
                    CGPoint endp = CGPointMake(markPoint, yEnd);
                    CGContextMoveToPoint(context, startp.x, startp.y);
                    CGContextAddLineToPoint(context, endp.x, endp.y);
                    CGContextSetStrokeColorWithColor(context, _colorBottomPeak);
                    CGContextStrokePath(context);
                    
                    
                    // STEP 2 Second Stroke Draw the avg
                    // Start draw height at the sample value
                    
                    sampleValueDrawHeight = avgSampleValue  * panFactorBottom;
                    
                    // With drawheight set compute the start and end points Y
                    
                    yStart = 0;
                    if (onCenter) {
                        yStart = center.y;
                    } else if (_kindOptions == VABOptionSingleChannelTopDown) {
                        yStart = 0;
                    } else if (_kindOptions == VABOptionSingleChannelBottomUp) {
                        yStart = effectiveHeight;
                    }
                    
                    // Endpoint.y drawing the bottom half from center add value TopDown same as center
                    
                    if (_kindOptions == VABOptionSingleChannelBottomUp) {
                        yEnd = yStart - sampleValueDrawHeight;
                    } else {
                        // top and center
                        yEnd = yStart + sampleValueDrawHeight;
                    }
                    
                    startp = CGPointMake(markPoint, yStart);
                    endp = CGPointMake(markPoint, yEnd);
                    CGContextMoveToPoint(context, startp.x, startp.y);
                    CGContextAddLineToPoint(context, endp.x, endp.y);
                    CGContextSetStrokeColorWithColor(context, _colorBottomAvg);
                    CGContextStrokePath(context);
                    
                } else {
                    
                    // OVERLAY (the default) - DRAW The peak first and the avg overlay on top
                    
                    if ([sample floatValue] < 0.05) {
                        sampleValue = 0.05f * effectiveHeight;
                        avgSampleValue = 0.05f * effectiveHeight;
                    }
                    
                    // STEP 1 First Stroke Draw the peak
                    
                    CGFloat sampleValueDrawHeight = sampleValue  * panFactorBottom;
                    
                    // With drawheight set compute the start and end points Y
                    
                    CGFloat yStart = 0;
                    if (onCenter) {
                        yStart = center.y;
                    } else if (_kindOptions == VABOptionSingleChannelTopDown) {
                        yStart = 0;
                    } else if (_kindOptions == VABOptionSingleChannelBottomUp) {
                        yStart = effectiveHeight;
                    }
                    
                    // Endpoint.y drawing the bottom half from center add value TopDown same as center
                    
                    CGFloat yEnd = 0;
                    if (_kindOptions == VABOptionSingleChannelBottomUp) {
                        yEnd = yStart - sampleValueDrawHeight;
                    } else {
                        // top and center
                        yEnd = yStart + sampleValueDrawHeight;
                    }
                    
                    CGPoint startp = CGPointMake(markPoint, yStart);
                    CGPoint endp = CGPointMake(markPoint, yEnd);
                    CGContextMoveToPoint(context, startp.x, startp.y);
                    CGContextAddLineToPoint(context, endp.x, endp.y);
                    CGContextSetStrokeColorWithColor(context, _colorBottomPeak);
                    CGContextStrokePath(context);
                    
                    // STEP 2 Second Stroke Draw the avg
                    // Start draw height at the sample value
                    
                    sampleValueDrawHeight = avgSampleValue  * panFactorBottom;
                    
                    // With drawheight set compute the start and end points Y
                    // Same yStart
                    // Endpoint.y drawing the bottom half from center add value TopDown same as center
                    
                    if (_kindOptions == VABOptionSingleChannelBottomUp) {
                        yEnd = yStart - sampleValueDrawHeight;
                    } else {
                        // top and center
                        yEnd = yStart + sampleValueDrawHeight;
                    }
                    
                    startp = CGPointMake(markPoint, yStart);
                    endp = CGPointMake(markPoint, yEnd);
                    CGContextMoveToPoint(context, startp.x, startp.y);
                    CGContextAddLineToPoint(context, endp.x, endp.y);
                    CGContextSetStrokeColorWithColor(context, _colorBottomAvg);
                    CGContextStrokePath(context);
                }
                
                // END Average samples channel 2
                
            } else {
                
                // DO NOT Draw Averages just Samples - One Step
                
                if ([sample floatValue] < 0.05) {
                    sampleValue = 0.05f * effectiveHeight;
                }
                
                CGFloat sampleValueDrawHeight = sampleValue  * panFactorBottom;
                
                // With drawheight set compute the start and end points Y
                
                CGFloat yStart = 0;
                if (onCenter) {
                    yStart = center.y;
                } else if (_kindOptions == VABOptionSingleChannelTopDown) {
                    yStart = 0;
                } else if (_kindOptions == VABOptionSingleChannelBottomUp) {
                    yStart = effectiveHeight;
                }
                
                // Endpoint.y drawing the bottom half from center add value TopDown same as center
                
                CGFloat yEnd = 0;
                if (_kindOptions == VABOptionSingleChannelBottomUp) {
                    yEnd = yStart - sampleValueDrawHeight;
                } else {
                    // top and center
                    yEnd = yStart + sampleValueDrawHeight;
                }
                
                CGPoint startp = CGPointMake(markPoint, yStart);
                CGPoint endp = CGPointMake(markPoint, yEnd);
                CGContextMoveToPoint(context, startp.x, startp.y);
                CGContextAddLineToPoint(context, endp.x, endp.y);
                CGContextSetStrokeColorWithColor(context, _colorBottomNoAvg);
                CGContextStrokePath(context);
            }
            
        }  // end for each Sample nsamples2
        
        // Done with BOTTOM
        
        
    } // End proceed with second channel - Dual channel
    
    
    if (onCenter && _layoutOptions & VABLayoutOptionShowCenterLine)
    {
        CGFloat lineWidth = 1.2;
        CGContextSetLineWidth(context,lineWidth);
        CGFloat yStart = center.y;
        CGPoint startp = CGPointMake(0, yStart);
        CGRect rect = CGRectMake(startp.x, startp.y - lineWidth/2, width,lineWidth);
        CGContextClearRect(context, rect);
    }

        //        CGFloat yEnd = center.y;
        //        CGPoint endp = CGPointMake(width, yEnd);
        //        CGColorRef centerLineColor = [[UIColor blackColor] colorWithAlphaComponent:0.65].CGColor;
        //        CGContextSetStrokeColorWithColor(context, centerLineColor);
        //        CGContextMoveToPoint(context, startp.x, startp.y);
        //        CGContextAddLineToPoint(context, endp.x, endp.y);
        //        CGContextStrokePath(context);

    
    if (_layoutOptions & VABLayoutOptionShowHashMarks)
    {
//        CGColorRef hashColor = [[UIColor darkGrayColor] colorWithAlphaComponent:0.5].CGColor;
        CGColorRef hashColor = [[UIColor blackColor] colorWithAlphaComponent:0.85].CGColor;

        CGContextSetStrokeColorWithColor(context, hashColor);

        if (onCenter) {
            
            CGFloat hashHeight = 8.0;
            CGFloat lineWidth = 0.5;

            CGContextSetLineWidth(context, lineWidth);

            CGFloat yStart = center.y;
            CGFloat yEnd = yStart - hashHeight/2 ;
            CGPoint startp = CGPointMake(width/2, yStart);
            CGPoint endp = CGPointMake(width/2, yEnd);
            CGContextMoveToPoint(context, startp.x, startp.y);
            CGContextAddLineToPoint(context, endp.x, endp.y);
            CGContextStrokePath(context);
            
            // same yStart
            yEnd = yStart + hashHeight/2 ;
            startp = CGPointMake(width/2, yStart);
            endp = CGPointMake(width/2, yEnd);
            CGContextMoveToPoint(context, startp.x, startp.y);
            CGContextAddLineToPoint(context, endp.x, endp.y);
            CGContextStrokePath(context);


        } else if (_kindOptions == VABOptionSingleChannelBottomUp) {
            
            CGFloat hashHeight = 5.0;
            CGFloat lineWidth = 0.76;


            // CENTER
            CGFloat yStart = effectiveHeight;
            CGFloat yEnd = yStart - hashHeight/2 ;
            CGPoint startp = CGPointMake(width/2, yStart);
            CGPoint endp = CGPointMake(width/2, yEnd);
            CGContextMoveToPoint(context, startp.x, startp.y);
            CGContextAddLineToPoint(context, endp.x, endp.y);
            CGContextSetLineWidth(context, lineWidth);
            CGContextStrokePath(context);

            // LEFT and RIGHT

            CGContextSetLineWidth(context, lineWidth/2);

            // LEFT
            // same yStart
            // same yEnd
            startp = CGPointMake(0, yStart);
            endp = CGPointMake(0, yEnd);
            CGContextMoveToPoint(context, startp.x, startp.y);
            CGContextAddLineToPoint(context, endp.x, endp.y);
            CGContextSetLineWidth(context, lineWidth/2);
            CGContextStrokePath(context);

            // RIGHT
            // same yStart
            // same yEnd
            startp = CGPointMake(width - lineWidth/2, yStart);
            endp = CGPointMake(width - lineWidth/2, yEnd);
            CGContextMoveToPoint(context, startp.x, startp.y);
            CGContextAddLineToPoint(context, endp.x, endp.y);
            CGContextStrokePath(context);

            
        } else if (_kindOptions == VABOptionSingleChannelTopDown) {

            CGFloat hashHeight = 5.0;
            CGFloat lineWidth = 0.76;
            
            // CENTER
            CGFloat yStart = 0;
            CGFloat yEnd = yStart + hashHeight/2 ;
            CGPoint startp = CGPointMake(width/2, yStart);
            CGPoint endp   = CGPointMake(width/2, yEnd);
            CGContextMoveToPoint(context, startp.x, startp.y);
            CGContextAddLineToPoint(context, endp.x, endp.y);
            CGContextSetLineWidth(context, lineWidth);
            CGContextStrokePath(context);

            
            // LEFT and RIGHT

            CGContextSetLineWidth(context, lineWidth/2);

            // LEFT
            // same yStart
            // same yEnd
            startp = CGPointMake(0, yStart);
            endp   = CGPointMake(0, yEnd);
            CGContextMoveToPoint(context, startp.x, startp.y);
            CGContextAddLineToPoint(context, endp.x, endp.y);
            CGContextStrokePath(context);
            
            // RIGHT
            // same yStart
            // same yEnd
            startp = CGPointMake(width - lineWidth/2, yStart);
            endp   = CGPointMake(width - lineWidth/2, yEnd);
            CGContextMoveToPoint(context, startp.x, startp.y);
            CGContextAddLineToPoint(context, endp.x, endp.y);
            CGContextStrokePath(context);
        }
    
    }


    CGContextRestoreGState(context);

    
}

@end


// ------------------------------------
// CODE SNIPPETS
// ------------------------------------
//                    NSLog(@"%s %@ %@",__func__,NSStringFromCGPoint(startp),NSStringFromCGPoint(endp));
//                    NSLog(@"avg %.4f peak %.4f",avgSampleValue,sampleValue);
    //                    NSLog(@"%s %@ %@",__func__,NSStringFromCGPoint(startp),NSStringFromCGPoint(endp));
    //                    NSLog(@"%s %@ %@",__func__,NSStringFromCGPoint(startp),NSStringFromCGPoint(endp));

// ------------------------------------
// FOR REFERENCE AND REMOVAL
// ------------------------------------
