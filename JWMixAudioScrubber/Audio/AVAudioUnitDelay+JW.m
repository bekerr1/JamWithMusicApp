//
//  AVAudioUnitDelay+JW.m
//  JamWIthT
//
//  Created by JOSEPH KERR on 11/5/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import "AVAudioUnitDelay+JW.h"
@import UIKit;


@implementation AVAudioUnitDelay (JW)

-(float)floatValue1 {
    NSLog(@"%s get wetdrymix %.2f",__func__,self.wetDryMix);
    return self.wetDryMix;
}

-(float)floatValue2 {
    NSLog(@"%s get feedback %.2f",__func__,self.feedback);
    return self.feedback;
}

-(float)floatValue3 {
    NSLog(@"%s get lowpasscutoff %.2f",__func__,self.lowPassCutoff);
    return self.lowPassCutoff;
}

-(float)floatValue4 {
    NSLog(@"%s not used, ignored",__func__);
    return 0.0;
}

-(BOOL)boolValue1 {
    NSLog(@"%s get bypass %@",__func__,@(self.bypass));
    return self.bypass;
}

-(BOOL)adjustFloatValue1:(float)value{
    NSLog(@"%s adjusting wetDryMix %.2f to %.2f",__func__,self.wetDryMix,value);
    self.wetDryMix = value;
    return YES;
}

-(BOOL)adjustFloatValue2:(float)value{
    NSLog(@"%s adjusting feedback %.2f to %.2f",__func__,self.feedback,value);
    self.feedback = value;
    return YES;
}

-(BOOL)adjustFloatValue3:(float)value{
    NSLog(@"%s adjusting lowPassCutoff %.2f to %.2f",__func__,self.lowPassCutoff,value);
    self.lowPassCutoff = value;
    return YES;
}

-(BOOL)adjustFloatValue4:(float)value{
    NSLog(@"%s not used, ignored",__func__);
    return NO;
}


-(BOOL)adjustBoolValue1:(BOOL)value {
    NSLog(@"%s adjusting bypass %@ to %@",__func__,@(self.bypass),@(value));
    self.bypass = value;
    return YES;
}

-(NSTimeInterval)timeInterval1 {
    NSLog(@"%s get delayTime %.2f",__func__,self.delayTime);
    return self.delayTime;
}

-(BOOL)adjustTimeInterval1:(NSTimeInterval)value {
    NSLog(@"%s adjusting delayTime %.2f to %.2f",__func__,self.delayTime,value);
    self.delayTime = value;
    return YES;
}



-(NSArray*)optionPresets {
    NSLog(@"%s not used, ignored",__func__);
    return nil;
    
}
-(BOOL)adjustOptionPreset:(NSUInteger)value {
    NSLog(@"%s not used, ignored",__func__);
    return NO;
}


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
