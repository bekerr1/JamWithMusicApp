//
//  JWRecorderTableViewCell.h
//  JamWIthT
//
//  co-created by joe and brendan kerr on 11/11/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JWUITransportButton.h"

@interface JWRecorderTableViewCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UISwitch *recorderSwitch;
@property (strong, nonatomic) IBOutlet UILabel *switchLabel;
@property (strong, nonatomic) IBOutlet JWUITransportButton *recordButton;
@property (nonatomic) BOOL recording;
@property (nonatomic) BOOL recordingEnabled;
@end
