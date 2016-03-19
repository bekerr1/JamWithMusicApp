//
//  JWCameraViewController.h
//  JWMixAudioScrubber
//
//  co-created by joe and brendan kerr on 1/11/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>


@protocol JWCameraDelegate;

@interface JWCameraViewController : UIViewController 

@property (nonatomic) id <JWCameraDelegate> delegate;
@property (nonatomic) id scrubberObject;
@property (nonatomic) NSArray *apccTrackSet;

//-(void)setScrubberObject:(id)scrubberObject;

@end

@protocol JWCameraDelegate <NSObject>



@end
