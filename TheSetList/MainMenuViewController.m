//
//  MainMenuViewController.m
//  TheSetList
//
//  Created by Andrew Friedman on 2/8/15.
//  Copyright (c) 2015 Andrew Friedman. All rights reserved.
//

#import "MainMenuViewController.h"
#import "SocketKeeperSingleton.h"
#import <SIOSocket/SIOSocket.h>
#import "SetListRoomViewController.h"
#import "RadialGradiantView.h"

#define HOST_URL @"http://54.152.215.221/"

@interface MainMenuViewController ()
@property (strong, nonatomic) SIOSocket *socket;
@property (nonatomic) BOOL isHost;
@property (nonatomic) BOOL joinLabelPushed;
@property (nonatomic) BOOL hostLabelPushed;
@property (nonatomic) BOOL joinLabelSelected;
@property (nonatomic) BOOL hostLabelSelected;
@property (strong, nonatomic) UIVisualEffectView *blurEffectView;
@end

@implementation MainMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //Add the radial gradient subview to the background.
    RadialGradiantView *radiantBackgroundView = [[RadialGradiantView alloc] initWithFrame:self.view.bounds];
    [self.backgroundView addSubview:radiantBackgroundView];
    
    self.exitJoinRoomImageView.transform = CGAffineTransformMakeRotation(M_PI/4);
    
    //Create A blur
    UIVisualEffect *blurEffect;
    blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *visualEffectView;
    visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    visualEffectView.frame = self.view.bounds;
    visualEffectView.alpha = 0;
    [self.menuView addSubview:visualEffectView];
    self.blurEffectView = visualEffectView;
    
    /////////JOIN ROOM VIEW///////////
    //Create a toolbar to push to the next view.
    UIToolbar* numberToolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, 320, 50)];
    numberToolbar.barStyle = UIBarStyleBlackTranslucent;
    UIBarButtonItem *joinButton = [[UIBarButtonItem alloc]initWithTitle:@"\u279e" style:UIBarButtonItemStyleDone target:self action:@selector(doneWithNumberPad)];
    
    numberToolbar.items = [NSArray arrayWithObjects:
                           [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                           joinButton, [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                           nil];
    [numberToolbar sizeToFit];
    self.roomCodeTextField.delegate = self;
    self.roomCodeTextField.inputAccessoryView = numberToolbar;
    self.roomCodeTextField.tintColor = [UIColor whiteColor];
}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveInitializeNotification:)
                                                 name:kInitialize
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveOnConnectNotification:)
                                                 name:kOnConnect
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveOnHostRoomConnectNotification:)
                                                 name:kOnHostRoomConnect
                                               object:nil];
    
    SocketKeeperSingleton *socketSingleton = [SocketKeeperSingleton sharedInstance];
    NSString *hostURLwithRoomCode = [NSString stringWithFormat:@"%@",HOST_URL];
    [socketSingleton startSocketWithHost:hostURLwithRoomCode];

    [self returnedToMenu];
    self.roomCodeTextField.inputAccessoryView.hidden = YES;
    self.roomCodeTextField.text = nil;
    self.menuView.alpha = 0;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [UIView animateWithDuration:.5 delay:.6 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.menuView.alpha = 1;
    } completion:^(BOOL finished) {
        //completed
    }];
}


#pragma mark - Notifications

-(void)receiveOnHostRoomConnectNotification:(NSNotification *)notificaiton
{
    [[NSNotificationCenter defaultCenter]removeObserver:self name:kInitialize     object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:kOnHostRoomConnect object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:kOnConnect object:nil];
    
    dispatch_async(dispatch_get_main_queue(), ^{
            [self performSegueWithIdentifier:@"toSetListRoomVC" sender:self];
    });
}

-(void)receiveOnConnectNotification:(NSNotification *)notificaiton
{
    self.socket = [[SocketKeeperSingleton sharedInstance]socket];
    NSLog(@"Connected to server");
}

-(void)receiveInitializeNotification:(NSNotification *)notificaiton
{
    [[NSNotificationCenter defaultCenter]removeObserver:self name:kInitialize     object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:kOnHostRoomConnect object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:kOnConnect object:nil];
    if (self.joinLabelSelected) {
        self.roomCodeTextField.inputAccessoryView.hidden = YES;
        [self.roomCodeTextField resignFirstResponder];
        self.menuView.hidden = YES;
        [self returnJoinLabel];
        [UIView animateWithDuration:.25 animations:^{
            self.roomCodeView.alpha = 0;
            self.blurEffectView.alpha = 0;
        } completion:^(BOOL finished) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self performSegueWithIdentifier:@"toSetListRoomVC" sender:self];
            });
            
        }];
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self performSegueWithIdentifier:@"toSetListRoomVC" sender:self];
        });
    }
}

