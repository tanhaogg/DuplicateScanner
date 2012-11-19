//
//  THPathSelectedView.m
//  image-browser-appearance
//
//  Created by TanHao on 12-11-12.
//
//

#import "THPathSelectedViewController.h"
#import "ImageBrowserBackgroundLayer.h"
#import "THBarView.h"

@interface myImageObject : NSObject
{
    NSString* path;
}
@end

@implementation myImageObject

- (NSString *)path
{
    return path;
}

- (void)setPath:(NSString*)inPath
{
    if (path != inPath)
	{
        path = inPath;
    }
}

#pragma mark -
#pragma mark item data source protocol

- (NSString*)imageRepresentationType
{
	return IKImageBrowserNSImageRepresentationType;
}

- (id)imageRepresentation
{
	return [[NSWorkspace sharedWorkspace] iconForFile:path];
}

- (NSString*)imageUID
{
    return path;
}

- (NSString*)imageTitle
{
    return [[path lastPathComponent] stringByDeletingPathExtension];
}

- (NSString*)imageSubtitle
{
    return [path pathExtension];
}
@end


@implementation THPathSelectedViewController

- (id)init
{
    self = [super initWithNibName:@"THPathSelectedViewController" bundle:[NSBundle bundleForClass:self.class]];
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    imageBrowser.dataSource = self;
    imageBrowser.delegate = self;
    
    images = [[NSMutableArray alloc] init];
    importedImages = [[NSMutableArray alloc] init];
    
    // Allow reordering, animations and set the dragging destination delegate.
    [imageBrowser setAllowsReordering:YES];
    [imageBrowser setAnimates:YES];
    [imageBrowser setDraggingDestinationDelegate:self];
	
	// customize the appearance
	[imageBrowser setCellsStyleMask:IKCellsStyleTitled];
	
	// background layer
	ImageBrowserBackgroundLayer *backgroundLayer = [[ImageBrowserBackgroundLayer alloc] init];
	[imageBrowser setBackgroundLayer:backgroundLayer];
	backgroundLayer.owner = imageBrowser;
	
	//-- change default font
	// create a centered paragraph style
	NSMutableParagraphStyle *paraphStyle = [[NSMutableParagraphStyle alloc] init];
	[paraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
	[paraphStyle setAlignment:NSCenterTextAlignment];
	
	NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
	[attributes setObject:[NSFont systemFontOfSize:10] forKey:NSFontAttributeName];
	[attributes setObject:paraphStyle forKey:NSParagraphStyleAttributeName];
	[attributes setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
	[imageBrowser setValue:attributes forKey:IKImageBrowserCellsTitleAttributesKey];
	
	attributes = [[NSMutableDictionary alloc] init];
	[attributes setObject:[NSFont boldSystemFontOfSize:10] forKey:NSFontAttributeName];
	[attributes setObject:paraphStyle forKey:NSParagraphStyleAttributeName];
	[attributes setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
	
	[imageBrowser setValue:attributes forKey:IKImageBrowserCellsHighlightedTitleAttributesKey];
	
	//change intercell spacing
	[imageBrowser setIntercellSpacing:NSMakeSize(10, 10)];
	
	//change selection color
	[imageBrowser setValue:[NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:1.0] forKey:IKImageBrowserSelectionColorKey];
	
	//set initial zoom value
	[imageBrowser setZoomValue:0.25];
    
    [barView setTitle:@"Path Seleted"];
}

- (void)updateDatasource
{
    [images addObjectsFromArray:importedImages];
    [importedImages removeAllObjects];
    [imageBrowser reloadData];
}

- (IBAction)addClick:(id)sender
{
    NSOpenPanel *openPanel = [[NSOpenPanel alloc] init];
    [openPanel setCanChooseFiles:YES];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setAllowsMultipleSelection:YES];
    
    /*
    if ([openPanel runModal] == NSFileHandlingPanelOKButton)
    {
        NSArray *fileURLs = [openPanel URLs];
        NSMutableArray *filePaths = [NSMutableArray arrayWithCapacity:[fileURLs count]];
        for (NSURL *aUrl in fileURLs)
        {
            [filePaths addObject:[aUrl path]];
        }
        [self addImagesWithPaths:filePaths];
        [self updateDatasource];
    }
     */
    
    [openPanel beginSheetModalForWindow:[self.view window]
                      completionHandler:^(NSInteger result) {
                          if (result == NSOKButton)
                          {
                              NSArray *fileURLs = [openPanel URLs];
                              NSMutableArray *filePaths = [NSMutableArray arrayWithCapacity:[fileURLs count]];
                              for (NSURL *aUrl in fileURLs)
                              {
                                  [filePaths addObject:[aUrl path]];
                              }
                              [self addImagesWithPaths:filePaths];
                              [self updateDatasource];
                              
                          }
                      }];
}

- (IBAction)removeClick:(id)sender
{
    NSIndexSet *indexes = [imageBrowser selectionIndexes];
    [images removeObjectsAtIndexes:indexes];
    [self updateDatasource];
}

#pragma mark -
#pragma mark IKImageBrowserDataSource

// Implement the image browser  data source protocol .
// The data source representation is a simple mutable array.
// -------------------------------------------------------------------------
- (NSUInteger)numberOfItemsInImageBrowser:(IKImageBrowserView*)view
{
	// The item count to display is the datadsource item count.
    return [images count];
}

// -------------------------------------------------------------------------
//	imageBrowser:view:index:
// -------------------------------------------------------------------------
- (id)imageBrowser:(IKImageBrowserView *) view itemAtIndex:(NSUInteger) index
{
    return [images objectAtIndex:index];
}

// -------------------------------------------------------------------------
//	The user wants to delete images, so remove these entries from the data source.
// -------------------------------------------------------------------------
- (void)imageBrowser:(IKImageBrowserView*)view removeItemsAtIndexes: (NSIndexSet*)indexes
{
	[images removeObjectsAtIndexes:indexes];
}

// -------------------------------------------------------------------------
//	The user wants to reorder images, update the datadsource and the browser
//	will reflect our changes.
// -------------------------------------------------------------------------
- (BOOL)imageBrowser:(IKImageBrowserView*)view moveItemsAtIndexes: (NSIndexSet*)indexes toIndex:(unsigned int)destinationIndex
{
	NSInteger		index;
	NSMutableArray*	temporaryArray;
    
	temporaryArray = [[NSMutableArray alloc] init];
    
	// First remove items from the data source and keep them in a temporary array.
	for (index = [indexes lastIndex]; index != NSNotFound; index = [indexes indexLessThanIndex:index])
	{
		if (index < destinationIndex)
            destinationIndex --;
        
		id obj = [images objectAtIndex:index];
		[temporaryArray addObject:obj];
		[images removeObjectAtIndex:index];
	}
    
	// Then insert the removed items at the appropriate location.
	NSInteger n = [temporaryArray count];
	for (index = 0; index < n; index++)
	{
		[images insertObject:[temporaryArray objectAtIndex:index] atIndex:destinationIndex];
	}
    
	return YES;
}


#pragma mark -
#pragma mark drag n drop

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    return NSDragOperationCopy;
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
    return NSDragOperationCopy;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSData*			data = nil;
    NSPasteboard*	pasteboard = [sender draggingPasteboard];
    
	// Look for paths on the pasteboard.
    if ([[pasteboard types] containsObject:NSFilenamesPboardType])
        data = [pasteboard dataForType:NSFilenamesPboardType];
    
    if (data)
	{
		NSString* errorDescription;
		
		// Retrieve  paths.
        NSArray* filenames = [NSPropertyListSerialization propertyListFromData:data
                                                              mutabilityOption:kCFPropertyListImmutable
                                                                        format:nil
                                                              errorDescription:&errorDescription];
        
		// Add paths to the data source.
		[self addImagesWithPaths:filenames];
		
		// Make the image browser reload the data source.
        [self updateDatasource];
    }
    
	// Accept the drag operation.
	return YES;
}

- (void)addImagesWithPaths:(NSArray*)paths
{
    @autoreleasepool
    {
        for (int i = 0; i < [paths count]; i++)
        {
            NSString* path = [paths objectAtIndex:i];
            if ([[NSFileManager defaultManager] fileExistsAtPath:path])
            {
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"path == %@",path];
                NSArray *filteredArr = [images filteredArrayUsingPredicate:predicate];
                if ([filteredArr count] > 0)
                {
                    continue;
                }
                
                myImageObject* p = [[myImageObject alloc] init];
                [p setPath:path];
                [importedImages addObject:p];
            }
        }
    }
}

- (NSArray *)filePaths
{
    NSMutableArray *resultArray = [NSMutableArray arrayWithCapacity:[images count]];
    for (myImageObject *obj in images)
    {
        [resultArray addObject:[obj path]];
    }
    return resultArray;
}

@end
