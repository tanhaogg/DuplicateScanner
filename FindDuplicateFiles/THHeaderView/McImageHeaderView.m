//
//  McImageHeaderView.m
//  McUICommon
//
//  Created by tanhao on 12-4-24.
//  Copyright (c) 2012  Magican Software Ltd. All rights reserved.
//

#import "McImageHeaderView.h"

@implementation McImageHeaderView

- (id)initWithImage:(NSImage *)image
{
    self = [super init];
    if (self)
    {
        NSImageView *imageView = [[NSImageView alloc] initWithFrame:self.bounds];
        [imageView setImageFrameStyle:NSImageFrameNone];
        [imageView setImageScaling:NSScaleProportionally];
        [imageView setImageAlignment:NSImageAlignCenter];
        [imageView setImage:image];
        [self addSubview:imageView];
    }
    return self;
}

@end
