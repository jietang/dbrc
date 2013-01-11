//
//  DBScreenSwitch.h
//  DBRC
//
//  Created by luedeman on 1/10/13.
//  Copyright (c) 2013 Dropbox. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DBScreenSwitch : UISwitch

- (id)initWithFrame:(CGRect)frame andScreenInfo:(NSDictionary *)screenInfo;

@property (nonatomic, retain) NSDictionary *screenInfo;

@end
