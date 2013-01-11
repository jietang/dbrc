//
//  DBScreenCodeViewController.m
//  DBRC
//
//  Created by luedeman on 1/11/13.
//  Copyright (c) 2013 Dropbox. All rights reserved.
//

#import "DBScreenCodeViewController.h"
#import "PasscodeView.h"
#import "DBBroadcast.h"
#import "DBBroadcastClient.h"

@interface DBScreenCodeViewController ()

@end

@implementation DBScreenCodeViewController

- (id)initWithDBBroadcast:(DBBroadcast *)broadcast {
    if (self = [super init]) {
        self.broadcast = broadcast;
        self.broadcastClient = [[DBBroadcastClient alloc] initWithBroadcast:self.broadcast];
        self.broadcastClient.delegate = self;
    }
    return self;
}

- (void)loadView {
    [super loadView];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"navbar.png"] forBarMetrics:UIBarMetricsDefault];
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                  target:self
                                                                                  action:@selector(cancelButtonPressed)];
    cancelButton.tintColor = [UIColor blueColor];
    self.navigationItem.rightBarButtonItem = cancelButton;
    
    self.invisTextField = [[UITextField alloc] initWithFrame:CGRectZero];
    self.invisTextField.keyboardType = UIKeyboardTypeNumberPad;
    self.invisTextField.delegate = self;
    [self.view addSubview:self.invisTextField];
    [self.invisTextField becomeFirstResponder];
    
    self.passcodeView = [[PasscodeView alloc] initWithFrame:CGRectMake(0, 100, 320, 100)];
    [self.view addSubview:self.passcodeView];
}

- (void)cancelButtonPressed {
    [self.navigationController dismissModalViewControllerAnimated:YES];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if ([self.passcodeView getFilledCount] >= 4) {
        return NO;
    }
    
    if ([string length] > 0) {
        [self.passcodeView fillNextCellWithChar:string];
    }
    else {
        [self.passcodeView deleteCellChar];
    }
    
    if ([self.passcodeView getFilledCount] == 4) {
        [self.broadcastClient addScreenToBroadcast:[self.passcodeView getPasscode]];
    }
   return YES;
}

- (void)clearCode {
    [self.passcodeView deleteCellChar];
    [self.passcodeView deleteCellChar];
    [self.passcodeView deleteCellChar];
    [self.passcodeView deleteCellChar];
}

#pragma mark DBBroadcastClientDelegate

- (void)broadcast:(DBBroadcastClient *)broadcastClient addedScreen:(NSString *)screen {
    [self.navigationController dismissModalViewControllerAnimated:YES];
}

- (void)broadcast:(DBBroadcastClient *)broadcastClient failedToAddScreen:(NSString *)screen withError:error {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:@"Failed to add device!"
                                                   delegate:self
                                          cancelButtonTitle:@"Dismiss"
                                          otherButtonTitles:nil];
    [alert show];
    [self clearCode];
}

@end
