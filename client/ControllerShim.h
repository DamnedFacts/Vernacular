//
//  ControllerShim.h
//  Vernacular
//
//  Created by Richard Sarkis on 8/12/13.
//
//

#import <objc/objc-class.h>
#import <Foundation/Foundation.h>
#import <RSWebSocketApplication/RSWebSocketApplication.h>
#import "VAMain.h"

@interface ControllerShim: NSObject {
    RSWebSocketApplication   *_wsa;
    NSMutableDictionary  *_keyValueStore;
    NSString *_curiePrefix, *_uriPrefix;
}

@property (nonatomic,retain) NSString *curiePrefix, *uriPrefix;
@property (nonatomic,retain) NSMutableDictionary *keyValueStore;
@property (nonatomic,retain) RSWebSocketApplication *wsa;

-(void) setRemoteBindingsForNamedObject:(NSString *)name object:(id)anObject signatures:(NSDictionary *)methodSignatures baseUri:topicUri;
-(void) setAction:(SEL)actionSelector;
@end

