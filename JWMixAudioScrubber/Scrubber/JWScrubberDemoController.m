//
//  JWScrubberDemoController.m
//  JamWIthT
//
//  Created by JOSEPH KERR on 11/12/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import "JWScrubberDemoController.h"

@implementation JWScrubberDemoController



// BEGIN DEMOS --------------------


-(void)demoBasicBackground{
    //_scrubberController.useGradient = NO;
    //_scrubberController.backLightColor = [UIColor grayColor];
    _scrubberController.darkBackground = YES;
}


// CONFIGURATION 1

-(void)demoPlayConfiguration1
{
    /*
     A basic scrubber using defaults for colors and view setup
     */
    [_scrubberController reset];
    _scrubberController.numberOfTracks = 1;
    [_delegate updateScrubberHeight:self];
    
    [self demoBasicBackground];
    
    [_scrubberController prepareScrubberFileURL:[_delegate scrubberDemoFile1URL:self]
                                 withSampleSize:SampleSize14
                                        options:0
                                           type:0
                                         layout:0
                                   onCompletion:nil];
}

-(void)demoPlayConfiguration1c
{
    /*
     A basic scrubber using defaults for colors and view setup
     */
    
    [_scrubberController reset];
    _scrubberController.numberOfTracks = 1;
    [_delegate updateScrubberHeight:self];
    
    [self demoBasicBackground];
    
    [_scrubberController configureColors:
     @{
       JWColorScrubberTopPeakNoAvg    : [UIColor greenColor],
       }];
    
    [_scrubberController prepareScrubberFileURL:[_delegate scrubberDemoFile1URL:self]
                                 withSampleSize:SampleSize14
                                        options:0
                                           type:0
                                         layout:0
                                   onCompletion:nil];
}

-(void)demoPlayConfiguration1a
{
    /*
     A configuration with two tracks one) primary track
     and the other a player
     try running 1,2,3 and upto 4 players
     plays the same file
     in the Audio Engine, a VisualAudio Tap
     
     */
    
    [_scrubberController reset];
    _scrubberController.numberOfTracks = 1;
    [_delegate updateScrubberHeight:self];
    
    
    //    [_scrubberController prepareScrubberFileURL:[_delegate scrubberDemoFile1URL:self]
    //                                 withSampleSize:SampleSize14
    //                                        options:SamplingOptionDualChannel
    //                                           type:VABOptionNone
    //                                         layout:0
    //                                   onCompletion:nil];
    
    [_scrubberController prepareScrubberFileURL:[_delegate scrubberDemoFile1URL:self]
                                 withSampleSize:SampleSize14
                                        options:SamplingOptionDualChannel
                                           type:VABOptionNone
                                         layout:VABLayoutOptionStackAverages | VABLayoutOptionShowAverageSamples
                                         colors:@{
                                                  JWColorScrubberTopPeak : [[UIColor greenColor] colorWithAlphaComponent:0.7],
                                                  JWColorScrubberTopAvg : [UIColor colorWithWhite:0.8 alpha:0.7] ,
                                                  JWColorScrubberBottomPeak : [[UIColor yellowColor] colorWithAlphaComponent:0.7],
                                                  JWColorScrubberBottomAvg : [UIColor colorWithWhite:0.8 alpha:0.7],
                                                  }
                                   onCompletion:nil];
}


