//
//  InitialDownloaderView.m
//  VeryInterestingTestTask
//
//  Created by Valeriy Buev on 19.07.14.
//  Copyright (c) 2014 bva. All rights reserved.
//

#import "InitialDownloaderView.h"
#import "AppDelegate.h"
#import "Place+PlaceCategory.h"
#import "AppSettings+AppSettingsCategory.h"
#import "Photo+PhotoCategory.h"

@interface InitialDownloaderView ()
<NSURLSessionDownloadDelegate, NSURLSessionDelegate, NSURLSessionTaskDelegate, UIAlertViewDelegate>{
}

@end

@implementation InitialDownloaderView

@synthesize delegate;
@synthesize context;
@synthesize progressView;

#pragma mark Initialization and Basic functions

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.progressView.progress = 0;
    [self startDownloading];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// User wants to stop downloading
- (IBAction)btnStopDownloadingClicked:(id)sender {
    [self stopDownloading];
}

// Saves context
- (void) saveManagedObjectContext{
    NSError *error;
    [self.context save:&error];
    if(error){
        NSLog(@"Unresolved error while saving managedObjectContext: %@",error.localizedDescription);
        abort();
    }
}

#pragma mark NSURLSession

// Stoping downloading
- (void) stopDownloading{

    [[self backgroundSession] getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks){
        // cancel all tasks
        for ( NSURLSessionDownloadTask *task in downloadTasks){
            [task cancel];
        }
    }];
}

// session getter
- (NSURLSession *) backgroundSession{
    
    static NSURLSession *session = nil;
    static dispatch_once_t onceToken;
    
    // get session once
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfiguration:@"ru.bva.VeryInterestingTestTask.backgroundSessoinForInitialDownloading"];
        // waits 20 seconds maximum
        config.timeoutIntervalForRequest = 20;
        config.timeoutIntervalForResource = 20;
        session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    });
    return session;
}

// Start downloading
- (void) startDownloading{
    NSURLSessionDownloadTask *task = [[self backgroundSession] downloadTaskWithURL:[NSURL URLWithString:@"https://dl.dropboxusercontent.com/u/32448889/TetsTask/places_25_06.json"]];
    [task resume];
}

// Downloading is completed
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location{

    NSError *error;
    // Parse JSon-data into NSDictionary
    NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfURL:location] options:NSJSONReadingAllowFragments error:&error];
    if(error){
        NSLog(@"json-serialization error: %@",error.localizedDescription);
    }
    // Save into CoreData
    [self saveData:jsonData];
}

// Task completed
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    if(error){
        NSLog(@"downloadTask error: %@",error.localizedDescription);
    } else {
        NSLog(@"downloading completed");
    }
    // call AppDelegate-completionHandler if needs
    [self callCompletionHandlerIfFinished];
}

// Asks user does he want start downloading again
- (void) sayUserAboutDownloadingError:(NSError *) error{
    NSString *message = [NSString stringWithFormat:
                         @"An error has occurred.. \ndescription:%@\n\n Whether you want to start the download again?",error.localizedDescription];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message: message delegate:self cancelButtonTitle:@"NO" otherButtonTitles:@"YES", nil];
    [alert show];
}

// User chose to start again or to ignore
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    switch (buttonIndex) {
        case 0:
            // ignore
            if(self.delegate)
                [self.delegate initialDownloaderViewShouldBeDisappeared:self];
            break;
        case 1:
            // start downloading again
            [self startDownloading];
            break;
            
        default:
            break;
    }
}

// call AppDelegate-completionHandler if needs
- (void) callCompletionHandlerIfFinished{
    [[self backgroundSession] getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks1){
        NSUInteger count = dataTasks.count + uploadTasks.count + downloadTasks1.count;
        if (count == 0) {
            // Change UI
            dispatch_async(dispatch_get_main_queue(), ^{
                self.progressView.progress = 1;
            });
            // call completionHandler
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            if (appDelegate.backgroundSessionCompletionHandler) {
                void (^completionHandler)() = appDelegate.backgroundSessionCompletionHandler;
                appDelegate.backgroundSessionCompletionHandler = nil;
                completionHandler();
            }
        }
    }];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes{
    ///NSLog(@"didResumeAtOffSet : %lld",expectedTotalBytes);
}

