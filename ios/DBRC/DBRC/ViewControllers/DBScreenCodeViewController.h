//
//  DBScreenCodeViewController.h
//  DBRC
//
//  Created by luedeman on 1/11/13.
//  Copyright (c) 2013 Dropbox. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DBBroadcastClientProtocol.h"

@class PasscodeView;
@class DBBroadcastClient;
@class DBBroadcast;

@interface DBScreenCodeViewController : UIViewController <UITextFieldDelegate, DBBroadcastClientProtocol>

@property (nonatomic, retain) PasscodeView *passcodeView;
@property (nonatomic, retain) UITextField *invisTextField;
@property (nonatomic, retain) DBBroadcast *broadcast;
@property (nonatomic, retain) DBBroadcastClient *broadcastClient;

- (id)initWithDBBroadcast:(DBBroadcast *)broadcast;

@end
