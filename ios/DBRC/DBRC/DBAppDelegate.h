//
//  DBAppDelegate.h
//  DBRC
//
//  Created by luedeman on 1/6/13.
//  Copyright (c) 2013 Dropbox. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GalleryDelegate.h"

@interface DBAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, retain) GalleryDelegate *photoSource;

@end
