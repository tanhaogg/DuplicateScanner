//
//  THConditionPredicateEditorRowTemplate.m
//  Test
//
//  Created by TanHao on 12-11-13.
//  Copyright (c) 2012年 tanhao.me. All rights reserved.
//

#import "THConditionPredicateEditorRowTemplate.h"

@implementation THConditionPredicateEditorRowTemplate

+ (id)defaultTemplate
{
    NSArray *leftExpressions = [NSArray arrayWithObjects:[NSExpression expressionForKeyPath:@"condition"], nil];
    NSArray *operators = [NSArray arrayWithObjects:
                          [NSNumber numberWithInteger:NSEqualToPredicateOperatorType],nil];
    NSAttributeType rightType = NSInteger16AttributeType;
    NSComparisonPredicateModifier modifier = NSAllPredicateModifier;
    
    THConditionPredicateEditorRowTemplate *sizeTemplate =
    [[THConditionPredicateEditorRowTemplate alloc] initWithLeftExpressions:leftExpressions
                                         rightExpressionAttributeType:rightType
                                                             modifier:modifier
                                                            operators:operators
                                                              options:0];
    return sizeTemplate;

}

- (NSArray *)templateViews
{
    if (!conditionButton)
    {
        conditionButton = [[NSPopUpButton alloc] init];
        [conditionButton addItemsWithTitles:[NSArray arrayWithObjects:THLocaleString(@"YES"), THLocaleString(@"NO"), nil]];
    }
    NSArray *currentViews = [super templateViews];
    NSMutableArray *resultViews = [currentViews mutableCopy];
    
    for (NSView *aView in currentViews)
    {
        if ([aView isKindOfClass:[NSTextField class]])
        {
            if ([(NSTextField *)aView isEditable])
            {
                [resultViews removeObject:aView];
            }
        }
    }
    
    if (![currentViews containsObject:conditionButton])
    {
        [resultViews addObject:conditionButton];
    }
    return resultViews;
}

- (BOOL)boolValue
{
    NSArray *views = [self templateViews];
    NSInteger rightIdx = [[views objectAtIndex:2] indexOfSelectedItem];
    if (rightIdx == 0)
    {
        return YES;
    }
    return NO;
}

- (NSPredicate *)predicateWithSubpredicates:(NSArray *)subpredicates
{
    NSArray *views = [self templateViews];
    
    NSInteger leftIdx = [[views objectAtIndex:0] indexOfSelectedItem];
    NSExpression *leftExpression = [self.leftExpressions objectAtIndex:leftIdx];
    
    NSInteger rightIdx = [[views objectAtIndex:2] indexOfSelectedItem];
    NSExpression *rightExpression = [NSExpression expressionForConstantValue:[NSNumber numberWithBool:NO]];;
    NSPredicateOperatorType operatorType = NSEqualToPredicateOperatorType;
    if (rightIdx == 0)
    {
        operatorType = NSNotEqualToPredicateOperatorType;
    }
    
    NSPredicate *newPredicate = [NSComparisonPredicate predicateWithLeftExpression:leftExpression
                                                                   rightExpression:rightExpression
                                                                          modifier:NSDirectPredicateModifier
                                                                              type:operatorType
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
