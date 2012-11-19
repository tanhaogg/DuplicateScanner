//
//  THLock.m
//  FindDuplicateFiles
//
//  Created by TanHao on 12-11-14.
//  Copyright (c) 2012年 tanhao.me. All rights reserved.
//

#import "THLock.h"

@implementation THLock

static NSMutableDictionary *lockList = nil;

+ (void)lockCreate
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        lockList = [[NSMutableDictionary alloc] init];
    });
}

+ (void)lockForKey:(id)key
{
    if (!lockList)
    {
        [self lockCreate];
    }
    
    NSLock *lock = NULL;
    @synchronized(lockList){
        lock = [lockList objectForKey:key];
        if (!lock)
        {
            lock = [[NSLock alloc] init];
            [lockList setObject:lock forKey:key];
        }
    }
    [lock lock];
}

+ (void)unLockForKey:(id)key
{    
    NSLock *lock  = NULL;
    @synchronized(lockList){
        lock = [lockList objectForKey:key];
    }
    
    [lock unlock];
    @synchronized(lockList){
        if ([lock tryLock]){
            [lockList removeObjectForKey:key];
            [lock unlock];
        }
    }
}

@end
