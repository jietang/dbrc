//
//  DBBroadcastClient.m
//  DBRC
//
//  Created by luedeman on 1/10/13.
//  Copyright (c) 2013 Dropbox. All rights reserved.
//

#import <DropboxSDK/DropboxSDK.h>

#import "AFJSONRequestOperation.h"

#import "DBBroadcast.h"
#import "DBBroadcastClient.h"
#import "DBBroadcastClientProtocol.h"


@implementation DBBroadcastClient

- (id)initWithBroadcast:(DBBroadcast *)broadcast {
    if (self = [super init]) {
        self.broadcast = broadcast;
    }
    return self;
}

- (void)addScreenToBroadcast:(NSString *)screenId {
    NSURL *url = [NSURL URLWithString:[[DBBroadcast baseUrl] stringByAppendingString:[NSString stringWithFormat:@"broadcasts/%d/screens/", self.broadcast.broadcastId, nil]]];
    NSData *postData = [self encodeDictionary:[NSDictionary dictionaryWithObject:screenId
                                                                          forKey:@"screen_id"]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:[NSString stringWithFormat:@"%d", postData.length] forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    
    AFJSONRequestOperation *op = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                 success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                                                                     NSLog(@"Success! Added screen %@ to broadcast %d", screenId, self.broadcast.broadcastId);
                                                                                     [self.delegate broadcast:self addedScreen:screenId];
                                                                                 }
                                                                                 failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                                                                     NSLog(@"Failure! Couldn't add screen %@ to broadcast %d", screenId, self.broadcast.broadcastId);
                                                                                     NSLog(@"%@", [error userInfo]);
                                                                                     NSLog(@"%@", error);
                                                                                     [self.delegate broadcast:self failedToAddScreen:screenId withError:nil];
                                                                                 }];
    
    [op start];
}

- (void)push:(NSString *)urlStr withParams:(NSDictionary *)params {
    NSURL *url = [NSURL URLWithString:[[DBBroadcast baseUrl] stringByAppendingString:[NSString stringWithFormat:@"broadcasts/%d/", self.broadcast.broadcastId, nil]]];
    // Massaging json into expected format...a mess for now
    NSMutableDictionary *jsonDict = [NSMutableDictionary dictionary];
    [jsonDict setValue:urlStr forKey:@"url"];
    [jsonDict setValue:@"url" forKey:@"type"];
    
    NSData *postData = [NSJSONSerialization dataWithJSONObject:jsonDict
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:nil];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:[NSString stringWithFormat:@"%d", postData.length] forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    
    AFJSONRequestOperation *op = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                 success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                                                                     NSLog(@"Success! Pushed %@ to %d", urlStr, self.broadcast.broadcastId);
                                                                                 }
                                                                                 failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                                                                     NSLog(@"%@", [error userInfo]);
                                                                                     NSLog(@"Failure! Couldn't push %@ to broadcast %d", urlStr, self.broadcast.broadcastId);
                                                                                 }];
    [op start];
}

- (void)fetchKnownScreens {
    NSURL *url = [NSURL URLWithString:[[DBBroadcast baseUrl] stringByAppendingString:[NSString stringWithFormat:@"broadcasts/%d/known_screens/", self.broadcast.broadcastId, nil]]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    AFJSONRequestOperation *op = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                 success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                                                                     NSArray *knownScreens = (NSArray *)JSON;
                                                                                     NSLog(@"Success! Found %d known screens for broadcast %d",
                                                                                           [knownScreens count],
                                                                                           self.broadcast.broadcastId, nil);
                                                                                     [self.delegate broadcast:self receivedKnownScreens:knownScreens];
                                                                                 }
                                                                                 failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                                                                     NSLog(@"%@", [error userInfo]);
                                                                                     NSLog(@"Failure! Couldn't find known screens for broadcast %d", self.broadcast.broadcastId);
                                                                                 }];
    [op start];
}

- (void)fetchLikelyScreens {
    NSURL *url = [NSURL URLWithString:[[DBBroadcast baseUrl] stringByAppendingString:[NSString stringWithFormat:@"broadcasts/%d/likely_screens/", self.broadcast.broadcastId, nil]]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    AFJSONRequestOperation *op = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                 success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                                                                     NSArray *likelyScreens = (NSArray *)JSON;
                                                                                     NSLog(@"Success! Found %d likely hosts for broadcast %d",
                                                                                           [likelyScreens count],
                                                                                           self.broadcast.broadcastId, nil);
                                                                                     [self.delegate broadcast:self receivedLikelyScreens:likelyScreens];
                                                                                 }
                                                                                 failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                                                                     NSLog(@"%@", [error userInfo]);
                                                                                     NSLog(@"Failure! Couldn't find likely screens for broadcast %d", self.broadcast.broadcastId);
                                                                                 }];
    [op start];
}

- (void)broadcastCredentials {
    NSMutableDictionary *postDict = [NSMutableDictionary dictionary];
    DBSession *session = [DBSession sharedSession];
    if ([session.userIds count]) {
        NSString *userId = [session.userIds objectAtIndex:0];
        MPOAuthCredentialConcreteStore *credentials = [session credentialStoreForUserId:userId];
        [postDict setValue:@"pairing" forKey:@"type"];
        [postDict setValue:[DBBroadcast appKey] forKey:@"app_key"];
        [postDict setValue:[DBBroadcast appSecret] forKey:@"app_secret"];
        [postDict setValue:[credentials accessToken]  forKey:@"access_token"];
        [postDict setValue:[credentials accessTokenSecret]  forKey:@"access_token_secret"];
    }
    
    if ([postDict count]) {
        NSURL *url = [NSURL URLWithString:[[DBBroadcast baseUrl] stringByAppendingString:[NSString stringWithFormat:@"broadcasts/%d/", self.broadcast.broadcastId, nil]]];
        NSData *postData = [NSJSONSerialization dataWithJSONObject:postDict
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:nil];
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        [request setHTTPMethod:@"POST"];
        [request setValue:[NSString stringWithFormat:@"%d", postData.length] forHTTPHeaderField:@"Content-Length"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setHTTPBody:postData];
        
        AFJSONRequestOperation *op = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                     success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                                                                         NSLog(@"Success! Pushed %@ to %d", postDict, self.broadcast.broadcastId);
                                                                                     }
                                                                                     failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                                                                         NSLog(@"%@", [error userInfo]);
                                                                                         NSLog(@"Failure! Couldn't push %@ to broadcast %d", postDict, self.broadcast.broadcastId);
                                                                                     }];
        [op start];
    }
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
