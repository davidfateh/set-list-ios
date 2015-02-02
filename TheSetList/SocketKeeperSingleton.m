//
//  SocketKeeperSingleton.m
//  TheSetList
//
//  Created by Andrew Friedman on 1/18/15.
//  Copyright (c) 2015 Andrew Friedman. All rights reserved.
//

#import "SocketKeeperSingleton.h"
#import "Constants.h"

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
        [self.socket on:kInitialize callback:^(NSArray *args) {
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
                [[NSNotificationCenter defaultCenter] postNotificationName:kInitialize object:nil];
            }
           
        }];
        
        //on Callback for events related to updates with the song queue.
        [self.socket on:kQueueUpdated callback:^(NSArray *args) {
            NSArray *tracks = [args objectAtIndex:0];
            self.setListTracks = tracks;
            [[NSNotificationCenter defaultCenter] postNotificationName:kQueueUpdated
                                                                object:nil];

        }];
        
        [self.socket on:kCurrentArtistUpdate callback:^(NSArray *args) {
            self.currentArtist = [args objectAtIndex:0];
            [[NSNotificationCenter defaultCenter] postNotificationName:kCurrentArtistUpdate object:nil];
            
        }];
        
        [self.socket on:kHostDisconnect callback:^(NSArray *args) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kHostDisconnect object:nil];
        }];
        
        self.socket.onDisconnect = ^()
        {
            NSLog(@"socket onDisconnect method fired");
            [[NSNotificationCenter defaultCenter] postNotificationName:kOnDisconnect
                                                                object:nil];
        };
        
        __weak typeof(self) weakSelf = self;
        self.socket.onConnect = ^()
        {
            weakSelf.isHost = NO;
            weakSelf.setListTracks = nil;
            weakSelf.currentArtist = nil;
            weakSelf.socketID = nil;
            [[NSNotificationCenter defaultCenter] postNotificationName:kOnConnect object:nil];
        };
        
        
        ///////MOBILE HOST SOCKET METHODS////////
        
        [self.socket on:kOnHostRoomConnect callback:^(NSArray *args) {
            NSString *roomCode = [args objectAtIndex:0];
            self.hostRoomCode = roomCode;
            self.isHost = YES;
            [[NSNotificationCenter defaultCenter] postNotificationName:kOnHostRoomConnect object:nil];
            
            
            [self.socket on:kQueueAdd callback:^(NSArray *args)
             {
                 NSDictionary *songAdded = [args objectAtIndex:0];
                 self.songAdded = songAdded;
                 [[NSNotificationCenter defaultCenter] postNotificationName:kQueueAdd object:nil];
             }];
            
            //When a mobile client joins
            [self.socket on:kUserJoined callback:^(NSArray *args) {
                NSMutableDictionary *idDic = args[0];
                self.clientSocketID = idDic[@"id"];
                [[NSNotificationCenter defaultCenter] postNotificationName:kUserJoined object:nil];
                
            }];

        }];

        
    }];
    
}

@end
