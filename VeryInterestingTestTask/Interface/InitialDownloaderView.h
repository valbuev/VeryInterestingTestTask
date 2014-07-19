//
//  InitialDownloaderView.h
//  VeryInterestingTestTask
//
//  Created by Valeriy Buev on 19.07.14.
//  Copyright (c) 2014 bva. All rights reserved.
//

#import <UIKit/UIKit.h>

@class InitialDownloaderView;
@protocol InitialDownloaderViewDelegate

- (void)  initialDownloaderViewShouldBeDisappeared:(InitialDownloaderView *) view;

@end

@interface InitialDownloaderView : UIViewController


@property (weak, nonatomic) IBOutlet UIProgressView *progressView;

@property (nonatomic,retain) NSManagedObjectContext *context;
@property (nonatomic, weak) id <InitialDownloaderViewDelegate> delegate;


- (IBAction)btnStopDownloadingClicked:(id)sender;

@end
