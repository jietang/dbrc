//
//  DBPairingViewController.m
//  DBRC
//
//  Created by luedeman on 1/7/13.
//  Copyright (c) 2013 Dropbox. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>

#import "DBPairingViewController.h"
#import "DBBroadcast.h"

@interface DBPairingViewController ()

@end

@implementation DBPairingViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Pair";
        self.broadcast = [[DBBroadcast alloc] init];
        self.broadcast.delegate = self;
        [self.broadcast startBroadcast];
        self.screenHasBeenAdded = NO;
    }
    return self;
}

- (void)loadView {
    [super loadView];
    self.view.backgroundColor = [UIColor grayColor];
    
    self.textField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 240, 40)];
    self.textField.delegate = self;
    self.textField.center = CGPointMake(160, 100);
    self.textField.backgroundColor = [UIColor whiteColor];
    self.textField.layer.cornerRadius = 5;
    self.textField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    
    self.instructions = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 60)];;
    self.instructions.text = @"Enter a pairing code";
    self.instructions.center = CGPointMake(160, 50);
    self.instructions.backgroundColor = [UIColor clearColor ];
    self.instructions.textAlignment = UITextAlignmentCenter;
    
    [self.view addSubview:self.textField];
    [self.view addSubview:self.instructions];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [self.textField becomeFirstResponder];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:YES];
}

#pragma mark UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (self.screenHasBeenAdded) {
        [self.broadcast push:self.textField.text withParams:nil];
    }
    else {
        [self.broadcast addScreenToBroadcast:self.textField.text];
        return YES;
    }
}

#pragma mark DBBroadcastDelegate
- (void)screenWasAdded:(NSString *)screen {
    NSLog(@"Screen was added!");
    self.screenHasBeenAdded = YES;
    self.instructions.text = @"Tell the screen to go to a url";
    self.textField.text = @"";
}

- (void)screenAddFailed:(NSString *)screen withError:(NSString *)err {
    NSLog(@"Failed to add screen");
}

# pragma mark DBBroadcastDelegate
- (void)broadcastWasStarted:(DBBroadcast *)broadcast {

}

@end
