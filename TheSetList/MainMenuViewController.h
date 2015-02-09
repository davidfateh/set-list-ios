//
//  MainMenuViewController.h
//  TheSetList
//
//  Created by Andrew Friedman on 2/8/15.
//  Copyright (c) 2015 Andrew Friedman. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface MainMenuViewController : UIViewController

/////MAIN MENU VIEW
@property (strong, nonatomic) IBOutlet UIView *menuView;
@property (strong, nonatomic) IBOutlet UIView *mainMenuView;
@property (strong, nonatomic) IBOutlet UIView *backgroundView;
@property (weak, nonatomic) IBOutlet UIImageView *sliderImageView;
@property (strong, nonatomic) IBOutlet UILabel *joinLabel;
@property (strong, nonatomic) IBOutlet UILabel *hostLabel;
@property (strong, nonatomic) IBOutlet UIView *lineView1;
@property (strong, nonatomic) IBOutlet UIView *lineView2;
-(IBAction)handlePan:(UIPanGestureRecognizer *)recognizer;
-(IBAction)handleTap:(UITapGestureRecognizer *)recognizer;


/////JOIN ROOM VIEW
@property (strong, nonatomic) IBOutlet UIView *roomCodeView;
@property (strong, nonatomic) IBOutlet UITextField *roomCodeTextField;
@property (strong, nonatomic) IBOutlet UILabel *roomCodeLabel;
@property (strong, nonatomic) IBOutlet UIImageView *exitJoinRoomImageView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *exitJoinRoomVertConst;
@property (strong, nonatomic) IBOutlet UIButton *exitJoinRoomViewButton;

- (IBAction)exitJoinRoomViewButtonPressed:(UIButton *)sender;


@end