#pragma mark - Navigation

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    //Send the room code to be displayed on the respective view controllers.
    if ([segue.identifier isEqualToString:@"toSetListRoomVC"]) {
        SetListRoomViewController *setListVC = segue.destinationViewController;
        setListVC.roomCode = self.roomCodeTextField.text;
    }
    
}

#pragma mark - Room Code

-(void)doneWithNumberPad{
    
    NSString *numberFromTheKeyboard = self.roomCodeTextField.text;
    [self.roomCodeTextField resignFirstResponder];
    NSDictionary *startDic = @{@"room" :numberFromTheKeyboard};
    NSArray *startArray = @[startDic];
    [self.socket emit:@"mobile connect" args:startArray];
}

//The user should not be allowed to enter more than 4 digits.
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string

{
    //Room Codes are only 4 digits.
    if (textField.tag == 2) {
        // Prevent crashing undo bug – see note below.
        if(range.length + range.location > textField.text.length)
        {
            return NO;
        }
        
        NSUInteger newLength = [textField.text length] + [string length] - range.length;
        return (newLength > 4) ? NO : YES;
    }
    
    return YES;
}

-(IBAction)handlePan:(UIPanGestureRecognizer *)recognizer
{
    CGPoint translation = [recognizer translationInView:self.view];
    recognizer.view.center = CGPointMake(recognizer.view.center.x, recognizer.view.center.y + translation.y);
    self.lineView1.center = CGPointMake(self.lineView1.center.x, recognizer.view.center.y + translation.y - 337.5f);
    self.lineView2.center = CGPointMake(self.lineView2.center.x, recognizer.view.center.y +translation.y + 337.5f);
    [recognizer setTranslation:CGPointMake(0, 0) inView:self.view];
    
    //Animate the joinLabel when the slider comes into the correct coordinates

    
    if ((recognizer.view.center.y + translation.y)>246 && (recognizer.view.center.y + translation.y)<293) {
        self.joinLabelPushed = YES;
        [UIView animateWithDuration:.25 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            [self.joinLabel setCenter:CGPointMake(183, 267)];
            self.joinLabel.alpha = 1;
        } completion:^(BOOL finished) {
            self.joinLabelSelected = YES;
        }];
    }
    else
    {
        if (self.joinLabelPushed && !((recognizer.view.center.y + translation.y)>246 && (recognizer.view.center.y + translation.y)<293)) {
            [self returnJoinLabel];
        }
    }
    //Animate the host label when slider comes into correct coordinates.
    if ((recognizer.view.center.y + translation.y)>313 && (recognizer.view.center.y + translation.y)<357) {
        self.hostLabelPushed = YES;
        [UIView animateWithDuration:.25 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            [self.hostLabel setCenter:CGPointMake(179.5f, 336)];
            self.hostLabel.alpha = 1;
        } completion:^(BOOL finished) {
            self.hostLabelSelected = YES;
        }];
        
    }
    else
    {
        if (self.hostLabelPushed && !((recognizer.view.center.y + translation.y)>313 && (recognizer.view.center.y + translation.y)<357)) {
            [self returnHostLabel];
        }
    }

    
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        
        //When the user selects the join room option
        if (self.joinLabelSelected) {
            self.roomCodeView.alpha = 0;
            self.roomCodeView.hidden = NO;
            self.exitJoinRoomImageView.hidden = YES;
            [UIView animateWithDuration:.3 animations:^{
                self.menuView.alpha = 0;
                self.roomCodeView.alpha = 1;
                self.blurEffectView.alpha = 1;
            } completion:^(BOOL finished) {
                self.menuView.hidden = YES;
                self.roomCodeTextField.inputAccessoryView.hidden = NO;
                [self.roomCodeTextField becomeFirstResponder];
                [self returnSliderWithRecognizer:recognizer];
                self.exitJoinRoomImageView.center = CGPointMake(self.exitJoinRoomImageView.center.x, self.exitJoinRoomImageView.center.y -75);
                self.exitJoinRoomImageView.hidden = NO;
                [UIView animateWithDuration:.5 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                    self.exitJoinRoomImageView.center = CGPointMake(self.exitJoinRoomImageView.center.x, self.exitJoinRoomImageView.center.y + 75);
                } completion:^(BOOL finished) {
                    //completion
                }];
                
            }];
    }
        
        //when the user selects the host room option
        else if (self.hostLabelSelected) {
            [self.socket emit:@"start room"];
            [UIView animateWithDuration:.25 animations:^{
                self.menuView.alpha = 0;
            } completion:^(BOOL finished)
            {
                [self returnSliderWithRecognizer:recognizer];
                [self returnHostLabel];
            }];

        }
        else {
            //animates the slider back to its original coordinates
            [self returnSliderWithRecognizer:recognizer];
          }
    }
}

