//
//  DBBroadcastClientProtocol.h
//  DBRC
//
//  Created by luedeman on 1/10/13.
//  Copyright (c) 2013 Dropbox. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DBBroadcastClient;

@protocol DBBroadcastClientProtocol <NSObject>

@optional

- (void)broadcast:(DBBroadcastClient *)broadcastClient addedScreen:(NSString *)screen;
- (void)broadcast:(DBBroadcastClient *)broadcastClient failedToAddScreen:(NSString *)screen withError:error;

- (void)broadcast:(DBBroadcastClient *)broadcastClient removedScreen:(NSString *)screen;
- (void)broadcast:(DBBroadcastClient *)broadcastClient failedToRemoveScreen:(NSString *)screen withError:error;

- (void)urlStrWasPushed:(NSString *)urlStr withParams:(NSDictionary *)params;
- (void)urlStrPushFailed:(NSString *) withParams:(NSDictionary *)params andErr:(NSError *)err;

- (void)broadcast:(DBBroadcastClient *)broadcastClient receivedConnectedScreens:(NSDictionary *)connectedScreens;
- (void)broadcast:(DBBroadcastClient *)broadcastClient failedToReceiveConnectedScreens:(NSError *)error;

- (void)broadcast:(DBBroadcastClient *)broadcastClient receivedKnownScreens:(NSArray *)likelyHosts;
- (void)broadcast:(DBBroadcastClient *)broadcastClient failedToReceiveKnownScreens:(NSError *)error;

- (void)broadcastPushedCredentials:(DBBroadcastClient *)broadcastClient;
- (void)broadcastFailedToPushCredentials:(DBBroadcastClient *)broadcastClient withError:(NSError *)error;


@end
