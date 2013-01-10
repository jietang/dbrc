//
//  DBBroadcastProtocol.h
//  DBRC
//
//  Created by luedeman on 1/7/13.
//  Copyright (c) 2013 Dropbox. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DBBroadcast;

@protocol DBBroadcastDelegate <NSObject>

@optional
- (void)broadcastWasStarted:(DBBroadcast *)broadcast;
- (void)broadcast:(DBBroadcast *)broadcast failedWithError:(NSError *)err;

- (void)broadcast:(DBBroadcast *)broadcast addedScreen:(NSString *)screen;
- (void)broadcast:(DBBroadcast *)broadcast failedToAddScreen:(NSString *)screen withError:error;

- (void)urlStrWasPushed:(NSString *)urlStr withParams:(NSDictionary *)params;
- (void)urlStrPushFailed:(NSString *) withParams:(NSDictionary *)params andErr:(NSError *)err;

- (void)broadcast:(DBBroadcast *)broadcast receivedLikelyScreens:(NSArray *)likelyHosts;
- (void)broadcast:(DBBroadcast *)broadcast failedToReceiveLikelyScreens:(NSError *)error;

- (void)broadcast:(DBBroadcast *)broadcast receivedKnownScreens:(NSArray *)likelyHosts;
- (void)broadcast:(DBBroadcast *)broadcast failedToReceiveKnownScreens:(NSError *)error;

- (void)broadcastPushedCredentials:(DBBroadcast *)broadcast;
- (void)broadcastFailedToPushCredentials:(DBBroadcast *)broadcast withError:(NSError *)error;

@end