-(void)demoPlayConfiguration1b
{
    // uses different line configs
    [_scrubberController reset];
    _scrubberController.numberOfTracks = 1;
    [_delegate updateScrubberHeight:self];
    
    _scrubberController.viewOptions = ScrubberViewOptionDisplayOnlyValueLabels;
    
    [_scrubberController prepareScrubberFileURL:[_delegate scrubberDemoFile1URL:self]
                                 withSampleSize:SampleSize14
                                        options:SamplingOptionDualChannel
                                           type:VABOptionNone
                                         layout:VABLayoutOptionStackAverages | VABLayoutOptionShowAverageSamples | VABLayoutOptionShowCenterLine
                                         colors:@{
                                                  JWColorScrubberTopPeak : [[UIColor greenColor] colorWithAlphaComponent:0.7],
                                                  JWColorScrubberTopAvg : [UIColor colorWithWhite:0.8 alpha:0.7] ,
                                                  JWColorScrubberBottomPeak : [[UIColor yellowColor] colorWithAlphaComponent:0.7],
                                                  JWColorScrubberBottomAvg : [UIColor colorWithWhite:0.8 alpha:0.7],
                                                  }
                                   onCompletion:nil];
    
    //    VABLayoutOptions layoutOptions =
    //    VABLayoutOptionStackAverages | VABLayoutOptionShowAverageSamples | VABLayoutOptionShowCenterLine | VABLayoutOptionShowHashMarks;
    //
    //    [_scrubberController prepareScrubberFileURL:[_delegate scrubberDemoFile1URL:self]
    //                                 withSampleSize:SampleSize14
    //                                        options:SamplingOptionDualChannel
    //                                           type:VABOptionNone
    //                                         layout:layoutOptions
    //                                         colors:@{
    //                                                  JWColorScrubberTopPeak : [UIColor whiteColor],
    //                                                  JWColorScrubberTopAvg : [UIColor grayColor],
    //                                                  JWColorScrubberBottomPeak : [UIColor whiteColor],
    //                                                  JWColorScrubberBottomAvg : [UIColor grayColor]
    //                                                  }
    //                                   onCompletion:nil];
    
}




// CONFIGURATION2

-(void)demoPlayConfiguration2
{
    /*
     A configuration with two tracks one) primary track playing two) a listener on a tap
     in the Audio Engine, a VisualAudio Tap
     trackId
     trackidMixerTap
     */
    
    [_scrubberController reset];
    _scrubberController.numberOfTracks = 2;  // one for primary track file and one formixer tap
    [_delegate updateScrubberHeight:self];
    
    
    NSDictionary *scrubberColors =
    @{
      JWColorScrubberTopPeakNoAvg : [[UIColor whiteColor] colorWithAlphaComponent:0.8],
      JWColorScrubberTopAvg : [UIColor colorWithWhite:0.9 alpha:0.5] ,
      JWColorScrubberTopPeak : [[UIColor whiteColor] colorWithAlphaComponent:0.8],
      
      JWColorScrubberBottomPeakNoAvg : [[UIColor yellowColor] colorWithAlphaComponent:0.8],
      JWColorScrubberBottomAvg : [UIColor colorWithWhite:0.9 alpha:0.5],
      JWColorScrubberBottomPeak : [[UIColor yellowColor] colorWithAlphaComponent:0.8],
      };
    
    [_scrubberController configureColors:scrubberColors];
    
    self.scrubberPrimaryColors = scrubberColors;
    [_scrubberController setViewOptions:ScrubberViewOptionNone];
    
    [_scrubberController prepareScrubberFileURL:[_delegate scrubberDemoFile1URL:self]
                                 withSampleSize:SampleSize14
                                        options:SamplingOptionDualChannel
                                           type:VABOptionNone
                                         layout:VABLayoutOptionOverlayAverages | VABLayoutOptionShowAverageSamples
                                         colors:@{
                                                  JWColorScrubberTopPeakNoAvg : [[UIColor blueColor] colorWithAlphaComponent:0.8],
                                                  JWColorScrubberTopAvg : [UIColor colorWithWhite:0.9 alpha:0.5] ,
                                                  JWColorScrubberTopPeak : [[UIColor blueColor] colorWithAlphaComponent:0.7],
                                                  JWColorScrubberBottomPeakNoAvg : [[UIColor blueColor] colorWithAlphaComponent:0.8],
                                                  JWColorScrubberBottomAvg : [UIColor colorWithWhite:0.9 alpha:0.5],
                                                  JWColorScrubberBottomPeak : [[UIColor blueColor] colorWithAlphaComponent:0.7],
                                                  }
                                   onCompletion:nil];
    
    // ADD A TAP to mixer for playAlll
    NSString *trackidMixerTap =
    [_scrubberController prepareScrubberListenerSource:[_delegate scrubberBufferController:self]
                                        withSampleSize:SampleSize14
                                               options:SamplingOptionDualChannel
                                                  type:VABOptionNone
                                                layout:VABLayoutOptionStackAverages
                                          onCompletion:nil];
    
//    [_audioEngine registerController:_scrubberController withTrackId:trackidMixerTap forPlayerRecorder:@"mixer"];
    
    [_delegate scrubberDemoController:self registerController:_scrubberController withTrackId:trackidMixerTap];

}

// CONFIGURATION3

