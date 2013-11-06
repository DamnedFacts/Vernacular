//
//  VernacularAppDelegate.m
//  Vernacular
//
//  Created by Richard Sarkis on 8/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "VAMain.h"
#import "NSLogConsole.h"
#import "ApplicationShim.h"

@implementation VAMain

@synthesize wsa;
@synthesize selectedApp;
@synthesize connectWindow;
@synthesize connectUrlTextField;
@synthesize connectButton;
@synthesize appsViewer;

- (void)awakeFromNib
{
	//[NSLogConsole sharedConsole];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // Pass wsa object to other classes, if needed.
    [[NSApplication sharedApplication] setDelegate: self]; 

    // Set "Connect" button as keyed default.
    [connectButton setKeyEquivalent:@"\r"];
    [[self connectButton] setEnabled:NO];

    // Disable Renaissance auto layout
    [defaults registerDefaults: [NSDictionary dictionaryWithObjectsAndKeys:
                                 @"NO", @"DisplayAutoLayout",
                                 nil]];
                        
    // Hardcode a default URL, and activate the connect button
    [connectUrlTextField setStringValue:@"ws://localhost:9000/"];
    [[NSNotificationCenter defaultCenter] postNotificationName:NSControlTextDidChangeNotification
                                                        object:connectUrlTextField userInfo:nil];
    // Show connect window
    [connectWindow setReleasedWhenClosed:NO];
    [connectWindow makeKeyAndOrderFront:self];
    
    // Set notification callback for Venarcular app selection
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(processAppSelection:)
                                                 name:VAAppSelectedNotification
                                               object:nil];
}


#pragma mark -
#pragma mark IBActions
- (IBAction)toggleConsole:(id)sender
{
	BOOL isOpen = [[NSLogConsole sharedConsole] isOpen];
	if (!isOpen)	[[NSLogConsole sharedConsole] open];
	else			[[NSLogConsole sharedConsole] close];
}

- (IBAction)connectToVernacularServer:(id)sender
{
    [connectWindow close];
    
    // connectUrlTextField at this point has been pre-validated.
    NSLog(@"Connecting to: %@",[connectUrlTextField stringValue]);
    appUrl = [NSURL URLWithString:[connectUrlTextField stringValue]];
    wsa = [RSWebSocketApplication webSocketApplicationConnectWithUrl:[connectUrlTextField stringValue]  delegate:self];
}

- (IBAction) reconnectToVernacularServer:(id)sender
{
    [wsa closeWebSocketApplicationConnection];
    [connectWindow makeKeyAndOrderFront:self];
}

#pragma mark -
#pragma mark WebSocketApplication Delegate
- (void)didWelcome
{
    NSLog(@"Welcome message received");
    
    [wsa sendCallMessage:@"availableApps"
                  target:self
          resultSelector:@selector(processAppsList:)
           errorSelector:@selector(handleCallError:errorURI:errorDesc:errorDetails:)
                    args:[NSArray arrayWithObjects: nil]];
}

- (void)didEvent:(NSString*)topicUri event:(id)event
{
    NSLog(@"Received event! %@ %@",topicUri, event);
    [self.selectedApp handleEvent:[NSURL URLWithString:topicUri] event:event];
}

/* CallResult and CallError are handled indirectly by invocations assigned to the call */


#pragma mark -
#pragma mark NSControl Delegate
- (void)controlTextDidChange:(NSNotification *)aNotification
{
    RSURLField *textField = [aNotification object];
    
    if ([textField isValidUrl]) {
        [[self connectButton] setEnabled:YES];
    } else {
        [[self connectButton] setEnabled:NO];
    }
}

#pragma mark -
#pragma mark Callbacks
- (void) processAppsList: (id)appsList {
    if ([appsList isKindOfClass:[NSDictionary class]]) {
        [canvasViewWindow makeKeyAndOrderFront:self];
        for (NSString *appName in appsList) {
            NSString *appUri = [appsList objectForKey:appName];
            ApplicationShim *anApp = [[ApplicationShim alloc] initWithInfo:appUri name:appName];
            [appsViewer performAddItem: anApp];
        }
    } else {
        NSLog(@"Failure to retrieve require apps list from server");
        [wsa closeWebSocketApplicationConnection];
    }
}

- (void) processAppSelection: (NSNotification *)appSelNotification {
    self.selectedApp = [appSelNotification object];
    [self.selectedApp beginApplication];
}

- (void) handleCallError: (NSString *)callId errorURI:(NSString *)uri errorDesc:(NSString*)desc errorDetails:(id)details {
    NSLog(@"Received error: %@ %@ %@ %@", callId, uri, desc, details);
}
@end
