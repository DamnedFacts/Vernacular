//
//  NSBezierPath+RoundRect.m
//
//  Created by Scott Stevenson on Thu Mar 24 2005.
//  Released under a BSD-style license. See License.txt
//

#import "NSBezierPath+RoundRect.h"


@implementation NSBezierPath (RoundRect)

// based on code from http://cocoadev.com/index.pl?RoundedRectangles

+ (NSBezierPath *) bezierPathWithRoundRectInRect:(NSRect)aRect radius: (float)radius
{
	NSBezierPath* path = [self bezierPath];
	radius = MIN ( radius, 0.5f * MIN (NSWidth(aRect),NSHeight(aRect)) );

	NSRect rect = NSInsetRect (aRect, radius, radius);

	float minX = NSMinX ( rect );
	float maxX = NSMaxX ( rect );
	float minY = NSMinY ( rect );
	float maxY = NSMaxY ( rect );
        
	NSPoint topLeft     = NSMakePoint (minX, minY);
	NSPoint topRight    = NSMakePoint (maxX, minY);
	NSPoint bottomRight = NSMakePoint (maxX, maxY);
	NSPoint bottomLeft  = NSMakePoint (minX, maxY);
        
	[path appendBezierPathWithArcWithCenter: topLeft
	                                 radius: radius
	                             startAngle: 180.0
	                               endAngle: 270.0];

	[path appendBezierPathWithArcWithCenter: topRight
	                                 radius: radius
	                             startAngle: 270.0
	                               endAngle: 360.0];

	[path appendBezierPathWithArcWithCenter: bottomRight
	                                 radius: radius
	                             startAngle: 0.0
	                               endAngle: 90.0];

	[path appendBezierPathWithArcWithCenter: bottomLeft
	                                 radius: radius
	                             startAngle: 90.0
	                               endAngle: 180.0];

	[path closePath];
	return path;        
}
@end
