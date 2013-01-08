//
//  DBBroadcast.h
//  DBRC
//
//  Created by luedeman on 1/7/13.
//  Copyright (c) 2013 Dropbox. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DBBroadcast : NSObject

+(DBBroadcast *)sharedBroadcast;

- (void)addScreenToBroadcast:(NSString *)screenOrDeviceId;
- (void)push:(NSString *)urlStr withParams:(NSDictionary *)params;

@end
