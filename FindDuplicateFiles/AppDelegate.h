//
//  AppDelegate.h
//  FindDuplicateFiles
//
//  Created by TanHao on 12-11-2.
//  Copyright (c) 2012年 tanhao.me. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class THDuplicationHelper;
@interface AppDelegate : NSObject <NSApplicationDelegate>
{
    THDuplicationHelper *helper;
    
    NSMutableDictionary *results;
    
    IBOutlet NSTextView *resultView;
    IBOutlet NSTextView *extenstionView;
    IBOutlet NSButton *filterPackageButton;
    IBOutlet NSTextField *sizeField;
}

@property (assign) IBOutlet NSWindow *window;
- (IBAction)click:(id)sender;
- (IBAction)stop:(id)sender;

@end
