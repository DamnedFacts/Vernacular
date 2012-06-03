//
//  VernacularAppDelegate.h
//  Vernacular
//
//  Created by Richard Sarkis on 8/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#ifdef GNUSTEP
/* When compiling on-site, on GNUstep the headers are not installed
 * yet.  */
# include "Renaissance.h"
#else
/* Here compiling on-site is simply not supported :-).  */
#include <Renaissance/Renaissance.h>

#endif

@interface VernacularAppDelegate : NSObject <NSApplicationDelegate> {
    NSString *fileName;
}

- (id) initWithFile: (NSString *)f;
- (void) setValue: (id)anObject  forUndefinedKey: (NSString *)aKey;
/* A dummy action method that you can use in your gsmarkup files
 * to test sending an action to the #NSOwner.  */
- (void) dummyAction: (id)aSender;
- (void) bundleDidLoadGSMarkup: (NSNotification *)aNotification;
- (void)applicationDidFinishLaunching: (NSNotification *)aNotification;

@end
