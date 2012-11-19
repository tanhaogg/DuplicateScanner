//
//  McHeaderView.m
//  McUICommon
//
//  Created by tanhao on 12-4-24.
//  Copyright (c) 2012  Magican Software Ltd. All rights reserved.
//

#import "McHeaderView.h"
#import "McHeaderViewController.h"

@implementation McHeaderView
@synthesize level;
@synthesize repeat;
@synthesize duration;


- (void)setUpDefault
{
    if (!setUp)
    {
        setUp = YES;
        
        self.level = kMcHeaderLevelDefault;
        self.repeat = kMcHeaderRepeatOnces;
        self.duration = kMcHeaderDurationDefault;
        
        NSImageView *bgView = [[NSImageView alloc] initWithFrame:self.bounds];
        [bgView setImageFrameStyle:NSImageFrameNone];
        [bgView setImageScaling:NSScaleToFit];
        [bgView setImageAlignment:NSImageAlignCenter];
        [bgView.cell setImageScaling:NSImageScaleAxesIndependently];
        NSString *imgPath = [kSelfBundle pathForImageResource:@"headerBg"];
        NSImage *img = [[NSImage alloc] initWithContentsOfFile:imgPath];
        [bgView setImage:img];
        [self addSubview:bgView positioned:NSWindowBelow relativeTo:nil];
    }
}

- (id)init
{
    self = [super initWithFrame:kMcHeaderViewFrame];
    if (self)
    {
        [self setUpDefault];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setUpDefault];
}

- (void)dismiss
{
    [[McHeaderViewController sharedController] removeHeaderView:self immediately:YES];
}

@end
