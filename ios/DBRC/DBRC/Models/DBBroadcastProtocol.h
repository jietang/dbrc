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

- (void)broadcast:(DBBroadcast *)broadcast receivedLikelyHosts:(NSArray *)likelyHosts;
- (void)broadcast:(DBBroadcast *)broadcast failedToReceiveLikelyHosts:(NSError *)error;

- (void)broadcast:(DBBroadcast *)broadcast receivedKnownHosts:(NSArray *)likelyHosts;
- (void)broadcast:(DBBroadcast *)broadcast failedToReceiveKnownHosts:(NSError *)error;

@end
