//
//  THPredicateEditorViewController.h
//  Test
//
//  Created by TanHao on 12-11-13.
//  Copyright (c) 2012年 tanhao.me. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class THBarView;
@interface THPredicateEditorViewController : NSViewController
{
    IBOutlet THBarView *barView;
    IBOutlet NSPredicateEditor *predicateEditor;
    
    uint64 minSize;
    uint64 maxSize;
    BOOL scanPackage;
    NSPredicate *suffixPredicate;
}

- (uint64)minSize;
- (uint64)maxSize;
- (BOOL)scanPackage;
- (NSPredicate *)extensionPredicate;

- (void)reload;

@end
