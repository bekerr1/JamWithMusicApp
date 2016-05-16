//
//  JWAWSFacbookAuthViewController.m
//  JamWDev
//
//  Created by brendan kerr on 4/8/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

#import "JWAWSFacbookAuthViewController.h"
#import "JWAWSIdentityManager.h"
#import "JWAWSDynamoDBManager.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>




@interface JWAWSFacbookAuthViewController() <FBSDKLoginButtonDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, copy) NSString *userId;
@property (nonatomic) FBSDKLoginButton *loginButton;
@property (nonatomic) NSMutableArray *trackSet;
@property (nonatomic) NSMutableDictionary *displayedUser;
@property (nonatomic) NSString *musicPath;
@property (weak, nonatomic) IBOutlet UITableView *dynamoTableView;
@property (weak, nonatomic) IBOutlet UIButton *queuedTrackButton;
@property (weak, nonatomic) IBOutlet UIButton *supplyTrackButton;

@end
@implementation JWAWSFacbookAuthViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSError *error;
    
    self.musicPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Musicfolder"];
    self.trackSet = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.musicPath error:&error] mutableCopy];
    
    
    self.dynamoTableView.delegate = self;
    self.dynamoTableView.dataSource = self;
    
    self.queuedTrackButton.backgroundColor = [UIColor greenColor];
    self.supplyTrackButton.backgroundColor = [UIColor greenColor];
    
    self.loginButton = [[FBSDKLoginButton alloc] init];
    NSArray *readPermissions = @[@"public_profile", @"email", @"user_actions.music"];
    [self.loginButton setReadPermissions:readPermissions];
    self.loginButton.center = self.view.center;
    [self.view addSubview:self.loginButton];
    self.loginButton.delegate = self;
    
}




//-(void)viewDidAppear:(BOOL)animated {
//    [super viewDidAppear:animated];
//    
//    if ([[JWAWSIdentityManager sharedInstance] isLoggedInWithFacebook]) {
//        NSLog(@"Already Logged In");
//        [self performSegueWithIdentifier:@"UserName" sender:nil];
//    }
//}




-(void)loginButton:(FBSDKLoginButton *)loginButton didCompleteWithResult:(FBSDKLoginManagerLoginResult *)result error:(NSError *)error {
    
    if (error) {
        NSLog(@"%@", [error description]);
    } else if (result.isCancelled) {
        NSLog(@"Cancelled.");
    } else {
        NSLog(@"Token recived.");
        
        [self.loginButton removeFromSuperview];
        [[JWAWSIdentityManager sharedInstance] completeFBLoginWithCompletion:^id(AWSTask *task) {
            NSLog(@"Completion.");
            dispatch_async(dispatch_get_main_queue(), ^{
                [self performSegueWithIdentifier:@"UserName" sender:nil];
            });
            return nil;
        }];
        
    }
    
}



-(void)loginButtonDidLogOut:(FBSDKLoginButton *)loginButton {
    NSLog(@"%s", __func__);
}



//- (IBAction)continueButtonPressed:(UIButton *)sender {
//    
////    NSLog(@"%@", [[JWAWSIdentityManager sharedInstance] identityId]);
//    [[JWAWSDynamoDBManager sharedInstance] createNewUserWithId:[[JWAWSIdentityManager sharedInstance] identityId] suppliedUserName:@"MyAxeAndMe" faceBookName:@"Brendan Kerr"];
//    
//    [self performSegueWithIdentifier:@"DisplayData" sender:nil];
//    
//    
//}




- (IBAction)addTrackFromList:(UIButton *)sender {
    
    NSString *trackname = [self.trackSet firstObject];
    [self.trackSet removeObjectAtIndex:0];
    NSString *trackURLString = [NSString stringWithFormat:@"%@/%@", self.musicPath, trackname];
    NSLog(@"%@", trackURLString);
    NSURL *trackURL = [NSURL fileURLWithPath:trackURLString];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:trackURLString]) {
        NSLog(@"File exists.");
    }
    
    self.queuedTrackButton.backgroundColor = [UIColor redColor];
    
    [[JWAWSDynamoDBManager sharedInstance] uploadObjectTo:AMAZON_S3_BUCKET_NAME usingIdentifier:trackname fromLocation:trackURL completionHandler:^(id returnedWith) {
        NSLog(@"Upload returned with object: %@", [returnedWith description]);
        self.queuedTrackButton.backgroundColor = [UIColor greenColor];
        
        //Once the user has succesfully added the jam track to S3, that jam track can be added to
        //DynamoDB and displayed to other users so they have the option of downloading it
        [[JWAWSDynamoDBManager sharedInstance] createNewJamTrackForUser:[[JWAWSIdentityManager sharedInstance] identityId] jamtrackName:trackname parameters:nil];
        
    }];
    
}



- (IBAction)promptUserForURL:(UIButton *)sender {
    
    
}



#pragma mark - TableView

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 5;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    return self.displayedUser[@"user"];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    return cell;
}




@end
