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
            NSLog(@"initialize emmited from socket");
            NSDictionary *socketIdDict = [args objectAtIndex:0];
            if ([socketIdDict objectForKey:@"error"])
            {
                NSLog(@"%@", [socketIdDict objectForKey:@"error"]);
            }
            else
            {
                NSString *socketID = [socketIdDict objectForKey:@"socket"];
                self.socketID = socketID;
                [[NSNotificationCenter defaultCenter] postNotificationName:@"initialize" object:nil];
            }
           
        }];
        
        //on Callback for events related to updates with the song queue.
        [self.socket on:@"q_update_B" callback:^(NSArray *args) {
            
            NSArray *tracks = [args objectAtIndex:0];
            self.setListTracks = tracks;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"qUpdateB"
                                                                object:nil];

        }];
        
        [self.socket on:@"current_artist_B" callback:^(NSArray *args) {
            
            self.currentArtist = [args objectAtIndex:0];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"currentArtistB" object:nil];
            
        }];
        
        [self.socket on:@"host disconnect" callback:^(NSArray *args) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"hostDisconnect" object:nil];
        }];
        
        self.socket.onDisconnect = ^()
        {
            NSLog(@"socket onDisconnect method fired");
            [[NSNotificationCenter defaultCenter] postNotificationName:@"onDisconnect"
                                                                object:nil];
        };
        
        __weak typeof(self) weakSelf = self;
        self.socket.onConnect = ^()
        {
            weakSelf.setListTracks = nil;
            weakSelf.currentArtist = nil;
            weakSelf.socketID = nil;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"onConnect" object:nil];
        };
        
        
        ///////HOST SOCKET METHODS////////
        
        [self.socket on:@"room code" callback:^(NSArray *args) {
            NSString *roomCode = [args objectAtIndex:0];
            self.hostRoomCode = roomCode;
            self.isHost = YES;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"onHostRoomConnect" object:nil];
            
            
            [self.socket on:@"song_added" callback:^(NSArray *args)
             {
                 NSLog(@"song added callback recieved");
                 NSDictionary *songAdded = [args objectAtIndex:0];
                 self.songAdded = songAdded;
                 [[NSNotificationCenter defaultCenter] postNotificationName:@"hostSongAdded" object:nil];
             }];
            
            //When a mobile client joins
            [self.socket on:@"add user" callback:^(NSArray *args) {
                NSMutableDictionary *idDic = args[0];
                self.clientSocketID = idDic[@"id"];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"userJoined" object:nil];
                
            }];

        }];

        
    }];
    
}

@end
