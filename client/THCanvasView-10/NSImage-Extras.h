//
//  NSImage-Extras.h
//  SimplePicture
//
//  Created by Scott Stevenson on 9/28/07.
//  Released under a BSD-style license. See License.txt

#import <Cocoa/Cocoa.h>


@interface NSImage (Extras)

// creates a copy of the current image while maintaining
// proportions. also centers image, if necessary

- (NSImage*)imageByScalingProportionallyToSize:(NSSize)aSize;
- (NSImage*)imageByScalingProportionallyToSize:(NSSize)targetSize flipped:(BOOL)isFlipped;

@end
