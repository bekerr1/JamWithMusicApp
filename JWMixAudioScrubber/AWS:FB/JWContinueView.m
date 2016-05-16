//
//  JWContinueView.m
//  JamWDev
//
//  Created by brendan kerr on 5/10/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

#import "JWContinueView.h"
#import "JWAWSDynamoDBManager.h"
#import "JWAWSIdentityManager.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

@interface JWContinueView()

@property (nonatomic) UILabel *userNamePromptLabel;
@property (nonatomic) UILabel *illigalActionLabel;
@property (nonatomic) UITextField *userNameTextField;
@property (nonatomic) UIButton *continueButton;

@end
@implementation JWContinueView

#define LABEL_WIDTH_OFFSET 50
#define LABEL_HEIGHT 200
#define ILLIGAL_LABEL_HEIGHT 60
#define ILLIGAL_LABEL_OFFSET 150
#define TEXT_HEIGHT 44
#define CENTER_X self.center.x
#define BUTTON_WIDTH 200
#define BUTTON_HEIGHT 40

-(instancetype)initWithFrame:(CGRect)frame {
    
    if (self = [super initWithFrame:frame]) {
        
        //LABEL
        self.userNamePromptLabel = [[UILabel alloc]
                                    initWithFrame:CGRectMake(0, 0, self.frame.size.width - LABEL_WIDTH_OFFSET, LABEL_HEIGHT)];
        self.userNamePromptLabel.textAlignment = NSTextAlignmentCenter;
        self.userNamePromptLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.userNamePromptLabel.textColor = [UIColor whiteColor];
        self.userNamePromptLabel.numberOfLines = 0;
        [self.userNamePromptLabel setText:@"Create A Username!"];
        
        self.illigalActionLabel = [[UILabel alloc]
                                    initWithFrame:CGRectMake(0, 0, self.frame.size.width - ILLIGAL_LABEL_OFFSET, ILLIGAL_LABEL_HEIGHT)];
        self.illigalActionLabel.textAlignment = NSTextAlignmentCenter;
        self.illigalActionLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.illigalActionLabel.textColor = [UIColor redColor];
        self.illigalActionLabel.numberOfLines = 0;
        
        
        //TEXTFIELD
        self.userNameTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width - LABEL_WIDTH_OFFSET, TEXT_HEIGHT)];
        [self.userNameTextField setBackgroundColor:[UIColor whiteColor]];
        
        //BUTTON
        self.continueButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [self.continueButton setFrame:CGRectMake(0, 0, BUTTON_WIDTH, BUTTON_HEIGHT)];
        [self.continueButton setBackgroundColor:[UIColor darkGrayColor]];
        [self.continueButton addTarget:self action:@selector(continueButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self.continueButton setTitle:@"Register" forState:UIControlStateNormal];
        [self.continueButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        
        
        
        self.userNamePromptLabel.center = CGPointMake(CENTER_X, 200);
        self.userNameTextField.center = CGPointMake(CENTER_X, 300);
        self.illigalActionLabel.center = CGPointMake(CENTER_X, self.userNameTextField.center.y - 50);
        self.continueButton.center = CGPointMake(CENTER_X, 400);
        
        [self addSubview:self.userNamePromptLabel];
        [self addSubview:self.userNameTextField];
        [self addSubview:self.continueButton];
        
    }
    
    return self;
}


- (IBAction)continueButtonPressed:(UIButton *)sender {
    
    if (self.userNameTextField.text == nil) {
        
        [self illigalActionCommited:JWIlligalRegisterActionEmptyUsername];
        
    } else {
        
        [FBSDKProfile loadCurrentProfileWithCompletion:^(FBSDKProfile *current, NSError *error) {
            NSLog(@"%s currentProfileBlock", __func__);
            
            NSAssert(current != nil, @"nil profile");
            
            [[JWAWSDynamoDBManager sharedInstance] createNewUserWithId:[[JWAWSIdentityManager sharedInstance] identityId] suppliedUserName:self.userNameTextField.text faceBookName:[NSString stringWithFormat:@"%@ %@", current.firstName, current.lastName] completionHandler:^ {
                [_delegate registrationComplete];
            }];
            
            
            
        }];
    }
    
}

-(void)illigalActionCommited:(JWIlligalRegisterAction)action {
    
    switch (action) {
        case JWIlligalRegisterActionEmptyUsername:
            //no username supplied (blank text field)
            
            break;
            
        case JWIlligalRegisterActionUsernameFormatError:
            //formatted wrong (character count)
            break;
            
        case JWIlligalRegisterActionUsernameTaken:
            //username alread taken (found after database query)
            break;
            
        default:
            break;
    }
    
}

@end
