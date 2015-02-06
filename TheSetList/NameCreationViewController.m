//
//  NameCreationViewController.m
//  TheSetList
//
//  Created by Andrew Friedman on 1/13/15.
//  Copyright (c) 2015 Andrew Friedman. All rights reserved.
//

#import "NameCreationViewController.h"
#import "SocketKeeperSingleton.h"
#import <SIOSocket/SIOSocket.h>
#import "SetListRoomViewController.h"
#import "RadialGradiantView.h"

#define HOST_URL @"http://54.152.215.221/"

@interface NameCreationViewController ()
@property (strong, nonatomic) SIOSocket *socket;
@property (nonatomic) BOOL isHost;
@end

@implementation NameCreationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //Add the radial gradient subview to the background.
    RadialGradiantView *radiantBackgroundView = [[RadialGradiantView alloc] initWithFrame:self.view.bounds];
    [self.backgroundView addSubview:radiantBackgroundView];
    
    self.roomCodeTextField.delegate = self;
    
    [self.roomCodeTextField setValue:[UIColor colorWithRed:0.325 green:0.313 blue:0.317 alpha:1] forKeyPath:@"_placeholderLabel.textColor"];
    self.roomCodeTextField.tintColor = [UIColor whiteColor];
    
    self.theSetListLabel.font = [UIFont fontWithName:@"Lobster" size:42.0];
    
    //Animate the name textField upon the view loading, to fade in.
    self.roomCodeTextField.alpha = 0;
    [UIView animateWithDuration:1.2 animations:^{
        self.roomCodeTextField.alpha = 1.0;
    }];

        
        UIToolbar* numberToolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, 320, 50)];
        numberToolbar.barStyle = UIBarStyleBlackTranslucent;
        UIBarButtonItem *joinButton = [[UIBarButtonItem alloc]initWithTitle:@"\u279e" style:UIBarButtonItemStyleDone target:self action:@selector(doneWithNumberPad)];
    
        numberToolbar.items = [NSArray arrayWithObjects:
                               [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                               joinButton, [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                               nil];
        [numberToolbar sizeToFit];
        self.roomCodeTextField.inputAccessoryView = numberToolbar;
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
    
    self.roomCodeTextField.text = nil;
    SocketKeeperSingleton *socketSingleton = [SocketKeeperSingleton sharedInstance];
    NSString *hostURLwithRoomCode = [NSString stringWithFormat:@"%@",HOST_URL];
    [socketSingleton startSocketWithHost:hostURLwithRoomCode];
}

//When the user hits the arrow key, connect to the host and resign the keyboard.
-(void)doneWithNumberPad{
    
    NSString *numberFromTheKeyboard = self.roomCodeTextField.text;
    if (self.roomCodeTextField.tag == 2 ) {
        
        [self.roomCodeTextField resignFirstResponder];
        NSDictionary *startDic = @{@"room" :numberFromTheKeyboard};
        NSArray *startArray = @[startDic];
        [self.socket emit:@"mobile connect" args:startArray];
        
        
    }
    
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

#pragma mark - Text Field Delegate

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

#pragma mark - Navigation

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    //Send the room code to be displayed on the respective view controllers. 
    if ([segue.identifier isEqualToString:@"toSetListRoomVC"]) {
        SetListRoomViewController *setListVC = segue.destinationViewController;
        setListVC.roomCode = self.roomCodeTextField.text;
    }
    
}

- (IBAction)hostRoomButtonPressed:(UIButton *)sender
{
    [self.socket emit:@"start room"];
}
@end
