//
//  VernacularAppDelegate.m
//  Vernacular
//
//  Created by Richard Sarkis on 8/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "VernacularAppDelegate.h"


@implementation VernacularAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSString *path;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL b;
    NSOpenPanel *openDialog = [NSOpenPanel openPanel];
    
    [defaults registerDefaults: [NSDictionary dictionaryWithObjectsAndKeys:
                                 @"NO", @"DisplayAutoLayout",
                                 nil]];
            
    [openDialog setCanChooseFiles:YES];
    [openDialog setCanChooseDirectories:NO];
    
    if ([openDialog runModalForDirectory:nil file:nil] == NSOKButton) {
        NSArray  *files = [openDialog filenames];
        path = [files objectAtIndex:0];
    }
    
    [[NSApplication sharedApplication] setDelegate: [self initWithFile: path]];
    
    NSLog (@"Loading %@", fileName);
    b = [NSBundle loadGSMarkupFile: fileName
                 externalNameTable: [NSDictionary dictionaryWithObject: self  
                                                                forKey: @"NSOwner"]
                          withZone: NULL];
    
    //[pool drain];
    
    if (b) {
        NSLog (@"%@ loaded!", fileName);
    } else {
        NSLog (@"Could not load %@!", fileName);
        exit (1);
    }
    [NSApp run];
}

- (id) initWithFile: (NSString *)f {
    [ f retain]; [fileName release]; fileName =  f;
    return self;
}

- (void) dealloc {
    [fileName release];
    [super dealloc];
}

- (void) dummyAction: (id)aSender {
    NSLog (@"Dummy action invoked by %@", aSender);
}

- (void) setValue: (id)anObject  forUndefinedKey: (NSString*)aKey {
    NSLog (@"Set value \"%@\" for key \"%@\" of NSOwner", anObject, aKey);
}

- (void) bundleDidLoadGSMarkup: (NSNotification *)aNotification {
    /* You can turn on DisplayAutoLayout by setting it in the user
     * defaults ('defaults write NSGlobalDomain DisplayAutoLayout
     * YES'), or by passing it on the command line ('openapp
     * GSMarkupBrowser.app file.gsmarkup -DisplayAutoLayout YES').
     */
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DisplayAutoLayout"]) {
        NSArray *topLevelObjects;
        u_long i, count;
        
        topLevelObjects = [[aNotification userInfo] objectForKey: 
                           @"NSTopLevelObjects"];
        
        /* Now enumerate the top-level objects.  If there is any
         * NSWindow or NSView, mark it as displaying autolayout
         * containers.
         */
        count = [topLevelObjects count];
        
        for (i = 0; i < count; i++) {
            id object = [topLevelObjects objectAtIndex: i];
            if ([object isKindOfClass: [NSWindow class]]
                || [object isKindOfClass: [NSView class]])
            {
                [(NSWindow *)object setDisplayAutoLayoutContainers: YES];
            }
        }
    }
}


@end
