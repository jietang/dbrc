//
//  GalleryDelegate.m
//  TestImageView
//
//  Created by Jie Tang on 1/10/13.
//  Copyright (c) 2013 Jie Tang. All rights reserved.
//

#import "GalleryDelegate.h"

@interface GalleryDelegate ()

@end

@implementation GalleryDelegate

- (id)init {
    if (self = [super init]) {
        // Custom initialization
        networkImages = [[NSArray alloc] init];
    }
    return self;
}

- (void)processPhotos:(NSArray*)photos {
    // iterate over photos, pull out the urls...
    NSMutableArray *tmp = [[NSMutableArray alloc] init];
    for(id object in photos) {
        DBMetadata* data = object;
        [tmp addObject:data.path];
    }
    networkImages = [tmp sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    NSSortDescriptor* sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:nil ascending:NO selector:@selector(localizedCaseInsensitiveCompare:)];
    networkImages = [tmp sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
}

- (int)numberOfPhotosForPhotoGallery:(FGalleryViewController*)gallery {
    return [networkImages count];
}
- (FGalleryPhotoSourceType)photoGallery:(FGalleryViewController*)gallery sourceTypeForPhotoAtIndex:(NSUInteger)index {
    return FGalleryPhotoSourceTypeNetwork;
}

// the photosource must implement one of these methods depending on which FGalleryPhotoSourceType is specified
- (NSString*)photoGallery:(FGalleryViewController*)gallery urlForPhotoSize:(FGalleryPhotoSize)size atIndex:(NSUInteger)index {
    return [networkImages objectAtIndex:index];
}

- (void)handleTrashButtonTouch:(id)sender {
    // here we could remove images from our local array storage and tell the gallery to remove that image
    // ex:
    //[localGallery removeImageAtIndex:[localGallery currentIndex]];
}


- (void)handleEditCaptionButtonTouch:(id)sender {
    // here we could implement some code to change the caption for a stored image
}
@end
