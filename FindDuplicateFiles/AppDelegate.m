//
//  AppDelegate.m
//  FindDuplicateFiles
//
//  Created by TanHao on 12-11-2.
//  Copyright (c) 2012年 tanhao.me. All rights reserved.
//

#import "AppDelegate.h"
#import "THFileUtility.h"
#import "THWebUtility.h"
#import "THDuplicationHelper.h"
#import "PXListView.h"
#import "THDuplicateCell.h"
#import "McHeaderViewController.h"
#import "THPathSelectedViewController.h"
#import "THPredicateEditorViewController.h"
#import "THBackgroundView.h"
#import "INAppStoreWindow.h"

@interface AppDelegate ()<PXListViewDelegate>

@end

const NSString *THDuplicationFileExtenstion = @"THDuplicationFileExtenstion";

@implementation AppDelegate

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag
{
    [self.window makeKeyAndOrderFront:nil];
    return YES;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{    
    [(INAppStoreWindow *)self.window setTitleBarHeight:NSHeight(barView.frame)];
    [(INAppStoreWindow *)self.window setCenterTrafficLightButtons:NO];
    [barView setFrameOrigin:NSMakePoint(0, 0)];
    [[(INAppStoreWindow *)self.window titleBarView] addSubview:barView];
    
    resultView.cellSpacing = 5;
    resultView.allowsSelection = NO;
    
    [startButton setEnabled:YES];
    [stopButton setEnabled:NO];
    
    headerVC = [McHeaderViewController sharedController];
    [headerVC.view setFrame:headerDocumentView.bounds];
    [headerVC.view setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    [headerDocumentView addSubview:headerVC.view];
    
    predicateVC = [[THPredicateEditorViewController alloc] init];
    [predicateVC.view setFrame:filterDocumentView.bounds];
    [predicateVC.view setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    [filterDocumentView addSubview:predicateVC.view];
    
    pathVC = [[THPathSelectedViewController alloc] init];
    [pathVC.view setFrame:pathDocumentView.bounds];
    [pathVC.view setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    [pathDocumentView addSubview:pathVC.view];
    
    sortKind = THDuplicationSortDefault;
    helper = [[THDuplicationHelper alloc] init];
    helper.notificationQueue = dispatch_queue_create(NULL, NULL);
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveResults:)
                                                 name:THDuplicationNotification
                                               object:helper];
}

- (IBAction)start:(id)sender
{
    if (helper.searching)
    {
        return;
    }
    
    //初使化helper
    helper.searchPaths = [pathVC filePaths];
    [predicateVC reload];
    helper.extensionsPredicate = [predicateVC extensionPredicate];
    helper.minFileSize = [predicateVC minSize];
    helper.maxFileSize = [predicateVC maxSize];
    helper.filterPackage = ![predicateVC scanPackage];
    
    //初使化界面显示
    results = [[NSMutableArray alloc] init];
    resultDictionary = [[NSMutableDictionary alloc] init];
    tempResultDictionary = [[NSMutableDictionary alloc] init];
    notificationInterval = 0.0;
    
    showHeaderView.duration = kMcHeaderDurationForever;
    [headerVC addHeaderView:showHeaderView immediately:YES];
    
    [startButton setEnabled:NO];
    [stopButton setEnabled:YES];
    [loadingView setHidden:NO];
    [loadingView startAnimation:nil];
    
    [self reloadList];
    [helper startSearch];
}

- (IBAction)stop:(id)sender
{
    [helper stopSearch];
}

- (IBAction)searchClick:(id)sender
{
    NSString *string = [(NSSearchField *)sender stringValue];
    if ([string length] > 0)
    {
        filterString = string;
    }else
    {
        filterString = nil;
    }
    
    [self reloadList];
}

- (IBAction)sortClick:(id)sender
{
    NSInteger idx = [(NSSegmentedControl *)sender selectedSegment];
    if (sortKind == idx)
    {
        [(NSSegmentedControl *)sender setSelected:NO forSegment:idx];
        sortKind = THDuplicationSortDefault;
    }else
    {
        sortKind = idx;
    }
    
    [self reloadList];
}

- (NSString *)idealExtension:(NSArray *)listArray
{
    NSString *resultExtension = nil;
    NSInteger appearCount = 0;
    for (NSString *aFilePath in listArray)
    {
        NSString *aExtension = [[aFilePath pathExtension] lowercaseString];
        if ([aExtension length] > 0)
        {
            if (!resultExtension)
            {
                resultExtension = aExtension;
                appearCount = 1;
            }
            else
            {
                NSArray *extensionArray = [NSArray arrayWithObjects:aExtension,[aExtension uppercaseString], nil];
                NSInteger currentCount = [[listArray pathsMatchingExtensions:extensionArray] count];
                if (currentCount > appearCount)
                {
                    resultExtension = aExtension;
                    appearCount = currentCount;
                }
            }
        }
    }
    return resultExtension;
}

- (void)receiveResults:(NSNotification *)notify
{
    @autoreleasepool {
        BOOL finished = [[[notify userInfo] objectForKey:THDuplicationFinished] boolValue];
        NSNumber *fileSize = [[notify userInfo] objectForKey:THDuplicationFileSize];
        NSString *fileHash = [[notify userInfo] objectForKey:THDuplicationFileHash];
        NSArray *fileList = [[notify userInfo] objectForKey:THDuplicationFileList];
        NSString *fileExtension = [self idealExtension:fileList];
        
        if (fileSize && fileList && fileHash)
        {
            NSMutableDictionary *listInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                             fileList,THDuplicationFileList,
                                             fileSize,THDuplicationFileSize,nil];
            if (fileExtension) [listInfo setObject:fileExtension forKey:THDuplicationFileExtenstion];
            @synchronized(tempResultDictionary){
                [tempResultDictionary setObject:listInfo forKey:fileHash];
            }
        }
        
        NSTimeInterval currentInterval = [NSDate timeIntervalSinceReferenceDate];
        NSTimeInterval interval = currentInterval - notificationInterval;
        
        if ((finished || interval > 5.0) && [tempResultDictionary count] > 0)
        {
            NSDictionary *updateInfo = [NSDictionary dictionaryWithDictionary:tempResultDictionary];
            @synchronized(tempResultDictionary){
                [tempResultDictionary removeAllObjects];
            }
            notificationInterval = currentInterval;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self refreshResultList:updateInfo];
                notificationInterval = [NSDate timeIntervalSinceReferenceDate];
            });
        }
        
        if (finished)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [startButton setEnabled:YES];
                [stopButton setEnabled:NO];
                [loadingView stopAnimation:nil];
                [loadingView setHidden:YES];
            });
        }
    }
}

