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
        self.uriPrefix = [[[NSApp delegate] selectedApp] uriPrefix];
        self.curiePrefix = [[[NSApp delegate] selectedApp] curiePrefix];
        self.keyValueStore = [NSMutableDictionary dictionary];
        return self;
    }
    return nil;
}

- (void)handleCallBack:(id)value {
    NSLog(@"FIXME ControllerShim handleCallBack:");
    NSLog(@"%@", value);
}

- (void)handleCallError: (NSString *)callId errorURI:(NSString *)uri errorDesc:(NSString*)desc errorDetails:(id)details {
    NSLog(@"FIXME ControllerShim handleCallError: %@ %@ %@ %@", callId, uri, desc, details);
}

#pragma mark Key-Value coding compliance
- (id) valueForUndefinedKey:(NSString *)key {
    return [self.keyValueStore objectForKey:key];
}

- (void) setValue: (id)anObject  forUndefinedKey: (NSString*)key {    
    NSLog (@"Set value \"%@\" for key \"%@\" of %@", anObject, key, [self class]);
    [self.keyValueStore setObject:anObject forKey:key];
    
    // Register this object to receive all Objective-C style messages sent to it
    NSMutableDictionary *methodSignatures = [[NSMutableDictionary alloc] init];
    [self dumpClassInfo: anObject
        signaturesTable: methodSignatures
     flattenInheritance: TRUE
   ignorePrivateMethods:TRUE];
    
    [self setRemoteBindingsForNamedObject:key object:anObject signatures:methodSignatures baseUri:self.curiePrefix];
}

-(void) setRemoteBindingsForNamedObject:(NSString *)name object:(id)anObject signatures:(NSDictionary *)methodSignatures baseUri:(NSString *)uri
{
    NSString *topicUri = [NSString stringWithFormat:@"%@:%@.iboutlet", uri, name];
    NSString *call = [NSString stringWithFormat:@"%@:setRemoteMethodBindingsForObject_",  self.curiePrefix];
    NSArray  *callArgs = [NSArray arrayWithObjects:@{@"object":name, @"methodSignatures":methodSignatures}, nil];

    [self.wsa sendCallMessage:call
                       target:self
               resultSelector:@selector(handleCallBack:)
                errorSelector:@selector(handleCallError:errorURI:errorDesc:errorDetails:)
                         args:callArgs];
    
//    [self.wsa registerMethodForRpc:anObject selector:selector baseUri:topicUri]

    [self.wsa registerForRpc:anObject baseUri:topicUri];
}

-(IBAction)genericAction:(id)sender {
    // Convert colons ":" to underscores "_" in selector names
    NSString *wsaRemoteMethodName = [NSString stringWithUTF8String:sel_getName(_cmd)];
    wsaRemoteMethodName = [wsaRemoteMethodName stringByReplacingOccurrencesOfString:@":"
                                                                         withString:@"_"];
    
    NSString *call = [NSString stringWithFormat:@"%@:%@",  self.curiePrefix, wsaRemoteMethodName];
    
    // FIXME Factor this out into a separate utility function designed to pull out
    // values from the various UI widgets. Buttons, for example,
    NSString *value = nil;
    if ([sender isKindOfClass:[NSButton class]]) {
        value = [sender title];
    } else if ([sender isKindOfClass:[NSTextField class]]) {
        value = [sender stringValue];
    }
    
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
