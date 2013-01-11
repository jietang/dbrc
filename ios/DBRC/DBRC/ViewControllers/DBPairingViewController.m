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
#import "DBScreenSwitch.h"

@interface DBPairingViewController ()

@end

@implementation DBPairingViewController

- (id)initWithBroadcast:(DBBroadcast *)broadcast {
    if (self = [super init]) {
        self.title = @"Screen Pairing";
        self.broadcast = broadcast;
        self.broadcastClient = [[DBBroadcastClient alloc] initWithBroadcast:self.broadcast];
        self.broadcastClient.delegate = self;
        self.knownDevices = [NSArray array];
    }
    return self;
}

- (void)loadView {
    [super loadView];
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationController.navigationBar.tintColor = [UIColor blueColor];
    
    // Add Done Button
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonItemStylePlain
                                                                                target:self
                                                                                action:@selector(doneButtonPressed)];
    doneButton.title = @"Done";
    self.navigationItem.rightBarButtonItem = doneButton;
    
    // Add table with suggested pairing devices
    self.devicesTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 320, 480) style:UITableViewStyleGrouped];
    self.devicesTableView.delegate = self;
    self.devicesTableView.dataSource = self;
    [self.view addSubview:self.devicesTableView];
    
    [self.broadcastClient fetchKnownScreens];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:YES];
}

- (void)doneButtonPressed {
    [self.navigationController dismissModalViewControllerAnimated:YES];
}

# pragma mark DBBroadcastDelegate
- (void)broadcast:(DBBroadcast *)broadcast receivedKnownScreens:(NSArray *)knownScreens {
    self.knownDevices = knownScreens;
    [self.devicesTableView reloadData];
}


# pragma mark UITableView DataSource/Delegate
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@""];
    NSDictionary *screenInfo = [self.knownDevices objectAtIndex:indexPath.row];
    
    DBScreenSwitch *screenSwitch = [[DBScreenSwitch alloc] initWithFrame:CGRectZero andScreenInfo:screenInfo];
    [screenSwitch addTarget:self action:@selector(screenSwitchWasFlipped:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = screenSwitch;

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 30.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 30.0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.knownDevices count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Devices";
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}



@end
