//
//  JWScrubberDemoController.h
//  JamWIthT
//
//  Created by JOSEPH KERR on 11/12/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JWScrubberController.h"

@protocol JWScrubberDemoDelegate;


@interface JWScrubberDemoController : NSObject

@property (weak) id <JWScrubberDemoDelegate> delegate;  // joe: name the propert delegate
@property (strong, nonatomic) JWScrubberController *scrubberController;
@property (strong, nonatomic) NSDictionary *scrubberPrimaryColors;

-(void) demoPlayConfiguration1;
-(void) demoPlayConfiguration1a;
-(void) demoPlayConfiguration1c;
-(void) demoPlayConfiguration2;
-(void) demoPlayConfiguration3;
-(void) demoPlayConfiguration4;
-(void) demoPlayConfiguration4a;
-(void) demoPlayConfiguration4c;
-(void) demoPlayConfiguration5;
-(void) demoPlayConfiguration6;

@end




@protocol JWScrubberDemoDelegate <NSObject>

-(void)updateScrubberHeight:(JWScrubberDemoController*)controller;
-(NSURL*)scrubberDemoFile1URL:(JWScrubberDemoController*)controller;
-(NSURL*)scrubberDemoFile2URL:(JWScrubberDemoController*)controller;

-(id <JWScrubberBufferControllerDelegate>)scrubberBufferController:(JWScrubberDemoController*)controller;

-(void)scrubberDemoController:(JWScrubberDemoController*)controller
            registerController:(id <JWScrubberBufferControllerDelegate> )scrubberContoller withTrackId:(NSString*)trackId;

@end
