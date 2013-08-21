//
//  NSSortDescriptor-Layers.h
//
//  Created by Scott Stevenson on Tue Mar 13 2005.
//  Released under a BSD-style license. See License.txt
//

#import <Foundation/Foundation.h>


@interface NSSortDescriptor (THLayers)

+ (NSArray *)  ascendingDescriptorsForKeys: (NSString *)firstKey,...;
+ (NSArray *) descendingDescriptorsForKeys: (NSString *)firstKey,...;

@end