-(void)demoPlayConfiguration3
{
    /*
     RED WHITE BLUE
     A configuration with three tracks one) primary track
     and the ather a player
     try running 1,2,3 and upto 4 players
     plays the same file
     in the Audio Engine, a VisualAudio Tap
     */
    
    [_scrubberController reset];
    _scrubberController.numberOfTracks = 3;
    [_delegate updateScrubberHeight:self];
    
    _scrubberController.useTrackGradient = YES;
    //    _scrubberController.trackLocations = @[@(0.3333),@(0.666)];
    //    _scrubberController.trackLocations = @[@(0.18),@(0.82)];
    //    _scrubberController.trackLocations = @[@(0.10)];
    
    [_scrubberController setViewOptions:ScrubberViewOptionNone];
    
    [_scrubberController prepareScrubberFileURL:[_delegate scrubberDemoFile1URL:self]
                                 withSampleSize:SampleSize14
                                        options:SamplingOptionDualChannel
                                           type:VABOptionNone
                                         layout:VABLayoutOptionOverlayAverages | VABLayoutOptionShowAverageSamples
                                         colors:@{
                                                  JWColorScrubberTopPeakNoAvg : [[UIColor redColor] colorWithAlphaComponent:0.8],
                                                  JWColorScrubberTopAvg : [UIColor colorWithWhite:0.9 alpha:0.5] ,
                                                  JWColorScrubberTopPeak : [[UIColor redColor] colorWithAlphaComponent:0.8],
                                                  
                                                  JWColorScrubberBottomPeakNoAvg : [[UIColor greenColor] colorWithAlphaComponent:0.8],
                                                  JWColorScrubberBottomAvg : [UIColor colorWithWhite:0.9 alpha:0.5],
                                                  JWColorScrubberBottomPeak : [[UIColor greenColor] colorWithAlphaComponent:0.8],
                                                  }
                                   onCompletion:nil];
    
    [_scrubberController prepareScrubberFileURL:[_delegate scrubberDemoFile1URL:self]
                                 withSampleSize:SampleSize14
                                        options:SamplingOptionDualChannel
                                           type:VABOptionNone
                                         layout:VABLayoutOptionStackAverages | VABLayoutOptionShowAverageSamples
                                         colors:@{
                                                  JWColorScrubberTopPeakNoAvg : [UIColor colorWithWhite:0.95 alpha:0.9] ,
                                                  JWColorScrubberTopAvg : [UIColor colorWithWhite:0.99 alpha:0.5] ,
                                                  JWColorScrubberTopPeak : [UIColor colorWithWhite:0.95 alpha:0.9] ,
                                                  
                                                  JWColorScrubberBottomPeakNoAvg : [UIColor colorWithWhite:0.95 alpha:0.9] ,
                                                  JWColorScrubberBottomAvg : [UIColor colorWithWhite:0.99 alpha:0.5] ,
                                                  JWColorScrubberBottomPeak : [UIColor colorWithWhite:0.95 alpha:0.9] ,
                                                  }
                                   onCompletion:nil];
    
    [_scrubberController prepareScrubberFileURL:[_delegate scrubberDemoFile1URL:self]
                                 withSampleSize:SampleSize14
                                        options:SamplingOptionDualChannel
                                           type:VABOptionNone
                                         layout:VABLayoutOptionOverlayAverages | VABLayoutOptionShowAverageSamples
                                         colors:@{
                                                  JWColorScrubberTopPeakNoAvg : [[UIColor blueColor] colorWithAlphaComponent:0.8],
                                                  JWColorScrubberTopAvg : [UIColor colorWithWhite:0.9 alpha:0.5] ,
                                                  JWColorScrubberTopPeak : [[UIColor blueColor] colorWithAlphaComponent:0.8],
                                                  JWColorScrubberBottomPeakNoAvg : [[UIColor greenColor] colorWithAlphaComponent:0.8],
                                                  JWColorScrubberBottomAvg : [UIColor colorWithWhite:0.9 alpha:0.5],
                                                  JWColorScrubberBottomPeak : [[UIColor greenColor] colorWithAlphaComponent:0.8],
                                                  }
                                   onCompletion:nil];
    
}