-(IBAction)handleTap:(UITapGestureRecognizer *)recognizer
{
    
    [UIView animateWithDuration:.1 delay:.2 options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         self.sliderImageView.center = CGPointMake(self.sliderImageView.center.x, 71.5f);
                         self.lineView1.center = CGPointMake(281, -266);
                         self.lineView2.center = CGPointMake(281, 409);
                     } completion:^(BOOL finished) {
                         
                         [UIView animateWithDuration:.1 animations:^{
                             self.sliderImageView.center = CGPointMake(self.sliderImageView.center.x, 99.5);
                             self.lineView1.center = CGPointMake(281, -238);
                             self.lineView2.center = CGPointMake(281, 437);                             } completion:^(BOOL finished) {
                                 
                                 [UIView animateWithDuration:.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                                     //Animation
                                 } completion:^(BOOL finished) {
                                     self.sliderImageView.center = CGPointMake(self.sliderImageView.center.x, 91.5f);
                                     self.lineView1.center = CGPointMake(281, -246);
                                     self.lineView2.center = CGPointMake(281, 429);
                                 }];
                                 
                             }];
                         
                     }];
    
}

- (IBAction)exitJoinRoomViewButtonPressed:(UIButton *)sender
{
    
    [self.joinLabel setCenter:CGPointMake(222,267)];
    self.joinLabel.alpha = .5;
    [self.roomCodeTextField resignFirstResponder];
    self.roomCodeTextField.text = nil;
    self.joinLabelPushed = NO;
    self.joinLabelSelected = NO;
    self.menuView.alpha = 0;
    self.menuView.hidden = NO;
    [UIView animateWithDuration:.3 animations:^{
        self.menuView.alpha = 1;
        self.roomCodeView.alpha = 0;
        self.blurEffectView.alpha = 0;
    } completion:^(BOOL finished) {
        self.roomCodeView.hidden = YES;
    }];
}

-(void)returnedToMenu
{
    self.joinLabelPushed = NO;
    self.joinLabelSelected = NO;
    self.menuView.alpha = 1;
    self.menuView.hidden = NO;
    self.blurEffectView.alpha = 0;
    self.roomCodeView.hidden = YES;
}

-(void)returnSliderWithRecognizer:(UIPanGestureRecognizer *)recognizer
{
    [UIView animateWithDuration:.2 delay:0 options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         recognizer.view.center = CGPointMake(recognizer.view.center.x, 71.5f);
                         self.lineView1.center = CGPointMake(281, -266);
                         self.lineView2.center = CGPointMake(281, 409);
                     } completion:^(BOOL finished) {
                         
                         [UIView animateWithDuration:.2 animations:^{
                             recognizer.view.center = CGPointMake(recognizer.view.center.x, 99.5);
                             self.lineView1.center = CGPointMake(281, -238);
                             self.lineView2.center = CGPointMake(281, 437);                             } completion:^(BOOL finished) {
                                 [UIView animateWithDuration:.1 animations:^{
                                     recognizer.view.center = CGPointMake(recognizer.view.center.x, 91.5f);
                                     self.lineView1.center = CGPointMake(281, -246);
                                     self.lineView2.center = CGPointMake(281, 429);
                                     
                                 }];
                             }];
                         
                     }];

}

-(void)returnJoinLabel
{
    self.joinLabelSelected = NO;
    [UIView animateWithDuration:.25 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        [self.joinLabel setCenter:CGPointMake(222,267)];
        self.joinLabel.alpha = .5;
        self.joinLabelPushed = NO;
    } completion:^(BOOL finished) {
        self.joinLabelSelected = NO;
    }];

}

-(void)returnHostLabel
{
    self.hostLabelSelected = NO;
    [UIView animateWithDuration:.25 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        [self.hostLabel setCenter:CGPointMake(219.5f, 336)];
        self.hostLabel.alpha = .5;
        self.hostLabelPushed = NO;
    } completion:^(BOOL finished) {
        self.hostLabelSelected = NO;
    }];

}

@end
