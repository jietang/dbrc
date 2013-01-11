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

@end
