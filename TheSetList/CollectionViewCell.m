//
//  CollectionViewCell.m
//  TheSetList
//
//  Created by Andrew Friedman on 2/15/15.
//  Copyright (c) 2015 Andrew Friedman. All rights reserved.
//

#import "CollectionViewCell.h"

@implementation CollectionViewCell

- (IBAction)deleteSongButtonPressed:(UIButton *)sender
{
    [self.delegate deleteSongButtonPressedOnCell:self];
}
@end
