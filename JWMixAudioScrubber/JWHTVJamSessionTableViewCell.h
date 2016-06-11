//
//  JWHTVJamSessionCellTableViewCell.h
//  JamWDev
//
//  Created by brendan kerr on 5/16/16.
//  Copyright © 2016 JOSEPH KERR. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JWHTVJamSessionTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIButton *previewAudioButton;
@property (weak, nonatomic) IBOutlet UILabel *titleAuthor;
@property (weak, nonatomic) IBOutlet UILabel *duration;
@property (weak, nonatomic) IBOutlet UILabel *trackCount;
@property (weak, nonatomic) IBOutlet UILabel *genre;
@property (weak, nonatomic) IBOutlet UILabel *tonalKey;
@property (weak, nonatomic) IBOutlet UILabel *instrument;
@property (weak, nonatomic) IBOutlet UIButton *buttonImage;
@property (nonatomic) NSMutableArray *audioURLsForThisCell;

@end
