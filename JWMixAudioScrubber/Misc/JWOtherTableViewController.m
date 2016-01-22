//
//  JWOtherTableViewController.m
//  JamWDev
//
//  Created by JOSEPH KERR on 1/21/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

#import "JWOtherTableViewController.h"

@implementation JWOtherTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIView *backgroundView = [UIView new];
    backgroundView.backgroundColor = [UIColor blackColor];
    self.tableView.backgroundView = backgroundView;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(nonnull UITableViewCell *)cell forRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    UIView *backgroundView = [UIView new];
    backgroundView.backgroundColor = [UIColor blackColor];
    cell.backgroundView = backgroundView;
}

@end
