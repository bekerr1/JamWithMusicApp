//
//  AVAudioUnitDelay+JW.h
//  JamWIthT
//
//  Created by JOSEPH KERR on 11/5/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "JWEffectsModifyingProtocol.h"

@interface AVAudioUnitDelay (JW) <JWEffectsModifyingProtocol>

-(float)floatValue1;
-(float)floatValue2;
-(BOOL)boolValue1;

-(BOOL)adjustFloatValue1:(float)value;
-(BOOL)adjustFloatValue2:(float)value;
-(BOOL)adjustBoolValue1:(BOOL)value;
@end