//
//  InitialDownloaderView.m
//  VeryInterestingTestTask
//
//  Created by Valeriy Buev on 19.07.14.
//  Copyright (c) 2014 bva. All rights reserved.
//

#import "InitialDownloaderView.h"
#import "AppDelegate.h"
#import "City+CityCategory.h"
#import "Place+PlaceCategory.h"
#import "AppSettings+AppSettingsCategory.h"
#import "Photo+PhotoCategory.h"

@interface InitialDownloaderView ()
<NSURLSessionDownloadDelegate, NSURLSessionDelegate, NSURLSessionTaskDelegate, UIAlertViewDelegate>{
    NSMutableArray *cities;
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
    cities = [NSMutableArray array];
    [self startDownloading];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)btnStopDownloadingClicked:(id)sender {
    [self stopDownloading];
}

// сохраняет контекст и выводит ошибку при надобности
- (void) saveManagedObjectContext{
    NSError *error;
    [self.context save:&error];
    if(error){
        NSLog(@"Unresolved error while saving managedObjectContext: %@",error.localizedDescription);
        abort();
    }
}

#pragma mark NSURLSession

- (void) stopDownloading{
    [[self backgroundSession] getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks){
        for ( NSURLSessionDownloadTask *task in downloadTasks){
            [task cancel];
        }
    }];
}

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

- (void) startDownloading{
    NSURLSessionDownloadTask *task = [[self backgroundSession] downloadTaskWithURL:[NSURL URLWithString:@"https://dl.dropboxusercontent.com/u/32448889/TetsTask/places_25_06.json"]];
    [task resume];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location{

    NSError *error;
    NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfURL:location] options:NSJSONReadingAllowFragments error:&error];
    if(error){
        NSLog(@"json-serialization error: %@",error.localizedDescription);
    }
    [self saveData:jsonData];
}

- (void) sayUserAboutDownloadingError:(NSError *) error{
    NSString *message = [NSString stringWithFormat:
                         @"An error has occurred.. \ndescription:%@\n\n Whether you want to start the download again?",error.localizedDescription];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message: message delegate:self cancelButtonTitle:@"NO" otherButtonTitles:@"YES", nil];
    [alert show];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    switch (buttonIndex) {
        case 0:
            if(self.delegate)
                [self.delegate initialDownloaderViewShouldBeDisappeared:self];
            break;
        case 1:
            [self startDownloading];
            break;
            
        default:
            break;
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    if(error){
        NSLog(@"downloadTask error: %@",error.localizedDescription);
    } else {
        NSLog(@"downloading completed");
    }
    [self callCompletionHandlerIfFinished];
}

- (void) callCompletionHandlerIfFinished{
    //[mysession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks1){
    [[self backgroundSession] getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks1){
        NSUInteger count = dataTasks.count + uploadTasks.count + downloadTasks1.count;
        //NSLog(@"count of tasks: %d",downloadTasks1.count);
        if (count == 0) {
            // все таски закончены
            //NSLog(@"all tasks ended");
            dispatch_async(dispatch_get_main_queue(), ^{
                self.progressView.progress = 1;
            });
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
    NSLog(@"didResumeAtOffSet : %lld",expectedTotalBytes);
}

-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    //NSLog(@"%lld %lld %lld",bytesWritten,totalBytesWritten,totalBytesExpectedToWrite);
    if(self.progressView.progress == 0){
        self.progressView.progress = 0.3;
    }
    if(totalBytesExpectedToWrite != NSURLSessionTransferSizeUnknown){
        dispatch_async(dispatch_get_main_queue(), ^{
            self.progressView.progress = 0.3 + 0.7 * (float) totalBytesWritten / (float) totalBytesExpectedToWrite;
        });
    }
    else{
        self.progressView.progress += 0.01;
    }
}

#pragma mark Saving downloaded data

- (void) sayUserAboutIncorrectData: (NSError *) error{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"Sorry, json-data is incorrect:("] delegate:nil cancelButtonTitle:@":(" otherButtonTitles: nil];
    [alert show];
    if(self.delegate){
        [self.delegate initialDownloaderViewShouldBeDisappeared:self];
    }
}

- (void) saveData:(NSDictionary *) jsonData {
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
    NSArray *placesDicts = [jsonData objectForKey:@"places"];
    for(NSDictionary *placeDict in placesDicts){
        [self savePlaceDict:placeDict];
    }
    [AppSettings getInstance:self.context].didDataBeLoaded = [NSNumber numberWithBool:YES];
    
    [self saveManagedObjectContext];
    if(self.delegate) {
        [self.delegate initialDownloaderViewShouldBeDisappeared:self];
    }
}

- (void) savePlaceDict:(NSDictionary *) placeDict{
    if(![placeDict isKindOfClass:[NSDictionary class]]){
        NSLog(@"this place-dictionary is incorrect: %@", placeDict);
        return;
    }
    NSString *description = [placeDict objectForKey:@"description"];
    NSString *photoUrlStr = [placeDict objectForKey:@"image"];
    NSNumber *latitude = [NSNumber numberWithFloat:[[placeDict objectForKey:@"latitude"] floatValue]];
    NSNumber *longtitude = [NSNumber numberWithFloat:[[placeDict objectForKey:@"longtitude"] floatValue]];
    NSString *name = [placeDict objectForKey:@"name"];
    NSString *cityName = [placeDict objectForKey:@"city"];
    if(!name
       || [name isEqualToString:@""]
       || latitude.doubleValue < -90
       || latitude.doubleValue > 90
       || longtitude.doubleValue < -180
       || longtitude.doubleValue > 180){
        NSLog(@"this place-dictionary is incorrect: %@", placeDict);
        return;
    }
    Place *place = [Place newPlaceWithName: name
                               description:description
                                  latitude:latitude
                                longtitude:longtitude
                                       MOC:self.context];
    if(photoUrlStr && ![photoUrlStr isEqualToString:@""]){
        [Photo newPhotoWithUrl: photoUrlStr
                      forPlace: place
                           MOC: self.context];
    }
    if( cityName && ![cityName isEqualToString:@""]){
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name like %@",cityName];
        NSArray * filtered_cities = [cities filteredArrayUsingPredicate:predicate];
        if( filtered_cities.count > 0){
            City *city = [filtered_cities objectAtIndex:0];
            place.city = city;
            //NSLog(@"city-%@-search count = %d",city.name,filtered_cities.count);
        }
        else{
            City *city = [City newCityWithName:cityName MOC:self.context];
            place.city = city;
            [cities addObject:city];
        }
    }
    
}


@end
