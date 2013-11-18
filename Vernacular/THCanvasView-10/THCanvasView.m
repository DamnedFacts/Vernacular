//
//  THCanvasView.m
//  Scrapbook
//
//  Created by Scott Stevenson on 3/19/05.
//  Released under a BSD-style license. See License.txt
//


#import "THCanvasView.h"
#import "THCanvasItem.h"
#import "NSBezierPath+RoundRect.h"
#import "NSSortDescriptor+Layers.h"
#import "NSImage-Extras.h"
#import "VADefines.h"

#pragma mark Constants

// pasteboard types
NSString * THCanvasItemsPboardType = @"THCanvasItemsPboardType";
static NSArray * THCanvasDraggedTypes = nil;

// contexts for key-value observing. these numbers
// are mostly just made up
static void * CanvasItemsObservationContext             = (void *)4080;
static void * CanvasItemAttributesObservationContext    = (void *)6500;
// static void * SelectedIndexesObservationContext         = (void *)4150;

// keys to observe on items which require us to redraw
// this variable is populated in +initialize
static NSArray * DrawingAttributeKeys = nil;



#pragma mark Private Category Definitions

@interface THCanvasView (PrivateUtilities)
// pass in a point from a mouse event in and get back
// a canvas item, or nil
- (THCanvasItem *)_canvasItemAtPoint: (NSPoint)point;
// checks to see if two items overlap. this is useful for
// setting the layer of one item higher than another.
- (THCanvasItem *)_itemIntersectingItem:(THCanvasItem *)testItem;
// this gets called when we need to set a new frame size
// for the scroll view
- (void)_recalculateFrameSize;
// called when the global canvas item size is adjusted.
// sets new bounds for all items then recalculates frame.
- (void)_rebuildCanvasItemsWithNewItemWidth;
// creates text attributes for canvas item labels
- (void)_setupItemLabelAttributes;
@end

@interface THCanvasView (PrivateBindings)
// become/resign observer for canvas items so that we can
// easily recalculate and redraw when their properties change
- (void)_becomeObserverForCanvasItems: (NSArray *)newItems;
- (void)_resignObserverForCanvasItems: (NSArray *)theItems;
@end

@interface THCanvasView (PrivateAccessors)
// key path info for the controllers we're bound to
- (NSMutableDictionary *)_bindingsInfo;
- (void)_setBindingsInfo: (NSMutableDictionary *)newBindingsInfo;
// a list of UTI types that we can probably open with NSImage.
// see http://developer.apple.com/macosx/uniformtypeidentifiers.html for
// more info on UTI types.
- (NSArray*)_imageFileTypes;
- (void)_setImageFileTypes:(NSArray*)aValue;
@end




#pragma mark Class Definition

@implementation THCanvasView

+ (void) initialize
{        
	// +initialize is a class method that is called once, when the
	// class (not the object) is created at runtime. in this case,
	// we're assigning NSArray objects to global variables

	THCanvasDraggedTypes = [[NSArray alloc] initWithObjects:
	        THCanvasItemsPboardType, NSFilenamesPboardType, nil];

	DrawingAttributeKeys = [[NSArray alloc] initWithObjects:
	        @"selected", @"layer", @"defaultImage", @"bounds", nil];

	// here we are exposing bindings for NSControllers to use
	[self exposeBinding: @"canvasItems"];
	[self exposeBinding: @"selectionIndexes"];
}


#pragma mark -
#pragma mark Standard NSView Methods

// these methods are inherited, so there's no
// need to declare them in the header

- (id) initWithFrame: (NSRect)frame
{
	// NSView subclasses use -initWithFrame: instead of just -init        
	if (self = [super initWithFrame: frame])
	{
	    // set initial styling options
		[self setBackgroundColor: [NSColor colorWithCalibratedWhite:0.96 alpha:1.0]]; 
		[self setBorderColor: [NSColor darkGrayColor]]; 
		
		// this allows us to declare which type of pasteboard types we support
		[self registerForDraggedTypes: THCanvasDraggedTypes];
		
		// start with an empty set of canvas items and an empty set of selections		
		[self setCanvasItems: [NSMutableArray array]];
		[self setSelectedItems: [NSMutableArray array]];
		[self setItemWidth: 128];

		// configure text attributes
		[self _setupItemLabelAttributes];
		
		// this dictionary will hold all of our KVO/KVB info
		[self _setBindingsInfo: [NSMutableDictionary dictionary]];
	}
	return self;
}


