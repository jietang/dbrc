//
//  DBScreenCodeViewController.h
//  DBRC
//
//  Created by luedeman on 1/11/13.
//  Copyright (c) 2013 Dropbox. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PasscodeView;

@interface DBScreenCodeViewController : UIViewController <UITextFieldDelegate>

@property (nonatomic, retain) PasscodeView *passcodeView;
@property (nonatomic, retain) UITextField *invisTextField;

@end
