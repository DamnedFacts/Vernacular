//
//  ControllerShim.m
//  Vernacular
//
//  Created by Richard Sarkis on 8/12/13.
//
//

#import "ControllerShim.h"
#import "ApplicationShim.h"

@implementation ControllerShim
-(id)init
{
    self = [super init];
    if (self) {
        self.wsa = [[NSApp delegate] wsa];
        self.curiePrefix = [[[NSApp delegate] selectedApp] curiePrefix];
        self.keyValueStore = [NSMutableDictionary dictionary];
        return self;
    }
    return nil;
}

#pragma mark Key-Value coding compliance
- (id) valueForUndefinedKey:(NSString *)key {
    return [self.keyValueStore objectForKey:key];
}

- (void) setValue: (id)anObject  forUndefinedKey: (NSString*)key {    
    NSLog (@"Set value \"%@\" for key \"%@\" of %@", anObject, key, [self class]);
    [self.keyValueStore setObject:anObject forKey:key];
    
    // Set WAMP subscription event for the referencing object outlet connections.
    NSString *topicUri = [NSString stringWithFormat:@"%@:%@.iboutlet", self.curiePrefix, key];

    [self.wsa sendSubscribeMessage: topicUri];
}

-(IBAction)genericAction:(id)sender {
    // Remove colon from end of method selector.
    NSString *wsaRemoteMethodName = [NSString stringWithUTF8String:sel_getName(_cmd)];
    if ( [wsaRemoteMethodName length] > 0)
        wsaRemoteMethodName = [wsaRemoteMethodName substringToIndex:[wsaRemoteMethodName length] - 1];
    
    NSString *call = [NSString stringWithFormat:@"%@:%@",  self.curiePrefix, wsaRemoteMethodName];
    
    // FIXME Factor this out into a separate utility function designed to pull out
    // values from the various UI widgets. Buttons, for example,
    NSString *value = nil;
    if ([sender isKindOfClass:[NSButton class]])
        value = [sender title];
    
    NSArray  *callArgs = [NSArray arrayWithObjects:@{@"value":value}, nil];
    NSLog(@"Send %@ call to Authobahn Value: %@", wsaRemoteMethodName,callArgs);
    [self.wsa sendCallMessage:call
                       target:[[NSApp delegate] selectedApp]
               resultSelector:@selector(handleCallBack:)
                errorSelector:@selector(handleCallError:errorURI:errorDesc:errorDetails:)
                         args:callArgs];
}

-(void)setAction:(SEL)actionSelector {
    IMP actionTemplate = [self methodForSelector:@selector(genericAction:)];
    // Obj-C Runtime swizzling. We're taking the method "generalCaseTest" and renaming it and
    // parameterizing it with the index number of the Autobahn test case we want it to run.
    NSLog(@"setAction: %@ %@ %s",[self class], self, sel_getName(actionSelector));
    class_addMethod([self class], actionSelector, actionTemplate, "v@:@"); // FIXME: Check BOOL return value.
}

@end
