//
//  McHeaderView.h
//  McUICommon
//
//  Created by tanhao on 12-4-24.
//  Copyright (c) 2012  Magican Software Ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>


enum
{
    kMcHeaderLevelDefault, //level is hightest
    kMcHeaderLevelConfirm,
    kMcHeaderLevelWeather,
    kMcHeaderLevelLogo,
};
typedef NSInteger McHeaderLevel;

enum
{
    kMcHeaderRepeatForever,
    kMcHeaderRepeatOnces
};
typedef NSInteger McHeaderRepeat;

#define kMcHeaderViewFrame  NSMakeRect(0, 0, 240, 32)
#define kMcHeaderDurationDefault 5
#define kMcHeaderDurationForever 100000000

@interface McHeaderView : NSView
{
    BOOL setUp;
}

@property (assign) McHeaderLevel level;
@property (assign) McHeaderRepeat repeat;
@property (assign) double duration;

- (void)dismiss;

@end