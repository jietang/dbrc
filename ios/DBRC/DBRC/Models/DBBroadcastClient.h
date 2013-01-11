//
//  DBBroadcastClient.h
//  DBRC
//
//  Created by luedeman on 1/10/13.
//  Copyright (c) 2013 Dropbox. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DBBroadcastClientProtocol;

@class DBBroadcast;

@interface DBBroadcastClient : NSObject

@property (nonatomic, assign) id<DBBroadcastClientProtocol>delegate;
@property (nonatomic, retain) DBBroadcast *broadcast;

- (id)initWithBroadcast:(DBBroadcast *)broadcast;

- (void)addScreenToBroadcast:(NSString *)screenId;
- (void)push:(NSString *)urlStr withParams:(NSDictionary *)params;
- (void)fetchLikelyScreens;
- (void)fetchKnownScreens;
- (void)broadcastCredentials;

@end
