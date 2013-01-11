//
//  DBSearchViewController.h
//  DBRC
//
//  Created by luedeman on 1/6/13.
//  Copyright (c) 2013 Dropbox. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DropboxSDK/DropboxSDK.h>

#import "DBBroadcastProtocol.h"
#import "DBBroadcastClientProtocol.h"
#import "DBPhotos.h"


@class DBBroadcastClient;
@class DBBroadcast;

@interface DBPhotosViewController : UIViewController <UITableViewDataSource, UITableViewDelegate,
UISearchBarDelegate, DBRestClientDelegate, DBBroadcastDelegate, DBPhotosDelegate, DBBroadcastClientProtocol>

@property (nonatomic, retain) UISearchBar *searchBar;
@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) DBSession *dbSession;
@property (nonatomic, retain) DBRestClient *rc;
@property (nonatomic, retain) DBBroadcast *broadcast;
@property (nonatomic, retain) DBBroadcastClient *broadcastClient;
@property (nonatomic, retain) NSArray *currentSearchResults;
@property (nonatomic, retain) DBPhotos *photos;

@end
