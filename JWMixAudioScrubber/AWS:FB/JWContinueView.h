//
//  JWContinueView.h
//  JamWDev
//
//  Created by brendan kerr on 5/10/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, JWIlligalRegisterAction) {
    JWIlligalRegisterActionEmptyUsername = 1,
    JWIlligalRegisterActionUsernameTaken,
    JWIlligalRegisterActionUsernameFormatError
};

@protocol ContinueViewDelegate <NSObject>

-(void)registrationComplete;

@end

@interface JWContinueView : UIView <UITextFieldDelegate>

@property (nonatomic) id <ContinueViewDelegate> delegate;


@end
