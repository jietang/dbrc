//
//  DBBroadcast.m
//  DBRC
//
//  Created by luedeman on 1/7/13.
//  Copyright (c) 2013 Dropbox. All rights reserved.
//
#import "AFJSONRequestOperation.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#import <DropboxSDK/DropboxSDK.h>

#import "DBBroadcast.h"
#import "DBBroadcastProtocol.h"


#define BASE_URL @"http://ec2-54-235-229-59.compute-1.amazonaws.com/"
//#define BASE_URL @"http://127.0.0.1:5000/"

@implementation DBBroadcast

#pragma mark -
#pragma mark Object Lifecycle
/* After initing a DBBroadcast, it must be "started". This will create a broadcasting
   session on the server. */
+ (NSString *)appKey {
    return @"gafchy215r87od1";
}

+ (NSString *)appSecret {
    return @"0bhl35g2fcybyvh";
}

+ (NSString *)baseUrl {
    return @"http://ec2-54-235-229-59.compute-1.amazonaws.com/";
//    return @"http://127.0.0.1:5000/";
}

- (id)init {
    if (self = [super init]) {

    }
    return self;
}

- (void)startBroadcast {
    self.broadcastId = -1;
    [self createBroadcast];
}

- (void)createBroadcast {
    // Get the wifi data, plug it into a json dict
    NSDictionary *ssidInfo = [self fetchSSIDInfo];
    NSString *ssid = [ssidInfo objectForKey:@"SSID"];
    NSString *bssid = [ssidInfo objectForKey:@"BSSID"];
    NSMutableDictionary *connectedDict;
    if (ssid && bssid) {
        connectedDict =[NSMutableDictionary dictionary];
        [connectedDict setObject:ssid forKey:@"ssid"];
        [connectedDict setObject:bssid forKey:@"bssid"];
    }
    else {
        connectedDict = [NSMutableDictionary dictionary];
    }
    
    NSMutableDictionary *infoDict = [NSMutableDictionary dictionary];
    [infoDict setObject:@"111111" forKey:@"remote_id"];
    [infoDict setObject:connectedDict forKey:@"connected"];
    [infoDict setObject:@"123123" forKey:@"remote_id"];
    [infoDict setObject:[NSArray array] forKey:@"nearby"];
    
    NSData *postData = [NSJSONSerialization dataWithJSONObject:infoDict
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:nil];
    NSLog(@"Posting: %@", [[NSString alloc] initWithData:postData encoding:NSUTF8StringEncoding]);
    
    // Build the url, attach the json
    NSURL *url = [NSURL URLWithString:[[DBBroadcast baseUrl] stringByAppendingString:@"broadcasts/"]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    
    AFJSONRequestOperation *op = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                 success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                                                                     NSLog(@"Succcessfully created a broadcast!");
                                                                                     NSLog(@"%@", JSON);
                                                                                     NSDictionary *jsonDict = (NSDictionary *)JSON;
                                                                                     self.broadcastId = [(NSNumber *)[jsonDict objectForKey:@"broadcast_id"] intValue];
                                                                                     [self.delegate broadcastWasStarted:self];
                                                                                 }
                                                                                 failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                                                                     NSLog(@"Failed to create broadcast.");
                                                                                     NSLog(@"%@", [error userInfo]);
                                                                                     NSLog(@"%@", JSON);
                                                                                     self.broadcastId = 0;
                                                                                     [self.delegate broadcast:self failedWithError:error];
                                                                                 }];
    [op start];
}


# pragma mark Wifi Helpers
- (id)fetchSSIDInfo
{
    NSArray *ifs = (__bridge id)CNCopySupportedInterfaces();
    NSLog(@"%s: Supported interfaces: %@", __func__, ifs);
    id info = nil;
    for (NSString *ifnam in ifs) {
        info = (__bridge id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        NSLog(@"%s: %@ => %@", __func__, ifnam, info);
        if (info && [info count]) {
            break;
        }
    }
    
    return info;
}

@end
