//
//  THFileUtility.h
//  FindDuplicateFiles
//
//  Created by TanHao on 12-11-2.
//  Copyright (c) 2012年 tanhao.me. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface THFileUtility : NSObject

+ (BOOL)fileIsRegular:(NSString *)filePath;
+ (BOOL)fileIsDirectory:(NSString *)filePath;
+ (uint64)fileSizeByPath:(NSString *)filePath;

@end
