//
//  THLock.h
//  FindDuplicateFiles
//
//  Created by TanHao on 12-11-14.
//  Copyright (c) 2012年 tanhao.me. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface THLock : NSObject

+ (void)lockForKey:(id)key;
+ (void)unLockForKey:(id)key;

@end
