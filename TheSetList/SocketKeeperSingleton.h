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

@property (strong, nonatomic) NSString *roomCode;
@property (nonatomic) BOOL socketIsConnected;

+ (SocketKeeperSingleton *) sharedInstance;

- (void)startSocketWithHost:(NSString *)host;

@end
