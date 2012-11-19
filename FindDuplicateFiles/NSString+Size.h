//
//  NSString+Size.h
//  randomTest
//
//  Created by TanHao on 12-9-24.
//  Copyright (c) 2012年 tanhao.me. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString(Size)

+ (NSString *)stringWithSize:(uint64_t)size;
+ (NSString *)stringWithDiskSize:(uint64_t)size;

@end
