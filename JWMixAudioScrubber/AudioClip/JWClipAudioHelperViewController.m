//
//  JWClipAudioHelperViewController.m
//  JamWDev
//
//  co-created by joe and brendan kerr on 1/24/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

#import "JWClipAudioHelperViewController.h"

@interface JWClipAudioHelperViewController () <UITextFieldDelegate>
@property (strong, nonatomic) IBOutlet UIButton *inchLeft;
@property (strong, nonatomic) IBOutlet UIButton *inchRight;
@property (strong, nonatomic) IBOutlet UITextField *minuteSeeker;
@property (strong, nonatomic) IBOutlet UITextField *secondSeeker;
@property (nonatomic) NSUInteger minuteInt;
@property (nonatomic) NSUInteger secondInt;
@end


@implementation JWClipAudioHelperViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.minuteSeeker.delegate = self;
    [self.minuteSeeker addTarget:self action:@selector(minuteEditing:) forControlEvents:UIControlEventEditingChanged];
    self.secondSeeker.delegate = self;
    [self.secondSeeker addTarget:self action:@selector(secondEditing:) forControlEvents:UIControlEventEditingChanged];
}

-(void)minuteEditing:(id)sender {
    UITextField *currentField = sender;
    NSLog(@"text did change to %@.", currentField.text);
    self.minuteInt = [currentField.text integerValue];
    [self.minuteSeeker resignFirstResponder];
    [self.secondSeeker becomeFirstResponder];
    
}

-(void)secondEditing:(id)sender {
    UITextField *currentField = sender;
    NSLog(@"text did change to %@.", currentField.text);
    if (self.minuteSeeker.text.length == 0) {
        self.minuteSeeker.text = @"0";
    }
    
    if (currentField.text.length == 2) {
        self.secondInt = [currentField.text integerValue];
        [self.secondSeeker resignFirstResponder];
        [self seekToPositionComplete];
    }
    
}


-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    //NSLog(@"text did change to %@.", textField.text);
    
    NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
    NSNumber * n = [f numberFromString:string];
    NSLog(@"N: %@", n);
    
    if (!n) {
        return NO;
    }
    return YES;
    
}

-(BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    NSLog(@"%s", __func__);
    return YES;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSLog(@"%s", __func__);
    return YES;
}

//Delegate

-(void)seekToPositionComplete {
    NSLog(@"Time to get the position to seek to.");
    NSUInteger userEnteredSeconds = self.minuteInt * 60 + self.secondInt;
    [_delegate seekToPositionInSeconds:userEnteredSeconds];
    
}

-(IBAction)inchLeft:(id)sender {
    [_delegate inchLeftPressed];
}

-(IBAction)inchRight:(id)sender {
    [_delegate inchRightPressed];
}

-(IBAction)textFieldActive:(UITextField *)sender {
    
    
}

-(void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
