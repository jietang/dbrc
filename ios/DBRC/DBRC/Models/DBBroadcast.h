//
//  DBBroadcast.h
//  DBRC
//
//  Created by luedeman on 1/7/13.
//  Copyright (c) 2013 Dropbox. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DBBroadcastDelegate;

@interface DBBroadcast : NSObject

@property (nonatomic, assign) id<DBBroadcastDelegate> delegate;
@property (nonatomic, assign) NSInteger broadcastId;
@property (nonatomic, assign) NSInteger connectedScreens;

- (void)startBroadcast;

+ (NSString *)appKey;
+ (NSString *)appSecret;
+ (NSString *)baseUrl;

@end
