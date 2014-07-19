//
//  InitialDownloaderView.m
//  VeryInterestingTestTask
//
//  Created by Valeriy Buev on 19.07.14.
//  Copyright (c) 2014 bva. All rights reserved.
//

#import "InitialDownloaderView.h"

@interface InitialDownloaderView ()
<NSURLSessionDownloadDelegate, NSURLSessionDelegate, NSURLSessionTaskDelegate>

@end

@implementation InitialDownloaderView

@synthesize delegate;
@synthesize context;
@synthesize progressView;

#pragma mark Initialization and Basic functions

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)btnStopDownloadingClicked:(id)sender {
}

#pragma mark NSURLSession

- (NSURLSession *) backgroundSession{
    static NSURLSession *session = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfiguration:@"ru.bva.VeryInterestingTestTask.backgroundSessoinForInitialDownloading"];
        config.timeoutIntervalForRequest = 20;
        config.timeoutIntervalForResource = 20;
        session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    });
    return session;
}


@end
