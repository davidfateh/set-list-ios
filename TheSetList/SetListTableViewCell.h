//
//  SetListTableViewCell.h
//  TheSetList
//
//  Created by Andrew Friedman on 1/18/15.
//  Copyright (c) 2015 Andrew Friedman. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SetListTableViewCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UILabel *songLabel;
@property (strong, nonatomic) IBOutlet UIView *userSelectedQueueIndicator;



//SearchTableViewCell properties
@property (strong, nonatomic) IBOutlet UIImageView *searchAlbumArtImage;
@property (strong, nonatomic) IBOutlet UILabel *searchSongTitle;
@property (strong, nonatomic) IBOutlet UILabel *searchArtist;
@property (strong, nonatomic) IBOutlet UILabel *searchDurationLabel;
@property (strong, nonatomic) IBOutlet UIButton *plusButton;




@end
