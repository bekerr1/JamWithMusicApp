//
//  JWClipAudioHelperViewController.h
//  JamWDev
//
//  Created by brendan kerr on 1/24/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AudioHelperDelegate;

@interface JWClipAudioHelperViewController : UIViewController

@property (nonatomic) id <AudioHelperDelegate> delegate;

@end

@protocol AudioHelperDelegate <NSObject>
-(void)seekToPositionInSeconds:(NSUInteger)seconds;
-(void)inchLeftPressed;
-(void)inchRightPressed;
@end
