//
//  DBSearchViewController.m
//  DBRC
//
//  Created by luedeman on 1/6/13.
//  Copyright (c) 2013 Dropbox. All rights reserved.
//

#import "DBSearchViewController.h"
#import "DBPairingViewController.h"
#import "DBBroadcast.h"

@interface DBSearchViewController ()

@property (nonatomic, retain) NSDate *requestStarted;

- (void)startTimingRequest;
- (void)stopTimingRequest;

@end

@implementation DBSearchViewController

- (id)init {
    if (self = [super init]) {
        self.dbSession = [[DBSession alloc] initWithAppKey:@"gafchy215r87od1"
                                                 appSecret:@"0bhl35g2fcybyvh"
                                                      root:kDBRootDropbox];
        [DBSession setSharedSession:self.dbSession];
        
//        for (NSString *userId in self.dbSession.userIds) {
//            DBSession *session  = [DBSession sharedSession];
//            NSLog(@" Credentials for: %@", userId);
//            MPOAuthCredentialConcreteStore *credentials = [session credentialStoreForUserId:userId];
//            NSLog(@"%@", credentials);
//        }
        
        self.broadcast = [[DBBroadcast alloc] init];
        self.broadcast.delegate = self;
        
        NSNotificationCenter *ctr = [NSNotificationCenter defaultCenter];
        [ctr addObserver:self selector:@selector(appClosed) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [ctr addObserver:self selector:@selector(appActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

- (void)appClosed {
    self.broadcast.broadcastId = 0;
}

- (void)appActive {
    if (!self.broadcast.broadcastId) {
        self.navigationItem.rightBarButtonItem = nil;
        [self.broadcast startBroadcast];
    }
}

- (void)loadView {
    [super loadView];
    self.title = @"Dropbox";
    
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 100)];
    self.searchBar.delegate = self;
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 100, 320, 300)
                                                  style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    [self.view addSubview:self.searchBar];
    [self.view addSubview:self.tableView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (![[DBSession sharedSession] isLinked]) {
        [[DBSession sharedSession] linkFromController:self];
    }
    self.rc = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
    self.rc.delegate = self;
	// Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated {
    if (!self.broadcast.broadcastId) {
        [self.broadcast startBroadcast];
    }
}

- (void)addPair {
    [self.broadcast fetchKnownScreens];
}

#pragma mark UISearchBarDelegate
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    NSString *searchString = searchBar.text;
    NSLog(@"searching for '%@'...", searchString, nil);
    
    [self.rc searchPath:@"/" forKeyword:searchString];
}

#pragma mark DBRestClient Delegate
- (void)restClient:(DBRestClient*)restClient loadedSearchResults:(NSArray*)results
           forPath:(NSString*)path keyword:(NSString*)keyword {
    self.currentSearchResults = results;
    [self.tableView reloadData];
}



#pragma mark DBBroadcastDelegate
- (void)broadcastWasStarted:(DBBroadcast *)broadcast {
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                               target:self
                                                                               action:@selector(addPair)];
    self.navigationItem.rightBarButtonItem = addButton;
}

- (void)broadcast:(DBBroadcast *)broadcast failedWithError:(NSError *)err {
    NSLog(@"%@err", err);
}

- (void)broadcast:(DBBroadcast *)broadcast addedScreen:(NSString *)screen {
    NSLog(@"Screen was added!");
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)broadcast:(DBBroadcast *)broadcast failedToAddScreen:(NSString *)screen withError:(id)error {
    NSLog(@"Failed to add screen");
}

- (void)broadcast:(DBBroadcast *)broadcast receivedLikelyScreens:(NSArray *)likelyHosts {
    [self.broadcast fetchKnownScreens];
}

- (void)broadcast:(DBBroadcast *)broadcast failedToReceiveLikelyScreens:(NSError *)error {
    
}

- (void)broadcast:(DBBroadcast *)broadcast receivedKnownScreens:(NSArray *)likelyHosts {
    DBPairingViewController *vc = [[DBPairingViewController alloc] initWithBroadcast:self.broadcast];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)broadcast:(DBBroadcast *)broadcast failedToReceiveKnownScreens:(NSError *)error {
    
}

# pragma mark UITableView DataSource / Delegates
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.currentSearchResults count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 30.0;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@""];
    DBMetadata *metadata = [self.currentSearchResults objectAtIndex:indexPath.row];
    cell.textLabel.text = metadata.path;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath  {
    DBMetadata *metadata = [self.currentSearchResults objectAtIndex:indexPath.row];
    [self startTimingRequest];
    [self.rc loadSharableLinkForFile:metadata.path];
}

- (void)restClient:(DBRestClient*)restClient loadedSharableLink:(NSString *)link forFile:(NSString *)path {
    NSLog(@"Got link: %@\nFor File:%@", link, path, nil);
    [self stopTimingRequest];
    [self.broadcast push:link withParams:nil];
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow]
                                  animated:YES];
}

# pragma mark Timing Helper
- (void)startTimingRequest {
    // 78247
    self.requestStarted = [NSDate date];
}

- (void)stopTimingRequest {
    NSLog(@"Request duration: %f", [[NSDate date] timeIntervalSinceDate:self.requestStarted]);
}

@end
