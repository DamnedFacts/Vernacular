//
//  THCanvasView.h
//  Scrapbook
//
//  Created by Scott Stevenson on 3/19/05.
//  Released under a BSD-style license. See License.txt
//


// TODO: Doesn't handle case of window "un-zooming" very well if
//       content ends up out of sight after window size changes


#import <Cocoa/Cocoa.h>
#import "THCanvasItem.h"


@interface THCanvasView : NSView
{
    NSMutableArray      * _canvasItems;
    NSMutableArray      * _selectedItems;
    NSIndexSet          * _selectionIndexes;            
	unsigned              _itemWidth;
    NSColor             * _backgroundColor;
	NSColor				* _borderColor;
	NSDictionary		* _itemLabelAttributes;
	NSDictionary		* _itemLabelAttributesForDragging;
    NSArray             * _imageFileTypes;

    // stores key path info for bound items
    NSMutableDictionary * _bindingsInfo;
}

#pragma mark Canvas Items

// the items that are drawn on the canvas. may contain image data
// for icons, photos, etc.
- (NSMutableArray *) canvasItems;
- (void) setCanvasItems:(NSArray *)newItems;

// alternate accessors. similar to action methods.
- (void) addCanvasItem: (THCanvasItem *)item;
- (void) removeCanvasItem: (THCanvasItem *)item;
- (void) addCanvasItems: (NSArray *)items;
- (void) removeCanvasItems: (NSArray *)theItems;

#pragma mark Selections

// a straight array of the selected items
- (NSMutableArray *) selectedItems;
- (void) setSelectedItems: (NSMutableArray *)newItems;

// a set of the selected items. particularly useful for bindings
// and array controllers. (TODO: may not be fully implemented)
- (NSIndexSet *) selectionIndexes;
- (void) setSelectionIndexes: (NSIndexSet *)newIndexes;

// alternate accessors. similar to action methods.
- (void) selectItem: (THCanvasItem *)item;
- (void) deselectItem: (THCanvasItem *)item;
- (void) selectItems: (NSArray *)theItems;
- (void) deselectItems: (NSArray *)theItems;

#pragma mark Simple Accessors

// current size of the items drawn in the canvas. used by bindings
- (unsigned)itemWidth;
- (void)setItemWidth:(unsigned)newItenWidth;

// general style elements
- (NSColor *) backgroundColor;
- (void) setBackgroundColor: (NSColor *)newColor;
- (NSColor *)borderColor;
- (void)setBorderColor:(NSColor *)aValue;

// text attributes for image labels
- (NSDictionary *)itemLabelAttributes;
- (void)setItemLabelAttributes:(NSDictionary *)aValue;

// the text attributes for dragging are different so that
// the item is drawn semi-transparent
- (NSDictionary *)itemLabelAttributesForDragging;
- (void)setItemLabelAttributesForDragging:(NSDictionary *)aValue;

@end
