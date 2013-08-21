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
#import "VAAppListController.h"
#import "VADefines.h"

@class ApplicationShim;
@interface VAMain : NSObject <NSApplicationDelegate,RSWebSocketApplicationDelegate> {
    IBOutlet NSWindow *canvasViewWindow;
    IBOutlet VAAppListController *appsViewer;
    
    NSString *fileName;
    NSURL *appUrl;
    
    // WebSocket related
    NSString* response;
    
    // temporary work
    NSString *rpcUri;
    NSString *rpcCurie;
}

// Property Declarations
@property (retain)           ApplicationShim *selectedApp;
@property (retain)           VAAppListController *appsViewer;
@property (retain)           RSWebSocketApplication* wsa;
@property (retain) IBOutlet  NSWindow *connectWindow;
@property (retain) IBOutlet  RSURLField *connectUrlTextField;
@property (retain) IBOutlet  NSButton *connectButton;

// Public Method Delcarations
- (void)applicationDidFinishLaunching: (NSNotification *)aNotification;
@end
