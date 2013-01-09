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

- (void)startBroadcast;
- (void)addScreenToBroadcast:(NSString *)screenId;
- (void)push:(NSString *)urlStr withParams:(NSDictionary *)params;

@end
