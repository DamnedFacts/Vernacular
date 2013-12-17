//  THCanvasItem.h
//  Scrapbook
//
//  Created by Scott Stevenson on 3/22/05.
//  Released under a BSD-style license. See License.txt

#import <Cocoa/Cocoa.h>


@interface THCanvasItem : NSObject
{
	NSString * _filesystemPath;
	NSString * _label;
	NSRect     _bounds;
	NSRect     _flippedBounds;
	NSRect	   _boundsWithLabel;
	NSRect	   _flippedBoundsWithLabel;
	NSRect	   _rectForLabelDrawing;
	BOOL       _selected;
	unsigned   _layer;
	NSImage  * _defaultImage;
}


+ (THCanvasItem *) canvasItem;


#pragma mark Basic Accessors
@property (retain) id object;

// the layer property is a simple unsigned integer which keeps
// track of where the item is on a stack. when we handle a mouse
// click, this allows us to figure out which item the user
// mean to select. it also tells us which order to draw the
// items in.
//
// TODO: reset this value to a lower number whenever possible.
- (unsigned)layer;
- (void)setLayer:(unsigned)newLayer;

// selected means that the user clicked on the canvas item.
// it gets a selection rectangle and responds to keyboard
// events
- (BOOL)isSelected;
- (void)setSelected:(BOOL)newSelected;

// the image to display in the canvas view
- (NSImage *)defaultImage;
- (void)setDefaultImage:(NSImage *)newDefaultImage;

// the file path that the canvas item represents
- (NSString *)filesystemPath;
- (void)setFilesystemPath:(NSString *)newFilesystemPath;

// a label for display in the view. for now, the label is
// just the file name
- (NSString *)label;
- (void)setLabel:(NSString *)aValue;


#pragma mark Geometry Accessors

// by default, we return "unflipped" bounds, which means
// the coordinates start in the upper-left
- (NSRect)bounds;
- (void)setBounds:(NSRect)newBounds;

// use when setting bounds in recalculateFrameSize, use this
// to method to avoid infinite KVO notifications
- (void)setBoundsWithoutNotification:(NSRect)newBounds;

// the flipped variant of the bounds, where the coordinates
// start in the lower-left, as in PDF and PostScript
- (NSRect)flippedBounds;

// the rect for the label below the image
- (NSRect)rectForLabelDrawing;

// flipped and unflipped versions of bounds with the
// label rect taken into account
- (NSRect)boundsWithLabel;
- (NSRect)flippedBoundsWithLabel;

// get width and height from boundsWithLabel
- (float)width;
- (float)height;

// these return the minimum and maximum x/y values for the
// object using flippedBounds. this is useful for changing
// the frame size of the view so we can tell the scroll
// view to adjust the size of the scrollers.
- (float)minX;
- (float)minY;
- (float)maxX;
- (float)maxY;

@end
