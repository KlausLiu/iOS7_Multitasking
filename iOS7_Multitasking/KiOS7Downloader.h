//
//  KiOS7Downloader.h
//  iOS7_MultiTask
//
//  Created by klaus on 13-9-28.
//  Copyright (c) 2013年 klaus. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KiOS7Downloader : NSObject

+ (id) sharedDownloader;

- (NSUInteger) downloadWithUrl:(NSString *)url filePath:(NSString *)filePath;

- (void) deleteDownloadWithTaskIdentifier:(NSUInteger)taskIdentifier;

- (void) stopDownloadWithTaskIdentifier:(NSUInteger)taskIdentifier;

- (void) stopAllDownload;

@end
