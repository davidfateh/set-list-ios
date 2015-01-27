//
//  RemoteTestViewController.m
//  TheSetList
//
//  Created by Andrew Friedman on 1/26/15.
//  Copyright (c) 2015 Andrew Friedman. All rights reserved.
//

#import "RemoteTestViewController.h"
#import <SIOSocket/SIOSocket.h>
#import "SocketKeeperSingleton.h"

@interface RemoteTestViewController ()
@property (nonatomic) BOOL isHost;
@property (strong, nonatomic) SIOSocket *socket;
@end

@implementation RemoteTestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.socket = [[SocketKeeperSingleton sharedInstance]socket];
    
}

- (IBAction)connectButtonPressed:(UIButton *)sender
{
    NSString *remotePassword = self.passwordTextField.text;
    NSMutableDictionary *passwordDick = [[NSMutableDictionary alloc]init];
    [passwordDick setObject:remotePassword forKey:@"password"];
    NSArray *argsArray = [[NSArray alloc]initWithObjects:passwordDick, nil];
    [self.socket emit:@"add remote" args:argsArray];
    [self.socket on:@"add remote" callback:^(NSArray *args) {
        
        NSMutableDictionary *key = [[NSMutableDictionary alloc]init];
        key = (NSMutableDictionary *)[args objectAtIndex:0];
        if ([key objectForKey:@"success"]) {
            self.isHost = YES;
            self.playPauseButton.hidden = NO;
            self.skipButton.hidden = NO;
            self.remoteLogoImageView.hidden = NO;
            
            [self.socket on:@"playing" callback:^(NSArray *args) {
                self.playPauseButton.selected = YES;
            }];
            [self.socket on:@"paused" callback:^(NSArray *args) {
                self.playPauseButton.selected = NO;
            }];

        }
    }];

}
- (IBAction)skipButtonPressed:(id)sender
{
    if (self.isHost) {
        
        NSMutableDictionary *skipDic = [[NSMutableDictionary alloc]init];
        [skipDic setObject:@"skip" forKey:@"action"];
        NSArray *argsArray = [[NSArray alloc]initWithObjects:skipDic, nil];
        [self.socket emit:@"remote" args:argsArray];
    }
}

- (IBAction)playPauseButtonPressed:(UIButton *)sender
{
    if (self.isHost){
        NSMutableDictionary *togglePauseDic = [[NSMutableDictionary alloc]init];
        [togglePauseDic setObject:@"togglePause" forKey:@"action"];
        NSArray *argsArray = [[NSArray alloc]initWithObjects:togglePauseDic, nil];
        [self.socket emit:@"remote" args:argsArray];
    }
}
@end
