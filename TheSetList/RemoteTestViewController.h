//
//  RemoteTestViewController.h
//  TheSetList
//
//  Created by Andrew Friedman on 1/26/15.
//  Copyright (c) 2015 Andrew Friedman. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RemoteTestViewController : UIViewController
@property (strong, nonatomic) IBOutlet UITextField *passwordTextField;
- (IBAction)connectButtonPressed:(UIButton *)sender;
@property (strong, nonatomic) IBOutlet UIImageView *remoteLogoImageView;
@property (strong, nonatomic) IBOutlet UIButton *skipButton;
@property (strong, nonatomic) IBOutlet UIButton *playPauseButton;
- (IBAction)skipButtonPressed:(id)sender;
- (IBAction)playPauseButtonPressed:(UIButton *)sender;

@end
