//
//  THBackgroundView.m
//  FindDuplicateFiles
//
//  Created by TanHao on 12-11-13.
//  Copyright (c) 2012年 tanhao.me. All rights reserved.
//

#import "THBackgroundView.h"

@implementation THBackgroundView
@synthesize image;

- (NSImage *)image
{
    return image;
}

- (void)setImage:(NSImage *)value
{
    image = value;
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect
{
    if (!image)
    {
        return;
    }
    NSRect visibleRect = [self bounds];
    float width = image.size.width;
	float height = image.size.height;
    
    float top, right;
    
    for (top = 0; top<NSHeight(visibleRect); top+=height)
    {
        for (right=0; right<NSWidth(visibleRect); right+=width)
        {
            NSRect currentRect = NSMakeRect(right, top, width, height);
            if (NSIntersectsRect(currentRect, dirtyRect))
            {
                NSRect drawRect = NSIntersectionRect(currentRect, visibleRect);
                NSRect fromRect = NSMakeRect(0, 0, NSWidth(drawRect), NSHeight(drawRect));
                [image drawInRect:drawRect fromRect:fromRect operation:NSCompositeSourceOver fraction:1.0];
            }
        }
    }
}

@end
