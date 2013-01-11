//
//  DBSearchViewController.m
//  DBRC
//
//  Created by luedeman on 1/6/13.
//  Copyright (c) 2013 Dropbox. All rights reserved.
//

#import "DBPhotosViewController.h"
#import "DBPairingViewController.h"
#import "DBBroadcast.h"
#import "DBBroadcastClient.h"

@interface DBPhotosViewController ()

@property (nonatomic, retain) NSDate *requestStarted;

- (void)startTimingRequest;
- (void)stopTimingRequest;

@end

@implementation DBPhotosViewController

- (id)init {
    if (self = [super init]) {
        self.dbSession = [[DBSession alloc] initWithAppKey:[DBBroadcast appKey]
                                                 appSecret:[DBBroadcast appSecret]
                                                      root:kDBRootDropbox];
        [DBSession setSharedSession:self.dbSession];

        self.broadcast = [[DBBroadcast alloc] init];
        self.broadcast.delegate = self;
        self.broadcastClient = [[DBBroadcastClient alloc] initWithBroadcast:self.broadcast];
        self.broadcastClient.delegate = self;
        
        NSNotificationCenter *ctr = [NSNotificationCenter defaultCenter];
        [ctr addObserver:self selector:@selector(appClosed) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [ctr addObserver:self selector:@selector(appActive) name:UIApplicationDidBecomeActiveNotification object:nil];
        
        self.photos = [[DBPhotos alloc] init];
        self.photos.delegate = self;
        [self.photos fetchPhotos];
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
    self.navigationController.navigationBar.tintColor = [UIColor blueColor];
    
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 100)];
    self.searchBar.delegate = self;
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)
                                                  style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
//    [self.view addSubview:self.searchBar];
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
    DBPairingViewController *vc = [[DBPairingViewController alloc] initWithBroadcast:self.broadcast];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)unlink {
    [self.dbSession unlinkAll];
    [self.dbSession linkFromController:self];
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
    
    UIBarButtonItem *unlinkButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                                                                  target:self
                                                                                  action:@selector(unlink)];
    self.navigationItem.leftBarButtonItem = unlinkButton;
}

- (void)broadcast:(DBBroadcast *)broadcast failedWithError:(NSError *)err {
    NSLog(@"%@err", err);
}

- (void)broadcast:(DBBroadcast *)broadcast addedScreen:(NSString *)screen {
    NSLog(@"Screen was added!");
    [self.broadcastClient broadcastCredentials];
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)broadcast:(DBBroadcast *)broadcast failedToAddScreen:(NSString *)screen withError:(id)error {
    NSLog(@"Failed to add screen");
}


- (void)broadcastPushedCredentials:(DBBroadcast *)broadcast {
    
}

- (void)broadcastFailedToPushCredentials:(DBBroadcast *)broadcast withError:(NSError *)error {
    
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
    DBSession *session = [DBSession sharedSession];
    if ([[session userIds] count]) {
        NSString *userId = [session.userIds objectAtIndex:0];
        MPOAuthCredentialConcreteStore *credentials = [session credentialStoreForUserId:userId];
        NSMutableString *urlString = [NSMutableString stringWithString:@"https://api-content.dropbox.com/1/thumbnails/dropbox"];
        [urlString appendString:[metadata.path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        [urlString appendString:@"?oauth_signature_method=PLAINTEXT"];
        [urlString appendFormat:@"&oauth_consumer_key=%@", [DBBroadcast appKey]];
        [urlString appendFormat:@"&oauth_token=%@", [credentials accessToken]];
        [urlString appendFormat:@"&oauth_signature=%@%%26%@", [DBBroadcast appSecret], [credentials accessTokenSecret], nil];
        [urlString appendString:@"&size=1280x960"];
        
        [self.broadcastClient push:urlString withParams:nil];
    }
}

- (void)restClient:(DBRestClient*)restClient loadedSharableLink:(NSString *)link forFile:(NSString *)path {
    NSLog(@"Got link: %@\nFor File:%@", link, path, nil);
    [self stopTimingRequest];
    [self.broadcastClient push:link withParams:nil];
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow]
                                  animated:YES];
}

#pragma mark DBPhotos delegate
- (void)dbPhotos:(DBPhotos *)dbPhotos photosWereFetched:(NSArray *)photos {
    self.currentSearchResults = photos;
    [self.tableView reloadData];
}

# pragma mark Timing Helper
- (void)startTimingRequest {
    self.requestStarted = [NSDate date];
}

- (void)stopTimingRequest {
    NSLog(@"Request duration: %f", [[NSDate date] timeIntervalSinceDate:self.requestStarted]);
}

@end
