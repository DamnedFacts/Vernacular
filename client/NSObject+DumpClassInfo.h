//
//  NSObject+DumpClassInfo.h
//  DumpSelectors
//
//  Created by Bennett Smith on 1/14/12.
//  Copyright (c) 2012 iDevelopSoftware, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (DumpClassInfo)
- (void)dumpClassInfo: (id)obj signaturesTable:(NSMutableDictionary *)methodSignatures flattenInheritance:(bool)flattenFlag ignorePrivateMethods:(bool)ignoreFlag;
@end
