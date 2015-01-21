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

#define HOST_URL @"http://149.152.101.2:5000"

@interface NameCreationViewController ()

@end

@implementation NameCreationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.nameTextField.delegate = self;
    self.roomCodeTextField.delegate = self;
    
    [self.nameTextField setValue:[UIColor colorWithRed:0.325 green:0.313 blue:0.317 alpha:1] forKeyPath:@"_placeholderLabel.textColor"];
    self.nameTextField.tintColor = [UIColor whiteColor];
    
    [self.roomCodeTextField setValue:[UIColor colorWithRed:0.325 green:0.313 blue:0.317 alpha:1] forKeyPath:@"_placeholderLabel.textColor"];
    self.roomCodeTextField.tintColor = [UIColor whiteColor];
    
    self.theSetListLabel.font = [UIFont fontWithName:@"Lobster" size:42.0];
    
    self.nameTextField.alpha = 0.0;
    [UIView animateWithDuration:.6 animations:^{
        self.nameTextField.alpha = 1.0;
    }];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveInitializeNotification:)
                                                 name:@"initialize"
                                               object:nil];
    
}

-(void)receiveInitializeNotification:(NSNotification *)notificaiton
{
    NSString *guestName = self.nameTextField.text;
    NSMutableDictionary *nameDict = [[NSMutableDictionary alloc]init];
    [nameDict setObject:guestName forKey:@"name"];
    NSArray *argsArray = [[NSArray alloc]initWithObjects:nameDict, nil];
    SIOSocket *socket = [[SocketKeeperSingleton sharedInstance]socket];
    [socket emit:@"join" args:argsArray];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self performSegueWithIdentifier:@"toSetListRoomVC" sender:self];
    });
    
}


-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField.tag == 1) {
        //Save the username string to NSUserDefaults to retrieve later in the application.
        NSString *usernameString = self.nameTextField.text;
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        [prefs setObject:usernameString forKey:@"usernameString"];
        [prefs synchronize];
        
        [UIView animateWithDuration:.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^
         {
             //move the login view up 50 points so that the keyboard does not hide views
             self.nameHorizontalConst.constant = -197;
             [self.view layoutIfNeeded];
             
         }
                         completion:^(BOOL finished)
         {
             [UIView animateWithDuration:.2 delay:.5 options:UIViewAnimationOptionCurveEaseOut animations:^
              {
                  //move the login view up 50 points so that the keyboard does not hide views
                  self.roomCodeHorizConst.constant = +54;
                  [self.view layoutIfNeeded];
                  
              }
                              completion:^(BOOL finished)
              {
                  //Animation completed
              }];
             
         }];
        
        
        [textField resignFirstResponder];

    }
    
    if (textField.tag == 2 ) {
        
        //When the user enters the code on the textField, start the socket with the correct host and room code.
        SocketKeeperSingleton *socketSingleton = [SocketKeeperSingleton sharedInstance];
        
        NSString *hostURLwithRoomCode = [NSString stringWithFormat:@"%@/%@",HOST_URL, self.roomCodeTextField.text];
        [socketSingleton startSocketWithHost:hostURLwithRoomCode];
        [textField resignFirstResponder];

    }
    return YES;
}

//The user should not be allowed to enter more than 5 digits.
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string

{
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

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"toSetListRoomVC"]) {
        SetListRoomViewController *setListVC = segue.destinationViewController;
        setListVC.roomCode = self.roomCodeTextField.text;
    }
}

@end
