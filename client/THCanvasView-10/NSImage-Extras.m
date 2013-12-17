//
//  NSImage-Extras.m
//  SimplePicture
//
//  Created by Scott Stevenson on 9/28/07.
//  Released under a BSD-style license. See License.txt

#import "NSImage-Extras.h"


@implementation NSImage (Extras)

- (NSImage*)imageByScalingProportionallyToSize:(NSSize)targetSize
{
    return [self imageByScalingProportionallyToSize:targetSize flipped:NO];
}

- (NSImage*)imageByScalingProportionallyToSize:(NSSize)targetSize flipped:(BOOL)isFlipped
{
    NSImage* sourceImage = self;
    NSImage* newImage = nil;
    
    if ([sourceImage isValid])
    {
        NSSize imageSize = [sourceImage size];
        float width  = imageSize.width;
        float height = imageSize.height;

        float targetWidth  = targetSize.width;
        float targetHeight = targetSize.height;

        // scaleFactor will be the fraction that we'll
        // use to adjust the size. For example, if we shrink
        // an image by half, scaleFactor will be 0.5. the
        // scaledWidth and scaledHeight will be the original,
        // multiplied by the scaleFactor.
        //
        // IMPORTANT: the "targetHeight" is the size of the space
        // we're drawing into. The "scaledHeight" is the height that
        // the image actually is drawn at, once we take into
        // account the ideal of maintaining proportions

        float scaleFactor  = 0.0;                
        float scaledWidth  = targetWidth;
        float scaledHeight = targetHeight;

        NSPoint thumbnailPoint = NSMakePoint(0,0);

        // since not all images are square, we want to scale
        // proportionately. To do this, we find the longest
        // edge and use that as a guide.

        if ( NSEqualSizes( imageSize, targetSize ) == NO )
        {            
            // use the longeset edge as a guide. if the
            // image is wider than tall, we'll figure out
            // the scale factor by dividing it by the
            // intended width. Otherwise, we'll use the
            // height.
            
            float widthFactor  = targetWidth / width;
            float heightFactor = targetHeight / height;
            
            if ( widthFactor < heightFactor )
                scaleFactor = widthFactor;
            else
                scaleFactor = heightFactor;

            // ex: 500 * 0.5 = 250 (newWidth)
            
            scaledWidth  = width  * scaleFactor;
            scaledHeight = height * scaleFactor;

            // center the thumbnail in the frame. if
            // wider than tall, we need to adjust the
            // vertical drawing point (y axis)
            
            if ( widthFactor < heightFactor )
                thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
                
            else if ( widthFactor > heightFactor )
                thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
        }


        // create a new image to draw into        
        newImage = [[NSImage alloc] initWithSize:targetSize];
        [newImage setFlipped:YES];

        // once focus is locked, all drawing goes into this NSImage instance
        // directly, not to the screen. It also receives its own graphics
        // context.
        //
        // Also, keep in mind that we're doing this in a background thread.
        // You only want to draw to the screen in the main thread, but
        // drawing to an offscreen image is (apparently) okay.

        [newImage lockFocus];
            
            [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
            NSRect thumbnailRect;
            thumbnailRect.origin = thumbnailPoint;
            thumbnailRect.size.width = scaledWidth;
            thumbnailRect.size.height = scaledHeight;

            [sourceImage drawInRect: thumbnailRect
                           fromRect: NSZeroRect
                          operation: NSCompositeSourceOver
                           fraction: 1.0];

        [newImage unlockFocus];
        
    }

    return newImage;
}

@end
