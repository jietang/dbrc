//
//  FGalleryPhoto.m
//  FGallery
//
//  Created by Grant Davis on 5/20/10.
//  Copyright 2011 Grant Davis Interactive, LLC. All rights reserved.
//

#import "FGalleryPhoto.h"
#import <DropboxSDK/DropboxSDK.h>

@interface FGalleryPhoto (Private)

// delegate notifying methods
- (void)willLoadThumbFromUrl;
- (void)willLoadFullsizeFromUrl;
- (void)willLoadThumbFromPath;
- (void)willLoadFullsizeFromPath;
- (void)didLoadThumbnail;
- (void)didLoadFullsize;

// loading local images with threading
- (void)loadFullsizeInThread;
- (void)loadThumbnailInThread;

@end


@implementation FGalleryPhoto
@synthesize tag;
@synthesize thumbnail = _thumbnail;
@synthesize fullsize = _fullsize;
@synthesize delegate = _delegate;
@synthesize isFullsizeLoading = _isFullsizeLoading;
@synthesize hasFullsizeLoaded = _hasFullsizeLoaded;
@synthesize isThumbLoading = _isThumbLoading;
@synthesize hasThumbLoaded = _hasThumbLoaded;


- (id)initWithThumbnailUrl:(NSString*)thumb fullsizeUrl:(NSString*)fullsize index:(NSUInteger)index delegate:(NSObject<FGalleryPhotoDelegate>*)delegate
{
	self = [super init];
	_useNetwork = YES;
	_thumbUrl = thumb;
	_fullsizeUrl = fullsize;
	_delegate = delegate;
    _rc = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
    _rc.delegate = self;
    _index = index;
	return self;
}

- (void)loadThumbnail
{
	if( _isThumbLoading || _hasThumbLoaded ) return;
	
	// load from network
	if( _useNetwork )
	{
		// notify delegate
		[self willLoadThumbFromUrl];
		
		_isThumbLoading = YES;

        NSString *root = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *fname = [root stringByAppendingString:[NSString stringWithFormat:@"/%d_thumb",_index,nil]];
		[_rc loadThumbnail:_thumbUrl ofSize:@"l" intoPath:fname];
		_thumbData = [[NSMutableData alloc] init];
	}	
}


- (void)loadFullsize
{
	if( _isFullsizeLoading || _hasFullsizeLoaded ) return;
	
	if( _useNetwork )
	{
		// notify delegate
		[self willLoadFullsizeFromUrl];
		
		_isFullsizeLoading = YES;
		
		NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:_fullsizeUrl]];
		_fullsizeConnection = [NSURLConnection connectionWithRequest:request delegate:self];
		_fullsizeData = [[NSMutableData alloc] init];
	}
	else
	{
		[self willLoadFullsizeFromPath];
		
		_isFullsizeLoading = YES;
		
		// spawn a new thread to load from disk
		[NSThread detachNewThreadSelector:@selector(loadFullsizeInThread) toTarget:self withObject:nil];
	}
}


- (void)loadFullsizeInThread
{
	NSString *path = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] bundlePath], _fullsizeUrl];
	_fullsize = [UIImage imageWithContentsOfFile:path];
	
	_hasFullsizeLoaded = YES;
	_isFullsizeLoading = NO;

	[self performSelectorOnMainThread:@selector(didLoadFullsize) withObject:nil waitUntilDone:YES];
}


- (void)loadThumbnailInThread
{	
	NSString *path = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] bundlePath], _thumbUrl];
	_thumbnail = [UIImage imageWithContentsOfFile:path];
	
	_hasThumbLoaded = YES;
	_isThumbLoading = NO;
	
	[self performSelectorOnMainThread:@selector(didLoadThumbnail) withObject:nil waitUntilDone:YES];
	
}


- (void)unloadFullsize
{
	[_fullsizeConnection cancel];
	
	_isFullsizeLoading = NO;
	_hasFullsizeLoaded = NO;
	
	_fullsize = nil;
}

- (void)unloadThumbnail
{
	[_thumbConnection cancel];
	
	_isThumbLoading = NO;
	_hasThumbLoaded = NO;
	
	_thumbnail = nil;
}


#pragma mark -
#pragma mark NSURLConnection Delegate Methods


