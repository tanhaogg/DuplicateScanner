//
//  THPathSelectedView.h
//  image-browser-appearance
//
//  Created by TanHao on 12-11-12.
//
//

#import <Cocoa/Cocoa.h>
#import "ImageBrowserView.h"

@class THBarView;
@interface THPathSelectedViewController : NSViewController
{
    IBOutlet THBarView *barView;
    IBOutlet ImageBrowserView *imageBrowser;
    NSMutableArray   *images;
    NSMutableArray   *importedImages;
}
- (IBAction)addClick:(id)sender;
- (IBAction)removeClick:(id)sender;

- (NSArray *)filePaths;

@end
