//
//  NSObject+DumpClassInfo.m
//  DumpSelectors
//
//  Created by Bennett Smith on 1/14/12.
//  Copyright (c) 2012 iDevelopSoftware, Inc. All rights reserved.
//

#import <objc/runtime.h>

static void dumpClassInfo(Class c, int inheritanceDepth, bool flattenInheritance, NSMutableDictionary *methodSignatures)
{
    Class superClass;
    superClass = class_getSuperclass(c);
    NSString *key;
    
    if (superClass != Nil)
    {
        NSLog(@"superClass: %@", superClass);
        if (flattenInheritance) {
            NSArray *values = [methodSignatures allKeys];
            key = [values objectAtIndex:0];
        } else {
            key = NSStringFromClass(superClass);
            [methodSignatures setObject:[NSMutableDictionary new] forKey:key];
        }
        dumpClassInfo(superClass, (inheritanceDepth + 1), flattenInheritance, methodSignatures);
    }
    
    int i = 0;
    unsigned int mc = 0;

    Method* mlist = class_copyMethodList(c, &mc);
    
    for (i = 0; i < mc; i++)
    {
        Method method = mlist[i];
        
        SEL methodSelector = method_getName(method);
        const char* methodName = sel_getName(methodSelector);
        const char *typeEncodings = method_getTypeEncoding(method);
        
        [[methodSignatures objectForKey:key] setObject: @{@"typeEncodings": [NSString stringWithCString:typeEncodings
                                                                                               encoding:NSASCIIStringEncoding],
                                                          @"inheritanceDepth": [NSNumber numberWithInt:inheritanceDepth]}
                                                forKey:[NSString stringWithCString:methodName
                                                                          encoding:NSASCIIStringEncoding]];
    }
}

@implementation NSObject (DumpClassInfo)

- (void)dumpClassInfo: (id)obj signaturesTable:(NSMutableDictionary *)methodSignatures flattenInheritance:(bool)flag
{
    Class c =  object_getClass(obj);
    [methodSignatures setObject:[NSMutableDictionary new] forKey:NSStringFromClass(c)];
    dumpClassInfo(c, 0, flag, methodSignatures);
}
@end
