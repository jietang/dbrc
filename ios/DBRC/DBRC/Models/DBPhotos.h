//
//  DBPhotos.h
//  DBRC
//
//  Created by luedeman on 1/10/13.
//  Copyright (c) 2013 Dropbox. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DropboxSDK/DropboxSDK.h>

@class DBPhotos;

@protocol DBPhotosDelegate <NSObject>

- (void)dbPhotos:(DBPhotos *)dbPhotos photosWereFetched:(NSArray *)photos;

@end


@interface DBPhotos : NSObject <DBRestClientDelegate>

@property (nonatomic, retain) DBRestClient *rc;
@property (nonatomic, assign) id<DBPhotosDelegate> delegate;

- (void)fetchPhotos;

@end
