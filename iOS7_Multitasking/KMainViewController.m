//
//  MainViewController.m
//
//  Created by klaus on 13-9-26.
//  Copyright (c) 2013年 klaus. All rights reserved.
//

#import "KMainViewController.h"
#import "KiOS7Downloader.h"
#import "KUtily.h"

@interface KMainViewController () {
    NSInteger downloadTask1Identifier, downloadTask2Identifier;
}

@end

@implementation KMainViewController

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        downloadTask1Identifier = downloadTask2Identifier = -1;
    }
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction) stopAll:(id)sender
{
    [[KiOS7Downloader sharedDownloader] stopAllDownload];
}

- (IBAction) download1:(id)sender
{
//    [[KiOS7Downloader sharedDownloader] downloadWithUrl:@"http://down.360safe.com/setup.exe"
//                                               filePath:[NSString stringWithFormat:@"%@/360 for win.exe", [Utily documentsPath]]];
    downloadTask1Identifier = [[KiOS7Downloader sharedDownloader] downloadWithUrl:@"http://mirrors.ustc.edu.cn/eclipse/technology/epp/downloads/release/kepler/R/eclipse-standard-kepler-R-macosx-cocoa-x86_64.tar.gz"
                                               filePath:[NSString stringWithFormat:@"%@/eclipse-standard.tar.gz", [KUtily documentsPath]]];
}

- (IBAction) stop1:(id)sender
{
    if (downloadTask1Identifier < 0) {
        return;
    }
    [[KiOS7Downloader sharedDownloader] stopDownloadWithTaskIdentifier:downloadTask1Identifier];
}

- (IBAction) delete1:(id)sender
{
    if (downloadTask1Identifier < 0) {
        return;
    }
    [[KiOS7Downloader sharedDownloader] deleteDownloadWithTaskIdentifier:downloadTask1Identifier];
    downloadTask1Identifier = -1;
}

- (IBAction) download2:(id)sender
{
//    [[KiOS7Downloader sharedDownloader] downloadWithUrl:@"http://dl.360safe.com/mac/safe/360InternetSecurity.dmg"
//                                               filePath:[NSString stringWithFormat:@"%@/360 for mac.dmg", [Utily documentsPath]]];
    downloadTask2Identifier = [[KiOS7Downloader sharedDownloader] downloadWithUrl:@"http://download.actuatechina.com/eclipse/technology/epp/downloads/release/kepler/R/eclipse-jee-kepler-R-macosx-cocoa-x86_64.tar.gz"
                                               filePath:[NSString stringWithFormat:@"%@/eclipse-standard.tar.gz", [KUtily documentsPath]]];
}

- (IBAction) stop2:(id)sender
{
    if (downloadTask2Identifier < 0) {
        return;
    }
    [[KiOS7Downloader sharedDownloader] stopDownloadWithTaskIdentifier:downloadTask2Identifier];
    downloadTask2Identifier = -1;
}

- (IBAction) delete2:(id)sender
{
    if (downloadTask2Identifier < 0) {
        return;
    }
    [[KiOS7Downloader sharedDownloader] deleteDownloadWithTaskIdentifier:downloadTask2Identifier];
    downloadTask2Identifier = -1;
}

@end
