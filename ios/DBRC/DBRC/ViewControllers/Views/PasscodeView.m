//
//  PasscodeView.m
//  Dropbox
//
//  Created by Will Stockwell on 3/5/10.
//  Copyright 2010 Dropbox, Inc. All rights reserved.
//

#import "PasscodeView.h"

#import "FileIcons.h"

@implementation PasscodeView

@synthesize filledCellCount;

- (id)initWithFrame:(CGRect)aRect
{
	if ((self = [super initWithFrame: aRect])) {
		filledCellCount = 0;
		[self setNeedsLayout];
	}
	return self;
}

-(void)dealloc
{
	for (int i = 0; i < kNumCells; i++) {
		[cell[i] release];
		cell[i] = nil;
	}
	[super dealloc];
}

-(void)layoutSubviews
{
	UIImage *emptyImage = [FileIcons iconByName: @"pin_cell_empty"];
	CGFloat centeringOffset = (self.frame.size.width - emptyImage.size.width*kNumCells - 10*(kNumCells-1)) / 2;
	for (int i = 0; i < kNumCells; i++) {
		if (cell[i] == nil)
			cell[i] = [[UIImageView alloc] initWithImage: emptyImage];
		if (cell[i].superview != self)
			[self addSubview: cell[i]];
		cell[i].frame = CGRectMake(centeringOffset + i * (emptyImage.size.width + 10), 0, emptyImage.size.width, emptyImage.size.height);
	}
}

-(void)setFilledCellCount:(NSUInteger)aFilledCellCount
{
	if (filledCellCount == aFilledCellCount)
		return;

	filledCellCount = aFilledCellCount;
	for (int i = 0; i < kNumCells; i++)
		cell[i].image = [FileIcons iconByName: (i < filledCellCount) ? @"pin_cell_full" : @"pin_cell_empty"];
	[self setNeedsDisplay];
}

@end
