//
//  VDelegateManager.h
//  Vernacular
//
//  Created by Richard Sarkis on 9/14/12.
//
//

#import <objc/objc-class.h>
#import <Cocoa/Cocoa.h>
#import <Renaissance/Renaissance.h>
#import <RSWebSocketApplication/RSWebSocketApplication.h>

@interface CalculatorController: NSObject {
    RSWebSocketApplication *wsa;
    NSMutableDictionary *keyValueStore;
    NSString *curiePrefix;
}

@end


@interface VDelegateManager : NSObject <NSApplicationDelegate> {
    CalculatorController *controller;
}

@property (assign, nonatomic) RSWebSocketApplication *wsa;

- (void)applicationDidFinishLaunching: (NSNotification *)aNotification;
- (id)initWithGSMarkupData:(NSData *)GSMarkup;
- (void) bundleDidLoadGSMarkup: (NSNotification *)aNotification;
- (void)delegateCallBack:(NSURL *)topicUri event:(id)event;
@end