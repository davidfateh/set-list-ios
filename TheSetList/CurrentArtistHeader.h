//
//  CurrentArtistHeader.h
//  TheSetList
//
//  Created by Andrew Friedman on 2/15/15.
//  Copyright (c) 2015 Andrew Friedman. All rights reserved.
//

#import "CollectionViewCell.h"

@interface CurrentArtistHeader : CollectionViewCell
@property (strong, nonatomic) IBOutlet UIImageView *artworkImage;
@property (strong, nonatomic) IBOutlet UILabel *artistLabel;
@property (strong, nonatomic) IBOutlet UILabel *songTitleLabel;
@property (strong, nonatomic) IBOutlet UIView *controlsBackgroundView;
@property (strong, nonatomic) IBOutlet UIImageView *skipImageView;
@property (strong, nonatomic) IBOutlet UIImageView *playPauseImageView;
- (IBAction)playPauseButtonPressed:(UIButton *)sender;
- (IBAction)skipButtonPressed:(UIButton *)sender;

@end
