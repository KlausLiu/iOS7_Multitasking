//
//  KiOS7Downloader.m
//  iOS7_MultiTask
//
//  Created by klaus on 13-9-28.
//  Copyright (c) 2013年 klaus. All rights reserved.
//

#import "KiOS7Downloader.h"
#import "KDefine.h"
#import "KUtily.h"
#import "KAppDelegate.h"

@interface KiOS7Downloader () <NSURLSessionDownloadDelegate>

@property (strong, nonatomic) NSOperationQueue *delegateQueue;

@property (strong, nonatomic) NSURLSession *session;

@property (strong, nonatomic) NSMutableDictionary *downloadInfoDictionary;

@end

@interface KDownloadInfo : NSObject <NSCoding>

@property (strong, nonatomic) NSString *downloadUrl;

@property (strong, nonatomic) NSString *filePath;

@property (strong, nonatomic) NSURLSessionDownloadTask *downloadTask;

@property (strong, nonatomic) NSData *resumeData;

@end

static KiOS7Downloader *instance = nil;

#define kDownloadInfoDictionaryKey  @"kDownloadInfoDictionaryKey"

#if defined (kIs64) && kIs64
#define kDownloadInfoKey(taskIdentifier)    [NSString stringWithFormat:@"kDownloadInfoPrefixKey_%lu", taskIdentifier]
#else
#define kDownloadInfoKey(taskIdentifier)    [NSString stringWithFormat:@"kDownloadInfoPrefixKey_%d", taskIdentifier]
#endif

@implementation KiOS7Downloader

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (id) sharedDownloader
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // iOS7中初始化对象时，会自动检测是否此对象是否实现NSURLSessionDownloadDelegate并是否有未正常-cancel的DownloadTask，若有则自动调用-URLSession:task:didCompleteWithError:方法并附带用作断点续传的resumeData
        instance = [[[KiOS7Downloader class] alloc] init];
        instance.delegateQueue = [[NSOperationQueue alloc] init];
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfiguration:@"com.klaus.download-demo"];
        instance.session = [NSURLSession sessionWithConfiguration:configuration delegate:instance delegateQueue:instance.delegateQueue];
        [instance loadDownloadInfoDictionary];
        [[NSNotificationCenter defaultCenter] addObserver:instance selector:@selector(appWillTerminate) name:UIApplicationWillTerminateNotification object:nil];
    });
    return instance;
}

#pragma mark - 公共方法

- (NSUInteger) downloadWithUrl:(NSString *)url filePath:(NSString *)filePath
{
    NSURLSessionDownloadTask *downloadTask = nil;
    NSMutableArray *removeKeyArray = [NSMutableArray array];
    KDownloadInfo *resumeDI = nil;      // 如果是断点续传，就要删除原来的，重新添加到dictionary中
    for (NSString *key in self.downloadInfoDictionary) {
        KDownloadInfo *di = [self.downloadInfoDictionary objectForKey:key];
        if (di.downloadTask == nil && di.resumeData == nil) {
            [removeKeyArray addObject:key];
            continue;
        }
        if ([di.downloadUrl isEqualToString:url] && [di.filePath isEqualToString:filePath]) {
            if (di.downloadTask && di.downloadTask.state == NSURLSessionTaskStateRunning) {
                // 正在下载
                return di.downloadTask.taskIdentifier;
            } else if (di.resumeData) {
                // 续传
                di.downloadTask = [self.session downloadTaskWithResumeData:di.resumeData];
                [di.downloadTask resume];
                resumeDI = di;
                [removeKeyArray addObject:key];
            } else if (di.downloadTask.state == NSURLSessionTaskStateSuspended) {
                // 暂停--开始
                [di.downloadTask resume];
            } else {
                di.downloadTask = nil;
            }
            downloadTask = di.downloadTask;
        }
    }
    if (resumeDI) {
        [self.downloadInfoDictionary setObject:resumeDI forKey:kDownloadInfoKey(resumeDI.downloadTask.taskIdentifier)];
    }
    [self.downloadInfoDictionary removeObjectsForKeys:removeKeyArray];
    if (downloadTask == nil) {
        downloadTask = [self.session downloadTaskWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
        [downloadTask resume];
        KDownloadInfo *di = [[KDownloadInfo alloc] init];
        di.downloadUrl = url;
        di.filePath = filePath;
        di.downloadTask = downloadTask;
        [self.downloadInfoDictionary setObject:di forKey:kDownloadInfoKey(di.downloadTask.taskIdentifier)];
    }
    return downloadTask.taskIdentifier;
}

- (void) deleteDownloadWithTaskIdentifier:(NSUInteger)taskIdentifier
{
    NSString *key = kDownloadInfoKey(taskIdentifier);
    KDownloadInfo *di = [self.downloadInfoDictionary objectForKey:key];
    if (di && di.downloadTask) {
        // -cancel方法会删除缓存
        [di.downloadTask cancel];
    } else if (di && di.resumeData) {
        NSURLSessionDownloadTask *downloadTask = [self.session downloadTaskWithResumeData:di.resumeData];
        [downloadTask cancel];
    }
    [self.downloadInfoDictionary removeObjectForKey:key];
}

- (void) stopDownloadWithTaskIdentifier:(NSUInteger)taskIdentifier
{
    KDownloadInfo *di = [self.downloadInfoDictionary objectForKey:kDownloadInfoKey(taskIdentifier)];
    if (di && di.downloadTask) {
        [di.downloadTask cancelByProducingResumeData:^(NSData *resumeData) {
            if (resumeData) {
                di.resumeData = resumeData;
            }
        }];
    }
}

- (void) stopAllDownload
{
    for (NSString *key in self.downloadInfoDictionary) {
        KDownloadInfo *di = [self.downloadInfoDictionary objectForKey:key];
        if (di && di.downloadTask) {
            [self stopDownloadWithTaskIdentifier:di.downloadTask.taskIdentifier];
        }
    }
}

#pragma mark - 私有方法

- (void) appWillTerminate
{
    [self stopAllDownload];
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:self.downloadInfoDictionary]
                                              forKey:kDownloadInfoDictionaryKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void) loadDownloadInfoDictionary
{
    id obj = [[NSUserDefaults standardUserDefaults] objectForKey:kDownloadInfoDictionaryKey];
    if (obj) {
        self.downloadInfoDictionary = [NSKeyedUnarchiver unarchiveObjectWithData:obj];
    } else {
        self.downloadInfoDictionary = [NSMutableDictionary dictionary];
    }
}