- (void)refreshResultList:(NSDictionary *)updateInfo
{
    for (id key in updateInfo)
    {
        NSDictionary *listInfo = [updateInfo objectForKey:key];
        NSDictionary *exist = [resultDictionary objectForKey:key];
        if (exist)
        {
            NSInteger idx = [results indexOfObject:exist];
            [results replaceObjectAtIndex:idx withObject:listInfo];
        }else
        {
            [results addObject:listInfo];
        }
    }
    [resultDictionary addEntriesFromDictionary:updateInfo];
    [self reloadList];
}

- (void)reloadList
{
    if ([filterString length] > 0)
    {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self contains[cd] %@",filterString];
        showLists = [[NSMutableArray alloc] init];
        for (NSDictionary *listInfo in results)
        {
            NSArray *fileList = [listInfo objectForKey:THDuplicationFileList];
            for (NSString *filePath in fileList)
            {
                if ([predicate evaluateWithObject:filePath])
                {
                    [showLists addObject:listInfo];
                    break;
                }
            }
        }
    }else
    {
        showLists = [results mutableCopy];
    }
    
    if (sortKind != THDuplicationSortDefault)
    {
        [showLists sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            @autoreleasepool {
                NSDictionary *listInfo1 = (NSDictionary *)obj1;
                NSDictionary *listInfo2 = (NSDictionary *)obj2;
                
                NSArray *fileList1 = [listInfo1 objectForKey:THDuplicationFileList];
                NSArray *fileList2 = [listInfo2 objectForKey:THDuplicationFileList];
                
                NSComparisonResult comparisionResult = NSOrderedSame;
                if (sortKind == THDuplicationSortCount)
                {
                    if (fileList1.count > fileList2.count) comparisionResult = NSOrderedAscending;
                    if (fileList2.count > fileList1.count) comparisionResult = NSOrderedDescending;
                }
                
                if (sortKind == THDuplicationSortSize)
                {
                    NSNumber *fileSize1 = [listInfo1 objectForKey:THDuplicationFileSize];
                    NSNumber *fileSize2 = [listInfo2 objectForKey:THDuplicationFileSize];
                    comparisionResult = [fileSize2 compare:fileSize1];
                }
                
                if (sortKind == THDuplicationSortType)
                {
                    NSString *extension1 = [listInfo1 objectForKey:THDuplicationFileExtenstion];
                    NSString *extension2 = [listInfo2 objectForKey:THDuplicationFileExtenstion];
                    if (!extension1 && extension2) comparisionResult = NSOrderedDescending;
                    else if (extension1 && !extension2) comparisionResult = NSOrderedAscending;
                    else comparisionResult = [extension1 compare:extension2];
                }
                
                return comparisionResult;
            }
        }];
    }
    
    uint64 totalCount = 0;
    uint64 totalSize = 0;
    for (NSDictionary *listInfo in showLists)
    {
        NSArray *fileList = [listInfo objectForKey:THDuplicationFileList];
        totalCount += [fileList count]-1;
        NSNumber *fileSize = [listInfo objectForKey:THDuplicationFileSize];
        totalSize += ([fileList count]-1)*[fileSize longLongValue];
    }
    NSString *resultString = [NSString stringWithFormat:@"%@/%lld files",[NSString stringWithSize:totalSize],totalCount];
    [showResultView setStringValue:resultString];
    [resultView reloadData];
}

