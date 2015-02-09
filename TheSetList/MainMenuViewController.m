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


@interface MainMenuViewController ()
@property (strong, nonatomic) SIOSocket *socket;
@property (nonatomic) BOOL isHost;
@property (nonatomic) BOOL joinLabelPushed;
@property (nonatomic) BOOL hostLabelPushed;
@property (nonatomic) BOOL joinLabelSelected;
@property (strong, nonatomic) UIVisualEffectView *blurEffectView;
@end

@implementation MainMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //Add the radial gradient subview to the background.
    RadialGradiantView *radiantBackgroundView = [[RadialGradiantView alloc] initWithFrame:self.view.bounds];
    [self.backgroundView addSubview:radiantBackgroundView];
    
    //Create A blur
    UIVisualEffect *blurEffect;
    blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    UIVisualEffectView *visualEffectView;
    visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    visualEffectView.frame = self.view.bounds;
    visualEffectView.alpha = 0;
    [self.mainMenuView addSubview:visualEffectView];
    self.blurEffectView = visualEffectView;

    
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
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self performSegueWithIdentifier:@"toSetListRoomVC" sender:self];
        
    });
    
}

#pragma mark - Navigation

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    //Send the room code to be displayed on the respective view controllers.
    if ([segue.identifier isEqualToString:@"toSetListRoomVC"]) {
        SetListRoomViewController *setListVC = segue.destinationViewController;
    }
    
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
        
        [UIView animateWithDuration:.25 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            [self.joinLabel setCenter:CGPointMake(183, 267)];
            self.joinLabel.alpha = 1;
            self.joinLabelPushed = YES;
        } completion:^(BOOL finished) {
            self.joinLabelSelected = YES;
        }];
    }
    else
    {
        if (self.joinLabelPushed) {
            [UIView animateWithDuration:.25 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
                [self.joinLabel setCenter:CGPointMake(222,267)];
                self.joinLabel.alpha = .5;
                self.joinLabelPushed = NO;
                self.joinLabelSelected = NO;
            } completion:^(BOOL finished) {
                
            }];
            
        }
    }
    //Animate the host label when slider comes into correct coordinates.
    if ((recognizer.view.center.y + translation.y)>313 && (recognizer.view.center.y + translation.y)<357) {
        [UIView animateWithDuration:.25 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            [self.hostLabel setCenter:CGPointMake(179.5f, 336)];
            self.hostLabel.alpha = 1;
            self.hostLabelPushed = YES;
        } completion:^(BOOL finished) {
            //completion
        }];
        
    }
    else
    {   if(self.hostLabelPushed) {
        [UIView animateWithDuration:.25 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            [self.hostLabel setCenter:CGPointMake(219.5f, 336)];
            self.hostLabel.alpha = .5;
            self.hostLabelPushed = NO;
        } completion:^(BOOL finished) {
            //completion
        }];
    }
        
    }

    
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        
        if (self.joinLabelSelected) {
            [UIView animateWithDuration:.25 animations:^{
                self.hostLabel.alpha = 0;
                self.lineView1.alpha = 0;
                self.lineView2.alpha = 0;
                self.sliderImageView.alpha = 0;
                self.joinLabel.alpha = 0;
                self.blurEffectView.alpha = 1;
            }];
        }
        else if (self.hostLabelPushed) {
            //do everything that allows the user to join the room.
        }
        else {
        
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

@end
