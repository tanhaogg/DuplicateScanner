//
//  NSArray+NSArray_remove.h
//  FindDuplicateFiles
//
//  Created by TanHao on 12-11-14.
//  Copyright (c) 2012年 tanhao.me. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (Remove)
- (NSArray*)arrayByRemoveObject:(id)obj;
- (NSArray*)arrayByRemoveObjectsFromArray:(NSArray *)array;
@end