#pragma mark -
#pragma mark PXListViewDelegate

- (NSUInteger)numberOfRowsInListView:(PXListView*)aListView
{
    return [showLists count];
}

- (CGFloat)listView:(PXListView*)aListView heightOfRow:(NSUInteger)row
{
    NSDictionary *listInfo = [showLists objectAtIndex:row];
    NSArray *fileList = [listInfo objectForKey:THDuplicationFileList];
    return kTHDuplicateCellMinSize.height + kTHPathViewHeight*([fileList count]-1);
}

- (PXListViewCell*)listView:(PXListView*)aListView cellForRow:(NSUInteger)row
{
    static NSString *kCellIdentifier = @"THDuplicateCellIdentifier";
    THDuplicateCell *cell = (THDuplicateCell*)[aListView dequeueCellWithReusableIdentifier:kCellIdentifier];
	
	if(!cell) {
        cell = [[THDuplicateCell alloc] initWithReusableIdentifier:kCellIdentifier];
        cell.delegate = self;
	}
    
    NSDictionary *listInfo = [showLists objectAtIndex:row];
    NSArray *fileList = [listInfo objectForKey:THDuplicationFileList];
    NSNumber *fileSize = [listInfo objectForKey:THDuplicationFileSize];
    cell.fileLists = fileList;
    cell.fileSize = [fileSize unsignedLongLongValue];
    
    return cell;
}

#pragma mark -
#pragma mark THDuplicateCellDelegate

- (void)cellOpenClick:(THDuplicateCell *)cell index:(NSInteger)index
{
    NSUInteger row = cell.row;
    NSDictionary *listInfo = [showLists objectAtIndex:row];
    NSArray *fileList = [listInfo objectForKey:THDuplicationFileList];
    NSString *filePath = [fileList objectAtIndex:index];
    [[NSWorkspace sharedWorkspace] selectFile:filePath
                     inFileViewerRootedAtPath:[filePath stringByDeletingLastPathComponent]];
}

- (void)cellRemoveClick:(THDuplicateCell *)cell index:(NSInteger)index
{
    NSUInteger row = cell.row;
    NSDictionary *listInfo = [showLists objectAtIndex:row];
    NSArray *fileList = [listInfo objectForKey:THDuplicationFileList];
    NSArray *keys = [resultDictionary allKeysForObject:listInfo];
    NSString *filePath = [fileList objectAtIndex:index];
    
    if ([fileList count] > 2)
    {
        NSInteger idx = [results indexOfObject:listInfo];
        fileList = [fileList arrayByRemoveObject:filePath];
        listInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                    fileList,THDuplicationFileList,
                    [listInfo objectForKey:THDuplicationFileSize],THDuplicationFileSize,nil];
        
        [results replaceObjectAtIndex:idx withObject:listInfo];
        for (NSArray *key in keys)
        {
            [resultDictionary setObject:listInfo forKey:key];
        }
    }else
    {
        NSInteger idx = [results indexOfObject:listInfo];
        [results removeObjectAtIndex:idx];
        for (NSArray *key in keys)
        {
            [resultDictionary removeObjectForKey:key];
        }
    }
    
    [self reloadList];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])
        {
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:NULL];
        }
    });
}

#pragma mark -
#pragma mark NSSplitViewDelegate

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedCoordinate ofSubviewAt:(NSInteger)index
{
    CGFloat constrainedCoordinate = proposedCoordinate;
    if (index == 0)
    {
		constrainedCoordinate = proposedCoordinate + 320;
    }
    return constrainedCoordinate;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedCoordinate ofSubviewAt:(NSInteger)index
{
    CGFloat constrainedCoordinate = proposedCoordinate;
    if (index == ([[splitView subviews] count] - 2))
	{
		constrainedCoordinate = proposedCoordinate - 320;
    }
	
    return constrainedCoordinate;
}

- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview
{
    return NO;
}

@end
