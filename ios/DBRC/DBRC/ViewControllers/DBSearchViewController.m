//
//  DBSearchViewController.m
//  DBRC
//
//  Created by luedeman on 1/6/13.
//  Copyright (c) 2013 Dropbox. All rights reserved.
//

#import "DBSearchViewController.h"

@interface DBSearchViewController ()

@end

@implementation DBSearchViewController

- (id)init {
    if (self = [super init]) {
        self.dbSession = [[DBSession alloc] initWithAppKey:@"gafchy215r87od1"
                                                 appSecret:@"0bhl35g2fcybyvh"
                                                      root:kDBRootDropbox];
        [DBSession setSharedSession:self.dbSession];
    }
    return self;
}

- (void)loadView {
    [super loadView];
    self.title = @"Dropbox";
    
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 100)];
    self.searchBar.delegate = self;
    
    [self.view addSubview:self.searchBar];
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    for (DBMetadata *metadata in results) {
        NSLog(@"%@", metadata.path, nil);
        [self.rc loadSharableLinkForFile:metadata.path];
    }
}

- (void)restClient:(DBRestClient*)restClient loadedSharableLink:(NSString *)link forFile:(NSString *)path {
    NSLog(@"Got link: %@\nFor File:%@", link, path, nil);
}

@end
