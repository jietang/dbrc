    //
//  FGalleryViewController.m
//  FGallery
//
//  Created by Grant Davis on 5/19/10.
//  Copyright 2011 Grant Davis Interactive, LLC. All rights reserved.
//

#import "FGalleryViewController.h"
#import "FGalleryPhoto.h"
#import "DBPhotosViewController.h"
#import "DBPairingViewController.h"
#import "DBBroadcast.h"
#import "DBBroadcastClient.h"
#import "GalleryDelegate.h"

#define kThumbnailSize 75
#define kThumbnailSpacing 4
#define kCaptionPadding 3
#define kToolbarHeight 40


@interface FGalleryViewController (Private)

// general
- (void)buildViews;
- (void)destroyViews;
- (void)layoutViews;
- (void)moveScrollerToCurrentIndexWithAnimation:(BOOL)animation;
- (void)updateTitle;
- (void)updateScrollSize;
- (void)resizeImageViewsWithRect:(CGRect)rect;
- (void)resetImageViewZoomLevels;

- (void)enterFullscreen;
- (void)exitFullscreen;
- (void)enableApp;
- (void)disableApp;

- (void)positionInnerContainer;
- (void)positionScroller;
- (void)resizeThumbView;

// thumbnails
- (void)toggleThumbnailViewWithAnimation:(BOOL)animation;
- (void)showThumbnailViewWithAnimation:(BOOL)animation;
- (void)hideThumbnailViewWithAnimation:(BOOL)animation;
- (void)buildThumbsViewPhotos;

- (void)arrangeThumbs;
- (void)loadAllThumbViewPhotos;

- (void)preloadThumbnailImages;
- (void)unloadFullsizeImageWithIndex:(NSUInteger)index;

- (void)scrollingHasEnded;

- (void)handleSeeAllTouch:(id)sender;
- (void)handleThumbClick:(id)sender;

- (FGalleryPhoto*)createGalleryPhotoForIndex:(NSUInteger)index;

- (void)loadThumbnailImageWithIndex:(NSUInteger)index;
- (void)loadFullsizeImageWithIndex:(NSUInteger)index;

@end



@implementation FGalleryViewController
@synthesize galleryID;
@synthesize photoSource = _photoSource;
@synthesize currentIndex = _currentIndex;
@synthesize thumbsView = _thumbsView;
@synthesize useThumbnailView = _useThumbnailView;
@synthesize startingIndex = _startingIndex;
@synthesize beginsInThumbnailView = _beginsInThumbnailView;
@synthesize hideTitle = _hideTitle;

#pragma mark - Public Methods

- (void)lowInit {
    
    // init gallery id with our memory address
    self.galleryID						= [NSString stringWithFormat:@"%p", self];
    
    // configure view controller
    self.hidesBottomBarWhenPushed		= YES;

    // set defaults
    _useThumbnailView                   = YES;
    _prevStatusStyle					= [[UIApplication sharedApplication] statusBarStyle];
    _hideTitle                          = NO;

    // create storage objects
    _currentIndex						= 0;
    _startingIndex                      = 0;
    _photoLoaders						= [[NSMutableDictionary alloc] init];
    _photoViews							= [[NSMutableArray alloc] init];
    _photoThumbnailViews				= [[NSMutableArray alloc] init];
    
    
    // API objects
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

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if((self = [super initWithNibName:nil bundle:nil])) {
        [self lowInit];
    }
	return self;
}


- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	
	if (self != nil) {
        [self lowInit];
    }
	
	return self;
}

