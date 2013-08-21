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
    NSString *_curiePrefix;
}

@property (nonatomic,retain) NSString *curiePrefix;
@property (nonatomic,retain) NSMutableDictionary *keyValueStore;
@property (nonatomic,retain) RSWebSocketApplication *wsa;

-(void) setAction:(SEL)actionSelector;
@end

