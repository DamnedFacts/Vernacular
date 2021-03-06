//
//  VAAppShimController.m
//  Vernacular
//
//  Created by Richard Sarkis on 7/31/13.
//
//

#import "ApplicationShim.h"
#import "ControllerShim.h"

@implementation ApplicationShim
-(id)initWithInfo:(NSString *)uri name:(NSString *)name
{
    self = [self init];
    if (self) {
        self.uriPrefix  = uri;
        self.curiePrefix = [[NSString alloc] initWithString: [[[uri stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString: @"#"]]
                                                               componentsSeparatedByString: @"/"] lastObject]];
        // FIXME: Here, we'd ideally have a custom icon provided to us
        self.appIcon = [NSImage imageNamed:@"GenericWSApplicationIcon"];
        self.appName = name;
        self.wsa = [[NSApp delegate] wsa];
        
        return self;
    }
    return nil;
}

- (NSString *) uniqueString
{
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    NSString *uString = (NSString *)CFBridgingRelease(CFUUIDCreateString(NULL, uuid));
    CFRelease(uuid);
    return uString;
}


- (void)handleCallBack:(id)value {
    NSLog(@"FIXME ApplicationShim handleCallBack:");
    NSLog(@"%@", value);
}

- (void)handleCallError: (NSString *)callId errorURI:(NSString *)uri errorDesc:(NSString*)desc errorDetails:(id)details {
    NSLog(@"FIXME ApplicationShim handleCallError: %@ %@ %@ %@", callId, uri, desc, details);
}

- (void)handleEvent:(NSURL *)topicUri event:(id)event {
    // Forwarded from VAMain class instance who is the delegate for RSWebSocketApplication.
    // FIXME May want to forward this event on to ControllerShim instance?
    
    NSString *fragment = [topicUri fragment];
    if ([fragment compare:@"GSMarkupEvent" ] == NSOrderedSame) {
        [self loadGSMarkupData: [event objectForKey:@"markup"]];
    }
}

- (void) loadIbData:(id)value {
    NSLog(@"%@", value);
    [self loadGSMarkupData: [value objectForKey:@"markup"]];
}

- (void) loadMainIbFileCallBack:(id)value
{

    NSLog(@"%@", value);
    [self loadGSMarkupData: [value objectForKey:@"markup"]];
    
    // FIXME Calls from Vernacular client through Autobahn will have their results
    // returned asynchronously, which needs to be handled if that is unwanted.
    
    // Register a RPC that will instruct the Vernacular client to load sent IB data
    NSString *selector = @"loadIbData:";
    Method meth = class_getInstanceMethod([self class], NSSelectorFromString(selector));
    NSString *typeSignature = [NSString stringWithCString:method_getTypeEncoding(meth)
                                                 encoding:NSASCIIStringEncoding];
    [self.controller setRemoteBindingsForNamedObject:@"clientControl"
                                              object:self
                                          signatures:@{NSStringFromClass([self class]):@{selector:typeSignature}}
                                             baseUri:self.curiePrefix];
        
    NSString *call = [NSString stringWithFormat:@"%@:applicationDidFinishLaunching", self.curiePrefix];
    [self.wsa sendCallMessage:call
                       target:self
               resultSelector:@selector(handleCallBack:)
                errorSelector:@selector(handleCallError:errorURI:errorDesc:errorDetails:)
                         args:[NSArray arrayWithObjects: nil]];
}

- (void) beginApplication
{
    // Send the app curie prefix we will be using
    if (self.uriPrefix) {
        NSLog(@"Curie: %@", self.curiePrefix);
        [self.wsa sendPrefixMessage:self.curiePrefix uri:self.uriPrefix];
    }
    
    // Indicate that this app is now the active app to the server
    [self.wsa sendCallMessage:[NSString stringWithFormat:@"registerAppAsRunning"]
                       target:self
               resultSelector:@selector(handleCallBack:)
                errorSelector:@selector(handleCallError:errorURI:errorDesc:errorDetails:)
                         args:[NSArray arrayWithObjects: self.appName, nil]];
    
    // Call for main IB (GS Markup Interface Builder) data
    [self.wsa sendCallMessage:[NSString stringWithFormat:@"%@:loadMainIbFile", self.curiePrefix]
                       target:self
               resultSelector:@selector(loadMainIbFileCallBack:)
                errorSelector:@selector(handleCallError:errorURI:errorDesc:errorDetails:)
                         args:[NSArray arrayWithObjects: nil]];
}


-(id)loadGSMarkupData:(id)value
{
    BOOL b = [NSBundle loadGSMarkupData: [value dataUsingEncoding:NSUTF8StringEncoding]
                               withName:@"FIXME"
                      externalNameTable: [NSDictionary dictionaryWithObject: self forKey: @"NSOwner"]
                               withZone: NULL
                localizableStringsTable:@"FIXME"
                               inBundle:nil];
    
    if (b) {
        NSLog (@"GS markup loaded!");
        return [self init];
    } else {
        NSLog (@"Could not load GS Data!");
        return nil;
    }
    
    // Instead of coercing IB defined objects into Cocoa native types, perhaps proxy objects instead?
}

/* We're overriding our property's setter in order to catch the setting of our controller object
 our simplified model of Apple's MVC is relying on one instance of a controller object for all
 instantiated GSMarkupObjects. The controller is meant to be a generic, well, controller.
 */
- (void)setController:(ControllerShim *)controller
{
    if (self.controller) {
        // Since we want only one controller instance, we merge the dictionary from the controller
        // object that is threatening to override our current controller.
        [[self.controller keyValueStore] addEntriesFromDictionary: [controller keyValueStore]];
    } else {
        // The controller has not been set yet, so assign one.
        _controller = controller;
    }
}
#pragma mark GSMarkup Delegate
/* Delegate method is called upon loading of GSMarkUp. Despite the name of the
 passed-in parameter, it is not a notification
 */
- (void) bundleDidLoadGSMarkup: (NSNotification *)aNotification {
    NSLog(@"bundleDidLoadGSMarkup");
    
    nameTable = [[aNotification userInfo] objectForKey:@"nameTable"];
    for (id aKey in nameTable) {
        id namedObject = [nameTable objectForKey:aKey];
        
        if ([namedObject respondsToSelector:@selector(target)] && [namedObject action]) {
            //
            // [object target] should be of instance type ApplicationShim.
            // This instance will be automatically instantiated with the GSMarkup file is loaded.
            //
            // [object action] should be the defined action selector in the XML file.
            //
            NSLog(@"Object: %@ Target:%@ Action:%@", namedObject, [namedObject target],
                  NSStringFromSelector([namedObject action]));
            [[namedObject target] setAction:[namedObject action]];
        }
    }
}
@end