-(void)demoPlayConfiguration4
{
    // A configuration that sets all track colors then modies one or more color components
    // the all track colorsare used that not overridden by individual track colors
    
    [_scrubberController reset];
    _scrubberController.numberOfTracks = 3;
    [_delegate updateScrubberHeight:self];
    [_scrubberController setViewOptions:ScrubberViewOptionNone];
    
    [_scrubberController configureColors:
     @{
       JWColorScrubberTopPeak         : [UIColor whiteColor],
       JWColorScrubberTopAvg          : [UIColor grayColor],
       JWColorScrubberBottomPeak      : [UIColor whiteColor],
       JWColorScrubberBottomAvg       : [UIColor grayColor],
       
       JWColorScrubberTopPeakNoAvg    : [UIColor whiteColor],
       JWColorScrubberBottomPeakNoAvg : [UIColor whiteColor],
       }];
    
    // First track
    
    [_scrubberController prepareScrubberFileURL:[_delegate scrubberDemoFile1URL:self]
                                 withSampleSize:SampleSize14
                                        options:SamplingOptionDualChannel
                                           type:VABOptionNone
                                         layout:VABLayoutOptionStackAverages | VABLayoutOptionShowAverageSamples | VABLayoutOptionShowCenterLine
                                         colors:nil
                                   onCompletion:nil];
    
    // Second Track
    
    [_scrubberController prepareScrubberFileURL:[_delegate scrubberDemoFile1URL:self]
                                 withSampleSize:SampleSize14
                                        options:SamplingOptionDualChannel
                                           type:VABOptionNone
                                         layout:VABLayoutOptionStackAverages | VABLayoutOptionShowAverageSamples | VABLayoutOptionShowCenterLine
                                         colors:@{
                                                  JWColorScrubberTopPeak : [UIColor greenColor],
                                                  }
                                   onCompletion:nil];
    // Third track
    
    // choose between the two
    // One will substitute jus the specified colors
    // the second will turn off showAverages layout option
    // and most set the PeakNoAvg color instead. if one is not supplied the alltracks color for that will be used
    
    [_scrubberController prepareScrubberFileURL:[_delegate scrubberDemoFile1URL:self]
                                 withSampleSize:SampleSize18
                                        options:SamplingOptionDualChannel
                                           type:VABOptionNone
                                         layout:VABLayoutOptionOverlayAverages | VABLayoutOptionShowAverageSamples | VABLayoutOptionShowCenterLine
                                         colors:@{
                                                  JWColorScrubberBottomPeak : [UIColor yellowColor],
                                                  JWColorScrubberTopAvg : [UIColor orangeColor]
                                                  }
                                   onCompletion:nil];
    
    
    //    // Remoce the showAverages option need to set correct colo as only PeakNoAvg is used Top and Bottom
    //    // TopPeak and TopAvg are ignored
    //    [_scrubberController prepareScrubberFileURL:[_delegate scrubberDemoFile1URL:self]
    //                                 withSampleSize:SampleSize18
    //                                        options:SamplingOptionDualChannel
    //                                           type:VABOptionNone
    //                                         layout:VABLayoutOptionOverlayAverages  | VABLayoutOptionShowCenterLine
    //                                         colors:@{
    //                                                  JWColorScrubberBottomPeak : [UIColor yellowColor],
    //                                                  JWColorScrubberTopAvg : [UIColor orangeColor],
    //                                                  JWColorScrubberTopPeakNoAvg : [UIColor orangeColor],
    //                                                  }
    //                                   onCompletion:nil];
    
}



-(void)demoPlayConfiguration4a
{
    // Regga
    // A configuration that sets all track colors then modies one or more color components
    // the all track colorsare used that not overridden by individual track colors
    
    [_scrubberController reset];
    _scrubberController.numberOfTracks = 1;
    [_delegate updateScrubberHeight:self];
    [_scrubberController setViewOptions:ScrubberViewOptionNone];
    
    [_scrubberController configureColors:
     @{
       JWColorScrubberTopPeak : [[UIColor redColor] colorWithAlphaComponent:0.8],
       JWColorScrubberTopAvg : [[UIColor yellowColor] colorWithAlphaComponent:0.5] ,
       
       JWColorScrubberBottomPeak : [[UIColor greenColor] colorWithAlphaComponent:0.8],
       JWColorScrubberBottomAvg : [[UIColor yellowColor] colorWithAlphaComponent:0.5],
       
       JWColorScrubberTopPeakNoAvg : [[UIColor blueColor] colorWithAlphaComponent:0.8],
       JWColorScrubberBottomPeakNoAvg : [[UIColor greenColor] colorWithAlphaComponent:0.8],
       }];
    
    // First track
    
    [_scrubberController prepareScrubberFileURL:[_delegate scrubberDemoFile1URL:self]
                                 withSampleSize:SampleSize14
                                        options:SamplingOptionDualChannel
                                           type:VABOptionCenter
                                         layout:VABLayoutOptionStackAverages | VABLayoutOptionShowAverageSamples | VABLayoutOptionShowCenterLine
                                         colors:    @{
                                                      }
                                   onCompletion:nil];
}


