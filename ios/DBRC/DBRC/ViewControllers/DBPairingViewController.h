//
//  DBPairingViewController.h
//  DBRC
//
//  Created by luedeman on 1/7/13.
//  Copyright (c) 2013 Dropbox. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DBBroadcast.h"
#import "DBBroadcastProtocol.h"
#import "DBBroadcastClient.h"
#import "DBBroadcastClientProtocol.h"

@interface DBPairingViewController : UIViewController <UITextFieldDelegate, DBBroadcastDelegate,
UITableViewDataSource, UITableViewDelegate, DBBroadcastClientProtocol>


@property (nonatomic, retain) DBBroadcast *broadcast;
@property (nonatomic, retain) DBBroadcastClient *broadcastClient;
@property (nonatomic, retain) UITableView *devicesTableView;
@property (nonatomic, retain) NSArray *knownDevices;

- (id)initWithBroadcast:(DBBroadcast *)broadcast;

@end
