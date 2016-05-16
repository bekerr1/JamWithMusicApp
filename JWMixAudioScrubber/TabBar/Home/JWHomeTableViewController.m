//
//  JWHomeTableViewController.m
//  JamWDev
//
//  Created by brendan kerr on 4/17/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//


/*
 
 Home controller purpose - Home controller serves as an area for the user to see:
    *Sessions started.
    *Following artists uploaded tracks
    *
 
 Home controller list -
    -Home items
        -Jamtracksets (get from filemanager)
            -session_"key"
        -People you follow's jamtracks (get from aws)
        -
 
 
 */
#import "JWHomeTableViewController.h"
#import "JWFileManager.h"

@interface JWHomeTableViewController()

@property UIImage *scrubberWhiteImage;
@property UIImage *scrubberBlueImage;
@property UIImage *scrubberGreenImage;

@end

@implementation JWHomeTableViewController


-(void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"%s", __func__);
    self.homeControllerData = [[JWFileManager defaultManager] homeItemsList];
    
    _scrubberBlueImage = [UIImage imageNamed:@"scrubberIconBlue"];
    _scrubberWhiteImage = [UIImage imageNamed:@"scrubberIconWhite"];
    _scrubberGreenImage = [UIImage imageNamed:@"scrubberIconGreen"];
    
    UIView *backgroundView = [UIView new];
    backgroundView.backgroundColor = [UIColor blackColor];
    self.tableView.backgroundView = backgroundView;
    
    [self.tableView reloadData];
}



#pragma mark - TABLE VIEW DELEGATE


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [self.homeControllerData[section] count];
    
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return [self.homeControllerData count];
}


//TODO: customize this so it reflects the title of each section
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section  {
    
    
    //UITableViewHeaderFooterView *view = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"JWHeaderViewX"];
//    if (view == nil)
//        view = [[UITableViewHeaderFooterView alloc] initWithReuseIdentifier:@"JWHeaderViewX"];
    
    UITableViewHeaderFooterView *view = [UITableViewHeaderFooterView new];
    view.contentView.backgroundColor = [UIColor blackColor];
    view.textLabel.textColor = [UIColor yellowColor];
    view.textLabel.text = self.homeControllerData[section][@"title"];
    return view;
    
}


/*



-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    
}

 //
 //- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
 //
 //    NSUInteger numberOfSessions = [self.homeControllerList[@"jamtracksets"] count];
 //
 //    NSAttributedString *titleheader = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%ld Jam Sessions", numberOfSessions] attributes:nil];
 //
 //    return
 //
 //}


-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

 
*/



#pragma mark - FILE SYSTEM (THINKING ABOUT SINGLETON)



@end
