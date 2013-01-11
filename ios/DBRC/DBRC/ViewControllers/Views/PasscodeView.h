//
//  PasscodeView.h
//  Dropbox
//
//  Created by Will Stockwell on 3/5/10.
//  Copyright 2010 Dropbox, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kNumCells 4

@interface PasscodeView : UIView {
	NSUInteger filledCellCount;
	UIImageView *cell[kNumCells];
}

@property (nonatomic, setter=setFilledCellCount:) NSUInteger filledCellCount;

@end
