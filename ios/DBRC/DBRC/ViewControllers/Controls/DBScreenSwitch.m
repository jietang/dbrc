//
//  DBScreenSwitch.m
//  DBRC
//
//  Created by luedeman on 1/10/13.
//  Copyright (c) 2013 Dropbox. All rights reserved.
//

#import "DBScreenSwitch.h"

@implementation DBScreenSwitch

- (id)initWithFrame:(CGRect)frame andScreenInfo:(NSDictionary *)screenInfo
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.screenInfo = screenInfo;
    }
    return self;
}


@end
