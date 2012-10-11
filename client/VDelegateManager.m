//
//  VDelegateManager.m
//  Vernacular
//
//  Created by Richard Sarkis on 9/14/12.
//
//

#import "VDelegateManager.h"

@implementation CalculatorController
+(NSString *) stringWithSentenceCapitalization:(NSString *)string{
    return [NSString stringWithFormat:@"%@%@",[[string substringToIndex:1] capitalizedString],[string substringFromIndex:1]];
}


-(id)init {
    wsa = [[NSApp delegate] wsa];
    keyValueStore = [NSMutableDictionary dictionary];
    
    //FIXME
    curiePrefix = @"calculator";

    return self;
}

#pragma mark Key-Value coding compliance
- (id) valueForUndefinedKey:(NSString *)key {
    return [keyValueStore objectForKey:key];
}

- (void) setValue: (id)anObject  forUndefinedKey: (NSString*)key {
    NSLog (@"Set value \"%@\" for key \"%@\" of %@", anObject, key, [self class]);
    [keyValueStore setObject:anObject forKey:key];
    
    // Set WAMP-based callback event
    // FIXME
    NSString *topicUri = @"calculator:textField.setStringValue";
    [wsa sendSubscribeMessage: topicUri];

}

-(IBAction)genericAction:(id)sender {    
    // Remove colon from end of method selector.
    NSString *wsaRemoteMethodName = [NSString stringWithUTF8String:sel_getName(_cmd)];
    if ( [wsaRemoteMethodName length] > 0)
        wsaRemoteMethodName = [wsaRemoteMethodName substringToIndex:[wsaRemoteMethodName length] - 1];
    
    NSString *call = [NSString stringWithFormat:@"%@:%@", curiePrefix, wsaRemoteMethodName];
    
    // FIXME Factor this out into a separate utility function designed to pull out
    // values from the various UI widgets. Buttons, for example, 
    NSString *value;
    if ([sender isKindOfClass:[NSButton class]])
        value = [sender title];
    
    NSArray  *callArgs = [NSArray arrayWithObjects:@{@"value":value}, nil];
    NSLog(@"Send %@ call to Authobahn Value: %@", wsaRemoteMethodName,callArgs);
    [wsa sendCallMessage:call target:self selector:@selector(callBack:) args:callArgs];
}

-(void)addActionMethod:(SEL)actionSelector {
    IMP actionTemplate = [self methodForSelector:@selector(genericAction:)];
    // Obj-C Runtime swizzling. We're taking the method "generalCaseTest" and renaming it and
    // parameterizing it with the index number of the Autobahn test case we want it to run.
    NSLog(@"%@ %@ %s",[self class], self, sel_getName(actionSelector));
    class_addMethod([self class], actionSelector, actionTemplate, "v@:@"); // FIXME: Check BOOL return value.
}

-(void)callBack:(id)value {
    
}

@end




@implementation VDelegateManager
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
}

-(id)init {
	return [super init];
}

-(id)initWithGSMarkupData:(NSData *)GSMainMarkup {
    
    BOOL b = [NSBundle loadGSMarkupData: GSMainMarkup
                               withName:@"FIXME?"
                      externalNameTable: [NSDictionary dictionaryWithObject: self forKey: @"NSOwner"]
                               withZone: NULL
                localizableStringsTable:@"FIXME?"
                               inBundle:nil];
    
    if (b) {
        NSLog (@"GS markup loaded!");
    } else {
        NSLog (@"Could not load GS Data!");
    }
    
    // Instead of coercing RIB defined objects into Cocoa native types, perhaps proxy objects instead?
    return [self init];
}

#pragma mark GSMarkup Delegate
- (void) bundleDidLoadGSMarkup: (NSNotification *)aNotification {
    NSLog(@"bundleDidLoadGSMarkup");
    
    NSDictionary *nameTable = [[aNotification userInfo] objectForKey:@"nameTable"];
    for (id aKey in nameTable) {
        id object = [nameTable objectForKey:aKey];
        NSLog(@"%@", object);
        if ([object respondsToSelector:@selector(target)]) {
            [[object target] addActionMethod:[object action]];
        }
    }
 }

- (void)delegateCallBack:(NSURL *)topicUri event:(id)event {
    // http://example.com/simple/calculator#textField.setStringValue 1
    NSLog(@"topicUri: %@ %@", topicUri, event);
    NSString *fragment = [topicUri fragment];
    NSArray *keyValue = [fragment componentsSeparatedByString: @"."];
    NSLog(@"%@ %@", [keyValue objectAtIndex:0], [keyValue objectAtIndex:1]);
    NSString *key = [keyValue objectAtIndex:0];
    NSString *selector = [NSString stringWithFormat:@"%@:", [keyValue objectAtIndex:1]];

    [[controller valueForKey:key] performSelector:NSSelectorFromString(selector) withObject:event];
}
@end
