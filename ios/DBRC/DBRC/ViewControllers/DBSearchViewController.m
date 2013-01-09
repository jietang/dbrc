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

@end

@implementation DBSearchViewController

- (id)init {
    if (self = [super init]) {
        self.dbSession = [[DBSession alloc] initWithAppKey:@"gafchy215r87od1"
                                                 appSecret:@"0bhl35g2fcybyvh"
                                                      root:kDBRootDropbox];
        [DBSession setSharedSession:self.dbSession];
        
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
    DBPairingViewController *vc = [[DBPairingViewController alloc] initWithBroadcast:self.broadcast];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)broadcast:(DBBroadcast *)broadcast failedWithError:(NSError *)err {
    NSLog(@"%@err", err);
}

- (void)screenWasAdded:(NSString *)screen {
    NSLog(@"Screen was added!");
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)screenAddFailed:(NSString *)screen withError:(NSString *)err {
    NSLog(@"Failed to add screen");
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
    [self.rc loadSharableLinkForFile:metadata.path];
}

- (void)restClient:(DBRestClient*)restClient loadedSharableLink:(NSString *)link forFile:(NSString *)path {
    NSLog(@"Got link: %@\nFor File:%@", link, path, nil);
    [self.broadcast push:link withParams:nil];
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow]
                                  animated:YES];
}

@end
