//
//  CollectionViewCell.h
//  TheSetList
//
//  Created by Andrew Friedman on 2/15/15.
//  Copyright (c) 2015 Andrew Friedman. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol CollectionViewCellDelegate <NSObject>
@optional
-(void)deleteSongButtonPressedOnCell:(id)sender;
@end
@interface CollectionViewCell : UICollectionViewCell
@property (weak, nonatomic) id delegate;
@property (strong, nonatomic) IBOutlet UILabel *songTitleLabel;
@property (strong, nonatomic) IBOutlet UILabel *artistLabel;
@property (strong, nonatomic) IBOutlet UIImageView *deleteSongImageView;
@property (strong, nonatomic) IBOutlet UIButton *deleteSongButton;
@property (strong, nonatomic) IBOutlet UIImageView *purpleDotIndicator;

- (IBAction)deleteSongButtonPressed:(UIButton *)sender;
@end