- (void)awakeFromNib
{	
	// we need to know when the scroll view is resized, so we
	// need it to actually post these notifications
	[[self enclosingScrollView] setPostsFrameChangedNotifications:YES];
	
    // now that the notifications have been turned on, we
    // will subscribe to them.
	NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
	[nc addObserver: self
		   selector: @selector(scrollViewChanged:)
			   name: NSViewFrameDidChangeNotification
			 object: nil];

    // this is an array of UTI file types provided by the ImageIO framework.
    // see http://developer.apple.com/macosx/uniformtypeidentifiers.html for
    // more info on UTI types.
    NSArray* types = (__bridge NSArray*)CGImageSourceCopyTypeIdentifiers();
    [self _setImageFileTypes:types];
}

- (void) dealloc
{
	[self unregisterDraggedTypes];

	// NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    // [nc removeObserver:self];

	[self setCanvasItems:nil];
	[self setSelectedItems:nil];
    [self setSelectionIndexes:nil];
    [self setBackgroundColor:nil];
    [self setBorderColor:nil];
    [self setItemLabelAttributes:nil];
    [self setItemLabelAttributesForDragging:nil];
    [self _setImageFileTypes:nil];
	[self _setBindingsInfo:nil];
	
}


- (void) drawRect: (NSRect)rect
{       
    // draw the highest-quality images
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
        
    // fill background        
    [[self backgroundColor] set];
    NSRectFill ([self bounds]);        

    // get the list of items and the sort descriptor which
    // orders the items by the canvas item "layer" property
    NSArray* myItems = [self canvasItems];
    NSArray* sort = [NSSortDescriptor ascendingDescriptorsForKeys:@"layer",nil];
    myItems = [myItems sortedArrayUsingDescriptors:sort];

    // get text attributes and setup the basic string
    NSDictionary * attrs = [self itemLabelAttributes];
    NSMutableAttributedString * labelString;
    labelString = [[NSMutableAttributedString alloc] initWithString:@"Item" attributes:attrs];
    NSMutableString * stringStorage = [labelString mutableString];

    // loop through all of the canvas items
    unsigned i, count = [myItems count];
    for ( i = 0; i < count; i++ )                
    {
        THCanvasItem* item = [myItems objectAtIndex: i];

        if ( [item isSelected] )
        {
            // if the item is selected, draw a round rect behind it
            [[NSColor colorWithCalibratedWhite:0.8 alpha:0.5] set];

            NSBezierPath * path = nil;
            path = [NSBezierPath bezierPathWithRoundRectInRect: [item flippedBounds]
                                                        radius: 8];
            [path fill];
        }

        // draw the image to screen, blending over any
        // other canvas items underneath

        [[item defaultImage] drawInRect: [item flippedBounds]
                               fromRect: NSZeroRect
                              operation: NSCompositeSourceOver
                               fraction: 1.0];

        [stringStorage setString: [item label]];
        [labelString drawInRect: [item rectForLabelDrawing]];
    }
}

- (BOOL) isFlipped
{
    // return YES: coordinates start in upper-left of view
    // return NO:  coordinates start in lower-left of view

    return YES;
}

- (BOOL) acceptsFirstResponder
{
    // return YES: the view can be selected
    // return NO:  the view cannot be selected

    return YES;
}

- (void) keyDown: (NSEvent *)event
{        
    // which key was pressed?
    unichar key = [[event charactersIgnoringModifiers] characterAtIndex: 0];
        
    // if delete was pressed, remove the selected items        
    if ( key == NSDeleteCharacter )
    {
        [self removeCanvasItems: [self selectedItems]]; 
    }
}

- (void) mouseDown: (NSEvent *) event
{        
    // figure out if the mouse pointer was over a canvas item
    // when it was clicked. if it was, select the item
            
    NSPoint location = [self convertPoint:[event locationInWindow] fromView:nil];
    THCanvasItem * clickedItem = [self _canvasItemAtPoint: location];        

    if (clickedItem != nil)
    {
        // when the user clicks a canvas item, it move to the
        // top of the stack, just like in the finder.
        THCanvasItem * underItem = [self _itemIntersectingItem: clickedItem];
        [self selectItem: clickedItem];

        if ( underItem != nil ) {
            [clickedItem setLayer: ([underItem layer] + 1)];
        } else {
            [clickedItem setLayer: 0];
        }
    }

    // if we received a double-click, open whatever the item is    
    if ([event clickCount] > 1)
    {
        if ([self isValidUrl:[clickedItem filesystemPath]]) {
            NSLog(@"Clicked URL: %@", [clickedItem filesystemPath]);
            [[NSNotificationCenter defaultCenter] postNotificationName:VAAppSelectedNotification
                                                                object: @{@"window":self, @"object":[clickedItem object]}
                                                          userInfo: nil];

        }
        NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
        [workspace openFile: [clickedItem filesystemPath]];
        
    }

    // deselect everything else. could expand this to consider multiple
    // selection if the command or shift key is held down
            
    NSMutableArray * itemsToDeselect = [[self canvasItems] mutableCopy];
    [itemsToDeselect removeObject: clickedItem];        
    [self deselectItems: itemsToDeselect];
    
}

