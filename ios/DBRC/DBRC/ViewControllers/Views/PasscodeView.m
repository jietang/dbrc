//
//  PasscodeView.m
//  Dropbox
//
//  Created by Will Stockwell on 3/5/10.
//  Copyright 2010 Dropbox, Inc. All rights reserved.
//

#import "PasscodeView.h"


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


-(void)layoutSubviews
{
	UIImage *emptyImage = [UIImage imageNamed:@"pin_cell_empty.png"];
	CGFloat centeringOffset = (self.frame.size.width - emptyImage.size.width*kNumCells - 10*(kNumCells-1)) / 2;
	for (int i = 0; i < kNumCells; i++) {
		if (cell[i] == nil)
			cell[i] = [[UIImageView alloc] initWithImage: emptyImage];
		if (cell[i].superview != self)
			[self addSubview: cell[i]];
        
		if (cellChars[i] == nil) {
			cellChars[i] = [[UILabel alloc] initWithFrame:CGRectZero];
            cellChars[i].textAlignment = UITextAlignmentCenter;
            cellChars[i].backgroundColor = [UIColor clearColor];
            cellChars[i].text = @"";
        }
		if (cellChars[i].superview != self)
			[self addSubview: cellChars[i]];
        
		cell[i].frame = CGRectMake(centeringOffset + i * (emptyImage.size.width + 10), 0, emptyImage.size.width, emptyImage.size.height);
        cellChars[i].frame = CGRectMake(centeringOffset + i * (emptyImage.size.width + 10), 0, emptyImage.size.width, emptyImage.size.height);
	}
}

- (void)fillNextCellWithChar:(NSString *)character {
    cellChars[filledCellCount].text = character;
    filledCellCount += 1;
    [self setNeedsDisplay];
}

- (void)deleteCellChar {
    filledCellCount -= 1;
    cellChars[filledCellCount].text = @"";
    [self setNeedsDisplay];
}

-(void)setFilledCellCount:(NSUInteger)aFilledCellCount
{
	if (filledCellCount == aFilledCellCount)
		return;

	filledCellCount = aFilledCellCount;
	for (int i = 0; i < kNumCells; i++)
		cell[i].image = [UIImage imageNamed: (i < filledCellCount) ? @"pin_cell_full.png" : @"pin_cell_empty.png"];
	[self setNeedsDisplay];
}

- (NSInteger)getFilledCount {
    return filledCellCount;
}

- (NSString *)getPasscode {
    NSMutableString *code = [NSMutableString string];
    for (int i = 0; i < kNumCells; i++) {
        [code appendString:cellChars[i].text];
    }
    return code;
}

@end
