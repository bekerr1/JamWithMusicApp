//
//  JWEffectParametersTableViewCell.h
//  JamWIthT
//
//  Created by brendan kerr on 11/3/15.
//  Copyright © 2015 JOSEPH KERR. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JWEffectParametersTableViewCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UISlider *effectParameter1;
@property (strong, nonatomic) IBOutlet UISlider *effectParameter2;
@property (strong, nonatomic) IBOutlet UISlider *effectParameter3;
@property (strong, nonatomic) IBOutlet UILabel *parameterLabel1;
@property (strong, nonatomic) IBOutlet UILabel *parameterLabel2;
@property (strong, nonatomic) IBOutlet UILabel *parameterLabel3;
@property (strong, nonatomic) IBOutlet UILabel *nodeTitleLabel;


@end
