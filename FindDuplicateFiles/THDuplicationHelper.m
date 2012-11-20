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
#import "THLock.h"

#define kTHDuplictionFileMinSize (1024)
#define kTHDuplictionConcurrentCount 5

NSString* const THDuplicationNotification = @"THDuplicationNotification";
NSString* const THDuplicationFileSize = @"THDuplicationFileSize";
NSString* const THDuplicationFileHash = @"THDuplicationFileHash";
NSString* const THDuplicationFileList = @"THDuplicationFileList";
NSString* const THDuplicationFinished = @"THDuplicationFinished";

@implementation THDuplicationHelper
@synthesize notificationQueue;

@synthesize searchPaths;
@synthesize filterFilePaths;
@synthesize extensionsPredicate;
@synthesize minFileSize;
@synthesize maxFileSize;
@synthesize filterPackage;

@synthesize searching;

//判断文件的有效性
- (BOOL)fileValid:(NSString *)filePath size:(UInt64 *)size
{
    @autoreleasepool {
        uint64 fileSize = [THFileUtility fileSizeByPath:filePath];
        if (size)
        {
            *size = fileSize;
        }
        if (fileSize < MAX(minFileSize, kTHDuplictionFileMinSize))
        {
            return NO;
        }
        if (maxFileSize > MAX(minFileSize, kTHDuplictionFileMinSize) && fileSize > maxFileSize)
        {
            return NO;
        }
        if (extensionsPredicate)
        {
            NSString *fileExtenstion = [filePath pathExtension];
            return [extensionsPredicate evaluateWithObject:fileExtenstion];
        }
        return YES;
    }
}

//判断目录的有效性
- (BOOL)directoryValid:(NSString *)filePath
{
    @autoreleasepool {
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
    }
}

//返回目录的的子目录绝对路径
- (NSArray *)directorySubPath:(NSString *)filePath
{
    @autoreleasepool {
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
            [subPaths addObject:fullPath];
        }
        
        return [NSArray arrayWithArray:subPaths];
    }
}

//处理扫描到的文件
- (void)fileDispose:(NSString *)filePath
{
    @autoreleasepool {
        uint64 fileSize = 0;
        BOOL valid = [self fileValid:filePath size:&fileSize];
        if (!valid)
        {
            return;
        }
        
        //以文件大小为Key
        NSNumber *fileKey = [NSNumber numberWithUnsignedLongLong:fileSize];
        
        id exist = nil;
        
        @synchronized(fileInfo){
            exist = [fileInfo objectForKey:fileKey];
            if (!exist)
            {
                [fileInfo setObject:filePath forKey:fileKey];
                return;
            }
        }
        
        //计算文件的hash值
        NSString *hashKey = [THWebUtility lazyHashFile:filePath];
        if (!hashKey)
        {
            return;
        }
        
        //文件大小相同，以下的代码互斥,加锁
        ////////////////////////////////////////
        [THLock lockForKey:fileKey];
        ///////////////////////////////////////
        
        //二次判断(防止在hash过程中其它线程已经改变fileInfo结构)
        @synchronized(fileInfo){
            exist = [fileInfo objectForKey:fileKey];
        }
        
        //标识是否已经找到重复项
        BOOL duplication = NO;
        NSArray *fileList = nil;
        
        //如果fileInfo中相同大小的为string，刚说明还没有计算过hash值
        if ([exist isKindOfClass:[NSString class]])
        {
            NSString *existFile = (NSString *)exist;
            NSString *existHashKey = [THWebUtility lazyHashFile:existFile];
            if (!existHashKey)
            {
                //如果计算已存在文件的hash值失败，则覆盖，并退出
                NSMutableArray *list = [NSMutableArray arrayWithObject:filePath];
                NSDictionary *hashDic = [NSMutableDictionary dictionaryWithObject:list forKey:hashKey];
                
                @synchronized(fileInfo){
                    [fileInfo setObject:hashDic forKey:fileKey];
                }
                
                ////////////////////////////////////////
                [THLock unLockForKey:fileKey];
                ///////////////////////////////////////
                return;
            }
            
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
        
        if ([exist isKindOfClass:[NSMutableDictionary class]])
        {
            NSMutableDictionary *hashDic = (NSMutableDictionary *)exist;
            
            //hash值相同，以下代码就互斥,加锁
            ////////////////////////////////////////
            [THLock lockForKey:hashKey];
            ///////////////////////////////////////
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
            ////////////////////////////////////////
            [THLock unLockForKey:hashKey];
            ///////////////////////////////////////
        }
        
        ////////////////////////////////////////
        [THLock unLockForKey:fileKey];
        ///////////////////////////////////////
        
        if (duplication)
        {
            dispatch_async(notificationQueue, ^{
                [self postNotificationSize:fileKey hash:hashKey fileList:fileList];
            });
        }
    }
}

//目录扫描
- (void)searth:(NSString *)filePath isDirectory:(BOOL)isDirectory
{
    //对一个文件的排队处理
    static void(^handleFile)(NSString *);
    handleFile = ^(NSString *currentFilePath){
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            @autoreleasepool {
                [self fileDispose:currentFilePath];
            }
            dispatch_semaphore_signal(semaphore);
        });
    };
    
    @autoreleasepool {
        NSArray *subItems = nil;
        if (isDirectory)
        {
            //如果是Package，先当做一个文件找重复
            if ([[NSWorkspace sharedWorkspace] isFilePackageAtPath:filePath])
            {
                handleFile(filePath);
            }
            //文件夹是否满足规则
            if (![self directoryValid:filePath])
            {
                return;
            }
            subItems = [self directorySubPath:filePath];
        }else
        {
            subItems = [NSArray arrayWithObject:filePath];
        }
        for (NSString *fullPath in subItems)
        {            
            @autoreleasepool
            {
                if (isStop)
                {
                    break;
                }
                
                if ([THFileUtility fileIsDirectory:fullPath])
                {
                    [self searth:fullPath isDirectory:YES];
                }
                else if ([THFileUtility fileIsRegular:fullPath])
                {
                    handleFile(fullPath);
                }
            }
        }
    }
}

