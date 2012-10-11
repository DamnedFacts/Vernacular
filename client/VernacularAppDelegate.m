//
//  VernacularAppDelegate.m
//  Vernacular
//
//  Created by Richard Sarkis on 8/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "VernacularAppDelegate.h"

@implementation VernacularAppDelegate

@synthesize wsa;
@synthesize connectWindow;
@synthesize connectUrlTextField;
@synthesize connectionConsole;
@synthesize connectButton;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // Set button for connection as default on enter.
    [connectButton setKeyEquivalent:@"\r"];
    
    [defaults registerDefaults: [NSDictionary dictionaryWithObjectsAndKeys:
                                 @"NO", @"DisplayAutoLayout",
                                 nil]];
                    

    [connectWindow makeKeyAndOrderFront:self];
    [[self connectButton] setEnabled:NO];
    
    // Temporary, perhaps. Used to validate programatically set text in the URL field, as if it were
    // user entered.
    [connectUrlTextField setStringValue:@"ws://localhost:9000/"];
    [connectUrlTextField isValidUrl];
    [[NSNotificationCenter defaultCenter] postNotificationName:NSControlTextDidChangeNotification
                                                        object:connectUrlTextField userInfo:nil];
    
    
    // Pipe all stderr output to our console window.
    pipe = [NSPipe pipe] ;
    pipeReadHandle = [pipe fileHandleForReading];
    dup2([[pipe fileHandleForWriting] fileDescriptor], STDERR_FILENO) ;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(writeToConsoleWindow:)
                                                 name:NSFileHandleReadCompletionNotification
                                               object:pipeReadHandle];
    
    [pipeReadHandle readInBackgroundAndNotify];

}



#pragma mark IBActions
- (IBAction)connectToVernacularServer:(id)sender
{
    [connectWindow close];
    
    // connectUrlTextField at this point has been pre-validated.
    NSLog(@"Connecting to: %@",[connectUrlTextField stringValue]);
    appUrl = [NSURL URLWithString:[connectUrlTextField stringValue]];
    wsa = [RSWebSocketApplication webSocketApplicationConnectWithUrl:[connectUrlTextField stringValue]  delegate:self];
}

#pragma mark WebSocketApplication Delegate
- (void)didWelcome
{
    rpcUri   = @"http://example.com/simple/calculator#";
    rpcCurie = @"calculator";
    
    [wsa sendPrefixMessage:rpcCurie uri:rpcUri];
    
    // Call for main RIB (Renaissance Interface Builder) data
    NSString *call = [NSString stringWithFormat:@"%@:mainRibData", rpcCurie];
    [wsa sendCallMessage:call target:self selector:@selector(localDispatch:) args:[NSArray arrayWithObjects: nil]];
}

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

#pragma mark Utility
- (void) writeToConsoleWindow: (NSNotification *) aNotification {
    [pipeReadHandle readInBackgroundAndNotify];
    
    NSString *str = [[NSString alloc] initWithData: [[aNotification userInfo] objectForKey: NSFileHandleNotificationDataItem]
                                          encoding: NSASCIIStringEncoding] ;
    
    // Get text storage of the NSTextView and append text to it.
	NSAttributedString *string = [[NSAttributedString alloc] initWithString:str];
	NSTextStorage *storage = [connectionConsole textStorage];
    
	[storage beginEditing];
	[storage appendAttributedString:string];
	[storage endEditing];
    
    // Scroll to bottom after appending
    NSRange end_pos = NSMakeRange([storage length], 0);
    [connectionConsole scrollRangeToVisible:end_pos];
}

- (void) didEvent:(NSString*)topicUri event:(id)event
{
    NSLog(@"Received event! %@ %@",topicUri, event);
    [vdelegate delegateCallBack:[NSURL URLWithString:topicUri] event:event];
}

- (void) localDispatch: (id)value {

    vdelegate = [[VDelegateManager alloc] initWithGSMarkupData:[value dataUsingEncoding:NSUTF8StringEncoding]];
    
    [[NSApplication sharedApplication] setDelegate: self];

}
@end
