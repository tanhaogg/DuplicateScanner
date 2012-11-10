//
//  THDragView.m
//  DragHash
//
//  Created by Hao Tan on 12-3-26.
//  Copyright (c) 2012年 http://www.tanhao.me. All rights reserved.
//

#import "THDragView.h"

@implementation THDragView
@synthesize delegate;

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
}

- (void)awakeFromNib
{
    NSArray *dragArray = [NSArray arrayWithObjects:NSFilenamesPboardType, nil];
    [self registerForDraggedTypes:dragArray];
}

- (NSDragOperation)draggingEntered:(id < NSDraggingInfo >)sender
{
    return NSDragOperationCopy;
}

- (BOOL)performDragOperation:(id < NSDraggingInfo >)sender 
{
    NSArray *draggedFilenames = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
    if ([draggedFilenames count] > 0)
    {
        NSString *filePath = nil;
        for (NSString *draggedFileName in draggedFilenames)
        {
            BOOL isDir;
            if ([[NSFileManager defaultManager] fileExistsAtPath:draggedFileName isDirectory:&isDir])
            {
                filePath = [draggedFileName copy];
                break;
            }
        }
        
        if (filePath && [self.delegate respondsToSelector:@selector(dragFileEnter:)])
        {
            [self.delegate dragFileEnter:filePath];
            return YES;
        }
    }
    return NO;
}

@end
