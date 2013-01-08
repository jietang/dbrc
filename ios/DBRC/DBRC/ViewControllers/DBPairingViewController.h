//
//  DBPairingViewController.h
//  DBRC
//
//  Created by luedeman on 1/7/13.
//  Copyright (c) 2013 Dropbox. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DBBroadcastProtocol.h"

@interface DBPairingViewController : UIViewController <UITextFieldDelegate, DBBroadcastDelegate>

@property (nonatomic, retain) UITextField *textField;

@end