- (KDownloadInfo *) downloadInfoWithTaskIdentifier:(NSUInteger)taskIdentifier
{
    for (NSString *key in self.downloadInfoDictionary) {
        if ([key isEqualToString:kDownloadInfoKey(taskIdentifier)]) {
            return [self.downloadInfoDictionary objectForKey:key];
        }
    }
    return nil;
}

#pragma mark - NSURLSessionDownloadDelegate

- (void) URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error
{
    NSLog(@"didBecomeInvalidWithError:%@", error);
}

- (void) URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session NS_AVAILABLE_IOS(7_0)
{
    
    KBasicBlock block = ((KAppDelegate *)[UIApplication sharedApplication].delegate).backgroundDownloadCompletionHandler;
    if (block) {
        block();
    }
}

- (void) URLSession:(NSURLSession *)session
               task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if ([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorCancelled) {
        // !!Note:-cancel获取不到resumeData
        if (error.userInfo && [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData]) {
            if (self.downloadInfoDictionary == nil) {
                [self loadDownloadInfoDictionary];
            }
            NSLog(@"%d", task.taskIdentifier);
            // 当用户关闭应用之后，下次进入app，会有resumeData，记录下来，用来断点续传
            KDownloadInfo *di = [self downloadInfoWithTaskIdentifier:task.taskIdentifier];
            if (di) {
                NSData *resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
                di.resumeData = resumeData;
            }
        }
    }
}

- (void) URLSession:(NSURLSession *)session
       downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    for (NSString *key in self.downloadInfoDictionary) {
        if ([key isEqualToString:kDownloadInfoKey(downloadTask.taskIdentifier)]) {
            KDownloadInfo *di = [self.downloadInfoDictionary objectForKey:key];
            NSError *error = nil;
            [[NSFileManager defaultManager] moveItemAtURL:location toURL:[NSURL fileURLWithPath:di.filePath] error:&error];
            
            NSString *logPath = nil;
            NSString *log = nil;
            if (error) {
                // 处理error，记录log
                logPath = [NSString stringWithFormat:@"%@/failed.log", [KUtily documentsPath]];
                log = [NSString stringWithFormat:@"date:%@, url:%@, failed!!! error:%@", [NSDate date], di.downloadUrl, error];
            } else {
                // 成功日志
                logPath = [NSString stringWithFormat:@"%@/success.log", [KUtily documentsPath]];
                log = [NSString stringWithFormat:@"date:%@, url:%@, success!!!!", [NSDate date], di.downloadUrl];
            }
            NSData *logData = [[NSFileManager defaultManager] contentsAtPath:logPath];
            NSMutableString *lastLog = nil;
            if (logData) {
                lastLog = [[NSMutableString alloc] initWithData:logData encoding:NSUTF8StringEncoding];
                [lastLog appendString:@"\n"];
            } else {
                lastLog = [NSMutableString string];
            }
            [lastLog appendString:log];
            [[NSFileManager defaultManager] createFileAtPath:logPath contents:[lastLog dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
        }
    }
}

// 记录下载速度及进度
- (void) URLSession:(NSURLSession *)session
       downloadTask:(NSURLSessionDownloadTask *)downloadTask
       didWriteData:(int64_t)bytesWritten
  totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    NSLog(@"------------------------");
    NSLog(@"------------------------");
    NSLog(@"下载中!!!");
    NSLog(@"bytesWritten:%lld", bytesWritten);
    NSLog(@"totalBytesWritten:%lld", totalBytesWritten);
    NSLog(@"totalBytesExpectedToWrite:%lld", totalBytesExpectedToWrite);
    NSLog(@"------------------------");
    NSLog(@"------------------------");
}

// 断点续传
- (void) URLSession:(NSURLSession *)session
       downloadTask:(NSURLSessionDownloadTask *)downloadTask
  didResumeAtOffset:(int64_t)fileOffset
 expectedTotalBytes:(int64_t)expectedTotalBytes
{
    NSLog(@"------------------------");
    NSLog(@"------------------------");
    NSLog(@"断点续传!!!");
    NSLog(@"fileOffset:%lld", fileOffset);
    NSLog(@"expectedTotalBytes:%lld", expectedTotalBytes);
    NSLog(@"------------------------");
    NSLog(@"------------------------");
}

@end

@implementation KDownloadInfo

#pragma mark - NSCoding

- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.downloadUrl forKey:@"downloadUrl"];
    [aCoder encodeObject:self.filePath forKey:@"filePath"];
    [aCoder encodeObject:self.resumeData forKey:@"resumeData"];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        self.downloadUrl = [aDecoder decodeObjectForKey:@"downloadUrl"];
        self.filePath = [aDecoder decodeObjectForKey:@"filePath"];
        self.resumeData = [aDecoder decodeObjectForKey:@"resumeData"];
    }
    return self;
}

@end
