//
//  AVAudioUnitReverb+JW.m
//  JamWIthT
//
//  Created by JOSEPH KERR on 11/5/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import "AVAudioUnitReverb+JW.h"
@import UIKit;

@implementation AVAudioUnitReverb (JW)

-(float)floatValue1 {
    NSLog(@"%s get wetdrymix %.2f",__func__,self.wetDryMix);
    return self.wetDryMix;
}

-(float)floatValue2 {
    NSLog(@"%s not used, ignored",__func__);
    return 0.0;
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
    NSLog(@"%s get bypass %@",__func__,@(self.bypass));
    return self.bypass;
}

-(BOOL)adjustFloatValue1:(float)value{
    NSLog(@"%s adjusting wetdrymix %.2f to %.2f",__func__,self.wetDryMix,value);
    self.wetDryMix = value;
    return YES;
}

-(BOOL)adjustFloatValue2:(float)value{
    NSLog(@"%s not used, ignored",__func__);
    return NO;
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
    NSLog(@"%s adjusting bypass %@",__func__,@(value));
    self.bypass = value;
    return YES;
}

-(NSTimeInterval)timeInterval1 {
    NSLog(@"%s not used, ignored",__func__);
    return 0.0;
}

-(BOOL)adjustTimeInterval1:(NSTimeInterval)value {
    NSLog(@"%s not used, ignored",__func__);
    return NO;
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
