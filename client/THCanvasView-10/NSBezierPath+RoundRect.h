//
//  NSBezierPath+RoundRect.h
//
//  Created by Scott Stevenson on Thu Mar 24 2005.
//  Released under a BSD-style license. See License.txt
//

#import <Foundation/Foundation.h>


@interface NSBezierPath (RoundRect)

+ (NSBezierPath *) bezierPathWithRoundRectInRect: (NSRect)aRect
                                          radius: (float)radius;

@end
