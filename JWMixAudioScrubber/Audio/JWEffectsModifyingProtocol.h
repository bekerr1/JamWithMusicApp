//
//  JWEffectsModifyingProtocol.h
//  JamWIthT
//
//  co-created by joe and brendan kerr on 11/2/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol JWEffectsModifyingProtocol <NSObject>

-(float)floatValue1;
-(BOOL)adjustFloatValue1:(float)value;

-(float)floatValue2;
-(BOOL)adjustFloatValue2:(float)value;

-(float)floatValue3;
-(BOOL)adjustFloatValue3:(float)value;

-(float)floatValue4;
-(BOOL)adjustFloatValue4:(float)value;

-(BOOL)boolValue1;
-(BOOL)adjustBoolValue1:(BOOL)value;

-(NSTimeInterval)timeInterval1;
-(BOOL)adjustTimeInterval1:(NSTimeInterval)value;

-(NSArray*)optionPresets;
-(BOOL)adjustOptionPreset:(NSUInteger)value;


// joe: for UI attachments
-(void)adjustFloatValue1WithSlider:(id)sender;
-(void)adjustFloatValue2WithSlider:(id)sender;
-(void)adjustFloatValue3WithSlider:(id)sender;
-(void)adjustFloatValue4WithSlider:(id)sender;

-(void)adjustTimeInterval1WithSlider:(id)sender;

-(void)adjustBoolValue1WithSwitch:(id)sender;

@end