-(BOOL) isValidUrl: (NSString *)location
{
    // replace content with its intValue ( or process the input's value differently )
    NSURL *candidateURL = [NSURL URLWithString:location];
    // WARNING > "test" is an URL according to RFCs, being just a path
    // so you still should check scheme and all other NSURL attributes you need
    if (candidateURL && candidateURL.scheme && candidateURL.host) {
        // candidate is a well-formed url with:
        //  - a scheme (like http://)
        //  - a host (like stackoverflow.com)
        if (![candidateURL.scheme isEqualToString:@"ws"] &&
            ![candidateURL.scheme isEqualToString:@"wss"] &&
            ![candidateURL.scheme isEqualToString:@"http"] &&
            ![candidateURL.scheme isEqualToString:@"https"]) {
            return NO;
        } else {
            return YES;
        }
    }
    return NO;
}

// this action is automatically wired up in the Edit menu.
// if we implement it here, it will be found in the responder
// chain and automatically validated. if we don't implement
// it, the menu item will be grayed out.

- (IBAction)selectAll:(id)sender
{
    [self selectItems:[self canvasItems]];
}

- (void)reflectScrolledClipView:(NSClipView *)aClipView
{
    [super reflectScrolledClipView:aClipView];
    if ([self inLiveResize] == NO)
    {
        [self _recalculateFrameSize];
    }
}

- (void)scrollViewChanged:(NSNotification *)note
{
    if ( [self inLiveResize] && [[self canvasItems] count] > 0 )
    {
        [self _recalculateFrameSize];            
    }
}


#pragma mark -
#pragma mark Standard Drag and Drop

- (void) mouseDragged: (NSEvent *)event
{
    // this method is called continuously when the user holds down
    // the mouse button and drags mouse inside the view

    // first, we need to get the latest x/y coordinate for the drag event
    NSPoint location = [self convertPoint:[event locationInWindow] fromView:nil];
    THCanvasItem * item  = [self _canvasItemAtPoint:location];
    
    // if we didn't find an item at this location, we can
    // just bail out of the method
    if (item == nil) return;

    // if we do have an item, get the dragging pasteboard
    // and declare the type we want to use
    NSPasteboard *pboard = [NSPasteboard pasteboardWithName: NSDragPboard];        
    [pboard declareTypes:[NSArray arrayWithObject:THCanvasItemsPboardType] owner:self];

    // no need to write the entire object to the pasteboard for now.
    // instead, just write the number that represents its location
    // in the canvasItem array   
    int index = [[self canvasItems] indexOfObject: item];
    NSNumber * itemNumber = [NSNumber numberWithInt: index];

    [pboard setPropertyList: itemNumber
                    forType: THCanvasItemsPboardType];

    // get text attributes and setup the basic string
    NSDictionary * attrs = [self itemLabelAttributesForDragging];
    NSMutableAttributedString * labelString;
    labelString = [[NSMutableAttributedString alloc] initWithString:[item label] attributes:attrs];
       
    // now we generate an image to display as the mouse is dragged around
    unsigned itemWidth = [self itemWidth];
    NSSize theSize = NSMakeSize ( itemWidth, 200 );
    NSImage *theImage = [[NSImage alloc] initWithSize:theSize];

    // lock focus on the image and draw into it
    [theImage lockFocus];
    
        [theImage setFlipped:YES];

        // 200 - 128 = 72
        // 128 + 50 + 5 = 183 -- total for all content
        // 200 - 183 - 17
            
        [[item defaultImage] drawInRect: NSMakeRect (0,0,itemWidth,itemWidth)
                               fromRect: NSZeroRect
                              operation: NSCompositeSourceOver
                               fraction: 0.35];
       
        // since we're drawing into a flipped view, we need to
        // translate the coord system before drawing text, otherwise
        // it will be upside-down
                
        NSAffineTransform* xform = [NSAffineTransform transform];
        [xform translateXBy:0.0 yBy:(itemWidth + 60)];
        [xform scaleXBy:1.0 yBy:-1.0];
        [xform concat];
        [labelString drawInRect: NSMakeRect (0,0,itemWidth,55)];
       
    [theImage unlockFocus];


    NSPoint placeForDragImage = [item boundsWithLabel].origin;
    placeForDragImage.y += (200 - itemWidth);

    // activate the drag image
    [self dragImage: theImage
                 at: placeForDragImage
             offset: NSZeroSize
              event: event
         pasteboard: [NSPasteboard pasteboardWithName:NSDragPboard]
             source: self
          slideBack: YES]; // use 'snap back' animation if drop doesn't complete

}


