//
//  THDuplicateCell.m
//  FindDuplicateFiles
//
//  Created by TanHao on 12-11-10.
//  Copyright (c) 2012年 tanhao.me. All rights reserved.
//

#import "THDuplicateCell.h"
#import "THStaticTextField.h"

#define kTHDuplicateCellIconSpacingBegin 8.0
#define kTHDuplicateCellIconSpacingEnd 8.0
#define kTHDuplicateCellIconHeight 28.0

@class THPathView;
@protocol THPathViewDelegate <NSObject>

@optional
- (void)openClick:(THPathView *)cell;
- (void)removeClick:(THPathView *)cell;

@end

@interface THPathView : NSView
{
    THStaticTextField *textField;
    NSButton *showButton;
    NSButton *removeButton;
}
@property (nonatomic, unsafe_unretained) id delegate;
@property (nonatomic, strong) NSString *filePath;

+ (THPathView *)pathView;

@end

@implementation THPathView
@synthesize delegate;
@synthesize filePath;

- (NSString *)filePath
{
    return filePath;
}

- (void)setFilePath:(NSString *)value
{
    if (filePath == value)
    {
        return;
    }
    filePath = value;
    if (filePath)
    {
        [textField setStringValue:filePath];
    }else
    {
        [textField setStringValue:@""];
    }
}

- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self)
    {
        textField = [[THStaticTextField alloc] initWithFrame:NSMakeRect(0, NSMidY(frameRect)-17/2, NSWidth(frameRect)-60, 17)];
        [textField.cell setLineBreakMode:NSLineBreakByTruncatingMiddle];
        [textField setAutoresizingMask:NSViewWidthSizable];
        [self addSubview:textField];
        
        showButton = [[NSButton alloc] initWithFrame:NSMakeRect(NSWidth(frameRect)-50, NSMidY(frameRect)-16/2, 16, 16)];
        [showButton setBordered:NO];
        [showButton.cell setImageScaling:NSImageScaleProportionallyUpOrDown];
        [showButton setImage:[NSImage imageNamed:NSImageNameRevealFreestandingTemplate]];
        [showButton setAutoresizingMask:NSViewMinXMargin];
        [showButton setTarget:self];
        [showButton setAction:@selector(openClick:)];
        [self addSubview:showButton];
        
        removeButton = [[NSButton alloc] initWithFrame:NSMakeRect(NSWidth(frameRect)-26, NSMidY(frameRect)-16/2, 16, 16)];
        [removeButton setBordered:NO];
        [removeButton.cell setImageScaling:NSImageScaleProportionallyUpOrDown];
        [removeButton setImage:[NSImage imageNamed:NSImageNameStopProgressFreestandingTemplate]];
        [removeButton setAutoresizingMask:NSViewMinXMargin];
        [removeButton setTarget:self];
        [removeButton setAction:@selector(removeClick:)];
        [self addSubview:removeButton];
        
        [self setAutoresizingMask:NSViewWidthSizable];
    }
    return self;
}

- (void)openClick:(id)sender
{
    if (delegate && [delegate respondsToSelector:@selector(openClick:)])
    {
        [delegate openClick:self];
    }
}

- (void)removeClick:(id)sender
{
    if (delegate && [delegate respondsToSelector:@selector(removeClick:)])
    {
        [delegate removeClick:self];
    }
}

+ (THPathView *)pathView
{
    THPathView *pathView = [[THPathView alloc] initWithFrame:
                            NSMakeRect(0, 0,
                                       kTHDuplicateCellMinSize.width-kTHDuplicateCellIconHeight-kTHDuplicateCellIconSpacingBegin-kTHDuplicateCellIconSpacingEnd,
                                       kTHPathViewHeight)];
    return pathView;
}

@end


@implementation THDuplicateCell
@synthesize delegate;
@synthesize fileLists;
@synthesize fileSize;

