//
//  VernacularAppsViewer.m
//  Vernacular
//
//  Created by Richard Sarkis on 7/13/13.
//
//

#import "VAAppListController.h"
#import "THCanvasView.h"
#import "ApplicationShim.h"

@implementation VAAppListController
@synthesize itemWidth;
@synthesize canvasItems;
- (id)init
{
    if (self = [super init])
    {
        canvasItems = nil;
        itemWidth = 128;
    }
    return self;
}

- (void) awakeFromNib
{
    [canvasView bind: @"canvasItems"
            toObject: canvasItemsController
         withKeyPath: @"arrangedObjects"
             options: nil];
    
    [canvasView bind: @"itemWidth"
            toObject: self
         withKeyPath: @"itemWidth"
             options: nil];
    
    
    [self setCanvasItems: [NSMutableArray array]];
}


- (BOOL) performAddItem: (ApplicationShim *) theItem
{
    THCanvasItem * item   = nil;

    NSPoint   dropPoint;
    NSRect    itemBounds;
    
    // we have accepted the drop, so we can put the canvas
    // back to the original color
    
    dropPoint = NSMakePoint(0, 0);
    
    NSImage* image = [theItem appIcon];
    NSSize imageSize = NSMakeSize ([self itemWidth], [self itemWidth]);
    
    // make a new item and set its path
    item = [THCanvasItem canvasItem];
    [item setFilesystemPath: [theItem uriPrefix]];
    [image setSize:imageSize];
    [item setDefaultImage: image];
    
    itemBounds = NSMakeRect (dropPoint.x - imageSize.width,
                             dropPoint.y + imageSize.height,
                             imageSize.width,
                             imageSize.height );
    
    [item setBounds: itemBounds];
    [item setLayer:0];
    [item setLabel:[theItem appName]];
    [item setObject:theItem];
    
    // hand off the array of items to add
    [canvasView addCanvasItem: item];
    
    return YES;
}

- (void) clearCanvasItems {
    [canvasView removeCanvasItems: canvasItems];
}
@end