- (NSDragOperation) draggingEntered: (id <NSDraggingInfo>)sender
{
    if ( [sender draggingSource] == self )
    {
        // if the dragging source is 'self', we're probably
        // just repositioning an item

        return NSDragOperationGeneric;
    }

    if ((NSDragOperationGeneric & [sender draggingSourceOperationMask]) == NSDragOperationGeneric)
    {
        // looks like we're getting a file drop from somewhere
        // set the background color to grey to indicate we're ready for
        // the drop, then return a 'copy' drag operation so that the
        // mouse pointer gets a "plus" icon. this tells the user
        // that the original will not be moved.

        [self setBackgroundColor:[NSColor controlHighlightColor]];
        [self setNeedsDisplay:YES];
                
        return NSDragOperationCopy;                
    }

    // if both of the other tests failed, we received some other
    // kind of drag operation, so just deny the drop        
    return NSDragOperationNone;        
}

- (void) draggingExited: (id <NSDraggingInfo>) sender
{
    // this is called if an item is dragged over the canvas
    // and then dragged out without dropping. all we need to
    // do is put the canvas back to its default color

    [self setBackgroundColor: [NSColor colorWithCalibratedWhite:0.96 alpha:1.0]]; 
    [self setNeedsDisplay: YES];
}

- (BOOL) performDragOperation: (id <NSDraggingInfo>) sender
{
    NSPasteboard * pboard = [sender draggingPasteboard];
    THCanvasItem * item   = nil;
    THCanvasItem * underItem = nil;

    NSPoint   dropPoint;
    NSRect    itemBounds;
    unsigned  itemLayer = 0;        
        
    // we have accepted the drop, so we can put the canvas
    // back to the original color
    
    [self setBackgroundColor: [NSColor colorWithCalibratedWhite:0.96 alpha:1.0]];
                
    if ( [sender draggingSource] == self )
    {
        // we have to use -convertPoint:fromView: because our view is 'flipped',
        // meaning the coordinates start at the upper-left
        //
        // we use -draggedImageLocation so that the item is placed
        // exactly at the point the user dropped it
        
        dropPoint = [self convertPoint: [sender draggedImageLocation] fromView: nil];

        // get the index of the item which was dragged. the index is its location
        // in the "canvas items" array
        NSNumber * itemNumber  = [pboard propertyListForType: THCanvasItemsPboardType];
        if ( !itemNumber ) return NO;
        int index = [itemNumber intValue];

        // use the index to retrieve the canvas item that was dragged
        item = [[self canvasItems] objectAtIndex: index];

        // 'bounds' is the rectangle on the canvas that the item will be drawn in

        unsigned itemWidth = [self itemWidth];          
        itemBounds = NSMakeRect ( dropPoint.x, dropPoint.y - (200-itemWidth), itemWidth, itemWidth);
        [item setBounds: itemBounds];

        // if there's an item already here, make sure our new item
        // will be placed above the existing one
        
        underItem = [self _itemIntersectingItem: item];

        if ( underItem != nil ) {
            [item setLayer: ([underItem layer] + 1)];
        } else {
            [item setLayer: 0];
        }
        return YES;
    }

    // if we got to this point, the drag is coming from the
    // outside somewhere this particular view. we'll treat
    // these as filesystem items
        
    // we use -draggingLocation when receiving drops from
    // external sources. using -draggedImageLocation would
    // put it at the wrong place
    
    dropPoint = [self convertPoint: [sender draggingLocation]
                          fromView: nil];        
    
    // try to get an array of file paths
            
    NSArray * fileArray = [pboard propertyListForType: NSFilenamesPboardType];
    unsigned fileArrayCount = [fileArray count];
    if ( fileArray == nil || fileArrayCount < 1 ) return NO;
    
    NSMutableArray* itemsToAdd = [NSMutableArray array];    
    NSWorkspace* workspace = [NSWorkspace sharedWorkspace];

    // properties for the canvas item

    unsigned itemWidth = [self itemWidth];
    unsigned halfItemWidth = (itemWidth * 0.5);    
        
    NSString* path = nil;
    NSImage* image = nil;
    NSSize imageSize = NSMakeSize (itemWidth,itemWidth);

    // if there's an item already here, make sure our new item
    // will be placed above the existing one        
    underItem = [self _canvasItemAtPoint: dropPoint];

    if ( underItem != nil ) {
        itemLayer = ([underItem layer] + 1);
    } else {
        itemLayer = 0;
    }

    // a list of UTI types which NSImage is likely able to open
    NSArray* imageFileTypes = [self _imageFileTypes];
    
    // loop through all of the files the user dropped
    // on the view.
    
    unsigned i;
    for ( i = 0; i < fileArrayCount; i++ )
    {
        // make a new item and set its path                
        item = [THCanvasItem canvasItem];
        path = [fileArray objectAtIndex:i];
        if ( path == nil || [path isEqualToString:@""] ) return NO;
        [item setFilesystemPath: path];

        // is this file an image type?
        NSString* utiTypeForFile = (__bridge NSString*)UTTypeCreatePreferredIdentifierForTag (
            kUTTagClassFilenameExtension,
            (__bridge CFStringRef)[path pathExtension],
            NULL);

        // if this does look like an image, use the preview instead of
        // the Finder icon. if it's not an image, just use the icon.
        if ( [imageFileTypes containsObject:utiTypeForFile] == YES )
        {            
            image = [[NSImage alloc] initWithContentsOfFile:path];
            image = [image imageByScalingProportionallyToSize:imageSize flipped:YES];
        } else {
            image = [workspace iconForFile:path];
        }

        [image setSize:imageSize];
        [item setDefaultImage: image];             

        // set layer for current item, then increment the
        // layer value for the next time through        
        [item setLayer:itemLayer];
        itemLayer++;

        // figure out where to position this item. center it
        // at the drop point by chopping adjusting by half
        // its width and height.
        //
        // we add (i*20) to make sure the items don't stack
        // directly on top of of each other. item 0 will be at
        // the center, item 1 will be 20 pixels lower and to
        // the right, item 2 will be 40 pixels lower and to the
        // right, and so on.
                
        itemBounds = NSMakeRect ( dropPoint.x - halfItemWidth + (i*20),
                                  dropPoint.y + halfItemWidth + (i*20),
                                  imageSize.width,
                                  imageSize.height );

        [item setBounds: itemBounds];
        [itemsToAdd addObject:item];        
    }

    // hand off the array of items to add
    [self addCanvasItems: itemsToAdd];

    return YES;
}


