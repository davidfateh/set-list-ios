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
    UIImage *plusImage = [UIImage imageNamed:@"plusImage"];
    [self.plusButton setBackgroundImage:plusImage forState:UIControlStateNormal];
    self.plusButton.enabled = YES;
    
    [super prepareForReuse];
}

- (IBAction)addSongButtonPressed:(UIButton *)sender
{
    [self.delegate addSongButtonPressedOnCell:self];
    
    UIImage *checkImage = [UIImage imageNamed:@"check.png"];
    [self.plusButton setBackgroundImage:checkImage forState:UIControlStateNormal];
    
    //Make the button pop up and down into a checkmark.
    sender.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.001, 0.001);
    [sender.superview addSubview:sender];
    
    [UIView animateWithDuration:0.3/1.5 animations:^{
        sender.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.1, 1.1);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3/2 animations:^{
            sender.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.9, 0.9);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.3/2 animations:^{
                sender.transform = CGAffineTransformIdentity;
                sender.enabled = NO;
            }];
        }];
    }];

}
- (IBAction)xButtonPressed:(UIButton *)sender {
}
@end
