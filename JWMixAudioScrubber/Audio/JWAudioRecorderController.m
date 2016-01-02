//
//  JWAudioRecorderController.m
//  JamWIthT
//
//  Created by JOSEPH KERR on 11/6/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import "JWAudioRecorderController.h"
@import AVFoundation;

@interface JWAudioRecorderController (){
    AVAudioFile* _micOutputFile;
    BOOL _useMetering;
    BOOL _recorded;
    BOOL _recording;
    BOOL _suspendVAB;
    dispatch_queue_t _bufferReceivedQueue;
}
@property (strong, nonatomic) AVAudioRecorder *audioRecorder;
@property (nonatomic,readwrite) BOOL recording;

// metering
@property (nonatomic,strong)  NSTimer *meteringTimer;
@property (nonatomic,strong)  NSMutableArray *meterSamples;
@property (nonatomic,strong)  NSMutableArray *meterPeakSamples;
@property (nonatomic,strong)  NSDate *lastMeterTimeStamp;
// registercontroller
@property (nonatomic,strong)  NSMutableDictionary *scrubberTrackIds;
@property (nonatomic,strong) id <JWScrubberBufferControllerDelegate> scrubberBufferController;
@end


@implementation JWAudioRecorderController

-(instancetype)initWithMetering:(BOOL)metering {

    if (self = [super init]) {
        _useMetering = metering;
        
        [self initializeController];
    }
    return self;
}

-(void)initializeController {

    if (_useMetering) {
        _meterSamples = [@[[@[] mutableCopy],[@[] mutableCopy]] mutableCopy];
        _meterPeakSamples = [@[[@[] mutableCopy],[@[] mutableCopy]] mutableCopy];
    }
    _recording = NO;
    _recorded = NO;
    _useMetering = YES;
    _scrubberTrackIds = [@{} mutableCopy];
    
    [self fileURLs];
    
    AVAudioChannelLayout *layout = [[AVAudioChannelLayout alloc] initWithLayoutTag:kAudioChannelLayoutTag_Stereo];
    AVAudioFormat* micFormat =
    [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatFloat32 sampleRate:44100. interleaved:NO channelLayout:layout];
    
    NSError *error;
    self.audioRecorder = [[AVAudioRecorder alloc] initWithURL:_micOutputFileURL settings:[micFormat settings] error:&error];
    
    _audioRecorder.meteringEnabled = _useMetering;

    [_audioRecorder prepareToRecord];
}

-(void)registerController:(id <JWScrubberBufferControllerDelegate> )myScrubberContoller withTrackId:(NSString*)trackId
        forPlayerRecorder:(NSString*)player
{
    if ([player isEqualToString:@"recorder"])
    {
        _scrubberTrackIds[player] = trackId;
    }
    
    _scrubberBufferController = myScrubberContoller; // last register called uses tha controller by all
    
    if (_bufferReceivedQueue == nil) {
        _bufferReceivedQueue =
        dispatch_queue_create("bufferReceivedAE",
                              dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL,QOS_CLASS_USER_INTERACTIVE, 0));
    }
}

-(void)record {

    [_audioRecorder record];
    
    _recording = YES;
    
    if (_useMetering)
        [self startMeteringTimer];
}

-(void)stopRecording {
    
    _suspendVAB = YES;
    
    [self.meteringTimer invalidate];
    
    self.meteringTimer = nil;
    
    [_audioRecorder stop];
    
    _recording = NO;
    _recorded = YES;
}

-(BOOL)hasRecorded
{
    return _recorded;
}

-(void)fileURLs {
    // .caf = CoreAudioFormat
    NSString *cacheKey = [[NSUUID UUID] UUIDString];
    NSString *thisfName = @"clipRecording";
    NSString *uniqueFname = [NSString stringWithFormat:@"%@_%@.caf",thisfName,cacheKey?cacheKey:@""];
    NSString *docsDir = [NSHomeDirectory() stringByAppendingPathComponent:  @"Documents"];
    
    _micOutputFileURL = [NSURL URLWithString:[docsDir stringByAppendingPathComponent:uniqueFname]];
}

#pragma mark - effects modifying delegate

-(float)floatValue1 {
    NSLog(@"%s not used, ignored",__func__);
    return 0.0;
}
-(float)floatValue2 {
    NSLog(@"%s not used, ignored",__func__);
    return 0.0;
}
-(BOOL)boolValue1 {
    NSLog(@"%s get isPlaying %@",__func__,@(self.recording));
    return self.recording;
}
-(BOOL)adjustFloatValue1:(float)value{
    NSLog(@"%s not used, ignored",__func__);
    return NO;
}
-(BOOL)adjustFloatValue2:(float)value{
    NSLog(@"%s not used, ignored",__func__);
    return NO;
}
-(BOOL)adjustBoolValue1:(BOOL)value {
    NSLog(@"%s adjusts toggles recording. %@",__func__,@(value));
    BOOL result = NO;
    if (value) {
        // wants to record
        if (_recording) {
            NSLog(@"%s already recording ",__func__);
        } else {
            [self record];
            result = YES;
        }
    } else {
        if (_recording) {
            [self stopRecording];
            result = YES;
        } else {
            NSLog(@"%s already is not recording ",__func__);
        }
    }
    return NO;
}
-(NSTimeInterval)timeInterval1 {
    NSLog(@"%s not used, ignored",__func__);
    return 0.0;
}
-(BOOL)adjustTimeInterval1:(NSTimeInterval)value {
    NSLog(@"%s not used, ignored",__func__);
    return NO;
}
-(void)adjustFloatValue1WithSlider:(id)sender {
    [self adjustFloatValue1:[(UISlider*)sender value]];
}
-(void)adjustFloatValue2WithSlider:(id)sender {
    [self adjustFloatValue2:[(UISlider*)sender value]];
}
-(void)adjustBoolValue1WithSwitch:(id)sender {
    [self adjustBoolValue1:[(UISwitch*)sender isOn]];
}


