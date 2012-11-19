//
//  THBarView.m
//  FindDuplicateFiles
//
//  Created by TanHao on 12-11-18.
//  Copyright (c) 2012年 tanhao.me. All rights reserved.
//

#import "THBarView.h"

@implementation THBarView
@synthesize title;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
    // 渐变
    NSArray * colors = [NSArray arrayWithObjects:
                        [NSColor colorWithDeviceRed:0.8627 green:0.8627 blue:0.8627 alpha:1.0],
                        [NSColor colorWithDeviceRed:0.7059 green:0.7059 blue:0.7059 alpha:1.0], nil];
    NSGradient * gradient = [[NSGradient alloc] initWithColors:colors];
    [gradient drawInRect:NSInsetRect(self.bounds, 0, 0) angle:270];
    
    //边框
    /*
    [[NSColor colorWithDeviceRed:114/255.0 green:120.0/255.0 blue:132.0/255.0 alpha:1.0] setStroke];
    NSBezierPath * border = [NSBezierPath bezierPathWithRect:NSInsetRect(self.bounds, 1, 1)];
    [border setLineWidth:1.0];
    [border stroke];
     */
    
    //画文字
    NSColor * textColor = [NSColor colorWithDeviceRed:90/255.0 green:90/255.0 blue:90/255.0 alpha:1.0];
    NSDictionary *textAtt = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSFont boldSystemFontOfSize:12], NSFontAttributeName,
                             textColor, NSForegroundColorAttributeName, nil];
    
    NSSize textsize = [title sizeWithAttributes:textAtt];
    
    NSRect textRect = NSMakeRect((NSWidth(self.bounds)-textsize.width)*0.5,
                                 (NSHeight(self.bounds)-textsize.height)*0.5,
                                 textsize.width,
                                 textsize.height);
    
    [title drawInRect:textRect withAttributes:textAtt];
    
    NSBezierPath * lastLine = [NSBezierPath bezierPath];
    [lastLine moveToPoint:NSZeroPoint];
    [lastLine lineToPoint:NSMakePoint(NSMaxX(self.bounds), 0)];
    [[NSColor darkGrayColor] setStroke];
    [lastLine setLineWidth:2.0];
    [lastLine stroke];
}

@end
