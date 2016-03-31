//
//  JWScrubber.h
//  JamWIthT
//
//  co-created by joe and brendan kerr on 10/24/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#ifndef JWScrubber_h
#define JWScrubber_h

typedef NS_OPTIONS(NSInteger, SamplingOptions) {
    SamplingOptionNone                = 1 << 0, // bits: 0001
    SamplingOptionDualChannel         = 1 << 1, // bits: 0100
    SamplingOptionNoAverages          = 1 << 2, // bits: 0100
    SamplingOptionCollectPulseData    = 1 << 3  // bits: 0100
};

typedef NS_ENUM(NSInteger, ScrubberViewOptions) {
    ScrubberViewOptionNone     =1,
    ScrubberViewOptionDisplayLabels,
    ScrubberViewOptionDisplayOnlyValueLabels,
    ScrubberViewOptionDisplayFullView,
    ScrubberViewOptionsDisplayInCameraView
};

typedef NS_ENUM(NSInteger, SampleSize) {
    SampleSizeMin = 1,
    SampleSize4,
    SampleSize6,
    SampleSize8,
    SampleSize10,
    SampleSize14,
    SampleSize18,
    SampleSize24,
    SampleSizeMax
};

//Visual audiobuffer  VAB_OPTIONS

typedef NS_ENUM(NSInteger, VABKindOptions) {
    VABOptionNone = 1,
    VABOptionCenter,
    VABOptionCenterMirrored,
    VABOptionSingleChannelTopDown,
    VABOptionSingleChannelBottomUp,
};

//Visual audiobuffer  Layout options

typedef NS_OPTIONS(NSInteger, VABLayoutOptions) {
    VABLayoutOptionNone                = 1 << 0,
    VABLayoutOptionShowAverageSamples  = 1 << 1,
    VABLayoutOptionShowHashMarks       = 1 << 2,
    VABLayoutOptionStackAverages       = 1 << 3,
    VABLayoutOptionOverlayAverages     = 1 << 4,
    VABLayoutOptionShowCenterLine      = 1 << 5
};

extern const NSString *JWColorScrubberTopPeak;
extern const NSString *JWColorScrubberBottomPeak;
extern const NSString *JWColorScrubberTopPeakNoAvg;
extern const NSString *JWColorScrubberBottomPeakNoAvg;
extern const NSString *JWColorScrubberTopAvg;
extern const NSString *JWColorScrubberBottomAvg;


extern const NSString *JWColorBackgroundHueColor;
extern const NSString *JWColorBackgroundHueGradientColor1;
extern const NSString *JWColorBackgroundHueGradientColor2;
extern const NSString *JWColorBackgroundTrackGradientColor1;
extern const NSString *JWColorBackgroundTrackGradientColor2;
extern const NSString *JWColorBackgroundTrackGradientColor3;
extern const NSString *JWColorBackgroundHeaderGradientColor1;
extern const NSString *JWColorBackgroundHeaderGradientColor2;



#endif /* JWScrubber_h */



/*
 
 The Visual Audio View shows peak samples in the audio
 
 averages may be collected as well
 
 ConfigOptions are use when collecting sample information
 VABKindOptions are VABLayoutOptions are for the visual presentation

 
 == Layout Options
 
 When averages are collected as well
 VABLayoutOptionShowAverageSamples will try to display averages if they are provided,
 but if  ~configOptionNoAverages is set they will not be collected
 VABLayoutOptionShowAverageSamples is set for both channels in when configOptionDualChannel is used
 for both channels and cannot be set for one
 
 configOptionNoAverages and VABLayoutOptionShowAverageSamples and there are averages available
 
 JWColorScrubberTopPeakNoAvg    USED
 JWColorScrubberTopPeak         NOT USED
 JWColorScrubberTopAvg          NOT USED
 
 
 ~configOptionNoAverages or ~VABLayoutOptionShowAverageSamples
 
 JWColorScrubberTopPeakNoAvg    NOT USED
 JWColorScrubberTopPeak         USED
 JWColorScrubberTopAvg          USED

 The design point behind this color scheme is that 
 
 
 There are two options OVERLAY and STACK

 VABLayoutOptionOverlayAverages
 Overlay will draw one line (the peak) first, then on top of that from the origin
 the avergae is drawn (with alphas the peak color is revealed underneath)
 
 The peak sample will always be bigger as it is part of the averages sample set
 VABLayoutOptionStackAverages
 
 By stacking, a line is drawn from origin to avg height, then a second line is drawn from that point up to the 
 peak (with alphas the background is revealed beneath the avg as well as peak)

 
 VABLayoutOptionOverlayAverages function is used by default is neither 
 VABLayoutOptionStackAverages nor VABLayoutOptionOverlayAverages are set
 
 
 == Kind Options (Type of Visual audio buffer)
 
 VABOptionCenter - centers origin in track 
 displays channel1 peaks on top, center up, from origin up to half the size of track
 displays channel2 peaks on bottom, center down
 
 VABOptionCenterMirrored - similar to center, but only uses channel1
 displays channel1 peaks on top, center up
 displays channel1 peaks on bottom, center down
 
 VABOptionSingleChannelTopDown - origin at top of view
 displays channel1 peaks, from origin down to the size of the track
 
 VABOptionSingleChannelBottomUp - origin at top of view
 displays channel1 peaks, from origin up to the size of the track
 
 
 
 == Config Options for sampling
 
 configOptionNone
 configOptionMirrored - not used should be deleted, use VABOptionCenterMirrored KindOption
 configOptionDualChannel
 

 
 
 
 */


