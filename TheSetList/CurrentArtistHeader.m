//
//  CurrentArtistHeader.m
//  TheSetList
//
//  Created by Andrew Friedman on 2/15/15.
//  Copyright (c) 2015 Andrew Friedman. All rights reserved.
//

#import "CurrentArtistHeader.h"
#import <CSStickyHeaderFlowLayoutAttributes.h>

@implementation CurrentArtistHeader

- (void)applyLayoutAttributes:(CSStickyHeaderFlowLayoutAttributes *)layoutAttributes {
    
    [UIView beginAnimations:@"" context:nil];
    if (layoutAttributes.progressiveness <= 0.58) {
        self.self.controlsBackgroundView.alpha = .85;
    } else {
        self.controlsBackgroundView.alpha = 0;
    }
    if (layoutAttributes.progressiveness <= 0.2) {
        self.self.artistView.alpha = 0;
    } else {
        self.artistView.alpha = 1;
    }

    [UIView commitAnimations];
}


- (IBAction)playPauseButtonPressed:(UIButton *)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"playPausePressed" object:nil];
}

- (IBAction)skipButtonPressed:(UIButton *)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"skipPressed" object:nil];
}
@end
