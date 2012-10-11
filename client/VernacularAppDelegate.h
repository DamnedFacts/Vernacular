//
//  VernacularAppDelegate.h
//  Vernacular
//
//  Created by Richard Sarkis on 8/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <RSWebSocketApplication/RSWebSocketApplication.h>
#import "RSURLField.h"
#import "VDelegateManager.h"

@interface VernacularAppDelegate : NSObject <NSApplicationDelegate,RSWebSocketApplication> {
    NSString *fileName;
    NSURL *appUrl;
    
    // WebSocket related
    NSString* response;
    
    // Console
    NSPipe *pipe;
    NSFileHandle *pipeReadHandle;
    
    // temporary work
    NSString *rpcUri;
    NSString *rpcCurie;
    
    // Proxy for our delegate manager
    VDelegateManager *vdelegate;
}

// Property Declarations
@property (retain)           RSWebSocketApplication* wsa;
@property (assign) IBOutlet  NSWindow *connectWindow;
@property (assign) IBOutlet  RSURLField *connectUrlTextField;
@property (assign) IBOutlet  NSButton *connectButton;
@property (assign) IBOutlet  NSTextView *connectionConsole;

// Public Method Delcarations
- (void)applicationDidFinishLaunching: (NSNotification *)aNotification;
@end