- (id)initWithReusableIdentifier:(NSString*)identifier
{
    self = [super initWithReusableIdentifier:identifier];
    if (self) {
        
        [self setFrameSize:kTHDuplicateCellMinSize];
        
        viewItemList = [[NSMutableArray alloc] initWithCapacity:2];
        
        iconView = [[NSImageView alloc] initWithFrame:
                    NSMakeRect(kTHDuplicateCellIconSpacingBegin, (kTHDuplicateCellMinSize.height-kTHDuplicateCellIconHeight)/2, kTHDuplicateCellIconHeight, kTHDuplicateCellIconHeight)];
        
        [iconView setImageFrameStyle:NSImageFrameNone];
        [iconView setImageScaling:NSImageScaleProportionallyUpOrDown];
        [iconView setAutoresizingMask:NSViewMinYMargin|NSViewMaxYMargin|NSViewMaxXMargin];
        [self addSubview:iconView];
        
        sizeField = [[THStaticTextField alloc] initWithFrame:NSMakeRect(5, NSMidY(self.bounds)-25, 50, 10)];
        [sizeField setFont:[NSFont labelFontOfSize:9]];
        [sizeField setTextColor:[NSColor redColor]];
        [self addSubview:sizeField];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(frameDidChanged:) name:NSViewFrameDidChangeNotification object:self];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)frameDidChanged:(NSNotification *)notify
{
    [sizeField setFrame:NSMakeRect(5, NSMidY(self.bounds)-25, 50, 10)];
}

- (uint64)fileSize
{
    return fileSize;
}

- (void)setFileSize:(uint64)value
{
    if (fileSize == value)
    {
        return;
    }
    fileSize = value;
    [sizeField setStringValue:[NSString stringWithSize:fileSize]];
}

- (NSArray *)fileLists
{
    return fileLists;
}

- (void)setFileLists:(NSArray *)value
{
    if (fileLists == value)
    {
        return;
    }
    fileLists = value;
    
    NSString *filePath = [fileLists objectAtIndex:0];
    NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:filePath];
    [icon setSize:iconView.frame.size];
    [iconView setImage:icon];
    
    [viewItemList makeObjectsPerformSelector:@selector(removeFromSuperview)];    
    for (int i=0; i<[fileLists count]; i++)
    {
        THPathView *pathView = nil;
        if ([viewItemList count] < i+1)
        {
            pathView = [THPathView pathView];
            pathView.delegate = self;
            [viewItemList addObject:pathView];
        }else
        {
            pathView = [viewItemList objectAtIndex:i];
        }
        
        pathView.filePath = [fileLists objectAtIndex:i];
        double iconSpacing = kTHDuplicateCellIconSpacingBegin+kTHDuplicateCellIconHeight+kTHDuplicateCellIconSpacingEnd;
        pathView.frame = NSMakeRect(iconSpacing, (kTHDuplicateCellMinSize.height-kTHPathViewHeight)/2+i*kTHPathViewHeight, NSWidth(self.frame)-iconSpacing, kTHPathViewHeight);
        [self addSubview:pathView];
    }
}

- (void)drawRect:(NSRect)dirtyRect
{
    static NSShadow *shadow = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shadow = [[NSShadow alloc] init];
        [shadow setShadowColor:[NSColor blackColor]];
        [shadow setShadowBlurRadius:2];
        [shadow setShadowOffset:NSMakeSize(1, -1)];
    });
    [shadow set];
    
	[[NSColor whiteColor] set];
    
    //Draw the border and background
	NSBezierPath *roundedRect = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect([self bounds], 5.0, 2.0)
                                                                xRadius:6.0
                                                                yRadius:6.0];
	[roundedRect fill];
}

#pragma mark -
#pragma mark THPathViewDelegate

- (void)openClick:(THPathView *)cell
{
    if (delegate && [delegate respondsToSelector:@selector(cellOpenClick:index:)])
    {
        [delegate cellOpenClick:self index:[viewItemList indexOfObject:cell]];
    }
}

- (void)removeClick:(THPathView *)cell
{
    if (delegate && [delegate respondsToSelector:@selector(cellRemoveClick:index:)])
    {
        [delegate cellRemoveClick:self index:[viewItemList indexOfObject:cell]];
    }
}

@end
