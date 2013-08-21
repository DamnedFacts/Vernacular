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


- (void)handleCallBack:(id)value {
    NSLog(@"ApplicationShim handleCallBack:");
    NSLog(@"%@", value);
}

- (void)handleCallError: (NSString *)callId errorURI:(NSString *)uri errorDesc:(NSString*)desc errorDetails:(id)details {
    NSLog(@"Received error: %@ %@ %@ %@", callId, uri, desc, details);
}

- (void)handleEvent:(NSURL *)topicUri event:(id)event {
    // http://example.com/simple/calculator#textField.iboutlet {selector, parameter}
    NSLog(@"topicUri: %@ %@", topicUri, event);
    NSString *fragment = [topicUri fragment];
    
    // Our object for a GUI element. Pull out left-hand value, ignoring ".iboutlet"
    NSString *objectName = [[fragment componentsSeparatedByString: @"."] objectAtIndex:0];
    
    // The selector to call upon this object.
    SEL selector = NSSelectorFromString([event objectForKey:@"selector"]);
    
    NSLog(@"handleEvent target:%@ action:%@", objectName, NSStringFromSelector(selector));
    
    // We're assuming only one value, so FIXME. Use NSInvocation for objects with
    // choosen selectors that take multiple arguments.
    id param = [[event objectForKey:@"parameters"] objectAtIndex:0];
    
    [[self.controller valueForKey:objectName] performSelector:selector withObject:param];
}


- (void) beginApplication
{
    // Send the app
    if (self.uriPrefix) {
        NSLog(@"Curie: %@", self.curiePrefix);
        [self.wsa sendPrefixMessage:self.curiePrefix uri:self.uriPrefix];
    }
    
    // Call for main RIB (Renaissance Interface Builder) data
    NSString *call = [NSString stringWithFormat:@"%@:mainRibData", self.curiePrefix];
    [self.wsa sendCallMessage:call target:self
          resultSelector:@selector(loadMainGSMarkupData:)
           errorSelector:@selector(handleCallError:errorURI:errorDesc:errorDetails:)
                    args:[NSArray arrayWithObjects: nil]];
}


-(id)loadMainGSMarkupData:(id)value
{
    
    BOOL b = [NSBundle loadGSMarkupData: [value dataUsingEncoding:NSUTF8StringEncoding]
                               withName:@"FIXME"
                      externalNameTable: [NSDictionary dictionaryWithObject: self forKey: @"NSOwner"]
                               withZone: NULL
                localizableStringsTable:@"FIXME"
                               inBundle:nil];
    
    if (b) {
        NSLog (@"GS markup loaded!");

        NSString *call = [NSString stringWithFormat:@"%@:applicationDidFinishLaunching", self.curiePrefix];
        [self.wsa sendCallMessage:call target:self
                   resultSelector:@selector(handleCallBack:)
                    errorSelector:@selector(handleCallError:errorURI:errorDesc:errorDetails:)
                             args:[NSArray arrayWithObjects: nil]];
        return [self init];
    } else {
        NSLog (@"Could not load GS Data!");
        return nil;
    }
    
    // Instead of coercing RIB defined objects into Cocoa native types, perhaps proxy objects instead?
}

#pragma mark GSMarkup Delegate
- (void) bundleDidLoadGSMarkup: (NSNotification *)aNotification {
    NSLog(@"bundleDidLoadGSMarkup");
    
    nameTable = [[aNotification userInfo] objectForKey:@"nameTable"];
    for (id aKey in nameTable) {
        id topLevelObject = [nameTable objectForKey:aKey];
        
        // All instance delcarations in the IB XML file need to be an instance of ApplicationShim.
        // We are finding all NSControls that respond to target:, in order to associate a
        // shim action method to that object.
        if ([topLevelObject isKindOfClass:[ControllerShim class]]){
             self.controller = topLevelObject;
        }
             
        if ([topLevelObject respondsToSelector:@selector(target)] && [topLevelObject action]) {
            //
            // [object target] should be of instance type ApplicationShim.
            // This instance will be automatically instantiated with the GSMarkup file is loaded.
            //
            // [object action] should be the defined action selector in the XML file.
            //
            NSLog(@"Object: %@ Target:%@ Action:%@", topLevelObject, [topLevelObject target], NSStringFromSelector([topLevelObject action]));
            [[topLevelObject target] setAction:[topLevelObject action]];
        }
    }
}
@end