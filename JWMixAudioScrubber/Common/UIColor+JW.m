//
//  UIColor+JW.m
//  JamWDev
//
//  Created by JOSEPH KERR on 1/21/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

#import "UIColor+JW.h"

@implementation UIColor (JW)

+(UIColor*)iosAsparagusColor {
    return [UIColor colorWithRed:128/255.0 green:128/255.0 blue:0/255.0 alpha:1.0]; // asparagus
}
+(UIColor*)iosOceanColor {
    return [UIColor colorWithRed:0/255.0 green:64/255.0 blue:128/255.0 alpha:1.0]; // ocean
}
+(UIColor*)iosAquaColor {
    return [UIColor colorWithRed:0/255.0 green:128/255.0 blue:255/255.0 alpha:1.0]; // aqua
}
+(UIColor*)iosSkyColor {
    return [UIColor colorWithRed:102/255.0 green:204/255.0 blue:255/255.0 alpha:1.0]; // sky
}
+(UIColor*)iosAluminumColor {
    return [UIColor colorWithRed:153/255.0 green:153/255.0 blue:153/255.0 alpha:1.0]; // aluminum
}
+(UIColor*)iosMercuryColor {
    return [UIColor colorWithRed:230/255.0 green:230/255.0 blue:230/255.0 alpha:1.0]; // mercury
}
+(UIColor*)iosTungstenColor {
    return [UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1.0]; // tungsten
}
+(UIColor*)iosSteelColor {
    return [UIColor colorWithRed:102/255.0 green:102/255.0 blue:102/255.0 alpha:1.0]; // steel
}
+(UIColor*)iosStrawberryColor {
    return [UIColor colorWithRed:244/255.0 green:102/255.0 blue:255/255.0 alpha:1.0]; // steel
}
+(UIColor*)iosSilverColor {
    return [UIColor colorWithRed:204/255.0 green:204/255.0 blue:204/255.0 alpha:1.0]; // steel
}


+(UIColor*)jwSectionTextColor {
    return [UIColor iosSilverColor];
}
+(UIColor*)jwBlackThemeColor {
    return [UIColor blackColor];
}

@end
