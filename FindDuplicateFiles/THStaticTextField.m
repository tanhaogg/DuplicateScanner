//
//  THStaticTextFiled.m
//  DesktopActivity
//
//  Created by TanHao on 12-9-29.
//  Copyright (c) 2012年 tanhao.me. All rights reserved.
//

#import "THStaticTextField.h"

@implementation THStaticTextField

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self setBackgroundColor:[NSColor clearColor]];
        [self setBordered:NO];
        [self setEditable:NO];
        [self setSelectable:NO];
    }
    
    return self;
}

@end
