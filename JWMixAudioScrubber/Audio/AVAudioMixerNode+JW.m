//
//  AVAudioMixerNode+JW.m
//  JamWIthT
//
//  co-created by joe and brendan kerr on 11/11/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import "AVAudioMixerNode+JW.h"
@import UIKit;

@implementation AVAudioMixerNode (JW)

-(float)floatValue1 {
//    NSLog(@"%s get outputVolume %.2f",__func__,self.outputVolume);
    return self.outputVolume;
}

-(float)floatValue2 {
//    NSLog(@"%s get pan %.2f",__func__,self.pan);
    return self.pan;
}

-(float)floatValue3 {
    NSLog(@"%s not used, ignored",__func__);
    return 0.0;
}

-(float)floatValue4 {
    NSLog(@"%s not used, ignored",__func__);
    return 0.0;
}

-(BOOL)boolValue1 {
    NSLog(@"%s not used, ignored",__func__);
    return NO;
}

#pragma mark -

-(BOOL)adjustFloatValue1:(float)value{
//    NSLog(@"%s adjusting outputVolume %.2f to %.2f",__func__,self.outputVolume,value);
    self.outputVolume = value;
    return YES;
}

-(BOOL)adjustFloatValue2:(float)value{
//    NSLog(@"%s adjusting pan %.2f to %.2f",__func__,self.pan,value);
    self.pan = value;
    return YES;
}

-(BOOL)adjustFloatValue3:(float)value{
    NSLog(@"%s not used, ignored",__func__);
    return NO;
}

-(BOOL)adjustFloatValue4:(float)value{
    NSLog(@"%s not used, ignored",__func__);
    return NO;
}

-(BOOL)adjustBoolValue1:(BOOL)value {
    NSLog(@"%s not used, ignored",__func__);
    return NO;
}

#pragma mark -

-(NSTimeInterval)timeInterval1 {
    NSLog(@"%s not used, ignored",__func__);
    return 0.0;
}

-(BOOL)adjustTimeInterval1:(NSTimeInterval)value {
    NSLog(@"%s not used, ignored",__func__);
    return NO;
}

#pragma mark -

-(NSArray*)optionPresets {
    NSLog(@"%s not used, ignored",__func__);
    return nil;
}

-(BOOL)adjustOptionPreset:(NSUInteger)value {
    NSLog(@"%s not used, ignored",__func__);
    return NO;
}

#pragma mark -

// UI Control actions

-(void)adjustFloatValue1WithSlider:(id)sender {
    [self adjustFloatValue1:[(UISlider*)sender value]];
}
-(void)adjustFloatValue2WithSlider:(id)sender {
    [self adjustFloatValue2:[(UISlider*)sender value]];
}
-(void)adjustFloatValue3WithSlider:(id)sender {
    [self adjustFloatValue3:[(UISlider*)sender value]];
}
-(void)adjustFloatValue4WithSlider:(id)sender {
    [self adjustFloatValue4:[(UISlider*)sender value]];
}
-(void)adjustTimeInterval1WithSlider:(id)sender {
    [self adjustTimeInterval1:(NSTimeInterval)[(UISlider*)sender value]];
}
-(void)adjustBoolValue1WithSwitch:(id)sender {
    [self adjustBoolValue1:[(UISwitch*)sender isOn]];
}

@end
