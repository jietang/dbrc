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
#import "DBScreenCodeViewController.h"

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
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"navbar.png"] forBarMetrics:UIBarMetricsDefault];
    
    // Add Done Button
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonItemStylePlain
                                                                                target:self
                                                                                action:@selector(doneButtonPressed)];
    doneButton.title = @"Done";
    self.navigationItem.rightBarButtonItem = doneButton;
    
    // Add table with suggested pairing devices
    self.devicesTableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.devicesTableView.delegate = self;
    self.devicesTableView.dataSource = self;
    self.devicesTableView.backgroundView = [[UIView alloc] initWithFrame:self.devicesTableView.bounds];
    self.devicesTableView.backgroundView.backgroundColor = [UIColor colorWithRed:241/255.0 green:248/255.0 blue:255/255.0 alpha:1];
    self.devicesTableView.separatorColor = [UIColor colorWithRed:184/255.0 green:200/255.0 blue:212/255.0 alpha:1.0];
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

# pragma mark DBBroadcastDelegate/DBBroadcastClientDelegate
- (void)broadcast:(DBBroadcast *)broadcast receivedKnownScreens:(NSArray *)knownScreens {
    self.knownDevices = knownScreens;
    [self.devicesTableView reloadData];
}

- (void)broadcast:(DBBroadcastClient *)broadcastClient addedScreen:(NSString *)screen {
    
}

- (void)broadcast:(DBBroadcastClient *)broadcastClient failedToAddScreen:(NSString *)screen withError:(id)error {
    
}

# pragma mark UITableView DataSource/Delegate
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@""];
    NSDictionary *screenInfo = [self.knownDevices objectAtIndex:indexPath.row];
    
    DBScreenSwitch *screenSwitch = [[DBScreenSwitch alloc] initWithFrame:CGRectZero andScreenInfo:screenInfo];
    [screenSwitch addTarget:self action:@selector(screenSwitchWasFlipped:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = screenSwitch;
    
    cell.textLabel.text = [screenInfo objectForKey:@"device_name"];
    cell.textLabel.textColor = [UIColor colorWithRed:60/255.0 green:68/255.0 blue:89/255.0 alpha:1];
    cell.backgroundColor = [UIColor colorWithRed:225/255.0 green:236/255.0 blue:245/255.0 alpha:1];

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 43.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 43.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 53.0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.knownDevices count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Devices";
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *containterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 53.0)];
    
    UIButton *newDeviceButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [newDeviceButton setFrame:CGRectMake(10, 10, 300, 43.0)];
    
    UIImage *bgImg = [[UIImage imageNamed:@"blue-button.png"] stretchableImageWithLeftCapWidth:7 topCapHeight:0];
    [newDeviceButton setBackgroundImage:bgImg forState:UIControlStateNormal];
    [newDeviceButton setTitle:@"Add New Device" forState:UIControlStateNormal];
    newDeviceButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    [newDeviceButton addTarget:self action:@selector(addNewDevice) forControlEvents:UIControlEventTouchUpInside];
    
    [containterView addSubview:newDeviceButton];
    
    return containterView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

# pragma mark Controls
- (void)screenSwitchWasFlipped:(id)sender {
    DBScreenSwitch *screenSwitch = (DBScreenSwitch *)sender;
    if ([screenSwitch isOn]) {
        NSString *screenId = [NSString stringWithFormat:@"%d", [(NSNumber *)[screenSwitch.screenInfo objectForKey:@"screen_id"] intValue]];
        [self.broadcastClient addScreenToBroadcast:screenId];
    }
}

- (void)addNewDevice {
    DBScreenCodeViewController *vc = [[DBScreenCodeViewController alloc] initWithDBBroadcast:self.broadcast];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
    
    [self.navigationController presentViewController:navController animated:YES completion:NULL];
}



@end