-(void)demoPlayConfiguration4b
{
    // Rock
    // A configuration that sets all track colors then modies one or more color components
    // the all track colorsare used that not overridden by individual track colors
    
    [_scrubberController reset];
    _scrubberController.numberOfTracks = 1;
    [_delegate updateScrubberHeight:self];
    [_scrubberController setViewOptions:ScrubberViewOptionNone];
    
    // First track
    
    [_scrubberController prepareScrubberFileURL:[_delegate scrubberDemoFile1URL:self]
                                 withSampleSize:SampleSize14
                                        options:SamplingOptionDualChannel
                                           type:VABOptionCenter
                                         layout:VABLayoutOptionStackAverages | VABLayoutOptionShowAverageSamples | VABLayoutOptionShowCenterLine
                                         colors:    @{
                                                      }
                                   onCompletion:nil];
}


-(void)demoPlayConfiguration4c
{
    // Rock
    // A configuration that sets all track colors then modies one or more color components
    // the all track colorsare used that not overridden by individual track colors
    
    [_scrubberController reset];
    _scrubberController.numberOfTracks = 1;
    [_delegate updateScrubberHeight:self];
    
    [_scrubberController setViewOptions:ScrubberViewOptionNone];
    
    NSDictionary *scrubberColors =
    @{
      JWColorScrubberTopPeak : [[UIColor redColor] colorWithAlphaComponent:0.7],
      JWColorScrubberTopAvg : [[UIColor yellowColor] colorWithAlphaComponent:0.5] ,
      
      JWColorScrubberBottomPeak : [[UIColor greenColor] colorWithAlphaComponent:0.7],
      JWColorScrubberBottomAvg : [[UIColor yellowColor] colorWithAlphaComponent:0.5],
      
      JWColorScrubberTopPeakNoAvg : [[UIColor blueColor] colorWithAlphaComponent:0.8],
      JWColorScrubberBottomPeakNoAvg : [[UIColor greenColor] colorWithAlphaComponent:0.8],
      };
    
    self.scrubberPrimaryColors = scrubberColors;
    [_scrubberController configureColors:scrubberColors];
    // Stack to see pulse behind average
    // First track
    
    [_scrubberController prepareScrubberFileURL:[_delegate scrubberDemoFile1URL:self]
                                 withSampleSize:SampleSize14
                                        options:SamplingOptionDualChannel
                                           type:VABOptionCenter
                                         layout:VABLayoutOptionStackAverages | VABLayoutOptionShowAverageSamples | VABLayoutOptionShowCenterLine
                                         colors:    @{
                                                      }
                                   onCompletion:nil];
}

