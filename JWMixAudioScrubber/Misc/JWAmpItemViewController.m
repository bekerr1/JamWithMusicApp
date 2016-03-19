//
//  JWAmpItemViewController.m
//  JamWIthT
//
//  co-created by joe and brendan kerr on 10/8/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import "JWAmpItemViewController.h"

@implementation JWAmpItemViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder: aDecoder];
    if (self) { }
    return self;
}

-(void)setAmpImage:(UIImage *)ampImage {
    self.ampImageView.image = ampImage;
}

@end


