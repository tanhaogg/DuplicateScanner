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
    dispatch_semaphore_t semaphore;
    dispatch_semaphore_t lock;
    CFIndex queryCount;
    BOOL isStop;
}
@property (assign) dispatch_queue_t notificationQueue;

@property (strong) NSArray *searchPaths;
@property (strong) NSArray *filterFilePaths;

@property (strong) NSPredicate *extensionsPredicate;
@property (assign) uint64 minFileSize;
@property (assign) uint64 maxFileSize;
@property (assign) BOOL filterPackage;

@property (readonly) BOOL searching;

- (void)startSearch;
- (void)stopSearch;

@end
