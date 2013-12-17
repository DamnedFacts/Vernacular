//
//  NSLogConsole.h
//  NSLogConsole
//
//  Created by Patrick Geiller on 16/08/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>


void	NSLogProlog(char* file, int line);
void	NSLogPostLog(char* file, int line);

@class	NSLogConsoleView;

@interface NSLogConsole : NSObject {
    NSPipe __strong*pipe;
    NSFileHandle __strong *pipeReadHandle, __strong *pipeWriteHandle;
    int new_stderr;
    
	BOOL		autoOpens;
	
	IBOutlet	id	window;
	IBOutlet	NSLogConsoleView*	webView;
	IBOutlet	id searchField;
	
	int			original_stderr;
	NSString*	logPath;
	NSFileHandle*	fileHandle;
	
	unsigned long long	fileOffset;

	// Window title
	NSString*	windowTitle;
}


+ (id)sharedConsole;

- (void)open;
- (void)close;
- (BOOL)isOpen;
- (IBAction)clear:(id)sender;
- (IBAction)searchChanged:(id)sender;
- (id)window;

- (void)logData:(NSData*)data file:(char*)file lineNumber:(int)line;
- (void)updateLogWithFile:(char*)file lineNumber:(int)line data:(NSData *)data;

@property BOOL autoOpens;
@property (copy) NSString* windowTitle;

@end


@interface NSWindow(Goodies)
- (void)setBottomCornerRounded:(BOOL)a;
@end



@interface NSLogConsoleView : WebView {

	// A message might trigger console opening, BUT the WebView will take time to load and won't be able to display messages yet.
	// Queue them - they will be unqueued when WebView has loaded.
	id		messageQueue;
	
	BOOL	webViewLoaded;
}

- (void)logString:(NSString*)string file:(char*)file lineNumber:(int)line;
- (void)clear;
- (void)search:(NSString*)string;

@end

