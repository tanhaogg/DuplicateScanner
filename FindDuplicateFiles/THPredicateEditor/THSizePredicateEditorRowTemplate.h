//
//  THSizePredicateEditorRowTemplate.h
//  Test
//
//  Created by TanHao on 12-11-13.
//  Copyright (c) 2012年 tanhao.me. All rights reserved.
//

#import <Cocoa/Cocoa.h>

enum
{
    THSizeUndefineOperatorType,
    THSizeLessThanOperatorType,
    THSizeGreaterThanOperatorType
};
typedef NSInteger THSizeOperatorType;

@interface THSizePredicateEditorRowTemplate : NSPredicateEditorRowTemplate
{
    NSPopUpButton *sizeButton;
    BOOL once;
}

+ (id)defaultTemplate;

- (THSizeOperatorType)operatorType;
- (uint64)size;

@end
