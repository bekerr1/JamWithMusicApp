//
//  JWSliderAndSwitchTableViewCell.h
//  JamWIthT
//
//  Created by JOSEPH KERR on 10/22/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JWSliderAndSwitchTableViewCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UISlider *slider;
@property (strong, nonatomic) IBOutlet UILabel *sliderLabel;
@property (strong, nonatomic) IBOutlet UISwitch *switchControl;
@property (strong, nonatomic) IBOutlet UILabel *nodeTitleLabel;
@end