#pragma mark - metering

-(void)startMeteringTimer
{
    self.lastMeterTimeStamp = [NSDate date];
    self.meteringTimer = [NSTimer timerWithTimeInterval:0.05 target:self selector:@selector(meteringTimerFired:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_meteringTimer forMode:NSRunLoopCommonModes];
}

-(void)meteringTimerFired:(NSTimer*)timer {
    
    if (timer.valid) {
        NSTimeInterval meteringInterval = 0.33;
        /*
        The current peak power, in decibels, for the sound being recorded. 
         A return value of 0 dB indicates full scale, or maximum power; a return value of -160 dB indicates minimum power (that is, near silence).
         but am gonna limit to 130
         The sampl
         */
        
        [self.audioRecorder updateMeters];
        
        // 0 maximum power -160 near silence
        
        float subtractValue = 60;
        
        // reduce
        // maxDB + avgSample   160 + (lowvalue) -158 = 2  , very low

        // maxDB + avgSample   160 + (highvalue) -2 = 158  , very low

        // maxDB + avgSample   160 + (midValue) -80 = 80  , very low

        float maxDB = 160.0f;
        float avgSample = 0.0f;
        float avgNormalizedValue = 0.0;// ratio 0 - 1.0
        float peakSample = 0.0f;
        float peakNormalizedValue = 0.0;// ratio 0 - 1.0
        
        // Channel 1 index 0
        // AVERAGE POWER
        avgSample = [self.audioRecorder averagePowerForChannel:0];
        NSLog(@"avgSample %.5f",avgSample);
        if (avgSample > 0 ) {
            avgNormalizedValue = 1.00f;
        } else {
            // - 60   is quiet
            if ((avgSample + maxDB) > subtractValue)
                avgSample -= subtractValue;

            avgNormalizedValue = (maxDB + avgSample) / maxDB;
        }
        [_meterSamples[0] addObject:@(avgNormalizedValue)];
        // PEAK POWER
        peakSample = [self.audioRecorder peakPowerForChannel:0];
        NSLog(@"peakSample %.5f",peakSample);

        if (peakSample > 0 ){
            peakNormalizedValue = 1.00f;
        }else {
            if ((peakSample + maxDB)  > subtractValue)
                peakSample -= subtractValue;


//            if (peakSample <  -subtractValue)
//                peakSample += subtractValue;
            peakNormalizedValue = (maxDB + peakSample) / maxDB;
        }
        [_meterPeakSamples[0] addObject:@(peakNormalizedValue)];

        // Channel 2 index 1
        // AVERAGE POWER
        avgSample = [self.audioRecorder averagePowerForChannel:1];
        avgSample += 0;
        if (avgSample > 0 )
            avgNormalizedValue = 1.00f;
        else
            avgNormalizedValue = (maxDB + avgSample) / maxDB;              // sample of (-45) + 160 = 115   160 + (-158) = 2/160 = 0.0125
        [_meterSamples[1] addObject:@(avgNormalizedValue)];
        // PEAK POWER
        peakSample = [self.audioRecorder peakPowerForChannel:1];
        peakSample += subtractValue;
        if (peakSample > 0 )
            peakNormalizedValue = 1.00f;
        else
            peakNormalizedValue = (maxDB + peakSample) / maxDB;
        [_meterPeakSamples[1] addObject:@(peakNormalizedValue)];
//        NSLog(@"peak %@",[_meterPeakSamples[1] description]);
        
        NSTimeInterval timedMeter =  [_lastMeterTimeStamp timeIntervalSinceNow];
        
        if (timedMeter <  - meteringInterval) {
            [_scrubberBufferController  meterChannelSamplesWithAverages:_meterPeakSamples[0] averageSamples:_meterSamples[0]
                                                        channel2Samples:_meterPeakSamples[1] averageSamples2:_meterSamples[1]
                                                            andDuration:-timedMeter
                                                             forTrackId:_scrubberTrackIds[@"recorder"] ];

            NSLog(@"peakcount %ld avg %ld",[_meterPeakSamples[0] count],[_meterSamples[0] count]);

            // Whole new arrays as the other array objects were passed and being processed
            _meterSamples[0] = [@[] mutableCopy];
            _meterPeakSamples[0] = [@[] mutableCopy];
            _meterSamples[1] = [@[] mutableCopy];
            _meterPeakSamples[1] = [@[] mutableCopy];

            self.lastMeterTimeStamp = [NSDate date];
        }
    }
    
}


@end
