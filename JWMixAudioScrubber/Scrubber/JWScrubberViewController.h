//
//  ScrubberViewController.h
//  AVAEMixerSample
//
//  Created by JOSEPH KERR on 9/17/15.
//  Copyright (c) 2015 apple. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JWScrubber.h"

@protocol ScrubberDelegate;

@interface JWScrubberViewController : UIViewController

@property (nonatomic,assign) id <ScrubberDelegate> delegate;
@property (nonatomic) NSString *playHeadValueStr;
@property (nonatomic) NSString *formatValueStr;
@property (nonatomic) NSString *remainingValueStr;
@property (nonatomic) NSString *durationValueStr;
@property (nonatomic) NSUInteger numberOfTracks;
@property (nonatomic) NSArray *locations;
@property (nonatomic) NSDictionary *userProvidedColorsAllTracks;
@property (nonatomic) SamplingOptions configOptions;
@property (nonatomic) ScrubberViewOptions viewOptions;
@property (nonatomic) CGFloat scale;
@property (nonatomic) BOOL pulseBackLight;
@property (nonatomic) BOOL darkBackground;
@property (nonatomic) BOOL useGradient;
@property (nonatomic) BOOL usePulse;
@property (nonatomic) BOOL useTrackGradient;
@property (nonatomic) UIColor *hueColor;
@property (nonatomic) UIColor *hueGradientColor1;
@property (nonatomic) UIColor *hueGradientColor2;
@property (nonatomic) UIColor *trackGradientColor1;
@property (nonatomic) UIColor *trackGradientColor2;
@property (nonatomic) UIColor *trackGradientColor3;
@property (nonatomic) UIColor *headerColor1;
@property (nonatomic) UIColor *headerColor2;
@property (nonatomic) NSString *playerProgressFormatString;
@property (nonatomic) CGFloat scrubberLength;
@property (nonatomic) NSUInteger selectedTrack;
@property (nonatomic) UIView *clipEnd;

- (void)selectTrack:(NSUInteger)track;
- (void)deSelectTrack;
- (void)prepareForTracks;
- (void)refresh;
- (void)resetScrubber;
- (void)resetScrubberForRecording;
- (void)rewindToBeginning;
- (void)rewindToEnd;
- (void)readyForPlay;
- (void)readyForScrub;
- (void)prepareToPlay:(NSUInteger)track;
- (void)prepareToPlay:(NSUInteger)track atPosition:(CGFloat)position;
- (void)prepareToRecord:(NSUInteger)track atPosition:(CGFloat)position;
- (void)setTrackStartPosition:(CGFloat)startPositionSeconds forTrack:(NSUInteger)track;
- (void)trackScrubberToProgress:(CGFloat)progress;
- (void)trackScrubberToProgress:(CGFloat)progress timeAnimated:(BOOL)animated;
- (void)trackScrubberToPostion:(CGFloat)position timeAnimated:(BOOL)animated;
- (void)trackScrubberToPostion:(CGFloat)position timeAnimated:(BOOL)animated animated:(BOOL)contentAnimated;
- (void)setProgress:(CGFloat)progress;
- (void)transitionToPlay;
- (void)transitionToPlayPreview;
- (void)transitionToStopPlayPreview;
- (void)transitionToStopPlaying;
- (void)transitionToRecording;
- (void)transitionToRecordingSingleRecorder:(BOOL)singleRecorder;
- (void)transitionToPlayTillEnd;
- (void)pulseRecording:(CGFloat)pulseStartValue endValue:(CGFloat)endValue duration:(CGFloat)duration;
- (void)pulseBackLight:(CGFloat)pulseStartValue endValue:(CGFloat)endValue duration:(CGFloat)duration;
- (void)pulseLight:(CGFloat)pulseStartValue endValue:(CGFloat)endValue duration:(CGFloat)duration;
- (void)adjustWhiteBacklightValue:(CGFloat)value;
-(void)setBackgroundToClear;
- (void)editTrack:(NSUInteger)track startInset:(CGFloat)startInset;
- (void)editTrack:(NSUInteger)track endInset:(CGFloat)endInset;
- (void)editTrack:(NSUInteger)track startTime:(CGFloat)startTime;
- (void)stopEditingTrackCancel:(NSUInteger)track;
- (id)stopEditingTrackSave:(NSUInteger)track completion:(void (^)(id fileRef))completion;
- (void)saveEditingTrack:(NSUInteger)track;
- (void)modifyTrack:(NSUInteger)track alpha:(CGFloat)alpha;
- (void)modifyTrack:(NSUInteger)track colors:(NSDictionary*)trackColors;
- (void)modifyTrack:(NSUInteger)track colors:(NSDictionary*)trackColors alpha:(CGFloat)alpha;
- (void)modifyTrack:(NSUInteger)track pan:(CGFloat)panValue;
- (void)modifyTrack:(NSUInteger)track volume:(CGFloat)volumeValue;
- (void)scaleBuffers;  // not working

- (void)addAudioViewChannelSamples:(NSArray*)samples1 averageSamples:(NSArray*)averageSamples
                   channel2Samples:(NSArray*)samples2 averageSamples2:(NSArray*)averageSamples2
                           inTrack:(NSUInteger)track
                     startDuration:(NSTimeInterval)startDuration
                          duration:(NSTimeInterval)duration
                             final:(NSUInteger)finalValue
                           options:(SamplingOptions)options
                              type:(VABKindOptions)typeOptions
                            layout:(VABLayoutOptions)layoutOptions
                            colors:(NSDictionary*)trackColors
                         bufferSeq:(NSUInteger)bufferNo
                       autoAdvance:(BOOL)autoAdvance
                         recording:(BOOL)recording
                           editing:(BOOL)editing
                              size:(CGSize)scrubberViewSize;

@end



@protocol ScrubberDelegate <NSObject>
@optional
// Track position changed by user Delegate methods
-(void)positionInTrackChanged:(int64_t)framePosition;
-(void)positionInTrackChangedProgress:(CGFloat)progress;
-(void)positionInTrackChangedPosition:(CGFloat)positionSeconds;
-(void)trackSelected:(NSUInteger)track;
-(void)trackNotSelected;
-(void)longPressOnTrack:(NSUInteger)track;
-(void)playHeadTapped;
-(CGSize)viewSize;
-(BOOL)isPlaying;
-(NSDictionary*)trackColorsForTrack:(NSUInteger)track;
// EDIT Delegate methods
-(NSDictionary*)trackInfoForTrack:(NSUInteger)track;
-(id)fileReferenceObjectForTrack:(NSUInteger)track;
-(NSTimeInterval)lengthInSecondsForTrack:(NSUInteger)track;
-(void)editCompleted:(NSUInteger)track;
-(void)editChange:(NSUInteger)track;
-(void)editCompletedForTrack:(NSUInteger)track withTrackInfo:(id)fileReference;
-(void)editChangeForTrack:(NSUInteger)track withTrackInfo:(id)fileReference;
-(NSUInteger)buffersCompletedTrack:(NSUInteger)track;
@end