#pragma mark -
#pragma mark Bindings Support

- (void) observeValueForKeyPath: (NSString *)keyPath ofObject: (id)controller change: (NSDictionary *)change context: (void *)context

{
    // this method can be thought of as a "did change" notification.
    // if the current set of canvas items changed, we need to adjust our KVO
    // subscriptions. if just an attribute of an item changed (such as
    // position), we only need to redraw
    
    if ( context == CanvasItemsObservationContext )
    {
        NSArray * newestFullArray    = [controller valueForKeyPath: keyPath];
        NSArray * previousFullArray  = [self canvasItems];

        // make a copy of the newest "current" set of items, and remove
        // the ones we were observing before. the result is an array of
        // just the new additions. start observing just the new items
        
        NSMutableArray * justNewItems = [newestFullArray mutableCopy];                
        [justNewItems removeObjectsInArray: previousFullArray];                
        [self _becomeObserverForCanvasItems: justNewItems];

        // get an array of the items we already knew about, then remove
        // the objects in the newest full array. this will leave us
        // with a list of objects we no longer need to observe
        
        NSMutableArray * removedItems = [previousFullArray mutableCopy];                
        [removedItems removeObjectsInArray: newestFullArray];                
        [self _resignObserverForCanvasItems: removedItems];

        // finally, set the array of all items as our "cached" copy
        
        [self setCanvasItems: newestFullArray];
        [self _recalculateFrameSize];
        return;
    }

    if ( context == CanvasItemAttributesObservationContext )
    {
        // if we got this context, it just means that one of the canvas
        // items changed in a way which requires a redraw. we could be
        // more efficent about this by only redrawing the affected canvas
        // item, but we're going to just redraw the whole thing

        [self _recalculateFrameSize];
        return;
    }
    
}


