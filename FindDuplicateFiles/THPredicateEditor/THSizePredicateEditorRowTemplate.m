//
//  THSizePredicateEditorRowTemplate.m
//  Test
//
//  Created by TanHao on 12-11-13.
//  Copyright (c) 2012年 tanhao.me. All rights reserved.
//

#import "THSizePredicateEditorRowTemplate.h"

@implementation THSizePredicateEditorRowTemplate

+ (id)defaultTemplate
{
    NSArray *leftExpressions = [NSArray arrayWithObjects:[NSExpression expressionForKeyPath:@"size"], nil];
    NSArray *operators = [NSArray arrayWithObjects:
                          [NSNumber numberWithInteger:NSGreaterThanPredicateOperatorType],
                          [NSNumber numberWithInteger:NSLessThanPredicateOperatorType],nil];
    NSAttributeType rightType = NSInteger16AttributeType;
    NSComparisonPredicateModifier modifier = NSAllPredicateModifier;
    
    THSizePredicateEditorRowTemplate *sizeTemplate =
    [[THSizePredicateEditorRowTemplate alloc] initWithLeftExpressions:leftExpressions
                                         rightExpressionAttributeType:rightType
                                                             modifier:modifier
                                                            operators:operators
                                                              options:0];
    return sizeTemplate;
}

- (THSizeOperatorType)operatorType
{
    NSArray *views = [self templateViews];
    NSInteger opeatorIdx = [[views objectAtIndex:1] indexOfSelectedItem];
    NSPredicateOperatorType opeatorType = [[[self operators] objectAtIndex:opeatorIdx] intValue];
    if (opeatorType == NSLessThanPredicateOperatorType)
    {
        return THSizeLessThanOperatorType;
    }
    if (opeatorType == NSGreaterThanPredicateOperatorType)
    {
        return THSizeGreaterThanOperatorType;
    }
    return THSizeUndefineOperatorType;
}

- (uint64)size
{
    NSArray *views = [self templateViews];
    uint64 size = [[views objectAtIndex:2] intValue];
    NSInteger rightIdx = [[views objectAtIndex:3] indexOfSelectedItem];
    switch (rightIdx)
    {
        case 0:size*=1024;break;
        case 1:size*=1024*1024;break;
        case 2:size*=1024*1024*1024;break;
        default:break;
    }
    return size;
}

- (NSArray *)templateViews
{
    if (!sizeButton)
    {
        sizeButton = [[NSPopUpButton alloc] init];
        [sizeButton addItemsWithTitles:[NSArray arrayWithObjects:@"KB", @"MB", @"GB", nil]];
    }
    NSArray *currentViews = [super templateViews];
    if (!once)
    {
        once = YES;
        for (NSView *aView in currentViews)
        {
            if ([aView isKindOfClass:[NSTextField class]]
                && [(NSTextField *)aView isEditable])
            {
                [(NSTextField *)aView setStringValue:@"100"];
            }
        }
    }
    if (![currentViews containsObject:sizeButton])
    {
        return [currentViews arrayByAddingObject:sizeButton];
    }
    return currentViews;
}

- (NSPredicate *)predicateWithSubpredicates:(NSArray *)subpredicates
{
    NSArray *views = [self templateViews];
    
    NSInteger leftIdx = [[views objectAtIndex:0] indexOfSelectedItem];
    NSExpression *leftExpression = [self.leftExpressions objectAtIndex:leftIdx];
    
    NSInteger opeatorIdx = [[views objectAtIndex:1] indexOfSelectedItem];
    NSPredicateOperatorType opeatorType = [[[self operators] objectAtIndex:opeatorIdx] intValue];
    
    uint64 size = [[views objectAtIndex:2] intValue];
    NSInteger rightIdx = [[views objectAtIndex:3] indexOfSelectedItem];
    switch (rightIdx)
    {
        case 0:size*=1024;break;
        case 1:size*=1024*1024;break;
        case 2:size*=1024*1024*1024;break;
        default:break;
    }
    NSExpression *rightExpression = [NSExpression expressionForConstantValue:@(size)];
    
    NSPredicate *newPredicate = [NSComparisonPredicate predicateWithLeftExpression:leftExpression
                                                                   rightExpression:rightExpression
                                                                          modifier:NSDirectPredicateModifier
                                                                              type:opeatorType
                                                                           options:0];
    if (subpredicates)
    {
        subpredicates = [subpredicates arrayByAddingObject:newPredicate];
    }else
    {
        subpredicates = [NSArray arrayWithObject:newPredicate];
    }
    NSCompoundPredicate *compoundPredicate = [[NSCompoundPredicate alloc] initWithType:NSAndPredicateType
                                                                         subpredicates:subpredicates];
	return compoundPredicate;
}

@end
