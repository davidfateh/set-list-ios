//
//  SetListTableViewCell.m
//  TheSetList
//
//  Created by Andrew Friedman on 1/18/15.
//  Copyright (c) 2015 Andrew Friedman. All rights reserved.
//

#import "SetListTableViewCell.h"

@implementation SetListTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)prepareForReuse
{
    [super prepareForReuse];
    self.plusButton.enabled = YES;
}

- (IBAction)addSongButtonPressed:(UIButton *)sender
{
    [self.delegate addSongButtonPressedOnCell:self];
    sender.enabled = NO;
    UIImage *checkImage = [UIImage imageNamed:@"check.png"];
    [self.addSongPlusImageView setImage:checkImage];
    
    //Make the button pop up and down into a checkmark.
    self.addSongPlusImageView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.001, 0.001);
    
    [UIView animateWithDuration:0.3/1.5 animations:^{
        self.addSongPlusImageView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.1, 1.1);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3/2 animations:^{
            self.addSongPlusImageView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.9, 0.9);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.3/2 animations:^{
                self.addSongPlusImageView.transform = CGAffineTransformIdentity;
            }];
        }];
    }];

}

@end
