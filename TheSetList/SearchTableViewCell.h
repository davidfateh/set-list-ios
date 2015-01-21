//
//  SearchTableViewCell.h
//  TheSetList
//
//  Created by Andrew Friedman on 1/20/15.
//  Copyright (c) 2015 Andrew Friedman. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SearchTableViewCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UIImageView *albumArtImage;
@property (strong, nonatomic) IBOutlet UILabel *songTitleLabel;
@property (strong, nonatomic) IBOutlet UILabel *artistLabel;
@property (strong, nonatomic) IBOutlet UILabel *songDurationLabel;

@end
