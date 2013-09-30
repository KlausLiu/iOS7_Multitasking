//
//  KDefine.h
//
//  Created by klaus on 13-9-28.
//  Copyright (c) 2013年 klaus. All rights reserved.
//

#ifndef iOS7_MultiTask_KDefine_h
#define iOS7_MultiTask_KDefine_h

typedef void(^KBasicBlock)(void);

#define kIs64   __LP64__ || (TARGET_OS_EMBEDDED && !TARGET_OS_IPHONE) || TARGET_OS_WIN32 || NS_BUILD_32_LIKE_64

#endif
