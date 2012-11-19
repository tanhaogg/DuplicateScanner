//
//  McHeaderViewController.m
//  MagicanCastle
//
//  Created by tanhao on 12-4-18.
//  Copyright (c) 2012  Magican Software Ltd. All rights reserved.
//

#import "McHeaderViewController.h"
#import "McImageHeaderView.h"
#import <QuartzCore/CoreAnimation.h>

#define kMcTemperatureUnitHeaderViewShowed @"McTemperatureUnitHeaderViewShowed"
#define kMcLocatedConfirmHeaderViewShowed  @"McLocatedConfirmHeaderViewShowed"

@interface McHeaderViewController()<NSAnimationDelegate>
@end

@implementation McHeaderViewController
@synthesize currentHeaderView;

+ (McHeaderViewController *)sharedController
{
    __strong static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[McHeaderViewController alloc] initWithNibName:@"McHeaderViewController" bundle:kSelfBundle];
    });
    return instance;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        viewArray = [[NSMutableArray alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveWindowWillBeginSheetNotification:) name:NSWindowWillBeginSheetNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveWindowDidEndSheetNotification:) name:NSWindowDidEndSheetNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    NSString *imgPath = [kSelfBundle pathForImageResource:@"headerLogo"];
    NSImage *headerImg = [[NSImage alloc] initWithContentsOfFile:imgPath];
    logoHeader = [[McImageHeaderView alloc] initWithImage:headerImg];
    logoHeader.level = kMcHeaderLevelLogo;
    logoHeader.repeat = kMcHeaderRepeatForever;
    [self addHeaderView:logoHeader immediately:YES];
}

#pragma mark -
#pragma mark NSAnimationDelegate

- (void)animationDidEnd:(NSAnimation*)animation
{
    NSArray *animationArr = [(NSViewAnimation *)animation viewAnimations];
    for (NSDictionary *animationDic in animationArr)
    {
        NSView *aView = [animationDic objectForKey:NSViewAnimationTargetKey];
        NSRect endFrame = [[animationDic objectForKey:NSViewAnimationEndFrameKey] rectValue];
        if (endFrame.origin.y < 0)
        {
            [aView removeFromSuperview];
        }else
        {
            [aView setFrame:endFrame];
        }
    }
}

- (void)animationDidStop:(NSAnimation *)animation
{
    NSArray *animationArr = [(NSViewAnimation *)animation viewAnimations];
    for (NSDictionary *animationDic in animationArr)
    {
        NSView *aView = [animationDic objectForKey:NSViewAnimationTargetKey];
        NSRect endFrame = [[animationDic objectForKey:NSViewAnimationEndFrameKey] rectValue];
        if (endFrame.origin.y < 0)
        {
            [aView removeFromSuperview];
        }else
        {
            [aView setFrame:endFrame];
        }
    }
}

- (void)replaceView:(McHeaderView *)aView
{
    if (aView == currentHeaderView)
    {
        return;
    }
    
    if (!aView)
    {
        [currentHeaderView removeFromSuperview];
        currentHeaderView = nil;
        return;
    }
    
    //create timer for next replace
    [timer invalidate];
    timer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:aView.duration] interval:aView.duration target:self selector:@selector(timerMethod) userInfo:nil repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    
    if (currentHeaderView)
    {
        //[[self.view animator] replaceSubview:currentHeaderView with:aView];
        {
            [showAnimation stopAnimation];
            showAnimation = nil;
            
            [aView setFrameOrigin:NSMakePoint(0, aView.bounds.size.height)];
            [self.view addSubview:aView];
            NSDictionary *aViewAnimationDic = [[NSDictionary alloc] initWithObjectsAndKeys:
                                               aView,NSViewAnimationTargetKey,
                                               [NSValue valueWithRect:aView.frame],NSViewAnimationStartFrameKey,
                                               [NSValue valueWithRect:currentHeaderView.frame],NSViewAnimationEndFrameKey, nil];
            NSRect currentEndFrame = currentHeaderView.frame;
            currentEndFrame.origin.y = -currentEndFrame.size.height;
            NSDictionary *currentViewAnimationDic = [[NSDictionary alloc] initWithObjectsAndKeys:
                                                     currentHeaderView,NSViewAnimationTargetKey,
                                                     [NSValue valueWithRect:currentHeaderView.frame],NSViewAnimationStartFrameKey,
                                                     [NSValue valueWithRect:currentEndFrame],NSViewAnimationEndFrameKey, nil];
            NSArray *animationArr = [[NSArray alloc] initWithObjects:aViewAnimationDic,currentViewAnimationDic, nil];
            showAnimation = [[NSViewAnimation alloc] initWithViewAnimations:animationArr];
            [showAnimation setDelegate:self];
            [showAnimation startAnimation];
        }
        
        if (currentHeaderView.repeat == kMcHeaderRepeatOnces)
        {
            [viewArray removeObject:currentHeaderView];
        }
    }else
    {
        [self.view addSubview:aView];
    }
    
    currentHeaderView = aView;
}

- (void)timerMethod
{
    if ([viewArray count] == 0)
    {
        [self replaceView:nil];
        return;
    }
    
    McHeaderView *aView = nil;
    
    if (currentHeaderView)
    {
        NSInteger idx = [viewArray indexOfObject:currentHeaderView];
        if (idx == NSNotFound || idx+1 >= [viewArray count])
        {
            aView = [viewArray objectAtIndex:0];
        }else
        {
            aView = [viewArray objectAtIndex:idx+1];
        }
    }else
    {
        aView = [viewArray objectAtIndex:0];
    }
    
    [self replaceView:aView];
}

- (void)addHeaderView:(McHeaderView *)headerView immediately:(BOOL)immediately
{
    [viewArray addObject:headerView];
    
    [viewArray sortUsingComparator:^NSComparisonResult(McHeaderView * obj1, McHeaderView * obj2) {
        NSComparisonResult result = NSOrderedSame;
        if (obj1.level < obj2.level) result = NSOrderedAscending;
        if (obj1.level > obj2.level) result = NSOrderedDescending;
        return result;
    }];
    
    if (immediately)
    {
        [self replaceView:headerView];
    }
}

- (void)removeHeaderView:(McHeaderView *)headerView immediately:(BOOL)immediately
{
    if ([viewArray containsObject:headerView])
    {
        [viewArray removeObject:headerView];
        if (immediately && currentHeaderView==headerView)
        {
            [self timerMethod];
        }
    }
}

#pragma mark -
#pragma NotificationMethod

- (void)receiveWindowWillBeginSheetNotification:(NSNotification *)notify
{
    NSWindow *notifyWindow = [notify object];
    if (notifyWindow == [self.view window])
    {
        [timer invalidate];
        timer = nil;
    }
}

- (void)receiveWindowDidEndSheetNotification:(NSNotification *)notify
{
    if (timer) return;
    if (!currentHeaderView) return;
    NSWindow *notifyWindow = [notify object];
    if (notifyWindow == [self.view window])
    {
        NSTimeInterval duration = [currentHeaderView duration];
        timer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:duration] interval:duration target:self selector:@selector(timerMethod) userInfo:nil repeats:NO];
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
        return;
    }
}

@end
