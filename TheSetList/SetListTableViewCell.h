//
//  SetListTableViewCell.h
//  TheSetList
//
//  Created by Andrew Friedman on 1/18/15.
//  Copyright (c) 2015 Andrew Friedman. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SetListCellDelegate <NSObject>
@optional
-(void)addSongButtonPressedOnCell:(id)sender;
@end

@interface SetListTableViewCell : UITableViewCell

@property (strong, nonatomic) id delegate;
@property (strong, nonatomic) IBOutlet UILabel *songLabel;
@property (strong, nonatomic) IBOutlet UIImageView *userSelectedSongImageView;
@property (strong, nonatomic) IBOutlet UILabel *artistLabel;

//SearchTableViewCell properties
@property (strong, nonatomic) IBOutlet UIImageView *searchAlbumArtImage;
@property (strong, nonatomic) IBOutlet UILabel *searchSongTitle;
@property (strong, nonatomic) IBOutlet UILabel *searchArtist;
@property (strong, nonatomic) IBOutlet UILabel *searchDurationLabel;
@property (strong, nonatomic) IBOutlet UIButton *plusButton;
@property (strong, nonatomic) NSMutableDictionary *track;
@property (strong, nonatomic) IBOutlet UIButton *artistButton;


- (IBAction)artistButtonPressed:(UIButton *)sender;

- (IBAction)addSongButtonPressed:(UIButton *)sender;


@end
