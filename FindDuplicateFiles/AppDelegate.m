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
#include <sys/stat.h>

@implementation AppDelegate

- (void)dragFileEnter:(NSString *)aFilePath
{
    if (helper.searching)
    {
        NSLog(@"扫描中");
        return;
    }
    
    NSArray *searchPaths = helper.searchPaths;
    if (searchPaths)
    {
        searchPaths = [searchPaths arrayByAddingObject:aFilePath];
    }else
    {
        searchPaths = [NSArray arrayWithObject:aFilePath];
    }
    helper.searchPaths = searchPaths;
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{    
    helper = [[THDuplicationHelper alloc] init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveResults:) name:THDuplicationNotification object:helper];
}

- (IBAction)click:(id)sender
{
    if (helper.searching)
    {
        NSLog(@"扫描中");
        return;
    }
    
    NSArray *filterExtenstions = [[extenstionView string] componentsSeparatedByString:@","];
    if ([extenstionView.string length]>0 && [filterExtenstions count] > 0)
    {
        helper.searchFileExtensions = filterExtenstions;
    }else
    {
        helper.searchFileExtensions = nil;
    }
    
    helper.filterPackage = (filterPackageButton.state == NSOnState);
    helper.minFileSize = [[sizeField stringValue] longLongValue];
    
    results = [[NSMutableDictionary alloc] init];
    [resultView setString:@""];
    
    [helper startSearch];
}

- (IBAction)stop:(id)sender
{
    [helper stopSearch];
}

- (void)receiveResults:(NSNotification *)notify
{
    BOOL finished = [[[notify userInfo] objectForKey:THDuplicationFinished] boolValue];
    NSString *fileHash = [[notify userInfo] objectForKey:THDuplicationFileHash];
    NSArray *fileList = [[notify userInfo] objectForKey:THDuplicationFileList];
    if (finished)
    {
        NSString *string = [NSString stringWithFormat:@"完成\r\n%@",resultView.string];
        [resultView setString:string];
    }
    else if (fileList && fileHash)
    {
        [results setObject:fileList forKey:fileHash];
        
        NSMutableString *string = [NSMutableString string];
        for (id key in results)
        {
            NSArray *paths = [results objectForKey:key];
            [string appendFormat:@"{\r\n    %@\r\n}\r\n",[paths componentsJoinedByString:@",\r\n    "]];
        }
        [resultView setString:string];
    }
}

@end
