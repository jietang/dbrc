//
//  DBSearchViewController.h
//  DBRC
//
//  Created by luedeman on 1/6/13.
//  Copyright (c) 2013 Dropbox. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DropboxSDK/DropboxSDK.h>

@interface DBSearchViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, DBRestClientDelegate>

@property (nonatomic, retain) UISearchBar *searchBar;
@property (nonatomic, retain) DBSession *dbSession;
@property (nonatomic, retain) DBRestClient *rc;

@end
