//
//  KAppDelegate.h
//  iOS7_Multitasking
//
//  Created by corptest on 13-9-30.
//  Copyright (c) 2013年 klaus. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KDefine.h"

@interface KAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

- (KBasicBlock) backgroundDownloadCompletionHandler;

@end
