//
//  Constants.h
//  TheSetList
//
//  Created by Andrew Friedman on 2/1/15.
//  Copyright (c) 2015 Andrew Friedman. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Constants : NSObject

#pragma mark - Initialize

extern NSString *const kInitialize;

#pragma mark - Queue

extern NSString *const kQueueChange;
extern NSString *const kQueueUpdated;
extern NSString *const kQueueRequest;
extern NSString *const kQueueAdd;

#pragma mark - Current

extern NSString *const kCurrentArtistChange;
extern NSString *const kCurrentArtistUpdate;

#pragma mark - Remote

extern NSString *const kRemoteAdd;
extern NSString *const kRemoteRequest;
extern NSString *const kRemoteSet;
extern NSString *const kRemoteAction;

#pragma mark - Connections and Disconnections

extern NSString *const kHostDisconnect;
extern NSString *const kOnDisconnect;
extern NSString *const kOnConnect;
extern NSString *const kOnHostRoomConnect;
extern NSString *const kUserJoined;


@end