- (id)initWithPhotoSource:(NSObject<FGalleryViewControllerDelegate>*)photoSrc
{
	if((self = [self initWithNibName:nil bundle:nil])) {
		
		_photoSource = photoSrc;
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



- (void)loadView
{
    [super loadView];
    self.navigationController.navigationBar.tintColor = [UIColor blueColor];

    // create public objects first so they're available for custom configuration right away. positioning comes later.
    _container							= [[UIView alloc] initWithFrame:CGRectZero];
    _innerContainer						= [[UIView alloc] initWithFrame:CGRectZero];
    _scroller							= [[UIScrollView alloc] initWithFrame:CGRectZero];
    _thumbsView							= [[UIScrollView alloc] initWithFrame:CGRectZero];
    _container.backgroundColor			= [UIColor blackColor];
    
    // listen for container frame changes so we can properly update the layout during auto-rotation or going in and out of fullscreen
    [_container addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
    
    // setup scroller
    _scroller.delegate							= self;
    _scroller.pagingEnabled						= YES;
    _scroller.showsVerticalScrollIndicator		= NO;
    _scroller.showsHorizontalScrollIndicator	= NO;
    
    // make things flexible
    _container.autoresizesSubviews				= NO;
    _innerContainer.autoresizesSubviews			= NO;
    _scroller.autoresizesSubviews				= NO;
    _container.autoresizingMask					= UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    // setup thumbs view
    _thumbsView.backgroundColor					= [UIColor whiteColor];
    //_thumbsView.hidden							= YES;
    _thumbsView.hidden							= NO;
    _thumbsView.contentInset					= UIEdgeInsetsMake( kThumbnailSpacing, kThumbnailSpacing, kThumbnailSpacing, kThumbnailSpacing);
    
	// set view
	self.view                                   = _container;
	
	// add items to their containers
	[_container addSubview:_innerContainer];
	[_container addSubview:_thumbsView];
	
	[_innerContainer addSubview:_scroller];
		
    // build stuff
    [self reloadGallery];
}

- (void)viewDidLoad {
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
    // if we are in an image view and have a paired screen, send a broadcast
    // else, bring up the pairing screen.
    if (!_isThumbViewShowing && self.broadcast.connectedScreens > 0) {
        DBSession *session = [DBSession sharedSession];
        if ([[session userIds] count]) {
            NSString *userId = [session.userIds objectAtIndex:0];
            MPOAuthCredentialConcreteStore *credentials = [session credentialStoreForUserId:userId];
            NSMutableString *urlString = [NSMutableString stringWithString:@"https://api-content.dropbox.com/1/thumbnails/dropbox"];
            FGalleryPhoto *photo = [_photoLoaders objectForKey:[NSString stringWithFormat:@"%i", _currentIndex]];
            [urlString appendString:[photo.thumbUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            [urlString appendString:@"?oauth_signature_method=PLAINTEXT"];
            [urlString appendFormat:@"&oauth_consumer_key=%@", [DBBroadcast appKey]];
            [urlString appendFormat:@"&oauth_token=%@", [credentials accessToken]];
            [urlString appendFormat:@"&oauth_signature=%@%%26%@", [DBBroadcast appSecret], [credentials accessTokenSecret], nil];
            [urlString appendString:@"&size=1280x960"];
            
            [self.broadcastClient push:urlString withParams:nil];
        }
    } else {
        DBPairingViewController *vc = [[DBPairingViewController alloc] initWithBroadcast:self.broadcast];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
        [self presentViewController:navController animated:YES completion:nil];
    }
}

- (void)unlink {
    [self.dbSession unlinkAll];
    [self.dbSession linkFromController:self];
}

- (void)viewDidUnload {
    
    [self destroyViews];
    
    _container = nil;
    _innerContainer = nil;
    _scroller = nil;
    _thumbsView = nil;
    
    [super viewDidUnload];
}


- (void)destroyViews {
    // remove previous photo views
    for (UIView *view in _photoViews) {
        [view removeFromSuperview];
    }
    [_photoViews removeAllObjects];
    
    // remove previous thumbnails
    for (UIView *view in _photoThumbnailViews) {
        [view removeFromSuperview];
    }
    [_photoThumbnailViews removeAllObjects];
    
    // remove photo loaders
    NSArray *photoKeys = [_photoLoaders allKeys];
    for (int i=0; i<[photoKeys count]; i++) {
        FGalleryPhoto *photoLoader = [_photoLoaders objectForKey:[photoKeys objectAtIndex:i]];
        photoLoader.delegate = nil;
        [photoLoader unloadFullsize];
        [photoLoader unloadThumbnail];
    }
    [_photoLoaders removeAllObjects];
}


- (void)reloadGallery
{
    _currentIndex = _startingIndex;
    _isThumbViewShowing = NO;
    
    // remove the old
    [self destroyViews];
    
    // build the new
    if ([_photoSource numberOfPhotosForPhotoGallery:self] > 0) {
        // create the image views for each photo
        [self buildViews];
        
        // create the thumbnail views
        [self buildThumbsViewPhotos];
        
        // start loading thumbs
        [self preloadThumbnailImages];
        
        // start on first image
        //[self gotoImageByIndex:_currentIndex animated:NO];
        
        // layout
        [self layoutViews];
    }
}

- (FGalleryPhoto*)currentPhoto
{
    return [_photoLoaders objectForKey:[NSString stringWithFormat:@"%i", _currentIndex]];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
	
    _isActive = YES;
    
    self.useThumbnailView = _useThumbnailView;
	
    // toggle into the thumb view if we should start there
    if (_beginsInThumbnailView && _useThumbnailView) {
        [self showThumbnailViewWithAnimation:NO];
        [self loadAllThumbViewPhotos];
    }
    
	[self layoutViews];
	
	// update status bar to be see-through
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:animated];
	
	// init with next on first run.
	if( _currentIndex == -1 ) [self next];
	else [self gotoImageByIndex:_currentIndex animated:NO];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
	_isActive = NO;

	[[UIApplication sharedApplication] setStatusBarStyle:_prevStatusStyle animated:animated];
}


- (void)resizeImageViewsWithRect:(CGRect)rect
{
	// resize all the image views
	NSUInteger i, count = [_photoViews count];
	float dx = 0;
	for (i = 0; i < count; i++) {
		FGalleryPhotoView * photoView = [_photoViews objectAtIndex:i];
		photoView.frame = CGRectMake(dx, 0, rect.size.width, rect.size.height );
		dx += rect.size.width;
	}
}


- (void)resetImageViewZoomLevels
{
	// resize all the image views
	NSUInteger i, count = [_photoViews count];
	for (i = 0; i < count; i++) {
		FGalleryPhotoView * photoView = [_photoViews objectAtIndex:i];
		[photoView resetZoom];
	}
}


- (void)removeImageAtIndex:(NSUInteger)index
{
	// remove the image and thumbnail at the specified index.
	FGalleryPhotoView *imgView = [_photoViews objectAtIndex:index];
 	FGalleryPhotoView *thumbView = [_photoThumbnailViews objectAtIndex:index];
	FGalleryPhoto *photo = [_photoLoaders objectForKey:[NSString stringWithFormat:@"%i",index]];
	
	[photo unloadFullsize];
	[photo unloadThumbnail];
	
	[imgView removeFromSuperview];
	[thumbView removeFromSuperview];
	
	[_photoViews removeObjectAtIndex:index];
	[_photoThumbnailViews removeObjectAtIndex:index];
	[_photoLoaders removeObjectForKey:[NSString stringWithFormat:@"%i",index]];
	
	[self layoutViews];
    [self updateTitle:YES];
}


- (void)next
{
	NSUInteger numberOfPhotos = [_photoSource numberOfPhotosForPhotoGallery:self];
	NSUInteger nextIndex = _currentIndex+1;
	
	// don't continue if we're out of images.
	if( nextIndex <= numberOfPhotos )
	{
		[self gotoImageByIndex:nextIndex animated:NO];
	}
}



- (void)previous
{
	NSUInteger prevIndex = _currentIndex-1;
	[self gotoImageByIndex:prevIndex animated:NO];
}



- (void)gotoImageByIndex:(NSUInteger)index animated:(BOOL)animated
{
	NSUInteger numPhotos = [_photoSource numberOfPhotosForPhotoGallery:self];
	
	// constrain index within our limits
    if( index >= numPhotos ) index = numPhotos - 1;
	
	
	if( numPhotos == 0 ) {
		
		// no photos!
		_currentIndex = -1;
	}
	else {
		
		// clear the fullsize image in the old photo
		[self unloadFullsizeImageWithIndex:_currentIndex];
		
		_currentIndex = index;
		[self moveScrollerToCurrentIndexWithAnimation:animated];
		[self updateTitle:YES];
		
		if( !animated )	{
			[self preloadThumbnailImages];
			[self loadFullsizeImageWithIndex:index];
		}
	}
}


- (void)layoutViews
{
	[self positionInnerContainer];
	[self positionScroller];
	[self resizeThumbView];
	[self updateScrollSize];
	[self resizeImageViewsWithRect:_scroller.frame];
	[self arrangeThumbs];
	[self moveScrollerToCurrentIndexWithAnimation:NO];
    [self updateTitle:NO];
}


- (void)setUseThumbnailView:(BOOL)useThumbnailView
{
    
    UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithTitle: NSLocalizedString(@"Back", @"") style: UIBarButtonItemStyleBordered target: nil action: nil];
    [[self navigationItem] setBackBarButtonItem: newBackButton];
    
    [self updateTitle:NO];
    _useThumbnailView = useThumbnailView;
    if( self.navigationController ) {
        [self.navigationItem setLeftBarButtonItem:nil animated:NO];
    }
}


#pragma mark - Private Methods

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if([keyPath isEqualToString:@"frame"]) 
	{
		[self layoutViews];
	}
}


- (void)positionInnerContainer
{
	CGRect screenFrame = [[UIScreen mainScreen] bounds];
	CGRect innerContainerRect;
	
	if( self.interfaceOrientation == UIInterfaceOrientationPortrait || self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown )
	{//portrait
		innerContainerRect = CGRectMake( 0, _container.frame.size.height - screenFrame.size.height, _container.frame.size.width, screenFrame.size.height );
	}
	else 
	{// landscape
		innerContainerRect = CGRectMake( 0, _container.frame.size.height - screenFrame.size.width, _container.frame.size.width, screenFrame.size.width );
	}
	
	_innerContainer.frame = innerContainerRect;
}


- (void)positionScroller
{
	CGRect screenFrame = [[UIScreen mainScreen] bounds];
	CGRect scrollerRect;
	
	if( self.interfaceOrientation == UIInterfaceOrientationPortrait || self.interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown )
	{//portrait
		scrollerRect = CGRectMake( 0, 0, screenFrame.size.width, screenFrame.size.height );
	}
	else
	{//landscape
		scrollerRect = CGRectMake( 0, 0, screenFrame.size.height, screenFrame.size.width );
	}
	
	_scroller.frame = scrollerRect;
}


- (void)resizeThumbView
{
    int barHeight = 0;
    if (self.navigationController.navigationBar.barStyle == UIBarStyleBlackTranslucent) {
        barHeight = self.navigationController.navigationBar.frame.size.height;
    }
	_thumbsView.frame = CGRectMake( 0, barHeight, _container.frame.size.width, _container.frame.size.height-barHeight );
}


- (void)enterFullscreen
{
    if (!_isThumbViewShowing)
    {
        _isFullscreen = YES;
        
        [self disableApp];
        
        UIApplication* application = [UIApplication sharedApplication];
        if ([application respondsToSelector: @selector(setStatusBarHidden:withAnimation:)]) {
            [[UIApplication sharedApplication] setStatusBarHidden: YES withAnimation: UIStatusBarAnimationFade]; // 3.2+
        } else {
    #pragma GCC diagnostic ignored "-Wdeprecated-declarations"
            [[UIApplication sharedApplication] setStatusBarHidden: YES animated:YES]; // 2.0 - 3.2
    #pragma GCC diagnostic warning "-Wdeprecated-declarations"
        }
        
        [self.navigationController setNavigationBarHidden:YES animated:YES];
        
        [UIView beginAnimations:@"galleryOut" context:nil];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(enableApp)];
        [UIView commitAnimations];
    }
}



- (void)exitFullscreen
{
	_isFullscreen = NO;
    
	[self disableApp];
    
	UIApplication* application = [UIApplication sharedApplication];
	if ([application respondsToSelector: @selector(setStatusBarHidden:withAnimation:)]) {
		[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade]; // 3.2+
	} else {
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
		[[UIApplication sharedApplication] setStatusBarHidden:NO animated:NO]; // 2.0 - 3.2
#pragma GCC diagnostic warning "-Wdeprecated-declarations"
	}
    
	[self.navigationController setNavigationBarHidden:NO animated:YES];
    
	[UIView beginAnimations:@"galleryIn" context:nil];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(enableApp)];
	[UIView commitAnimations];
}



