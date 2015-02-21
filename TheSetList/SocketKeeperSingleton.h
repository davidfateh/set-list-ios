//
//  SocketKeeperSingleton.h
//  TheSetList
//
//  Created by Andrew Friedman on 1/18/15.
//  Copyright (c) 2015 Andrew Friedman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SIOSocket/SIOSocket.h>

@interface SocketKeeperSingleton : NSObject

@property (nonatomic, strong) SIOSocket *socket;
@property (strong, nonatomic) NSArray *setListTracks;
@property (strong, nonatomic) NSDictionary *currentArtist;
@property (strong, nonatomic) NSString *socketID;
@property (nonatomic) BOOL isHost;
@property (strong, nonatomic) NSString *hostRoomCode;
@property (strong, nonatomic) NSString *roomCode;
@property (nonatomic) BOOL socketIsConnected;
@property (strong, nonatomic) NSDictionary *songAdded;
@property (strong, nonatomic) NSString *clientSocketID;
@property (strong, nonatomic) NSDictionary *remoteKey;

+ (SocketKeeperSingleton *) sharedInstance;

- (void)startSocketWithHost:(NSString *)host;

@end