// Downloading progresses. View that on UI
-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    
    // starts from 0.3 for more illustrative displaing of progress when totalBytesExpectedToWrite is unknown
    if(self.progressView.progress == 0){
        self.progressView.progress = 0.3;
    }
    if(totalBytesExpectedToWrite != NSURLSessionTransferSizeUnknown){
        dispatch_async(dispatch_get_main_queue(), ^{
            self.progressView.progress = 0.3 + 0.7 * (float) totalBytesWritten / (float) totalBytesExpectedToWrite;
        });
    }
    // simulate progress
    else{
        self.progressView.progress += 0.01;
    }
}

#pragma mark Saving downloaded data

//
- (void) sayUserAboutIncorrectData: (NSError *) error{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"Sorry, json-data is incorrect:("] delegate:nil cancelButtonTitle:@":(" otherButtonTitles: nil];
    [alert show];
    if(self.delegate){
        [self.delegate initialDownloaderViewShouldBeDisappeared:self];
    }
}

// Saves data into CoreData storage
- (void) saveData:(NSDictionary *) jsonData {
    
    // validate input dictionary
    if( ![jsonData isKindOfClass:[NSDictionary class]] ){
        [self sayUserAboutIncorrectData:[NSError errorWithDomain:@"JsonData-saving error" code:999 userInfo:[NSDictionary dictionaryWithObject:@"Json-data is not a dictionary" forKey:@"info"]]];
        return;
    }
    if( ![jsonData objectForKey:@"places"] ){
        [self sayUserAboutIncorrectData:[NSError errorWithDomain:@"JsonData-saving error" code:999 userInfo:[NSDictionary dictionaryWithObject:@"Json-data-dictionary does not have tag 'places'" forKey:@"info"]]];
        return;
    }
    if( ![[jsonData objectForKey:@"places"] isKindOfClass:[NSArray class]] ){
        [self sayUserAboutIncorrectData:[NSError errorWithDomain:@"JsonData-saving error" code:999 userInfo:[NSDictionary dictionaryWithObject:@"The tag 'places' is not a dictionary" forKey:@"info"]]];
        return;
    }
    
    // a dictionary of places
    NSArray *placesDicts = [jsonData objectForKey:@"places"];
    for(NSDictionary *placeDict in placesDicts){
        // parse every place separately
        [self savePlaceDict:placeDict];
    }
    
    // Save in Settings that data has been downloading
    [AppSettings getInstance:self.context].didDataBeLoaded = [NSNumber numberWithBool:YES];
    
    [self saveManagedObjectContext];
    if(self.delegate) {
        // notificate delegate downloading completed
        [self.delegate initialDownloaderViewShouldBeDisappeared:self];
    }
}

// Save place NSDictionary-serialisation into CoreData storage
- (void) savePlaceDict:(NSDictionary *) placeDict
{
    // validate dictionaary
    if(![placeDict isKindOfClass:[NSDictionary class]]){
        NSLog(@"this place-dictionary is incorrect: %@", placeDict);
        return;
    }
    
    // getting of attributes
    NSString *description = [placeDict objectForKey:@"description"];
    NSString *photoUrlStr = [placeDict objectForKey:@"image"];
    NSNumber *latitude = [NSNumber numberWithFloat:[[placeDict objectForKey:@"latitude"] floatValue]];
    NSNumber *longtitude = [NSNumber numberWithFloat:[[placeDict objectForKey:@"longtitude"] floatValue]];
    NSString *name = [placeDict objectForKey:@"name"];
    NSString *cityName = [placeDict objectForKey:@"city"];
    
    // validating attributes
    if ( !cityName )
        cityName = @"";
    if(!name
       || [name isEqualToString:@""]
       || latitude.doubleValue < -90
       || latitude.doubleValue > 90
       || longtitude.doubleValue < -180
       || longtitude.doubleValue > 180){
        NSLog(@"this place-dictionary is incorrect: %@", placeDict);
        return;
    }
    
    // create new place
    Place *place = [Place newPlaceWithName: name
                                      city: cityName
                               description:description
                                  latitude:latitude
                                longtitude:longtitude
                                       MOC:self.context];
    // add new photo to place
    if(photoUrlStr && ![photoUrlStr isEqualToString:@""]){
        [Photo newPhotoWithUrl: photoUrlStr
                      forPlace: place
                           MOC: self.context];
    }
}


@end
