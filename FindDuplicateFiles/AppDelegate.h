//
//  AppDelegate.h
//  FindDuplicateFiles
//
//  Created by TanHao on 12-11-2.
//  Copyright (c) 2012年 tanhao.me. All rights reserved.
//

#import <Cocoa/Cocoa.h>

enum
{
    THDuplicationSortDefault = -1,
    THDuplicationSortSize,
    THDuplicationSortCount,
    THDuplicationSortType
};
typedef NSInteger THDuplicationSort;

@class McHeaderViewController;
@class McHeaderView;
@class THPredicateEditorViewController;
@class THPathSelectedViewController;
@class THDuplicationHelper;
@class PXListView;
@interface AppDelegate : NSObject <NSApplicationDelegate,NSSplitViewDelegate>
{
    THDuplicationHelper *helper;
    NSMutableArray *showLists;
    NSMutableArray *results;
    NSMutableDictionary *resultDictionary;
    NSMutableDictionary *tempResultDictionary;
    NSTimeInterval notificationInterval;
    
    NSString *filterString;
    THDuplicationSort sortKind;
    
    IBOutlet NSButton *startButton;
    IBOutlet NSButton *stopButton;
    
    IBOutlet NSView *barView;
    IBOutlet NSView *headerDocumentView;
    IBOutlet McHeaderView *showHeaderView;
    IBOutlet PXListView *resultView;
    IBOutlet NSView *filterDocumentView;
    IBOutlet NSView *pathDocumentView;
    IBOutlet NSProgressIndicator *loadingView;
    IBOutlet NSTextField *showResultView;
    
    McHeaderViewController *headerVC;
    THPathSelectedViewController *pathVC;
    THPredicateEditorViewController *predicateVC;
}

@property (assign) IBOutlet NSWindow *window;
- (IBAction)start:(id)sender;
- (IBAction)stop:(id)sender;
- (IBAction)searchClick:(id)sender;
- (IBAction)sortClick:(id)sender;

@end
