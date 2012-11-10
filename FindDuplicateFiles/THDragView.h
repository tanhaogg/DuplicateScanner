//
//  THDragView.h
//  DragHash
//
//  Created by Hao Tan on 12-3-26.
//  Copyright (c) 2012年 http://www.tanhao.me. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol THDragViewDelegate;
@interface THDragView : NSView
{
    __unsafe_unretained id<THDragViewDelegate> _delegate;
}
@property (nonatomic, unsafe_unretained) IBOutlet id<THDragViewDelegate> delegate;

@end


@protocol THDragViewDelegate <NSObject>

- (void)dragFileEnter:(NSString *)filePath;

@end