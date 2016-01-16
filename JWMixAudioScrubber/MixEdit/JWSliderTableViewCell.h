//
//  JWSliderTableViewCell.h
//  JamWIthT
//
//  Created by JOSEPH KERR on 10/15/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JWSliderTableViewCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UISlider *slider;
@property (strong, nonatomic) IBOutlet UILabel *sliderLabel;
@end
