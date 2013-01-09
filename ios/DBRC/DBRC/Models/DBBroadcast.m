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

#define BASE_URL @"http://ec2-54-235-229-59.compute-1.amazonaws.com/"
//#define BASE_URL @"http://127.0.0.1:5000/"

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
    NSURL *url = [NSURL URLWithString:[BASE_URL stringByAppendingString:@"broadcasts/"]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    
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
                                                                                     NSLog(@"%@", JSON);
                                                                                     [self.delegate broadcast:self failedWithError:error];
                                                                                 }];
    [op start];
}

- (void)addScreenToBroadcast:(NSString *)screenId {
    NSURL *url = [NSURL URLWithString:[BASE_URL stringByAppendingString:[NSString stringWithFormat:@"broadcasts/%d/screens/", self.broadcastId, nil]]];
    NSData *postData = [self encodeDictionary:[NSDictionary dictionaryWithObject:screenId
                                                                          forKey:@"screen_id"]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:[NSString stringWithFormat:@"%d", postData.length] forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    
    AFJSONRequestOperation *op = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                 success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                                                                     NSLog(@"Success! Added screen %@ to broadcast %d", screenId, self.broadcastId);
                                                                                     [self.delegate screenWasAdded:screenId];
                                                                                 }
                                                                                 failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                                                                     NSLog(@"%@", [error userInfo]);
                                                                                     NSLog(@"%@", error);
                                                                                     
                                                                                     NSLog(@"Failure! Couldn't add screen %@ to broadcast %d", screenId, self.broadcastId);
                                                                                     [self.delegate screenAddFailed:screenId withError:nil];
                                                                                 }];
    
    [op start];
}

- (void)push:(NSString *)urlStr withParams:(NSDictionary *)params {
    NSURL *url = [NSURL URLWithString:[BASE_URL stringByAppendingString:[NSString stringWithFormat:@"broadcasts/%d/", self.broadcastId, nil]]];
    // Massaging json into expected format...a mess for now
    NSDictionary *jsonDict = [NSDictionary dictionaryWithObject:urlStr
                                                         forKey:@"url"];
    NSData *postData = [NSJSONSerialization dataWithJSONObject:jsonDict
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:nil];
    NSString *jsonStr = [[NSString alloc] initWithData:postData encoding:NSUTF8StringEncoding];
    
    NSData *htmlEncoded = [self encodeDictionary:[NSDictionary dictionaryWithObject:jsonStr forKey:@"data"]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:[NSString stringWithFormat:@"%d", postData.length] forHTTPHeaderField:@"Content-Length"];
//    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
//    [request setHTTPBody:postData];
    [request setValue:@"application/x-www-form-urlencoded charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:htmlEncoded];
    
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


# pragma mark URL Helpers
- (NSData*)encodeDictionary:(NSDictionary*)dictionary {
    NSMutableArray *parts = [[NSMutableArray alloc] init];
    for (NSString *key in dictionary) {
        NSString *encodedValue = [[dictionary objectForKey:key] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *encodedKey = [key stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *part = [NSString stringWithFormat: @"%@=%@", encodedKey, encodedValue];
        [parts addObject:part];
    }
    NSString *encodedDictionary = [parts componentsJoinedByString:@"&"];
    return [encodedDictionary dataUsingEncoding:NSUTF8StringEncoding];
}


@end
