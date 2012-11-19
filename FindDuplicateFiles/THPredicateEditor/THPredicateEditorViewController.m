//
//  THPredicateEditorViewController.m
//  Test
//
//  Created by TanHao on 12-11-13.
//  Copyright (c) 2012年 tanhao.me. All rights reserved.
//

#import "THPredicateEditorViewController.h"
#import "THSizePredicateEditorRowTemplate.h"
#import "THConditionPredicateEditorRowTemplate.h"
#import "THBarView.h"

@interface THPredicateEditorViewController ()

@end

@implementation THPredicateEditorViewController

- (id)init
{
    self = [super initWithNibName:@"THPredicateEditorViewController" bundle:[NSBundle bundleForClass:self.class]];
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [barView setTitle:@"Filter Condition"];
    
    /*
    THSizePredicateEditorRowTemplate *sizeTemplate = [THSizePredicateEditorRowTemplate defaultTemplate];
    THConditionPredicateEditorRowTemplate *conditionTemplate = [THConditionPredicateEditorRowTemplate defaultTemplate];
    NSArray *templates = [predicateEditor.rowTemplates arrayByAddingObject:sizeTemplate];
    templates = [templates arrayByAddingObject:conditionTemplate];
    [predicateEditor setRowTemplates:templates];
     */
    
    [predicateEditor setNestingMode:NSRuleEditorNestingModeCompound];
    [predicateEditor setCanRemoveAllRows:NO];
    [predicateEditor insertRowAtIndex:0 withType:NSRuleEditorRowTypeCompound asSubrowOfRow:-1 animate:NO];
    [predicateEditor insertRowAtIndex:1 withType:NSRuleEditorRowTypeSimple asSubrowOfRow:0 animate:NO];
    [predicateEditor insertRowAtIndex:2 withType:NSRuleEditorRowTypeSimple asSubrowOfRow:0 animate:NO];
    [predicateEditor insertRowAtIndex:3 withType:NSRuleEditorRowTypeSimple asSubrowOfRow:0 animate:NO];
}

- (uint64)minSize
{
    return minSize;
}

- (uint64)maxSize
{
    return maxSize;
}

- (BOOL)scanPackage
{
    return scanPackage;
}

- (NSPredicate *)extensionPredicate
{
    return suffixPredicate;
}

- (void)reload
{
    suffixPredicate = nil;
    scanPackage = NO;
    minSize = 0;
    maxSize = 0;
    
    static void(^searchPredicate)(NSPredicate*);
    searchPredicate = ^(NSPredicate*predicate){
        if ([predicate isKindOfClass:[NSCompoundPredicate class]])
        {
            NSArray *predicateArray = [(NSCompoundPredicate*)predicate subpredicates];
            for (NSPredicate *aPredicate in predicateArray)
            {
                searchPredicate(aPredicate);
            }
        }
        
        if ([predicate isKindOfClass:[NSComparisonPredicate class]])
        {
            NSExpression *leftEx = [(NSComparisonPredicate *)predicate leftExpression];
            NSExpression *rightEx = [(NSComparisonPredicate *)predicate rightExpression];
            NSPredicateOperatorType oprator = [(NSComparisonPredicate *)predicate predicateOperatorType];
            
            if ([[leftEx keyPath] isEqualToString:@"suffix"])
            {
                NSComparisonPredicateOptions options = [(NSComparisonPredicate *)predicate options];
                suffixPredicate =
                [NSComparisonPredicate predicateWithLeftExpression:[NSExpression expressionWithFormat:@"SELF"]
                                                   rightExpression:rightEx
                                                          modifier:NSDirectPredicateModifier
                                                              type:oprator
                                                           options:options];
            }
            
            if ([[leftEx keyPath] isEqualToString:@"size"])
            {
                uint64 sizeValue = (uint64)[[rightEx constantValue] longLongValue];
                
                if (oprator == NSLessThanPredicateOperatorType)
                {
                    minSize = minSize==0?sizeValue:MAX(minSize,sizeValue);
                }
                
                if (oprator == NSGreaterThanPredicateOperatorType)
                {
                    maxSize = maxSize==0?sizeValue:MIN(maxSize,sizeValue);
                }
            }
            
            if ([[leftEx keyPath] isEqualToString:@"package"])
            {
                if (oprator == NSEqualToPredicateOperatorType)
                {
                    scanPackage = NO;
                }
                
                if (oprator == NSNotEqualToPredicateOperatorType)
                {
                    scanPackage = YES;
                }
            }
        }
    };
    
    NSPredicate *predicate = [predicateEditor predicate];
    searchPredicate(predicate);
    
    /*
    NSLog(@"suffixPredicate:%@",suffixPredicate);
    NSLog(@"minSize:%lld",minSize);
    NSLog(@"maxSize:%lld",maxSize);
    NSLog(@"scanPackage:%d",scanPackage);
    */
     
    /*
    NSDictionary *textInfo = @{@"size" : @(10000),@"package":@(NO)};
    NSDictionary *info2 = @{@"size" : @(100),@"package":@(2)};
    NSArray *textArray = @[textInfo,info2];
    
    NSLog(@"%@",predicate);
    NSLog(@"%d",[predicate evaluateWithObject:textInfo]);
    NSLog(@"%@",[textArray filteredArrayUsingPredicate:predicate]);
    
    NSLog(@"%@",[(NSCompoundPredicate *)predicate subpredicates]);
     */
}

@end