- (void) bind: (NSString *)attribute toObject: (id)controller withKeyPath: (NSString *)keyPath options: (NSDictionary *)options
{
    // if a controller is trying to bind to our array of canvas items, tuck
    // the subscription info away in a simple dictionary
    
    if ([attribute isEqualToString:@"canvasItems"])
    {
        [self setValue: controller
            forKeyPath: @"bindingsInfo.canvasItemsController"];

        [self setValue: keyPath
            forKeyPath: @"bindingsInfo.canvasItemsKeyPath"];

        [controller addObserver: self
                     forKeyPath: keyPath
                        options: (NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                        context: CanvasItemsObservationContext];
    } else {
        [super bind:attribute toObject:controller withKeyPath:keyPath options:options];
    }        
}



#pragma mark -
#pragma mark Canvas Items

// the items that are drawn on the canvas. may contain image data
// for icons, photos, etc.

- (NSMutableArray *) canvasItems
{
    return _canvasItems;
}

- (void) setCanvasItems: (NSArray *)newItems
{
    _canvasItems = [newItems mutableCopy];
}

// alternate accessors. similar to action methods. note
// that we can use "bindingsInfo" as a key, even though
// the actually method is "_bindingsInfo". KVC can figure
// it out.

- (void) addCanvasItem: (THCanvasItem *)item
{
    id controller = [self valueForKeyPath: @"bindingsInfo.canvasItemsController"];
    [controller addObject: item];
}

- (void) removeCanvasItem: (THCanvasItem *)item
{
    id controller = [self valueForKeyPath: @"bindingsInfo.canvasItemsController"];
    [controller removeObject: item];
}

- (void) addCanvasItems: (NSArray *)items
{
    id controller = [self valueForKeyPath: @"bindingsInfo.canvasItemsController"];
    [controller addObjects: items]; 
}

- (void) removeCanvasItems: (NSArray *)theItems
{
    id controller = [self valueForKeyPath: @"bindingsInfo.canvasItemsController"];
    [controller removeObjects: theItems];
}



#pragma mark -
#pragma mark Selections

// a straight array of the selected items

- (NSMutableArray *) selectedItems
{
    return _selectedItems;
}

- (void) setSelectedItems: (NSMutableArray *)newItems
{
    _selectedItems = [newItems mutableCopy];
}

// a set of the selected items. particularly useful for bindings
// and array controllers. (TODO: may not be fully implemented)

- (NSIndexSet *) selectionIndexes
{
    return _selectionIndexes;
}

- (void) setSelectionIndexes: (NSIndexSet *)newIndexes
{
    _selectionIndexes = [newIndexes copy];
}

// alternate accessors. similar to action methods.

- (void) selectItem: (THCanvasItem *)item
{
    if (!item) return;

    // 1. set the selected flag on the item
    // 2. add to selectedItems array
    // 3. redraw

    [item setSelected: YES];
    [[self selectedItems] addObject: item];        
    [self setNeedsDisplay: YES];
}

- (void) deselectItem: (THCanvasItem *)item
{
    if (!item) return;

    // 1. set the selected flag on the item
    // 2. add to selectedItems array
    // 3. redraw

    [item setSelected: NO];
    [[self selectedItems] removeObject: item];        
    [self setNeedsDisplay: YES];
}

- (void) selectItems: (NSArray *)theItems
{
    if (!theItems) return;

    // we use NSArray's implementation of
    // -setValue:forKey: here to set to set a value
    // to all the items in the array at once

    [theItems setValue:[NSNumber numberWithBool:YES] forKey: @"selected"];
    [[self selectedItems] addObjectsFromArray:theItems];        
    [self setNeedsDisplay: YES];
}

- (void) deselectItems: (NSArray *)theItems
{
    if (!theItems) return;

    // we use NSArray's implementation of
    // -setValue:forKey: here to set to set a value
    // to all the items in the array at once

    [theItems setValue: [NSNumber numberWithBool:NO] forKey: @"selected"];
    [[self selectedItems] removeObjectsInArray: theItems];        
    [self setNeedsDisplay: YES];
}



#pragma mark -
#pragma mark Simple Accessors

// current size of the items drawn in the canvas. used by bindings

- (unsigned)itemWidth
{
    return _itemWidth;
}

- (void)setItemWidth:(unsigned)newItemWidth
{
    _itemWidth = newItemWidth;
    [self _rebuildCanvasItemsWithNewItemWidth];
}

// general style elements

- (NSColor *) backgroundColor
{
    return _backgroundColor;
}

- (void) setBackgroundColor: (NSColor *)newColor
{
    _backgroundColor = [newColor copy];
}

- (NSColor *)borderColor
{
    return _borderColor;
}

- (void)setBorderColor:(NSColor *)aValue
{
    _borderColor = [aValue copy];
}

// text attributes for image labels

- (NSDictionary *)itemLabelAttributes
{
    return _itemLabelAttributes;
}

- (void)setItemLabelAttributes:(NSDictionary *)aValue
{
    _itemLabelAttributes = [aValue copy];
}

// the text attributes for dragging are different so that
// the item is drawn semi-transparent

- (NSDictionary *)itemLabelAttributesForDragging
{
    return _itemLabelAttributesForDragging;
}

- (void)setItemLabelAttributesForDragging:(NSDictionary *)aValue
{
    _itemLabelAttributesForDragging = [aValue copy];
}



#pragma mark -
#pragma mark Private Utilities

// pass in a point from a mouse event in and get back
// a canvas item, or nil

- (THCanvasItem *) _canvasItemAtPoint: (NSPoint)point
{
    NSArray *sort = [NSSortDescriptor descendingDescriptorsForKeys:@"layer",nil];
    NSArray* myItems = [self canvasItems];

    // sort by layer number
    myItems = [myItems sortedArrayUsingDescriptors:sort];

    // loop through all canvas items that we have and look for one
    // whose bounds contains the point where the mouse clicked.
    // if we find one, return it.

    unsigned i = 0;
    unsigned count = [myItems count];

    for ( i = 0; i < count; i++ )                
    {
        THCanvasItem* item = [myItems objectAtIndex:i];
        if ( NSPointInRect ( point, [item flippedBoundsWithLabel] ))
        {
            return item;
        }
    }
    
    // we didn't find a canvas item at this point, so return nil
    return nil;        
}


// checks to see if two items overlap. this is useful for
// setting the layer of one item higher than another.

- (THCanvasItem *)_itemIntersectingItem: (THCanvasItem *)testItem
{
    NSArray * myItems       = [self canvasItems];
    unsigned i              = 0;
    unsigned count          = [myItems count];
    THCanvasItem * item    = nil;
                                                    
    // order array items by layer, so that the "highest" items
    // come up in the list first. Obviously, the user would want
    // the item highest on the stack to receive the click.
    
    NSArray *sort = [NSSortDescriptor descendingDescriptorsForKeys:@"layer",nil];
    myItems = [myItems sortedArrayUsingDescriptors:sort];

    // loop through all canvas items that we have and look for one
    // whose bounds contains the point where the mouse clicked.
    // if we find one, return it.

    for ( i = 0; i < count; i++ )                
    {
        item = [myItems objectAtIndex: i];

        // see if these items intersect, if they do, return this item,
        // but make sure they're not the same object.
                
        if ( NSIntersectsRect ( [item bounds], [testItem bounds] ) && item != testItem )
        {
            return item;
        }
    }
    
    // we didn't find an item at this point, so return nil
    return nil;
}

// this gets called when we need to set a new frame size
// for the scroll view

- (void)_recalculateFrameSize
{
    NSScrollView * scrollView = [self enclosingScrollView];
    if ( !scrollView ) {
        [self setNeedsDisplay:YES];
        return; 
    }
    NSSize scrollViewSize = [scrollView contentSize];

    // setup some loop variables. we'll use these multiple times
    THCanvasItem * oneItem = nil;
    NSRect itemBounds;
    NSRect itemFlippedBounds;   
    NSArray *myItems = [self canvasItems];  
    unsigned i;
    unsigned count = [myItems count];

    // figure out the total size of the frame we'll
    // need to contain all the canvas items. we want
    // it at least as big as the viewable area    
    float maxX = scrollViewSize.width;
    float maxY = scrollViewSize.height; 
    float minX = 0.0;
    float minY = 0.0;           

    NSRect newFrame;

    // the get maximum and minimum values for x and y to
    // figure out how big of a frame we need to hold everything.
    // fmax and fmin are functions from ANSI C's math.h                
    for ( i = 0; i < count; i++ )
    {
        oneItem = [myItems objectAtIndex:i];

        maxX = fmax ( maxX, [oneItem maxX] );
        minX = fmin ( minX, [oneItem minX] );
        
        maxY = fmax ( maxY, [oneItem maxY] );           
        minY = fmin ( minY, [oneItem minY] );                   
    }

    // if any items are past the left or top edges, we need to
    // adjust the frame to accomodate them    
    if ( minX < 0 || minY < 0 )
    {       
        // the fabs function returns the absolute (non-negative)
        // value of minX and minY, also from math.h                         
        float moveRightBy = fabs(minX);
        float moveDownBy  = fabs(minY);

        minX  = 0;
        minY  = 0;
        maxX += moveRightBy;
        maxY += moveDownBy;
        
        for ( i = 0; i < count; i++ )
        {
            // adjust items after the view resize
            // so that canvas items are back in sight
            oneItem = [myItems objectAtIndex:i];
            itemFlippedBounds = [oneItem flippedBounds];            
            itemFlippedBounds.origin.x += moveRightBy;
            itemFlippedBounds.origin.y += moveDownBy;

            // setting the bounds will implicitly set
            // the flipped bounds as well. the details of
            // this aren't important            
            float height = NSHeight ( itemFlippedBounds );      
            itemBounds = NSOffsetRect ( itemFlippedBounds, 0, height );

            // this method we're in is called when bounds changes, so                       
            // we have a special 'no KVO' variant of the bounds setter
            // so that we don't go into infinite recursion.             
            [oneItem setBoundsWithoutNotification:itemBounds];
        }       
    }               

    // do the final setting of the new frame rect
    newFrame = NSMakeRect ( minX, minY, maxX, maxY );
    [self setFrame:newFrame];  
    [self setNeedsDisplay:YES];
}


// called when the global canvas item size is adjusted.
// sets new bounds for all items, then recalculates frame.

- (void)_rebuildCanvasItemsWithNewItemWidth
{
    NSArray * canvasItems = [self canvasItems];

    unsigned i;
    unsigned count = [canvasItems count];
    
    for ( i = 0; i < count; i += 1 )
    {
        // get current item bounds
        THCanvasItem* item = [canvasItems objectAtIndex:i];
        NSRect bounds = [item bounds];
        
        // adjust bounds to match new size
        bounds.size.width  = [self itemWidth];
        bounds.size.height = [self itemWidth];

        // update bounds, but don't set KVO notification. if we
        // did, this view would pick it up, try to recalculate,
        // and we'd go into infinite recursion
        [item setBoundsWithoutNotification:bounds];        
    }
    
    // see if we need to adjust the frame size at all,
    // and tell the enclosing scroll view to resize.
    [self _recalculateFrameSize];
}


// creates text attributes for canvas item labels

- (void) _setupItemLabelAttributes
{
    // setup paragraph styling
    NSMutableParagraphStyle * pStyle = [[NSMutableParagraphStyle alloc] init];
    [pStyle setAlignment: NSCenterTextAlignment];   
                                                                                        
    // setup font descriptor
    NSDictionary * fontAttrs  = [NSDictionary dictionaryWithObjectsAndKeys: 
        @"Lucida Grande",   NSFontNameAttribute,
    nil];   
    
    NSFontDescriptor * fontDescr = [NSFontDescriptor fontDescriptorWithFontAttributes: fontAttrs];

    // create the font and color
    NSColor * color     = [NSColor colorWithCalibratedWhite:0.2 alpha:1.0];
    NSFont  * myFont    = [NSFont fontWithDescriptor: fontDescr size:14];

    // combine into an attributes dictionary for an attributed string
    NSMutableDictionary * attrs  = [NSMutableDictionary dictionaryWithObjectsAndKeys:   
        myFont,     NSFontAttributeName,
        color,      NSForegroundColorAttributeName,
        pStyle,     NSParagraphStyleAttributeName,
    nil];
    
    [self setItemLabelAttributes: attrs];
    
    // lighter text when dragging
    NSColor * draggingColor = [NSColor colorWithCalibratedWhite:0.2 alpha:0.3];
    [attrs setValue:draggingColor forKey:NSForegroundColorAttributeName];
    [self setItemLabelAttributesForDragging: attrs];
    
}



#pragma mark -
#pragma mark Private Bindings Support

- (void) _becomeObserverForCanvasItems: (NSArray *)newItems
{
    // this method loops through an array of new canvas items
    // that we want to observe through KVO. anytime one of
    // these canvas items change, we'll redraw
    
    unsigned count  = [newItems count];
    if ( !newItems || count < 1 ) return;

    // loop through all the new canvas items
   
    unsigned i;
    for ( i = 0; i < count; i++ )
    {                
        THCanvasItem* item = [newItems objectAtIndex: i];

        // for each item, subscribe to key-value observing notifications for
        // each of the keys that affect drawing
        NSEnumerator* e = [DrawingAttributeKeys objectEnumerator];
        NSString* oneKey = nil;
        
        while ( oneKey = [e nextObject] )
        {
            // provide a context when observing to provide better performance
            // when receiving new values
            [item addObserver: self
                   forKeyPath: oneKey
                      options: nil
                      context: CanvasItemAttributesObservationContext];
        }
    }

}

- (void) _resignObserverForCanvasItems: (NSArray *)theItems
{
    // this is the counterpart to becomeObserverForCanvasItems.
    // here we undo the KVO subscriptions for all items in
    // the array    
    unsigned count  = [theItems count];
    if ( !theItems || count < 1 ) return;        

    // loop through all the canvas items
    THCanvasItem * item    = nil;
    NSEnumerator  * e       = nil;
    NSString      * oneKey  = nil;

    unsigned i;
    for ( i = 0; i < count; i++ )
    {
        item = [theItems objectAtIndex:i];

        // for each item, unsubscribe from key-value observing notifications for
        // each of the keys that affect drawing        
        e = [DrawingAttributeKeys objectEnumerator];                
        while ( oneKey = [e nextObject] )
        {
            [item removeObserver:self forKeyPath:oneKey];
        }
    }
    
}



#pragma mark -
#pragma mark Private Accessors

// key path info for the controllers we're bound to

- (NSMutableDictionary *) _bindingsInfo
{
    return _bindingsInfo;
}

- (void) _setBindingsInfo: (NSMutableDictionary *)newInfo
{
    _bindingsInfo = [newInfo mutableCopy];
}

// a list of UTI types that we can probably open with NSImage.
// see http://developer.apple.com/macosx/uniformtypeidentifiers.html for
// more info on UTI types.

- (NSArray*)_imageFileTypes
{
    return _imageFileTypes;
}

- (void)_setImageFileTypes:(NSArray*)aValue
{
    NSArray* oldImageFileTypes = _imageFileTypes;
    _imageFileTypes = [aValue copy];
}


@end