- (void)connection:(NSURLConnection *)conn didReceiveResponse:(NSURLResponse *)response {
	
	if( conn == _thumbConnection )
		[_thumbData setLength:0];
	
    else if( conn == _fullsizeConnection )
		[_fullsizeData setLength:0];
	
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}



- (void)connection:(NSURLConnection *)conn didReceiveData:(NSData *)data 
{
	if( conn == _thumbConnection )
		[_thumbData appendData:data];
	
    else if( conn == _fullsizeConnection )
		[_fullsizeData appendData:data];
	
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}



- (void)connectionDidFinishLoading:(NSURLConnection *)conn 
{	
	if( conn == _thumbConnection )
	{
		_isThumbLoading = NO;
		_hasThumbLoaded = YES;
		
		// create new image with data
		_thumbnail = [[UIImage alloc] initWithData:_thumbData];
				
		// notify delegate
		if( _delegate ) 
			[self didLoadThumbnail];
	}
    else if( conn == _fullsizeConnection )
	{
		_isFullsizeLoading = NO;
		_hasFullsizeLoaded = YES;
		
		// create new image with data
		_fullsize = [[UIImage alloc] initWithData:_fullsizeData];
				
		// notify delegate
		if( _delegate )
			[self didLoadFullsize];
	}
	
	// turn off data indicator
	if( !_isFullsizeLoading && !_isThumbLoading ) 
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

#pragma mark -
#pragma mark Delegate Notification Methods


- (void)willLoadThumbFromUrl
{
	if([_delegate respondsToSelector:@selector(galleryPhoto:willLoadThumbnailFromUrl:)])
		[_delegate galleryPhoto:self willLoadThumbnailFromUrl:_thumbUrl];
}


- (void)willLoadFullsizeFromUrl
{
	if([_delegate respondsToSelector:@selector(galleryPhoto:willLoadFullsizeFromUrl:)])
		[_delegate galleryPhoto:self willLoadFullsizeFromUrl:_fullsizeUrl];
}


- (void)willLoadThumbFromPath
{
	if([_delegate respondsToSelector:@selector(galleryPhoto:willLoadThumbnailFromPath:)])
		[_delegate galleryPhoto:self willLoadThumbnailFromPath:_thumbUrl];
}


- (void)willLoadFullsizeFromPath
{
	if([_delegate respondsToSelector:@selector(galleryPhoto:willLoadFullsizeFromPath:)])
		[_delegate galleryPhoto:self willLoadFullsizeFromPath:_fullsizeUrl];
}


- (void)didLoadThumbnail
{
//	FLog(@"gallery phooto did load thumbnail!");
	if([_delegate respondsToSelector:@selector(galleryPhoto:didLoadThumbnail:)])
		[_delegate galleryPhoto:self didLoadThumbnail:_thumbnail];
}


- (void)didLoadFullsize
{
//	FLog(@"gallery phooto did load fullsize!");
	if([_delegate respondsToSelector:@selector(galleryPhoto:didLoadFullsize:)])
		[_delegate galleryPhoto:self didLoadFullsize:_fullsize];
}


# pragma mark RestClient Callbacks
- (void)restClient:(DBRestClient*)client loadedThumbnail:(NSString*)destPath metadata:(DBMetadata*)metadata {
    NSLog(@"faasdf");
    NSLog(@"huhwhat? %@ %@", destPath, metadata);
    _thumbnail = [[UIImage alloc] initWithData:[NSData dataWithContentsOfFile:destPath]];
    
    // notify delegate
    if( _delegate )
        [self didLoadThumbnail];

}

- (void)restClient:(DBRestClient*)client loadThumbnailFailedWithError:(NSError*)error {
    NSLog(@"error =( %@", error);
}

    // is this the right delegate call?
    //[self.delegate dbPhotos:self photosWereFetched:metadata.contents];
    //- (void)restClient:(DBRestClient*)client loadedThumbnail:(NSString*)destPath metadata:(DBMetadata*)metadata;

    // - (void)restClient:(DBRestClient*)client loadedFile:(NSString*)destPath;


#pragma mark -
#pragma mark Memory Management



- (void)dealloc
{
//	NSLog(@"FGalleryPhoto dealloc");
	
//	[_delegate release];
	_delegate = nil;
	
	[_fullsizeConnection cancel];
	[_thumbConnection cancel];
	
	_thumbUrl = nil;
	_fullsizeUrl = nil;
	_thumbnail = nil;
	_fullsize = nil;
}


@end
