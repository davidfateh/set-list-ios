//
//  SocketKeeperSingleton.m
//  TheSetList
//
//  Created by Andrew Friedman on 1/18/15.
//  Copyright (c) 2015 Andrew Friedman. All rights reserved.
//

#import "SocketKeeperSingleton.h"

@implementation SocketKeeperSingleton

// The synthesize will automatically generate a getter and setter
@synthesize socket = _socketIO;

+ (SocketKeeperSingleton *) sharedInstance {
    
    static dispatch_once_t _once;
    static SocketKeeperSingleton *sharedSingleton = nil;
    
    
    dispatch_once(&_once, ^{
        sharedSingleton = [[SocketKeeperSingleton alloc] init];
    });
    
    return sharedSingleton;
    
}

- (void)startSocketWithHost:(NSString *)host;{
    
    [SIOSocket socketWithHost:host response:^(SIOSocket *socket) {
        
        self.socket = socket;
        
        
        //Send a message to RoomCode controler to notify the reciever that the user has enetered a correct code and can enter the specific setList room.
        [self.socket on:@"initialize" callback:^(NSArray *args) {
            
            NSDictionary *socketIdDict = [args objectAtIndex:0];
            NSString *socketID = [socketIdDict objectForKey:@"socket"];
            self.socketID = socketID;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"initialize" object:nil];
            
        }];
        
        //on Callback for events related to updates with the song queue.
        [self.socket on:@"q_update_B" callback:^(NSArray *args) {
            
            NSLog(@"qUpdateB has been emitted");
            NSArray *tracks = [args objectAtIndex:0];
            self.setListTracks = tracks;
            
            [self performSelectorOnMainThread:@selector(postQUpdateBNotification) withObject:nil waitUntilDone:YES] ;
        }];
        
        [self.socket on:@"current_artist_B" callback:^(NSArray *args) {
            
            self.currentArtist = [args objectAtIndex:0];
            
            [self performSelectorOnMainThread:@selector(postCurrentArtistBNotification) withObject:nil waitUntilDone:YES] ;
            
        }];
        
        [self.socket on:@"host disconnect" callback:^(NSArray *args) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"hostDisconnect" object:nil];
        }];
        
        self.socket.onDisconnect = ^()
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"onDisconnect" object:nil];
        };
        
        self.socket.onConnect = ^()
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"onConnect" object:nil];
        };
        
    }];
    
}


- (void)postQUpdateBNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"qUpdateB"
                                                        object:nil];

}

-(void)postCurrentArtistBNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"currentArtistB" object:nil];
}

@end
