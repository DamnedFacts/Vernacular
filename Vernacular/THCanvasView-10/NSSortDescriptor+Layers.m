//
//  NSSortDescriptor-Layers.m
//
//  Created by Scott Stevenson on Tue Mar 13 2005.
//  Released under a BSD-style license. See License.txt
//

#import "NSSortDescriptor+Layers.h"


@implementation  NSSortDescriptor (THLayers)


+ (NSArray *) ascendingDescriptorsForKeys: (NSString *)firstKey,...
{
    
    NSMutableArray    __strong *returnArray   = [NSMutableArray arrayWithCapacity: 5];
    va_list           keyList;
    
    NSString          * oneKey;
    NSSortDescriptor  * oneDescriptor;
    
    if (firstKey)
    {
        oneDescriptor = [[NSSortDescriptor alloc] initWithKey: firstKey
                                                    ascending: YES];
        [returnArray addObject: oneDescriptor];
        
        va_start (keyList, firstKey);
        
        while (oneKey = va_arg(keyList, NSString *))
        {
            oneDescriptor = [[NSSortDescriptor alloc] initWithKey:oneKey ascending:YES];                           
            [returnArray addObject: oneDescriptor];
        }
        
        va_end (keyList);
    }
    
    return returnArray;
    
}

+ (NSArray *) descendingDescriptorsForKeys: (NSString *)firstKey,...
{
        
        NSMutableArray    __strong *returnArray   = [NSMutableArray arrayWithCapacity: 5];
        va_list           keyList;
        
        NSString          * oneKey;
        NSSortDescriptor  * oneDescriptor;
        
        if (firstKey)
        {
                oneDescriptor = [[NSSortDescriptor alloc] initWithKey: firstKey
                                                            ascending: NO];
                [returnArray addObject: oneDescriptor];
                
                va_start (keyList, firstKey);
                
                while (oneKey = va_arg(keyList, NSString *))
                {
                        oneDescriptor = [[NSSortDescriptor alloc] initWithKey:oneKey ascending:NO];                           
                        [returnArray addObject: oneDescriptor];
                }
                
                va_end (keyList);
        }
        
        return returnArray;
}

@end