-(void)demoPlayConfiguration5
{
    /*
     A configuration with two tracks one) primary track
     and the ather a player
     try running 1,2,3 and upto 4 players
     plays the same file
     in the Audio Engine, a VisualAudio Tap
     
     //    _scrubberController.trackLocations = @[@(0.3333),@(0.666)];
     _scrubberController.trackLocations = @[@(0.18),@(0.82)];
     //    _scrubberController.trackLocations = @[@(0.10)];
     
     */
    
    [_scrubberController reset];
    _scrubberController.numberOfTracks = 3;
    _scrubberController.trackLocations = @[@(0.18),@(0.36)];
    [_delegate updateScrubberHeight:self];
    [_scrubberController setViewOptions:ScrubberViewOptionNone];
    
    
    [_scrubberController prepareScrubberFileURL:[_delegate scrubberDemoFile1URL:self]
                                 withSampleSize:SampleSize14
                                        options:SamplingOptionDualChannel
                                           type:VABOptionNone
                                         layout:VABLayoutOptionStackAverages
                                   onCompletion:nil];
    
    [_scrubberController prepareScrubberFileURL:[_delegate scrubberDemoFile1URL:self]
                                 withSampleSize:SampleSize14
                                        options:SamplingOptionDualChannel
                                           type:VABOptionNone
                                         layout:VABLayoutOptionStackAverages | VABLayoutOptionShowAverageSamples
                                         colors:@{
                                                  JWColorScrubberTopPeak : [[UIColor greenColor] colorWithAlphaComponent:0.7],
                                                  JWColorScrubberTopAvg : [UIColor colorWithWhite:0.8 alpha:0.7] ,
                                                  JWColorScrubberBottomPeak : [[UIColor yellowColor] colorWithAlphaComponent:0.7],
                                                  JWColorScrubberBottomAvg : [UIColor colorWithWhite:0.8 alpha:0.7],
                                                  }
                                   onCompletion:nil];
    
    // ADD A TAP to mixer for playAlll
    NSString *trackidMixerTap =
    [_scrubberController prepareScrubberListenerSource:[_delegate scrubberBufferController:self]
                                        withSampleSize:SampleSize14
                                               options:SamplingOptionDualChannel
                                                  type:VABOptionNone
                                                layout:VABLayoutOptionStackAverages | VABLayoutOptionShowAverageSamples
                                                colors:@{
                                                         JWColorScrubberTopPeak : [[UIColor redColor] colorWithAlphaComponent:0.8],
                                                         JWColorScrubberTopAvg : [UIColor colorWithWhite:0.8 alpha:0.7] ,
                                                         JWColorScrubberBottomPeak : [[UIColor redColor] colorWithAlphaComponent:0.6],
                                                         JWColorScrubberBottomAvg : [UIColor colorWithWhite:0.8 alpha:0.7],
                                                         }
                                          onCompletion:nil];
    
//    [_audioEngine registerController:_scrubberController withTrackId:trackidMixerTap forPlayerRecorder:@"mixer"];
    
    [_delegate scrubberDemoController:self registerController:_scrubberController withTrackId:trackidMixerTap];

    
}


-(void)demoPlayConfiguration6
{
    /*
     A configuration with two tracks one) primary track
     and the ather a player
     in the Audio Engine, a VisualAudio Tap
     */
    
    [_scrubberController reset];
    _scrubberController.numberOfTracks = 3;
    _scrubberController.trackLocations = @[@(0.18),@(0.50)];
    [_delegate updateScrubberHeight:self];
    [_scrubberController setViewOptions:ScrubberViewOptionNone];
    
    [_scrubberController prepareScrubberFileURL:[_delegate scrubberDemoFile1URL:self]
                                 withSampleSize:SampleSize14
                                        options:SamplingOptionDualChannel
                                           type:VABOptionNone
                                         layout:VABLayoutOptionStackAverages
                                   onCompletion:nil];
    
    [_scrubberController prepareScrubberFileURL:[_delegate scrubberDemoFile1URL:self]
                                 withSampleSize:SampleSize14
                                        options:SamplingOptionDualChannel
                                           type:VABOptionNone
                                         layout:VABLayoutOptionStackAverages | VABLayoutOptionShowAverageSamples
                                         colors:@{
                                                  JWColorScrubberTopPeak : [[UIColor greenColor] colorWithAlphaComponent:0.7],
                                                  JWColorScrubberTopAvg : [UIColor colorWithWhite:0.8 alpha:0.7] ,
                                                  JWColorScrubberBottomPeak : [[UIColor yellowColor] colorWithAlphaComponent:0.7],
                                                  JWColorScrubberBottomAvg : [UIColor colorWithWhite:0.8 alpha:0.7],
                                                  }
                                   onCompletion:nil];
    
    [_scrubberController prepareScrubberFileURL:[_delegate scrubberDemoFile1URL:self]
                                 withSampleSize:SampleSize14
                                        options:SamplingOptionDualChannel
                                           type:VABOptionNone
                                         layout:VABLayoutOptionStackAverages | VABLayoutOptionShowAverageSamples
                                         colors:@{
                                                  JWColorScrubberTopPeak : [[UIColor orangeColor] colorWithAlphaComponent:0.7],
                                                  JWColorScrubberTopAvg : [UIColor colorWithWhite:0.8 alpha:0.7] ,
                                                  JWColorScrubberBottomPeak : [[UIColor whiteColor] colorWithAlphaComponent:0.8],
                                                  JWColorScrubberBottomAvg : [UIColor colorWithWhite:0.8 alpha:0.7],
                                                  }
                                   onCompletion:nil];
    
}


// END DEMOS --------------------

#pragma mark END DEMOS

@end
