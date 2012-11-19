//
//  THShadowField.m
//  FindDuplicateFiles
//
//  Created by TanHao on 12-11-18.
//  Copyright (c) 2012年 tanhao.me. All rights reserved.
//

#import "THShadowField.h"

@implementation THShadowField

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)awakeFromNib
{
    [self setWantsLayer:YES];
    NSShadow *shadow = [[NSShadow alloc] init];
    [shadow setShadowBlurRadius:1.0];
    [shadow setShadowColor:[NSColor whiteColor]];
    [shadow setShadowOffset:NSMakeSize(1, 1)];
    [self setShadow:shadow];
}

@end
