//
//  NSLogConsole.m
//  NSLogConsole
//
//  Created by Patrick Geiller on 16/08/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "NSLogConsole.h"
#import <ScriptingBridge/ScriptingBridge.h>

@implementation NSLogConsole
@synthesize autoOpens, windowTitle;

+ (id)sharedConsole
{
	static id singleton = NULL;
    
	@synchronized(self)
    {
		if (!singleton)	{
			singleton = [self alloc];
			(void)[singleton init]; // We need singleton above to be
                                    // defined before calling init
		}
	}
	return singleton;
}

//
// Init : should only be called once by sharedConsole
//
- (id)init
{
	autoOpens	= YES;
	original_stderr = dup(fileno(stderr)); 	// Save stderr

	// Redirect stderr
    // Pipe all stderr output to our console window.
    pipe = [NSPipe pipe];
    pipeReadHandle = [pipe fileHandleForReading];
    pipeWriteHandle = [pipe fileHandleForWriting];
    new_stderr = [pipeWriteHandle fileDescriptor];
    if (!dup2(new_stderr, fileno(stderr)))
        NSLog(@"Couldn't redirect stderr");
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dataAvailable:)
                                                 name:NSFileHandleReadCompletionNotification
                                               object:pipeReadHandle];
    [pipeReadHandle readInBackgroundAndNotify];
	
	return [super init];
}

// NSLog will generate an event posted in the next run loop run
- (void)dataAvailable:(NSNotification *)aNotification
{
    [pipeReadHandle readInBackgroundAndNotify];
    NSData *data = [[aNotification userInfo] objectForKey: NSFileHandleNotificationDataItem];
	[[NSLogConsole sharedConsole] updateLogWithFile:"" lineNumber:0 data:data];
}

//
// Read log data from handle
//
- (void)updateLogWithFile:(char*)file lineNumber:(int)line data:(NSData *)data
{
	// Open console if it's hidden
	if (![window isVisible] && autoOpens)	[self open];
    
	// Read data
//	NSData* data = [pipeReadHandle readDataToEndOfFile];
	[self logData:data file:file lineNumber:line];
}


- (void)open
{
	if (!window)
	{
		if (![NSBundle loadNibNamed:@"NSLogConsole" owner:self])
		{
			NSLog(@"NSLogConsole.nib not loaded");
			return;
		}
		if ([window respondsToSelector:@selector(setBottomCornerRounded:)])
			[window setBottomCornerRounded:NO];
	}
	if (windowTitle)	[window setTitle:windowTitle];
	[window orderFront:self];
}
- (void)close
{
	[window orderOut:self];
}
- (BOOL)isOpen
{
	return	[window isVisible];
}

- (IBAction)clear:(id)sender
{
	[webView clear];
}
- (IBAction)searchChanged:(id)sender
{
	[webView search:[sender stringValue]];
}

- (id)window
{
	return	window;
}


//
// Log data to webview and original stderr 
//
- (void)logData:(NSData*)data file:(char*)file lineNumber:(int)line
{
	if (![window isVisible] && autoOpens)	[self open];

	id str = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding];
//	[[NSAlert alertWithMessageText:@"hello" defaultButton:@"Furthe" alternateButton:nil otherButton:nil informativeTextWithFormat:str] runModal];
	// Write back to original stderr
	write(original_stderr, [data bytes], [data length]);
	// Clear search
	[searchField setStringValue:@""];
	[webView search:@""];
	// Log string
	[webView logString:str file:file lineNumber:line];
}
@end

@implementation NSLogConsoleView
- (BOOL)drawsBackground
{
	return	NO;
}

- (void)awakeFromNib
{
	messageQueue	= [[NSMutableArray alloc] init];
	webViewLoaded	= NO;

	// Frame load
	[self setFrameLoadDelegate:self];

	// Load html page
	id path = [[NSBundle mainBundle] pathForResource:@"NSLogConsole" ofType:@"html"];
	[[self mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]]];

	// Navigation notification
	[self setPolicyDelegate:self];
}

//
//	Javascript is available
//		Register our custom javascript object in the hosted page
//
- (void)webView:(WebView *)view windowScriptObjectAvailable:(WebScriptObject *)windowScriptObject
{
	[windowScriptObject setValue:self forKey:@"NSLogConsoleView"];
}

//
// WebView has finished loading
//
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
	webViewLoaded	= YES;

	// Flush message queue
	for (id o in messageQueue)
		[self logString:[o valueForKey:@"string"] file:(char*)[[o valueForKey:@"file"] UTF8String] lineNumber:[[o valueForKey:@"line"] intValue]];
}

//
// Notify WebView of new message
//
- (void)logString:(NSString*)string file:(char*)file lineNumber:(int)line
{
	// Queue message if WebView has not finished loading
	if (!webViewLoaded)
	{
		id o = [NSDictionary dictionaryWithObjectsAndKeys:	[NSString stringWithString:string], @"string",
															[NSString stringWithUTF8String:file], @"file",
															[NSNumber numberWithInt:line], @"line",
															nil];
		[messageQueue addObject:o];
		return;
	}
	[[self windowScriptObject] callWebScriptMethod:@"log" withArguments:[NSArray arrayWithObjects:string, 
																			[NSString stringWithUTF8String:file], 
																			[NSNumber numberWithInt:line],
																			nil]];
}

//
// Open source file in XCode at correct line number
//
- (void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)actionInformation
                                                           request:(NSURLRequest *)request
                                                             frame:(WebFrame *)frame
                                                  decisionListener:(id<WebPolicyDecisionListener>)listener
{
	// Get path, formed by AbsolutePathOnDisk(space)LineNumber
	NSString* pathAndLineNumber = [[request URL] path];
	
	// From end of string, skip to space before number
	char* s = (char*)[pathAndLineNumber UTF8String];
	char* s2 = s+strlen(s)-1;
	while (*s2 && *s2 != ' ' && s2 > s) s2--;
	if (*s2 != ' ')	return	NSLog(@"Did not find line number in %@", pathAndLineNumber);
	
	// Patch a zero to recover path
	*s2 = 0;
	
	// Get line number
	int line;
	BOOL foundLine = [[NSScanner scannerWithString:[NSString stringWithUTF8String:s2+1]] scanInt:&line];
	if (!foundLine)	return	NSLog(@"Did not parse line number in %@", pathAndLineNumber);

	// Get path
	NSString* path = [NSString stringWithUTF8String:s];
//	NSLog(@"opening line %d of _%@_", line, path);

	// Open in XCode
	id source = [NSString stringWithFormat:@"tell application \"Xcode\"									\n\
												set doc to open \"%@\"									\n\
												set selection to paragraph (%d) of contents of doc		\n\
											end tell", path, line];
	id script = [[NSAppleScript alloc] initWithSource:source];
	[script executeAndReturnError:nil];
}


- (void)clear
{
	[[self windowScriptObject] callWebScriptMethod:@"clear" withArguments:nil];
}

- (void)search:(NSString*)string
{
	[[self windowScriptObject] callWebScriptMethod:@"search" withArguments:[NSArray arrayWithObjects:string, nil]];
}


@end

