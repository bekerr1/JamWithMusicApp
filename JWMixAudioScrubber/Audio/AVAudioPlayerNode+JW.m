//
//  AVAudioPlayerNode+JW.m
//  JamWIthT
//
//  Created by JOSEPH KERR on 11/5/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import "AVAudioPlayerNode+JW.h"
@import UIKit;

@implementation AVAudioPlayerNode (JW)

-(float)floatValue1 {
    NSLog(@"%s get volume %.2f",__func__,self.volume);
    return self.volume;
}

-(float)floatValue2 {
    NSLog(@"%s get pan %.2f",__func__,self.pan);
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
    NSLog(@"%s get isPlaying %@",__func__,@(self.isPlaying));
    return self.isPlaying;
}

-(BOOL)adjustFloatValue1:(float)value{
//    NSLog(@"%s adjusting volume %.2f to %.2f",__func__,self.volume,value);
    self.volume = value;
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
    NSLog(@"%s cannot adjust bool value1 %@ ignored.",__func__,@(value));
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