- (void)enableApp
{
	[[UIApplication sharedApplication] endIgnoringInteractionEvents];
}


- (void)disableApp
{
	[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
}


- (void)didTapPhotoView:(FGalleryPhotoView*)photoView
{
	// don't change when scrolling
	if( _isScrolling || !_isActive ) return;
	
	// toggle fullscreen.
	if( _isFullscreen == NO ) {
		
		[self enterFullscreen];
	}
	else {
		
		[self exitFullscreen];
	}

}


- (void)updateScrollSize
{
	float contentWidth = _scroller.frame.size.width * [_photoSource numberOfPhotosForPhotoGallery:self];
	[_scroller setContentSize:CGSizeMake(contentWidth, _scroller.frame.size.height)];
}


- (void)updateTitle:(BOOL)isThumbnail
{
    if (isThumbnail){
        [self setTitle:[NSString stringWithFormat:@"%i %@ %i", _currentIndex+1, NSLocalizedString(@"of", @"") , [_photoSource numberOfPhotosForPhotoGallery:self]]];
    } else{
        [self setTitle:@"Camera Uploads"];
    }
}

- (void)moveScrollerToCurrentIndexWithAnimation:(BOOL)animation
{
	int xp = _scroller.frame.size.width * _currentIndex;
	[_scroller scrollRectToVisible:CGRectMake(xp, 0, _scroller.frame.size.width, _scroller.frame.size.height) animated:animation];
	_isScrolling = animation;
}


// creates all the image views for this gallery
- (void)buildViews
{
	NSUInteger i, count = [_photoSource numberOfPhotosForPhotoGallery:self];
	for (i = 0; i < count; i++) {
		FGalleryPhotoView *photoView = [[FGalleryPhotoView alloc] initWithFrame:CGRectZero];
		photoView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		photoView.autoresizesSubviews = YES;
		photoView.photoDelegate = self;
		[_scroller addSubview:photoView];
		[_photoViews addObject:photoView];
	}
}


- (void)buildThumbsViewPhotos
{
	NSUInteger i, count = [_photoSource numberOfPhotosForPhotoGallery:self];
	for (i = 0; i < count; i++) {
		
		FGalleryPhotoView *thumbView = [[FGalleryPhotoView alloc] initWithFrame:CGRectZero target:self action:@selector(handleThumbClick:)];
		[thumbView setContentMode:UIViewContentModeScaleAspectFill];
		[thumbView setClipsToBounds:YES];
		[thumbView setTag:i];
		[_thumbsView addSubview:thumbView];
		[_photoThumbnailViews addObject:thumbView];
	}
}



- (void)arrangeThumbs
{
	float dx = 0.0;
	float dy = 0.0;
	// loop through all thumbs to size and place them
	NSUInteger i, count = [_photoThumbnailViews count];
	for (i = 0; i < count; i++) {
		FGalleryPhotoView *thumbView = [_photoThumbnailViews objectAtIndex:i];
		[thumbView setBackgroundColor:[UIColor grayColor]];
		
		// create new frame
		thumbView.frame = CGRectMake( dx, dy, kThumbnailSize, kThumbnailSize);
		
		// increment position
		dx += kThumbnailSize + kThumbnailSpacing;
		
		// check if we need to move to a different row
		if( dx + kThumbnailSize + kThumbnailSpacing > _thumbsView.frame.size.width - kThumbnailSpacing )
		{
			dx = 0.0;
			dy += kThumbnailSize + kThumbnailSpacing;
		}
	}
	
	// set the content size of the thumb scroller
	[_thumbsView setContentSize:CGSizeMake( _thumbsView.frame.size.width - ( kThumbnailSpacing*2 ), dy + kThumbnailSize + kThumbnailSpacing )];
}


- (void)toggleThumbnailViewWithAnimation:(BOOL)animation
{
    if (_isThumbViewShowing) {
        [self hideThumbnailViewWithAnimation:animation];
    }
    else {
        [self showThumbnailViewWithAnimation:animation];
    }
}


- (void)showThumbnailViewWithAnimation:(BOOL)animation
{
    _isThumbViewShowing = YES;
    
    [self arrangeThumbs];
    //[self.navigationItem.leftBarButtonItem setTitle:NSLocalizedString(@"Pull", @"")];
    [self.navigationItem setLeftBarButtonItem:nil animated:NO];
    
    if (animation) {
        // do curl animation
        [UIView beginAnimations:@"uncurl" context:nil];
        [UIView setAnimationDuration:.666];
        [UIView setAnimationTransition:UIViewAnimationTransitionCurlDown forView:_thumbsView cache:YES];
        [_thumbsView setHidden:NO];
        [UIView commitAnimations];
    }
    else {
        [_thumbsView setHidden:NO];
    }
}


- (void)hideThumbnailViewWithAnimation:(BOOL)animation
{
    _isThumbViewShowing = NO;
    UIBarButtonItem *btn = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", @"") style:UIBarButtonItemStylePlain target:self action:@selector(handleSeeAllTouch:)];
    [self.navigationItem setLeftBarButtonItem:btn animated:NO];
    
    if (animation) {
        // do curl animation
        [UIView beginAnimations:@"curl" context:nil];
        [UIView setAnimationDuration:.666];
        [UIView setAnimationTransition:UIViewAnimationTransitionCurlUp forView:_thumbsView cache:YES];
        [_thumbsView setHidden:YES];
        [UIView commitAnimations];
    }
    else {
        [_thumbsView setHidden:YES];
    }
}


- (void)handleSeeAllTouch:(id)sender
{
	// show thumb view
	[self toggleThumbnailViewWithAnimation:NO];
	
	// tell thumbs that havent loaded to load
	[self loadAllThumbViewPhotos];
    [self updateTitle:NO];
}


- (void)handleThumbClick:(id)sender
{
	FGalleryPhotoView *photoView = (FGalleryPhotoView*)[(UIButton*)sender superview];
	[self hideThumbnailViewWithAnimation:NO];
	[self gotoImageByIndex:photoView.tag animated:NO];
}


#pragma mark - Image Loading


- (void)preloadThumbnailImages
{
	NSUInteger index = _currentIndex;
	NSUInteger count = [_photoViews count];
    
	// make sure the images surrounding the current index have thumbs loading
	NSUInteger nextIndex = index + 1;
	NSUInteger prevIndex = index - 1;
	
	// the preload count indicates how many images surrounding the current photo will get preloaded.
	// a value of 2 at maximum would preload 4 images, 2 in front of and two behind the current image.
	NSUInteger preloadCount = 24;
	
	FGalleryPhoto *photo;
	
	// check to see if the current image thumb has been loaded
	photo = [_photoLoaders objectForKey:[NSString stringWithFormat:@"%i", index]];
	
	if( !photo )
	{
		[self loadThumbnailImageWithIndex:index];
		photo = [_photoLoaders objectForKey:[NSString stringWithFormat:@"%i", index]];
	}
	
	if( !photo.hasThumbLoaded && !photo.isThumbLoading )
	{
		[photo loadThumbnail];
	}
	
	NSUInteger curIndex = prevIndex;
	while( curIndex > -1 && curIndex > prevIndex - preloadCount )
	{
		photo = [_photoLoaders objectForKey:[NSString stringWithFormat:@"%i", curIndex]];
		
		if( !photo ) {
			[self loadThumbnailImageWithIndex:curIndex];
			photo = [_photoLoaders objectForKey:[NSString stringWithFormat:@"%i", curIndex]];
		}
		
		if( !photo.hasThumbLoaded && !photo.isThumbLoading )
		{
			[photo loadThumbnail];
		}
		
		curIndex--;
	}
	
	curIndex = nextIndex;
	while( curIndex < count && curIndex < nextIndex + preloadCount )
	{
		photo = [_photoLoaders objectForKey:[NSString stringWithFormat:@"%i", curIndex]];
		
		if( !photo ) {
			[self loadThumbnailImageWithIndex:curIndex];
			photo = [_photoLoaders objectForKey:[NSString stringWithFormat:@"%i", curIndex]];
		}
		
		if( !photo.hasThumbLoaded && !photo.isThumbLoading )
		{
			[photo loadThumbnail];
		}
		
		curIndex++;
	}
}


- (void)loadAllThumbViewPhotos
{
	NSUInteger i, count = [_photoSource numberOfPhotosForPhotoGallery:self];
	for (i=0; i < count; i++) {
		
		[self loadThumbnailImageWithIndex:i];
	}
}


- (void)loadThumbnailImageWithIndex:(NSUInteger)index
{
	FGalleryPhoto *photo = [_photoLoaders objectForKey:[NSString stringWithFormat:@"%i", index]];
	
	if( photo == nil )
		photo = [self createGalleryPhotoForIndex:index];
	
	[photo loadThumbnail];
}


- (void)loadFullsizeImageWithIndex:(NSUInteger)index
{
	FGalleryPhoto *photo = [_photoLoaders objectForKey:[NSString stringWithFormat:@"%i", index]];
	
	if( photo == nil )
		photo = [self createGalleryPhotoForIndex:index];
	
	[photo loadFullsize];
}


- (void)unloadFullsizeImageWithIndex:(NSUInteger)index
{
	if (index < [_photoViews count]) {		
		FGalleryPhoto *loader = [_photoLoaders objectForKey:[NSString stringWithFormat:@"%i", index]];
		[loader unloadFullsize];
		
		FGalleryPhotoView *photoView = [_photoViews objectAtIndex:index];
		photoView.imageView.image = loader.thumbnail;
	}
}


- (FGalleryPhoto*)createGalleryPhotoForIndex:(NSUInteger)index
{
	FGalleryPhotoSourceType sourceType = [_photoSource photoGallery:self sourceTypeForPhotoAtIndex:index];
	FGalleryPhoto *photo;
	NSString *thumbPath;
	NSString *fullsizePath;
	
    if( sourceType == FGalleryPhotoSourceTypeNetwork )
	{
		thumbPath = [_photoSource photoGallery:self urlForPhotoSize:FGalleryPhotoSizeThumbnail atIndex:index];
		fullsizePath = [_photoSource photoGallery:self urlForPhotoSize:FGalleryPhotoSizeFullsize atIndex:index];
		photo = [[FGalleryPhoto alloc] initWithThumbnailUrl:thumbPath fullsizeUrl:fullsizePath index:index delegate:self];
	}
	else 
	{
		// invalid source type, throw an error.
		[NSException raise:@"Invalid photo source type" format:@"The specified source type of %d is invalid", sourceType];
	}
    
	// assign the photo index
	photo.tag = index;
	
	// store it
	[_photoLoaders setObject:photo forKey: [NSString stringWithFormat:@"%i", index]];
	
	return photo;
}


- (void)scrollingHasEnded {
	
	_isScrolling = NO;
	
	NSUInteger newIndex = floor( _scroller.contentOffset.x / _scroller.frame.size.width );
	
	// don't proceed if the user has been scrolling, but didn't really go anywhere.
	if( newIndex == _currentIndex )
		return;
	
	// clear previous
	[self unloadFullsizeImageWithIndex:_currentIndex];
	
	_currentIndex = newIndex;
	[self updateTitle:YES];
	[self loadFullsizeImageWithIndex:_currentIndex];
	[self preloadThumbnailImages];
}


#pragma mark - FGalleryPhoto Delegate Methods


- (void)galleryPhoto:(FGalleryPhoto*)photo willLoadThumbnailFromPath:(NSString*)path
{
	// show activity indicator for large photo view
	FGalleryPhotoView *photoView = [_photoViews objectAtIndex:photo.tag];
	[photoView.activity startAnimating];
	
	// show activity indicator for thumbail 
	if( _isThumbViewShowing ) {
		FGalleryPhotoView *thumb = [_photoThumbnailViews objectAtIndex:photo.tag];
		[thumb.activity startAnimating];
	}
}


- (void)galleryPhoto:(FGalleryPhoto*)photo willLoadThumbnailFromUrl:(NSString*)url
{
	// show activity indicator for large photo view
	FGalleryPhotoView *photoView = [_photoViews objectAtIndex:photo.tag];
	[photoView.activity startAnimating];
	
	// show activity indicator for thumbail 
	if( _isThumbViewShowing ) {
		FGalleryPhotoView *thumb = [_photoThumbnailViews objectAtIndex:photo.tag];
		[thumb.activity startAnimating];
	}
}


- (void)galleryPhoto:(FGalleryPhoto*)photo didLoadThumbnail:(UIImage*)image
{
	// grab the associated image view
	FGalleryPhotoView *photoView = [_photoViews objectAtIndex:photo.tag];
	
	// if the gallery photo hasn't loaded the fullsize yet, set the thumbnail as its image.
	if( !photo.hasFullsizeLoaded )
		photoView.imageView.image = photo.thumbnail;

	[photoView.activity stopAnimating];
	
	// grab the thumbail view and set its image
	FGalleryPhotoView *thumbView = [_photoThumbnailViews objectAtIndex:photo.tag];
	thumbView.imageView.image = image;
	[thumbView.activity stopAnimating];
}



- (void)galleryPhoto:(FGalleryPhoto*)photo didLoadFullsize:(UIImage*)image
{
	// only set the fullsize image if we're currently on that image
	if( _currentIndex == photo.tag )
	{
		FGalleryPhotoView *photoView = [_photoViews objectAtIndex:photo.tag];
		photoView.imageView.image = photo.fullsize;
	}
	// otherwise, we don't need to keep this image around
	else [photo unloadFullsize];
}

/*- (void) sendURLForMetadata {
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
}*/


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


#pragma mark DBPhotos delegate
- (void)dbPhotos:(DBPhotos *)dbPhotos photosWereFetched:(NSArray *)photos {
    [self.photoSource processPhotos:photos];
    [self reloadGallery];
}


#pragma mark - UIScrollView Methods


- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	_isScrolling = YES;
}
 

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
	if( !decelerate )
	{
		[self scrollingHasEnded];
	}
}


- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
	[self scrollingHasEnded];
}


#pragma mark - Memory Management Methods

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
	
	NSLog(@"[FGalleryViewController] didReceiveMemoryWarning! clearing out cached images...");
	// unload fullsize and thumbnail images for all our images except at the current index.
	NSArray *keys = [_photoLoaders allKeys];
	NSUInteger i, count = [keys count];
    if (_isThumbViewShowing==YES) {
        for (i = 0; i < count; i++)
        {
            FGalleryPhoto *photo = [_photoLoaders objectForKey:[keys objectAtIndex:i]];
            [photo unloadFullsize];
            
            // unload main image thumb
            FGalleryPhotoView *photoView = [_photoViews objectAtIndex:i];
            photoView.imageView.image = nil;
        }
    } else {
        for (i = 0; i < count; i++)
        {
            if( i != _currentIndex )
            {
                FGalleryPhoto *photo = [_photoLoaders objectForKey:[keys objectAtIndex:i]];
                [photo unloadFullsize];
                [photo unloadThumbnail];
                
                // unload main image thumb
                FGalleryPhotoView *photoView = [_photoViews objectAtIndex:i];
                photoView.imageView.image = nil;
                
                // unload thumb tile
                photoView = [_photoThumbnailViews objectAtIndex:i];
                photoView.imageView.image = nil;
            }
        }
    }
}


