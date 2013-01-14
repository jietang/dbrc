//
//  DBPhotos.m
//  DBRC
//
//  Created by luedeman on 1/10/13.
//  Copyright (c) 2013 Dropbox. All rights reserved.
//

#import "DBPhotos.h"

@implementation DBPhotos

- (id)init {
    if (self = [super init]) {
        self.rc = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        self.rc.delegate = self;
    }
    return self;
}

- (void)fetchPhotos {
    [self.rc searchPath:@"/Camera Uploads" forKeyword:@"2013"];
//    [self.rc loadMetadata:@"/Camera Uploads"];

}

# pragma mark RestClient Callbacks
- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata {
    [self.delegate dbPhotos:self photosWereFetched:metadata.contents];
}

- (void)restClient:(DBRestClient *)restClient loadedSearchResults:(NSArray *)results forPath:(NSString *)path keyword:(NSString *)keyword {
    [self.delegate dbPhotos:self photosWereFetched:results];
}

@end
