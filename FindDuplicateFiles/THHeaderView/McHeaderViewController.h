//
//  McHeaderViewController.h
//  MagicanCastle
//
//  Created by tanhao on 12-4-18.
//  Copyright (c) 2012  Magican Software Ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "McHeaderView.h"
#import "McImageHeaderView.h"

@class McLocatedConfirmHeaderView;
@interface McHeaderViewController : NSViewController
{
    NSTimer *timer;
    NSViewAnimation *showAnimation;
    NSMutableArray *viewArray;
    McHeaderView *logoHeader;
}

@property (strong,readonly) McHeaderView *currentHeaderView;

+ (McHeaderViewController *)sharedController;

- (void)addHeaderView:(McHeaderView *)headerView immediately:(BOOL)immediately;
- (void)removeHeaderView:(McHeaderView *)headerView immediately:(BOOL)immediately;

@end
