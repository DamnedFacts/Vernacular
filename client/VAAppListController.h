//
//  VernacularAppsViewer.h
//  Vernacular
//
//  Created by Richard Sarkis on 7/13/13.
//
//

#import <Foundation/Foundation.h>
@class THCanvasView;

@interface VAAppListController : NSObject {
    IBOutlet THCanvasView *canvasView;
    IBOutlet NSArrayController *canvasItemsController;
}

@property unsigned itemWidth;
@property (retain) NSMutableArray *canvasItems;

- (BOOL) performAddItem: (id) theItem;
- (NSMutableArray *)canvasItems;
- (void)setCanvasItems:(NSMutableArray *)aValue;

@end
