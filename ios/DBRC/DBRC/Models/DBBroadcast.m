//
//  DBBroadcast.m
//  DBRC
//
//  Created by luedeman on 1/7/13.
//  Copyright (c) 2013 Dropbox. All rights reserved.
//

#import "DBBroadcast.h"

static DBBroadcast *sharedBroadcastInstance = nil;

@implementation DBBroadcast

#pragma mark -
#pragma mark Object Lifecycle
+ (DBBroadcast *)sharedBroadcast
{
	if (sharedBroadcastInstance == nil)
	{
        sharedBroadcastInstance = [[DBBroadcast alloc] init];
	}
	
	return sharedBroadcastInstance;
}

- (id)init {
    if (self = [super init]) {
        
    }
    return self;
}

- (void)addScreenToBroadcast:(NSString *)screenOrDeviceId {
    
}

- (void)push:(NSString *)urlStr withParams:(NSDictionary *)params {
    
}


@end
