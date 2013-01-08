//
//  DBBroadcastProtocol.h
//  DBRC
//
//  Created by luedeman on 1/7/13.
//  Copyright (c) 2013 Dropbox. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DBBroadcastDelegate <NSObject>


@optional
- (void)broadcastWasStarted:(DBBroadcast *)broadcast;
- (void)broadcast:(DBBroadcast *)broadcast failedWithError:(NSError *)err;

- (void)screenWasAdded:(NSString *)screen;
- (void)screenAddFailed:(NSString *)screen withError:(NSString *)err;

- (void)urlStrWasPushed:(NSString *)urlStr withParams:(NSDictionary *)params;
- (void)urlStrPushFailed:(NSString *) withParams:(NSDictionary *)params andErr:(NSError *)err;

@end
