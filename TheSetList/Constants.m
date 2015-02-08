//
//  Constants.m
//  TheSetList
//
//  Created by Andrew Friedman on 2/1/15.
//  Copyright (c) 2015 Andrew Friedman. All rights reserved.
//

#import "Constants.h"

@implementation Constants

#pragma mark - Initialize

NSString *const kInitialize              =@"initialize";

#pragma mark - Queue

NSString *const kQueueChange                    = @"queue_change";
NSString *const kQueueUpdated                   = @"queue_updated";
NSString *const kQueueRequest                   = @"queue_request";
NSString *const kQueueAdd                       = @"queue_add";

#pragma mark - Current

NSString *const kCurrentArtistChange            = @"currentArtist_change";
NSString *const kCurrentArtistUpdate            = @"currentArtist_updated";

#pragma mark - Remote

NSString *const kRemoteAdd                      = @"remote_add";
NSString *const kRemoteRequest                  = @"remote_request";
NSString *const kRemoteSet                      = @"remote_set";
NSString *const kRemoteAction                   = @"remote_action";

#pragma mark - Connections and Disconnections

NSString *const kHostDisconnect                 = @"host disconnect";
NSString *const kOnDisconnect                   = @"onDisconnect";
NSString *const kOnConnect                      = @"onConnect";
NSString *const kOnHostRoomConnect              = @"room code";
NSString *const kUserJoined                     = @"add user";


@end