- (void)dealloc {
	
	// remove KVO listener
	[_container removeObserver:self forKeyPath:@"frame"];
	
	// Cancel all photo loaders in progress
	NSArray *keys = [_photoLoaders allKeys];
	NSUInteger i, count = [keys count];
	for (i = 0; i < count; i++) {
		FGalleryPhoto *photo = [_photoLoaders objectForKey:[keys objectAtIndex:i]];
		photo.delegate = nil;
		[photo unloadThumbnail];
		[photo unloadFullsize];
	}
	
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	
	self.galleryID = nil;
	
	_photoSource = nil;
		
    _container = nil;
	
    _innerContainer = nil;
		
    _thumbsView = nil;
	
    _scroller = nil;
	
	[_photoLoaders removeAllObjects];
    _photoLoaders = nil;
		
	[_photoThumbnailViews removeAllObjects];
    _photoThumbnailViews = nil;
	
	[_photoViews removeAllObjects];
    _photoViews = nil;
		
}


@end


/**
 *	This section overrides the auto-rotate methods for UINaviationController and UITabBarController 
 *	to allow the tab bar to rotate only when a FGalleryController is the visible controller. Sweet.
 */

@implementation UINavigationController (FGallery)

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	if([self.visibleViewController isKindOfClass:[FGalleryViewController class]]) 
	{
        return YES;
	}

	// To preserve the UINavigationController's defined behavior,
	// walk its stack.  If all of the view controllers in the stack
	// agree they can rotate to the given orientation, then allow it.
	BOOL supported = YES;
	for(UIViewController *sub in self.viewControllers)
	{
		if(![sub shouldAutorotateToInterfaceOrientation:interfaceOrientation])
		{
			supported = NO;
			break;
		}
	}	
	if(supported)
		return YES;
	
	// we need to support at least one type of auto-rotation we'll get warnings.
	// so, we'll just support the basic portrait.
	return ( interfaceOrientation == UIInterfaceOrientationPortrait ) ? YES : NO;
}


- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	// see if the current controller in the stack is a gallery
	if([self.visibleViewController isKindOfClass:[FGalleryViewController class]])
	{
		FGalleryViewController *galleryController = (FGalleryViewController*)self.visibleViewController;
		[galleryController resetImageViewZoomLevels];
	}
}

@end




@implementation UITabBarController (FGallery)


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // only return yes if we're looking at the gallery
    if( [self.selectedViewController isKindOfClass:[UINavigationController class]])
    {
        UINavigationController *navController = (UINavigationController*)self.selectedViewController;
        
        // see if the current controller in the stack is a gallery
        if([navController.visibleViewController isKindOfClass:[FGalleryViewController class]])
        {
            return YES;
        }
    }
	
	// we need to support at least one type of auto-rotation we'll get warnings.
	// so, we'll just support the basic portrait.
	return ( interfaceOrientation == UIInterfaceOrientationPortrait ) ? YES : NO;
}


- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	if([self.selectedViewController isKindOfClass:[UINavigationController class]])
	{
		UINavigationController *navController = (UINavigationController*)self.selectedViewController;
		
		// see if the current controller in the stack is a gallery
		if([navController.visibleViewController isKindOfClass:[FGalleryViewController class]])
		{
			FGalleryViewController *galleryController = (FGalleryViewController*)navController.visibleViewController;
			[galleryController resetImageViewZoomLevels];
		}
	}
}


@end



