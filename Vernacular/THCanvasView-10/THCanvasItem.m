//
//  THCanvasItem.m
//  Scrapbook
//
//  Created by Scott Stevenson on 3/22/05.
//  Released under a BSD-style license. See License.txt
//

#import "THCanvasItem.h"

// these are accessors that we don't really want
// called from the outside

@interface THCanvasItem (PrivateAccessors)
- (void)_coreSetBounds: (NSRect)newBounds;
- (void)_setFlippedBounds:(NSRect)newBounds;
- (void)_setRectForLabelDrawing:(NSRect)newRectForLabelDrawing;
- (void)_setBoundsWithLabel:(NSRect)newBoundsWithLabel;
- (void)_setFlippedBoundsWithLabel:(NSRect)newFlippedBoundsWithLabel;
@end


@implementation THCanvasItem
@synthesize object;

+ (void) initialize
{
	// when the "bounds" key changes, anybody who is observing
	// us using KVO will want to know "flippedBounds" changed as well
	
	[self setKeys: [NSArray arrayWithObject: @"bounds"]
		triggerChangeNotificationsForDependentKey: @"flippedBounds"];
		
	[self exposeBinding: @"bounds"];
	[self exposeBinding: @"flippedBounds"];
}

+ (THCanvasItem *) canvasItem
{
	return [[self alloc] init];
}



- (id) init
{
	if (self = [super init])
	{
        NSRect defaultRect = NSZeroRect;
		
		_filesystemPath			= nil;
		_label					= nil;
        _bounds					= defaultRect;
        _flippedBounds			= defaultRect;
		_boundsWithLabel		= defaultRect;
		_flippedBoundsWithLabel = defaultRect;
		_rectForLabelDrawing	= defaultRect;
        _selected				= NO;
        _layer					= 0;
        _defaultImage			= nil;
	}
	return self;
}

- (void) dealloc
{
	[self setFilesystemPath: nil];
	[self setLabel: nil];
	[self setDefaultImage: nil];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"CanvasItem: <%p> %u", self, [self layer]];
}


#pragma mark -
#pragma mark Basic Accessors


// the layer property is a simple unsigned integer which keeps
// track of where the item is on a stack. when we handle a mouse
// click, this allows us to figure out which item the user
// mean to select. it also tells us which order to draw the
// items in.
- (unsigned) layer
{
	return _layer;
}

- (void) setLayer: (unsigned)newLayer
{
	_layer = newLayer;
}

// selected means that the user clicked on the canvas item.
// it gets a selection rectangle and responds to keyboard
// events
- (BOOL) isSelected
{
	return _selected;
}

- (void) setSelected: (BOOL)newSelected
{
	_selected = newSelected;
}

// the image to display in the canvas view
- (NSImage *) defaultImage
{
	return _defaultImage;
}

- (void) setDefaultImage: (NSImage *)newImage
{
	_defaultImage = [newImage copy];
	[_defaultImage setFlipped:YES];
}

// the file path that the canvas item represents
- (NSString *)filesystemPath {
	return _filesystemPath;
}

- (void)setFilesystemPath:(NSString *)newFilesystemPath
{
	_filesystemPath = [newFilesystemPath copy];

	// we want to set the label to be the filename	
	[self setLabel: [_filesystemPath lastPathComponent]];
}

// a label for display in the view. for now, the label is
// just the file name
- (NSString *) label
{
	return _label;
}

- (void) setLabel:(NSString *)aValue
{
	_label = [aValue copy];
}



#pragma mark -
#pragma mark Geometry Accessors

// by default, we return "unflipped" bounds, which means
// the coordinates start in the upper-left
- (NSRect) bounds
{
	return _bounds;
}

- (void) setBounds: (NSRect)newBounds
{
    [self _coreSetBounds: newBounds];
}

// use when setting bounds in recalculateFrameSize, use this
// to method to avoid infinite KVO notifications
- (void)setBoundsWithoutNotification:(NSRect)newBounds
{
	// this method name is not KVO compliant so it shouldn't
	// generate a KVO event
    [self _coreSetBounds: newBounds];
}

// the flipped variant of the bounds, where the coordinates
// start in the lower-left, as in PDF and PostScript
- (NSRect)flippedBounds
{
	return _flippedBounds;
}

// the rect for the label below the image
-(NSRect)rectForLabelDrawing
{
	return _rectForLabelDrawing;
}

// flipped and unflipped versions of bounds with the
// label rect taken into account
-(NSRect)boundsWithLabel {
	return _boundsWithLabel;
}

-(NSRect)flippedBoundsWithLabel {
	return _flippedBoundsWithLabel;
}

// get width and height from boundsWithLabel
- (float)width
{
	return [self flippedBoundsWithLabel].size.width;
}

- (float)height
{
	return [self flippedBoundsWithLabel].size.height;
}


// these return the minimum and maximum x/y values for the
// object using flippedBounds. this is useful for changing
// the frame size of the view so we can tell the scroll
// view to adjust the size of the scrollers.
- (float)minX
{
	return [self flippedBoundsWithLabel].origin.x;
}

- (float)minY
{
	return [self flippedBoundsWithLabel].origin.y;
}

- (float)maxX
{
	NSRect bounds = [self flippedBoundsWithLabel];
	return (bounds.origin.x + bounds.size.width);
}

- (float)maxY
{
	NSRect flippedBounds = [self flippedBoundsWithLabel];
	return (flippedBounds.origin.y + flippedBounds.size.height);
}



#pragma mark -
#pragma mark Private Accessors


- (void)_coreSetBounds: (NSRect)newBounds
{
    _bounds = newBounds;
            
	// create a flipped version too. used for background
	// drawing and hit testing
	float height = NSHeight ( _bounds );      
	NSRect flippedRect = NSOffsetRect ( _bounds, 0, -height );
	[self _setFlippedBounds: flippedRect];

	// make a rect for drawing the label under the item
	NSRect flippedLabelRect;
	flippedLabelRect = flippedRect;
	flippedLabelRect.origin.y += (flippedLabelRect.size.height + 5);
	flippedLabelRect.size.height = 50;
	[self _setRectForLabelDrawing: flippedLabelRect];

	// set rect for flippedBounds + flippedLabel. this is one
	// of the most important ones for the camvas view
	NSRect flippedBoundsWithLabel = NSUnionRect ( flippedRect, flippedLabelRect );
	[self _setFlippedBoundsWithLabel: flippedBoundsWithLabel];

	// set an equivalent version for 'unflipped' coordinate systems,
	// just in case we need it somewhere
	NSRect labelRect = _bounds;
	labelRect.origin.y += (labelRect.size.height + 5);
	labelRect.size.height = 50;		
	
	NSRect boundsWithLabel = NSUnionRect ( _bounds, labelRect );
    [self _setBoundsWithLabel: boundsWithLabel];	
}


- (void)_setFlippedBounds: (NSRect)newBounds
{
	_flippedBounds = newBounds;
}

-(void)_setRectForLabelDrawing:(NSRect)newRectForLabelDrawing
{
	_rectForLabelDrawing = newRectForLabelDrawing;
}

-(void)_setBoundsWithLabel:(NSRect)newBoundsWithLabel {
	_boundsWithLabel = newBoundsWithLabel;
}

-(void)_setFlippedBoundsWithLabel:(NSRect)newFlippedBoundsWithLabel {
	_flippedBoundsWithLabel = newFlippedBoundsWithLabel;
}

@end
