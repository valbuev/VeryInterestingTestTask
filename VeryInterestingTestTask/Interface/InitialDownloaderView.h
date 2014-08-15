//
//  InitialDownloaderView.h
//  VeryInterestingTestTask
//
//  Created by Valeriy Buev on 19.07.14.
//  Copyright (c) 2014 bva. All rights reserved.
//

//
//  This view is used for downloading initial data and save it into CoreData storage
//

#import <UIKit/UIKit.h>

@class InitialDownloaderView;

//
@protocol InitialDownloaderViewDelegate
//  Data has been downloaded
- (void)  initialDownloaderViewShouldBeDisappeared:(InitialDownloaderView *) view;

@end

@interface InitialDownloaderView : UIViewController


@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (nonatomic,retain) NSManagedObjectContext *context;
@property (nonatomic, weak) id <InitialDownloaderViewDelegate> delegate;

// User wants to stop downloading
- (IBAction)btnStopDownloadingClicked:(id)sender;

@end
