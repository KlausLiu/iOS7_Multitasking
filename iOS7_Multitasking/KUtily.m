//
//  Utily.m
//  iOS7_MultiTask
//
//  Created by corptest on 13-9-27.
//  Copyright (c) 2013年 klaus. All rights reserved.
//

#import "KUtily.h"

@implementation KUtily

+ (NSString *) documentsPath
{
#if TARGET_IPHONE_SIMULATOR
    return @"/Users/corptest";
#elif TARGET_OS_IPHONE
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
#endif
}

@end
