//
//  THStringPredicateEditorRowTemplate.m
//  FindDuplicateFiles
//
//  Created by TanHao on 12-11-14.
//  Copyright (c) 2012年 tanhao.me. All rights reserved.
//

#import "THStringPredicateEditorRowTemplate.h"

@implementation THStringPredicateEditorRowTemplate

- (NSArray *)templateViews
{
    NSArray *views = [super templateViews];
    if (!once)
    {
        once = YES;
        for (NSView *aView in views)
        {
            if ([aView isKindOfClass:[NSTextField class]]
                && [(NSTextField *)aView isEditable])
            {
                [(NSTextField *)aView setStringValue:@"JPG"];
            }
        }
    }
    return views;
}

@end