- (void)searchByEnum:(NSArray *)filePathList
{
    for (NSString *searchPath in filePathList)
    {
        if ([THFileUtility fileIsDirectory:searchPath])
        {
            [self searth:searchPath isDirectory:YES];
        }
        else if ([THFileUtility fileIsRegular:searchPath])
        {
            [self searth:searchPath isDirectory:NO];
        }
    }
}

- (void)queryUpdateNotification:(NSNotification *)notify
{
    @autoreleasepool {
        NSString *notificationName = [notify name];
        if ([notificationName isEqualToString:(__bridge NSString *)kMDQueryDidFinishNotification])
        {
            isStop = YES;
        }
        else if ([notificationName isEqualToString:(__bridge NSString *)kMDQueryProgressNotification])
        {
            MDQueryRef query = (__bridge MDQueryRef)[notify object];
            CFIndex totalCount = MDQueryGetResultCount(query);
            for (CFIndex i=queryCount; i<totalCount; i++)
            {
                if (isStop)
                {
                    break;
                }
                MDItemRef item = (MDItemRef)MDQueryGetResultAtIndex(query, i);
                if (item == NULL)
                {
                    continue;
                }
                
                NSString *path = (__bridge NSString *)MDItemCopyAttribute(item, kMDItemPath);
                if ([THFileUtility fileIsDirectory:path])
                {
                    [self searth:path isDirectory:YES];
                }
                else if ([THFileUtility fileIsRegular:path])
                {
                    [self searth:path isDirectory:NO];
                }
            }
            queryCount = totalCount;
        }
    }
}

- (BOOL)searchByQuery:(NSArray *)filePathList
{
    @autoreleasepool {
        if ([filePathList count] == 0)
        {
            return NO;
        }
        NSString *searchScope = [NSString stringWithFormat:@"(kMDItemFSSize > '%lld')",MAX(minFileSize,1024)];
        if (maxFileSize > MAX(minFileSize,1024))
        {
            searchScope = [searchScope stringByAppendingFormat:@" && (kMDItemFSSize < '%lld')",maxFileSize];
        }
        //searchScope = [searchScope stringByAppendingFormat:@"&& (kMDItemContentType != 'public.folder')"];
        searchScope = [searchScope stringByAppendingFormat:@"&& (kMDItemContentType != 'com.apple.mail.emlx')"];
        searchScope = [searchScope stringByAppendingFormat:@"&& (kMDItemContentType != 'public.vcard')"];
        MDQueryRef query = MDQueryCreate(kCFAllocatorDefault, (__bridge CFStringRef)searchScope, NULL, NULL);
        MDQuerySetSearchScope(query, (__bridge CFArrayRef)filePathList, 0);
        if (!query)
        {
            return NO;
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(queryUpdateNotification:)
                                                     name:(__bridge NSString *)kMDQueryDidFinishNotification
                                                   object:(__bridge id)query];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(queryUpdateNotification:)
                                                     name:(__bridge NSString *)kMDQueryProgressNotification
                                                   object:(__bridge id)query];
        BOOL sucess = MDQueryExecute(query, 0);
        
        while (sucess)
        {
            if (isStop)
            {
                break;
            }
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
            usleep(100*1000);
        }
        
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:(__bridge NSString *)kMDQueryDidFinishNotification
                                                      object:(__bridge id)query];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:(__bridge NSString *)kMDQueryProgressNotification
                                                      object:(__bridge id)query];
        
        MDQueryStop(query);
        CFRelease(query);
        return sucess;
    }
}

- (void)searchStart
{    
    //开始检索
    searching = YES;
    queryCount = 0;
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
    
    //使用spotlight查询
    BOOL result = [self searchByQuery:validSearchPaths];
    //使用枚举方式遍历所有目录(阻塞的)
    if (!result)
    {
        [self searchByEnum:validSearchPaths];
    }
    
    //等待所有线程结束
    int waitTread = kTHDuplictionConcurrentCount;
    while (waitTread > 0)
    {
        waitTread--;
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }
    
    //让semaphore恢复初使状态
    while (waitTread < kTHDuplictionConcurrentCount)
    {
        waitTread ++;
        dispatch_semaphore_signal(semaphore);
    }
    
    searching = NO;
    
    dispatch_async(notificationQueue, ^{
        [self postNotificationSize:nil hash:nil fileList:nil];
    });
}

- (id)init
{
    self = [super init];
    if (self)
    {
        notificationQueue = dispatch_get_main_queue();
        semaphore = dispatch_semaphore_create(kTHDuplictionConcurrentCount);
        lock = dispatch_semaphore_create(1);
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
        @autoreleasepool {
            [self searchStart];
            fileInfo = nil;
        }
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
