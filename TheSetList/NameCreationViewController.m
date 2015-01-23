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

#define HOST_URL @"http://the-set-list.herokuapp.com"

@interface NameCreationViewController ()

@end

@implementation NameCreationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //Add the radial gradient subview to the background.
    RadialGradiantView *radiantBackgroundView = [[RadialGradiantView alloc] initWithFrame:self.view.bounds];
    [self.backgroundView addSubview:radiantBackgroundView];
    
    //Set the roomCodeTextField's aplha to 0 so that it can fade in upon request.
    self.roomCodeTextField.alpha = 0;
    
    //Set delegates
    self.nameTextField.delegate = self;
    self.roomCodeTextField.delegate = self;
    
    //Modify text attributes.
    [self.nameTextField setValue:[UIColor colorWithRed:0.325 green:0.313 blue:0.317 alpha:1] forKeyPath:@"_placeholderLabel.textColor"];
    self.nameTextField.tintColor = [UIColor whiteColor];
    
    [self.roomCodeTextField setValue:[UIColor colorWithRed:0.325 green:0.313 blue:0.317 alpha:1] forKeyPath:@"_placeholderLabel.textColor"];
    self.roomCodeTextField.tintColor = [UIColor whiteColor];
    
    self.theSetListLabel.font = [UIFont fontWithName:@"Lobster" size:42.0];
    
    //Animate the name textField upon the view loading, to fade in.
    self.nameTextField.alpha = 0.0;
    [UIView animateWithDuration:1.2 animations:^{
        self.nameTextField.alpha = 1.0;
    }];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveInitializeNotification:)
                                                 name:@"initialize"
                                               object:nil];
    
   
        
        UIToolbar* numberToolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, 320, 50)];
        numberToolbar.barStyle = UIBarStyleBlackTranslucent;
        UIBarButtonItem *joinButton = [[UIBarButtonItem alloc]initWithTitle:@"\u279e" style:UIBarButtonItemStyleDone target:self action:@selector(doneWithNumberPad)];
    
        numberToolbar.items = [NSArray arrayWithObjects:
                               [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                               joinButton, [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                               nil];
        [numberToolbar sizeToFit];
        self.roomCodeTextField.inputAccessoryView = numberToolbar;
    
        self.nameTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    
}

//When the user hits the arrow key, connect to the host and resign the keyboard.
-(void)doneWithNumberPad{
    
    NSString *numberFromTheKeyboard = self.roomCodeTextField.text;
    if (self.roomCodeTextField.tag == 2 ) {
        
        //When the user enters the code on the textField, start the socket with the correct host and room code.
        SocketKeeperSingleton *socketSingleton = [SocketKeeperSingleton sharedInstance];
        
        NSString *hostURLwithRoomCode = [NSString stringWithFormat:@"%@/%@",HOST_URL, numberFromTheKeyboard];
        [socketSingleton startSocketWithHost:hostURLwithRoomCode];
        [self.roomCodeTextField resignFirstResponder];
        
    }
    
    [self.roomCodeTextField resignFirstResponder];
}

-(void)receiveInitializeNotification:(NSNotification *)notificaiton
{
    //Upon recieving a notification that we have connected to the host, emit the user's name to the socket and perform the segue to the set list view controller.
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
        
        
        //The textfields will animate out of view and in to view.
        [UIView animateWithDuration:.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^
         {
             //move the login view up 50 points so that the keyboard does not hide views
             self.nameVertConst.constant = +170;
             self.nameTextField.alpha = 0;
             [self.view layoutIfNeeded];
             
         }
                         completion:^(BOOL finished)
         {
                //completed animation
         }];
        
        //Animation on the room code, fade in with delay.
        [UIView animateWithDuration:1.0 delay:.5 options:UIViewAnimationOptionCurveEaseOut animations:^
         {
             //move the login view up 50 points so that the keyboard does not hide views
             self.roomCodeTextField.alpha = 1.0;
             [self.view layoutIfNeeded];
             
         }
                         completion:^(BOOL finished)
         {
             [self.roomCodeTextField becomeFirstResponder];
         }];

    }
    
       return YES;
}

//The user should not be allowed to enter more than 4 digits.
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string

{
    //User is only allowed to have a name of 12 characters or less.
    if (textField.tag == 1) {
        // Prevent crashing undo bug – see note below.
        if(range.length + range.location > textField.text.length)
        {
            return NO;
        }
        
        NSUInteger newLength = [textField.text length] + [string length] - range.length;
        return (newLength > 12) ? NO : YES;

    }
    
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

@end
