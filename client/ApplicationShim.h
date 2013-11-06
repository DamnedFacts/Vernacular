//
//  ApplicationShim.h
//  Vernacular
//
//  Created by Richard Sarkis on 7/31/13.
//
//

#import <Foundation/Foundation.h>
#import <Renaissance/Renaissance.h>
#import <RSWebSocketApplication/RSWebSocketApplication.h>

@class ControllerShim;

@interface ApplicationShim: NSObject {
    NSString *_appName;
    NSImage *_appIcon;
    NSString *_uriPrefix;
    NSString *_curiePrefix;
    ControllerShim *_controller;
    RSWebSocketApplication *_wsa;
    NSDictionary *nameTable;
}
@property (nonatomic, retain) ControllerShim *controller;
@property (nonatomic, retain) NSString *curiePrefix;
@property (retain) NSString *uriPrefix;
@property (retain) NSString *appName;
@property (retain) NSImage *appIcon;
@property (nonatomic,retain) RSWebSocketApplication *wsa;

-(id)initWithInfo:(NSString *)uri name: (NSString *)name;
-(void) beginApplication;
-(void) handleEvent:(NSURL *)topicUri event:(id)event;

@end