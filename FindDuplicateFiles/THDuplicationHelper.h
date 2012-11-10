//
//  THDuplicationHelper.h
//  FindDuplicateFiles
//
//  Created by TanHao on 12-11-5.
//  Copyright (c) 2012年 tanhao.me. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* const THDuplicationNotification;
extern NSString* const THDuplicationFileSize;
extern NSString* const THDuplicationFileHash;
extern NSString* const THDuplicationFileList;
extern NSString* const THDuplicationFinished;

@interface THDuplicationHelper : NSObject
{
    NSMutableDictionary *fileInfo;
    dispatch_semaphore_t semaphoreA;
    dispatch_semaphore_t semaphoreB;
    dispatch_semaphore_t lock;
    BOOL isStop;
}

@property (strong) NSArray *searchPaths;
@property (strong) NSArray *filterFilePaths;
@property (strong) NSArray *searchFileExtensions;
@property (strong) NSArray *filterFileExtensions;
@property (assign) uint64 minFileSize;
@property (assign) BOOL filterPackage;

@property (readonly) BOOL searching;

- (void)startSearch;
- (void)stopSearch;

@end
