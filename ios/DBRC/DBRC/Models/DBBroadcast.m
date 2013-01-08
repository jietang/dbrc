//
//  DBBroadcast.m
//  DBRC
//
//  Created by luedeman on 1/7/13.
//  Copyright (c) 2013 Dropbox. All rights reserved.
//
#import "AFJSONRequestOperation.h"

#import "DBBroadcast.h"
#import "DBBroadcastProtocol.h"


@implementation DBBroadcast

#pragma mark -
#pragma mark Object Lifecycle
/* After initing a DBBroadcast, it must be "started". This will create a broadcasting
   session on the server. */
- (id)init {
    if (self = [super init]) {

    }
    return self;
}

- (void)startBroadcast {
    [self createBroadcast];
}

- (void)createBroadcast {
    NSURL *url = [NSURL URLWithString:@"http://0.0.0.0:5000/create_broadcast"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    AFJSONRequestOperation *op = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                 success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                                                                     NSLog(@"Success!");
                                                                                     NSLog(@"%@", JSON);
                                                                                     NSDictionary *jsonDict = (NSDictionary *)JSON;
                                                                                     self.broadcastId = [(NSNumber *)[jsonDict objectForKey:@"broadcast_id"] intValue];
                                                                                     [self.delegate broadcastWasStarted:self];
                                                                                 }
                                                                                 failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                                                                     NSLog(@"%@", [error userInfo]);
                                                                                     [self.delegate broadcast:self failedWithError:error];
                                                                                 }];
    [op start];
}

- (void)addScreenToBroadcast:(NSString *)screenOrDeviceId {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://0.0.0.0:5000/add_to_broadcast/%d/%@", self.broadcastId, screenOrDeviceId, nil]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    AFJSONRequestOperation *op = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                 success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                                                                     NSLog(@"Success! Added screen %@ to broadcast %d", screenOrDeviceId, self.broadcastId);
                                                                                     [self.delegate screenWasAdded:screenOrDeviceId];
                                                                                 }
                                                                                 failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                                                                     NSLog(@"%@", [error userInfo]);
                                                                                     NSLog(@"Failure! Couldn't add screen %@ to broadcast %d", screenOrDeviceId, self.broadcastId);
                                                                                     [self.delegate screenAddFailed:screenOrDeviceId withError:nil];
                                                                                 }];
    
    [op start];
}

- (void)push:(NSString *)urlStr withParams:(NSDictionary *)params {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://0.0.0.0:5000/push/%d/%@", self.broadcastId, urlStr, nil]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    AFJSONRequestOperation *op = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                 success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                                                                     NSLog(@"Success! Pushed %@ to %d", urlStr, self.broadcastId);
                                                                                 }
                                                                                 failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                                                                     NSLog(@"%@", [error userInfo]);
                                                                                     NSLog(@"Failure! Couldn't push %@ to broadcast %d", urlStr, self.broadcastId);
                                                                                 }];
    
    [op start];
}


@end
