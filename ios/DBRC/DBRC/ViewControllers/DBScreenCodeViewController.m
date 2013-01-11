//
//  DBScreenCodeViewController.m
//  DBRC
//
//  Created by luedeman on 1/11/13.
//  Copyright (c) 2013 Dropbox. All rights reserved.
//

#import "DBScreenCodeViewController.h"
#import "PasscodeView.h"

@interface DBScreenCodeViewController ()

@end

@implementation DBScreenCodeViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"Enter Code";
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
        [self performSelector:@selector(submitCode:) withObject:[self.passcodeView getPasscode] afterDelay:.25];
    }
   return YES;
}

- (void)submitCode:(NSString *)passcode {
    [self.passcodeView deleteCellChar];
    [self.passcodeView deleteCellChar];
    [self.passcodeView deleteCellChar];
    [self.passcodeView deleteCellChar];
    [self.passcodeView setNeedsDisplay];
}


@end
