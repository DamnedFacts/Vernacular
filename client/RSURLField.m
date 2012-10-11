//
//  RSURLField.m
//  Vernacular
//
//  Created by Richard Sarkis on 8/27/12.
//
//

#import "RSURLField.h"

@implementation RSURLField

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    valid_url = NO;
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
}

-(BOOL) isValidUrl
{
    // replace content with its intValue ( or process the input's value differently )
    NSURL *candidateURL = [NSURL URLWithString:[self stringValue]];
    // WARNING > "test" is an URL according to RFCs, being just a path
    // so you still should check scheme and all other NSURL attributes you need
    if (candidateURL && candidateURL.scheme && candidateURL.host) {
        // candidate is a well-formed url with:
        //  - a scheme (like http://)
        //  - a host (like stackoverflow.com)
        if (![candidateURL.scheme isEqualToString:@"ws"] &&
            ![candidateURL.scheme isEqualToString:@"wss"]) {
            valid_url = NO;
        } else {
            valid_url = YES;
        }
    }
    return valid_url;
}

-(void) textDidChange:(NSNotification *)notification {
	// make sure the notification is sent back to any delegate
    [self isValidUrl];
	[super textDidChange:notification];
}
@end
