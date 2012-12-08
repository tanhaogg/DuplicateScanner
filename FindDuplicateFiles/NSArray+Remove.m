//
//  NSArray+NSArray_remove.m
//  FindDuplicateFiles
//
//  Created by TanHao on 12-11-14.
//  Copyright (c) 2012年 tanhao.me. All rights reserved.
//

#import "NSArray+Remove.h"

@implementation NSArray (Remove)

- (NSArray*)arrayByRemoveObject:(id)obj
{
    if (!obj || ![self containsObject:obj])
    {
        return [self copy];
    }
    
    NSMutableArray *tempArray = [self mutableCopy];
    [tempArray removeObject:obj];
    NSArray *array = [[NSArray alloc] initWithArray:tempArray];
    return array;
}

- (NSArray*)arrayByRemoveObjectsFromArray:(NSArray *)array
{
    if ([array count] == 0)
    {
        return [self copy];
    }
    
    NSArray *resultArray = self;
    for (id obj in array)
    {
        resultArray = [resultArray arrayByRemoveObject:obj];
    }
    return resultArray;
}

@end
