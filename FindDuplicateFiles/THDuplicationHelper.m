//
//  THDuplicationHelper.m
//  FindDuplicateFiles
//
//  Created by TanHao on 12-11-5.
//  Copyright (c) 2012年 tanhao.me. All rights reserved.
//

#import "THDuplicationHelper.h"
#import "THWebDefine.h"
#import "THFileUtility.h"

#define kTHDuplictionConcurrentCount 5

NSString* const THDuplicationNotification = @"THDuplicationNotification";
NSString* const THDuplicationFileSize = @"THDuplicationFileSize";
NSString* const THDuplicationFileHash = @"THDuplicationFileHash";
NSString* const THDuplicationFileList = @"THDuplicationFileList";
NSString* const THDuplicationFinished = @"THDuplicationFinished";

@implementation THDuplicationHelper
@synthesize searchPaths;
@synthesize filterFilePaths;
@synthesize searchFileExtensions;
@synthesize filterFileExtensions;
@synthesize minFileSize;
@synthesize filterPackage;

@synthesize searching;

- (void)searchStart
{
    //判断文件的有效性
    static BOOL(^fileValid)(NSString*filePath);
    fileValid = ^(NSString *filePath){
        uint64 fileSize = [THFileUtility fileSizeByPath:filePath];
        if (fileSize < minFileSize)
        {
            return NO;
        }
        NSString *fileExtenstion = [[filePath pathExtension] lowercaseString];
        if (searchFileExtensions && ![searchFileExtensions containsObject:fileExtenstion])
        {
            return NO;
        }
        if (filterFileExtensions && [filterFileExtensions containsObject:fileExtenstion])
        {
            return NO;
        }
        return YES;
    };
    
    //判断目录的有效性
    static BOOL(^directoryValid)(NSString*filePath);
    directoryValid = ^(NSString *filePath){
        if (filterFilePaths)
        {
            for (NSString *filterPath in filterFilePaths)
            {
                if ([filePath hasPrefix:filterPath])
                {
                    return NO;
                }
            }
        }
        
        if (filterPackage && [[NSWorkspace sharedWorkspace] isFilePackageAtPath:filePath])
        {
            return NO;
        }
        return YES;
    };
    
    //返回目录的的子目录绝对路径
    static NSArray *(^directorySubPath)(NSString *filePath);
    directorySubPath = ^(NSString *filePath){
        
        NSMutableArray *subPaths = [NSMutableArray array];
        NSArray *subItems = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:filePath error:NULL];
        for (NSString *path in subItems)
        {
            if ([[path lastPathComponent] hasPrefix:@"."]
                ||[[path lastPathComponent] hasPrefix:@"__MACOSX"])
            {
                continue;
            }
            NSString *fullPath = [filePath stringByAppendingPathComponent:path];
            BOOL valid = directoryValid(fullPath);
            if (valid)
            {
                [subPaths addObject:fullPath];
            }
        }
        
        return [NSArray arrayWithArray:subPaths];
    };
    
    //处理扫描到的文件
    static void(^fileDispose)(NSString *filePath);
    fileDispose = ^(NSString *filePath){
        
        BOOL valid = fileValid(filePath);
        if (!valid)
        {
            return;
        }
        
        uint64 fileSize = [THFileUtility fileSizeByPath:filePath];
        if (fileSize < 1024*1024)
        {
            return;
        }
        
        //以文件大小为Key
        NSNumber *fileKey = [NSNumber numberWithUnsignedLongLong:fileSize];
        id exist = nil;
        
        @synchronized(fileInfo){
            exist = [fileInfo objectForKey:fileKey];
        }
        
        //还没有大小相同的，则记录下，并返回
        if (!exist)
        {
            @synchronized(fileInfo){
                [fileInfo setObject:filePath forKey:fileKey];
            }
            return;
        }
        
        //计算文件的hash值
        NSString *hashKey = [THWebUtility hashFile:filePath with:THHashKindMd5];
        if (!hashKey)
        {
            return;
        }
        
        //标识是否已经找到重复项
        BOOL duplication = NO;
        NSArray *fileList = nil;
        
        //二次判断(防止在hash过程中其它线程已经改变fileInfo结构)
        @synchronized(fileInfo){
            exist = [fileInfo objectForKey:fileKey];
        }
        
        //如果fileInfo中相同大小的为string，刚说明还没有计算过hash值
        if ([exist isKindOfClass:[NSString class]])
        {
            NSString *existFile = (NSString *)exist;
            NSString *existHashKey = [THWebUtility hashFile:existFile with:THHashKindMd5];
            if (!existHashKey)
            {
                //如果计算已存在文件的hash值失败，则覆盖，并退出
                NSMutableArray *list = [NSMutableArray arrayWithObject:filePath];
                NSDictionary *hashDic = [NSMutableDictionary dictionaryWithObject:list forKey:hashKey];
                
                @synchronized(fileInfo){
                    [fileInfo setObject:hashDic forKey:fileKey];
                }
                return;
            }
            
            //三次判断(防止在hash过程中其它线程已经改变fileInfo结构)
            @synchronized(fileInfo){
                exist = [fileInfo objectForKey:fileKey];
            }
            if ([exist isKindOfClass:[NSString class]])
            {
                NSMutableDictionary *hashDic = [NSMutableDictionary dictionaryWithCapacity:2];
                if ([existHashKey isEqualToString:hashKey])
                {
                    duplication = YES;
                    NSMutableArray *list = [NSMutableArray arrayWithObjects:filePath,exist, nil];
                    [hashDic setObject:list forKey:hashKey];
                    fileList = [list copy];
                }else
                {
                    NSMutableArray *list = [NSMutableArray arrayWithObject:filePath];
                    [hashDic setObject:list forKey:hashKey];
                    list = [NSMutableArray arrayWithObject:exist];
                    [hashDic setObject:list forKey:existHashKey];
                }
                
                @synchronized(fileInfo){
                    [fileInfo setObject:hashDic forKey:fileKey];
                }
            }
        }
        
        
        if ([exist isKindOfClass:[NSMutableDictionary class]])
        {
            NSMutableDictionary *hashDic = (NSMutableDictionary *)exist;
            NSMutableArray *list = [hashDic objectForKey:hashKey];
            if (list)
            {
                duplication = YES;
                @synchronized(list){
                    [list addObject:filePath];
                }
                fileList = [list copy];
            }else
            {
                list = [NSMutableArray arrayWithObject:filePath];
                @synchronized(hashDic){
                    [hashDic setObject:list forKey:hashKey];
                }
            }
        }
        
        if (duplication)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self postNotificationSize:fileKey hash:hashKey fileList:fileList];
            });
        }
    };
    
    
    //目录扫描
    static void(^searth)(NSString *filePath);
    searth = ^(NSString *filePath){
        NSArray *subPaths = directorySubPath(filePath);
        NSMutableArray *searchSubPaths = [NSMutableArray arrayWithArray:subPaths];
        while ([searchSubPaths count] > 0)
        {
            if (isStop)
            {
                break;
            }
            
            @autoreleasepool {
                NSString *fullPath = [searchSubPaths objectAtIndex:0];
                
                if ([THFileUtility fileIsDirectory:fullPath])
                {
                    [searchSubPaths addObjectsFromArray:directorySubPath(fullPath)];
                }
                else if ([THFileUtility fileIsRegular:fullPath])
                {
                    dispatch_semaphore_wait(semaphoreB, DISPATCH_TIME_FOREVER);
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        @autoreleasepool {
                            fileDispose(fullPath);
                        }
                        dispatch_semaphore_signal(semaphoreB);
                    });
                }
                
                [searchSubPaths removeObjectAtIndex:0];
            }
        }
    };
    
    //开始检索
    searching = YES;
    isStop = NO;
    
    //去除重复、包含的扫描路径
    NSMutableArray *validSearchPaths = [NSMutableArray array];
    for (NSString *searchPathA in searchPaths)
    {
        NSString *validPath = searchPathA;
        for (NSString *searchPathB in searchPaths)
        {
            if (searchPathB != validPath &&
                [[validPath stringByResolvingSymlinksInPath] hasPrefix:[searchPathB stringByResolvingSymlinksInPath]])
            {
                validPath = searchPathB;
            }
        }
        
        if (![validSearchPaths containsObject:validPath])
        {
            [validSearchPaths addObject:validPath];
        }
    }
    
    for (NSString *searchPath in validSearchPaths)
    {
        searth(searchPath);
    }
    
    //等待所有线程结束
    int waitTread = kTHDuplictionConcurrentCount;
    while (waitTread > 0)
    {
        waitTread--;
        dispatch_semaphore_wait(semaphoreA, DISPATCH_TIME_FOREVER);
        dispatch_semaphore_wait(semaphoreB, DISPATCH_TIME_FOREVER);
    }
    
    //让semaphore恢复初使状态
    while (waitTread < kTHDuplictionConcurrentCount)
    {
        waitTread ++;
        dispatch_semaphore_signal(semaphoreA);
        dispatch_semaphore_signal(semaphoreB);
    }
    
    searching = NO;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self postNotificationSize:nil hash:nil fileList:nil];
    });
}

- (id)init
{
    self = [super init];
    if (self)
    {
        semaphoreA = dispatch_semaphore_create(kTHDuplictionConcurrentCount);
        semaphoreB = dispatch_semaphore_create(kTHDuplictionConcurrentCount);
        lock = dispatch_semaphore_create(1);
        minFileSize = 100*1024;
    }
    return self;
}

- (void)startSearch
{
    if (searching)
    {
        return;
    }
    
    fileInfo = [[NSMutableDictionary alloc] init];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self searchStart];
    });
}

- (void)stopSearch
{
    isStop = YES;
}

- (void)postNotificationSize:(NSNumber *)sizeKey hash:(NSString *)hashKey fileList:(NSArray *)fileList
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    if (sizeKey) [userInfo setObject:sizeKey forKey:THDuplicationFileSize];
    if (hashKey) [userInfo setObject:hashKey forKey:THDuplicationFileHash];
    if (fileList) [userInfo setObject:fileList forKey:THDuplicationFileList];
    if (!sizeKey && !hashKey && !fileList)
    {
        [userInfo setObject:[NSNumber numberWithBool:!searching] forKey:THDuplicationFinished];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:THDuplicationNotification object:self userInfo:userInfo];
}

@end
