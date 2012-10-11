//
//  RSURLField.h
//  Vernacular
//
//  Created by Richard Sarkis on 8/27/12.
//
//

#import <Cocoa/Cocoa.h>

@interface RSURLField : NSTextField
{
    BOOL valid_url;
}

-(BOOL) isValidUrl;
-(void) textDidChange:(NSNotification *)notification;
@end
