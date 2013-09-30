//
//  KAppDelegate.m
//  iOS7_Multitasking
//
//  Created by corptest on 13-9-30.
//  Copyright (c) 2013年 klaus. All rights reserved.
//

#import "KAppDelegate.h"
#import "KMainViewController.h"
#import "KUtily.h"
#import "KiOS7Downloader.h"

@interface KAppDelegate ()

@property (strong, nonatomic) KBasicBlock completionHandler;

@end

@implementation KAppDelegate

- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    // 申请消息推送权限
//    if ([[UIApplication sharedApplication] enabledRemoteNotificationTypes] == UIRemoteNotificationTypeNone) {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert];
//    }
    
    if (launchOptions && [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey]) {
        NSLog(@"通过push启动应用，数据:%@", [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey]);
        
        if ([launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey] && [[launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey] isKindOfClass:[NSDictionary class]]) {
            NSDictionary *dic = (NSDictionary *)[launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
            if ([dic objectForKey:@"t"] && [[dic objectForKey:@"t"] isKindOfClass:[NSString class]]) {
                NSLog(@"************************");
                NSLog(@"************************");
                NSLog(@"接收到t:%@", [dic objectForKey:@"t"]);
                NSLog(@"************************");
                NSLog(@"************************");
            }
        }
    }
    
    self.window.rootViewController = [[KMainViewController alloc] init];
    
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    
    // 先去检查是否有异常退出的后台下载task
    [KiOS7Downloader sharedDownloader];
    
    // 设置后台fetch间隔
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    return YES;
}

// 拿到本设备的Device Token
- (void) application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken NS_AVAILABLE_IOS(3_0)
{
    NSLog(@"原始deviceToken:%@", [deviceToken description]);
}

// 申请推送权限失败
- (void) application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error NS_AVAILABLE_IOS(3_0)
{
    NSLog(@"申请推送权限失败:%@", error);
}

// app在前台时接收到推送消息
- (void) application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo NS_AVAILABLE_IOS(3_0)
{
    NSLog(@"接收到推送信息:%@", userInfo);
}

- (void) application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification NS_AVAILABLE_IOS(4_0)
{
    NSLog(@"本地通知:%@", notification);
}

// 有限制，1小时内只能执行10次以下，而且用户关闭应用之后就没用了。。。
// 要在payload中加入{aps:{content-available:1}}
- (void) application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler NS_AVAILABLE_IOS(7_0)
{
    NSLog(@"&&&&&&&&&&&&&&&&&&&&&&&&");
    NSLog(@"&&&&&&&&&&&&&&&&&&&&&&&&");
    NSLog(@"接收到t:%@", [userInfo objectForKey:@"t"]);
    NSLog(@"&&&&&&&&&&&&&&&&&&&&&&&&");
    NSLog(@"&&&&&&&&&&&&&&&&&&&&&&&&");
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    if (notification != nil) {
        notification.fireDate = [NSDate dateWithTimeIntervalSinceNow:5];
        notification.timeZone = [NSTimeZone defaultTimeZone];
        notification.alertBody = [NSString stringWithFormat:@"接到push t:%@", [userInfo objectForKey:@"t"]];
        notification.applicationIconBadgeNumber = 1;
        notification.soundName = UILocalNotificationDefaultSoundName;
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    }
    
    if ([userInfo objectForKey:@"t"] && [[userInfo objectForKey:@"t"] isKindOfClass:[NSString class]]) {
        completionHandler(UIBackgroundFetchResultNewData);
        return;
    }
    completionHandler(UIBackgroundFetchResultNoData);
}

// 后台获取数据：重点是，不知道什么时候会去fetch数据...
- (void) application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler NS_AVAILABLE_IOS(7_0)
{
    // 好的做法是在某个地方，然后将completionHandler传过去，由那里调用。具体情况具体对待。
    // [[KBackgroundFetchManager sharedManager] performFetchWithCompletionHandler:completionHandler];
    // 参数UIBackgroundFetchResultNewData表示获取到新数据，如果需要更新UI，因为系统的App Switcher会更新你的App的截图
    
    [[[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:@"http://DST54398.local:8080/c!test.action"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            // 不知道UIBackgroundFetchResultFailed对App有神马影响
            completionHandler(UIBackgroundFetchResultFailed);
            return;
        }
        // 返回json数据：{"img":"http://www.abc.com/123.jpg"}
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        if (dic && dic.count > 0 && [dic objectForKey:@"img"]) {
            [[[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:[dic objectForKey:@"img"]] completionHandler:^(NSData *data1, NSURLResponse *response1, NSError *error1) {
                // 此处我就不做error处理了
                // 此处更新了MainViewController.view中的UIImageView的image，按两次home键可以看到更新的图片已经更新到App Switcher中
                [((KMainViewController *)self.window.rootViewController).imgView setImage:[UIImage imageWithData:data1]];
                completionHandler(UIBackgroundFetchResultNewData);
            }] resume];
        } else {
            completionHandler(UIBackgroundFetchResultNoData);
        }
    }] resume];
}

// 后台下载完毕，只有一个session中的下载结束后才会调用此方法。如果需要下载多个文件，下载完一个就启动本地通知，可以多个session进行下载
- (void) application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler NS_AVAILABLE_IOS(7_0)
{
    [[NSFileManager defaultManager] createFileAtPath:[NSString stringWithFormat:@"%@/appdelegate.txt", [KUtily documentsPath]] contents:[[NSString stringWithFormat:@"identifier:%@,下载完毕", identifier] dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    if (notification != nil) {
        notification.fireDate = [NSDate dateWithTimeIntervalSinceNow:2];
        notification.timeZone = [NSTimeZone defaultTimeZone];
        notification.alertBody = [NSString stringWithFormat:@"identifier:%@,下载完毕", identifier];
        notification.applicationIconBadgeNumber = 1;
        notification.soundName = UILocalNotificationDefaultSoundName;
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    }
    self.completionHandler = completionHandler;
}

- (KBasicBlock) backgroundDownloadCompletionHandler
{
    return self.completionHandler;
}

- (void) applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void) applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void) applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void) applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void) applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
