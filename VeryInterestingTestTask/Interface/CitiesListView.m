//
//  CitiesListView.m
//  VeryInterestingTestTask
//
//  Created by Valeriy Buev on 19.07.14.
//  Copyright (c) 2014 bva. All rights reserved.
//

#import "CitiesListView.h"
#import "City+CityCategory.h"
#import "PlaceTableViewCell.h"
#import "Place+PlaceCategory.h"
#import "AppSettings+AppSettingsCategory.h"
#import "AppDelegate.h"
#import "InitialDownloaderView.h"
#import "CitySectionHeaderView.h"
#import "Photo+PhotoCategory.h"

static NSString *SectionHeaderViewIdentifier = @"SectionHeaderViewIdentifier";
static NSString *PlaceCellIdentifier = @"CellPlace";

@interface CitiesListView ()
<NSFetchedResultsControllerDelegate, CitySectionHeaderViewDelegate, InitialDownloaderViewDelegate,NSURLSessionDownloadDelegate, NSURLSessionDelegate, NSURLSessionTaskDelegate>
{
    NSFetchedResultsController *controller;
    NSMutableArray *hiddenSections;
    
    NSMutableArray *downloadPhotos;
    NSMutableArray *downloadTasks;
}

@property (nonatomic,retain) AppSettings *appSettings;
@property  (nonatomic, retain) NSManagedObjectContext *context;

@end

@implementation CitiesListView
@synthesize appSettings = _appSettings;
@synthesize context = _context;

#pragma mark initialization and basic functions

- (void)saveContext {
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.context;
    
    if(managedObjectContext != nil) {
        if([managedObjectContext hasChanges] && ![managedObjectContext save:&error]){
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

- (NSManagedObjectContext *) context{
    if ( _context != nil )
        return _context;
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    _context = appDelegate.managedObjectContext;
    return _context;
}
- (AppSettings *) appSettings{
    if(_appSettings != nil)
        return _appSettings;
    _appSettings = [AppSettings getInstance:self.context];
    return _appSettings;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    downloadPhotos = [NSMutableArray array];
    downloadTasks = [NSMutableArray array];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"CitySectionHeaderView_iPad" bundle:nil] forHeaderFooterViewReuseIdentifier:SectionHeaderViewIdentifier];
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:PlaceCellIdentifier];
    [self.tableView setRowHeight:cell.frame.size.height];
    [self.tableView setSectionHeaderHeight:44];
    if ( self.appSettings.didDataBeLoaded.boolValue == NO ){
        [self showInitialDownloaderView];
    }
    else {
        [self setFetchedResultsController];
    }
}

- (void) showInitialDownloaderView{
    InitialDownloaderView *view = [self.storyboard instantiateViewControllerWithIdentifier:@"InitialDownloaderView"];
    view.delegate = self;
    view.context = self.context;
    [self presentViewController: view animated: NO completion:nil];
}

- (void) setFetchedResultsController{
    controller = [Place newFetchedResultsControllerForMOC:self.context];
    controller.delegate = self;
    NSError *error;
    [controller performFetch:&error];
    if( error ){
        NSLog(@"Error while performing fetch: %@",error.localizedDescription);
        controller = nil;
    }
    else{
        hiddenSections = [NSMutableArray array];
        NSUInteger sectionsCount = controller.sections.count;
        for ( NSUInteger i=0; i < sectionsCount; i++ ) {
            [hiddenSections addObject:[NSNumber numberWithBool:NO]];
        }
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    //NSLog(@"sections count; %d",controller.sections.count);
    if( !controller )
        return 0;
    else
        return controller.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //CitySectionHeaderView *view = (CitySectionHeaderView *) [self.tableView headerViewForSection:section];
    NSNumber *isSectionHidden = [hiddenSections objectAtIndex:section];
    if( isSectionHidden.boolValue == YES )
        return 0;
    else{
        id <NSFetchedResultsSectionInfo> sectionInfo = [controller.sections objectAtIndex:section];
        return [sectionInfo numberOfObjects];
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PlaceTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:PlaceCellIdentifier forIndexPath:indexPath];
    
    [self configureCell:cell forIndexPath:indexPath];
    
    return cell;
}

- (void) configureCell: (PlaceTableViewCell *) cell forIndexPath: (NSIndexPath *) indexPath {
    Place *place = [controller objectAtIndexPath:indexPath];
    cell.labelName.text = place.name;
    if( place.photos.count > 0){
        Photo *photo;
        for( Photo *photo_ in place.photos){
            photo = photo_;
            break;
        }
        cell.photo = photo;
        if( ( photo.thumbnail_filePath == nil
           || [photo.thumbnail_filePath isEqualToString:@""] )
            && photo.url != nil && ![photo.url isEqualToString:@""]){
            [self startDownloadingPhoto:photo];
        }
    }
    else {
        cell.imageViewPhoto.image = [UIImage imageNamed:@"no_photo.jpg"];
        cell.photo = nil;
    }
}



// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    CitySectionHeaderView *view = [self.tableView dequeueReusableHeaderFooterViewWithIdentifier:SectionHeaderViewIdentifier];
    [self configureHeaderView:view sectionIndex:section];
    return view;
}

- (void) configureHeaderView:(CitySectionHeaderView *) view sectionIndex:(NSUInteger ) sectionIndex{
    id <NSFetchedResultsSectionInfo> sectioninfo = [controller.sections objectAtIndex:sectionIndex];
    view.delegate = self;
    view.sectionInfo = sectioninfo;
    NSNumber *isSectionHidden = [hiddenSections objectAtIndex:sectionIndex];
    view.isSectionHidden = isSectionHidden.boolValue;
    NSString *name = [sectioninfo name];
    if(!name || [name isEqualToString:@""]){
        view.labelCityName.text = @"Without city";
    }
    else {
        view.labelCityName.text = [sectioninfo name];
    }
}



- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Place *place = [controller objectAtIndexPath:indexPath];
        NSUInteger searchResult = [downloadPhotos indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop){
            BOOL _stop = NO;
            Photo *pObj = obj;
            if(pObj.place == place)
                _stop = YES;
            stop = &_stop;
            return _stop;
        }];
        if(searchResult != NSNotFound){
            NSURLSessionDownloadTask *task = [downloadTasks objectAtIndex:searchResult];
            [downloadPhotos removeObjectAtIndex:searchResult];
            [downloadTasks removeObjectAtIndex:searchResult];
            [task cancel];
        }
        [self.context deleteObject:place];
        [self saveContext];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark NSFetchResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller{
    [self.tableView endUpdates];
}

-(void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    BOOL isSectionHidden = [[hiddenSections objectAtIndex:indexPath.section] boolValue];
    BOOL isNewSectionHidden = [[hiddenSections objectAtIndex:newIndexPath.section] boolValue];
    switch (type) {
        case NSFetchedResultsChangeDelete:
            if(isSectionHidden == NO){
                [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            }
            break;
            
        case NSFetchedResultsChangeInsert:
            if(isSectionHidden == NO){
                [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            }
            break;
            
        case NSFetchedResultsChangeMove:{
            if(isSectionHidden == NO){
                [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            }
            if(isNewSectionHidden == NO){
                [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            }
        }
            break;
            
        case NSFetchedResultsChangeUpdate:{
            PlaceTableViewCell *cell = (PlaceTableViewCell *) [self.tableView cellForRowAtIndexPath:indexPath];
            [self configureCell:cell forIndexPath:indexPath];
        }
            break;
            
        default:
            break;
    }
}

-(void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    switch (type) {
        case NSFetchedResultsChangeDelete:{
            [hiddenSections removeObjectAtIndex:sectionIndex];
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
        }
            break;
            
        case NSFetchedResultsChangeInsert:{
            [hiddenSections insertObject:[NSNumber numberWithBool:NO] atIndex:sectionIndex];
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
        }
            break;
            
        case NSFetchedResultsChangeMove:
            break;
            
        case NSFetchedResultsChangeUpdate:{
            CitySectionHeaderView *view = (CitySectionHeaderView *) [self.tableView headerViewForSection:sectionIndex];
            [self configureHeaderView:view sectionIndex:sectionIndex];
        }
            break;
            
        default:
            break;
    }
}

#pragma mark CitySectionHeaderViewDelegate

- (void)citySectionHeaderView:(CitySectionHeaderView *)view didHidden:(Boolean)isHidden{
    id <NSFetchedResultsSectionInfo> sectionInfo = view.sectionInfo;
    NSUInteger sectionIndex = [controller.sections indexOfObject:sectionInfo];
    [hiddenSections setObject:[NSNumber numberWithBool:isHidden] atIndexedSubscript:sectionIndex];
    NSMutableArray *indexPathes = [NSMutableArray arrayWithCapacity:[sectionInfo numberOfObjects]];
    for(int i=0;i<[sectionInfo numberOfObjects];i++){
        [indexPathes addObject:[NSIndexPath indexPathForRow:i inSection:sectionIndex]];
    }
    [self.tableView beginUpdates];
    if(isHidden == NO){
        [self.tableView insertRowsAtIndexPaths:indexPathes withRowAnimation:UITableViewRowAnimationRight];
    }
    else {
        [self.tableView deleteRowsAtIndexPaths:indexPathes withRowAnimation:UITableViewRowAnimationRight];
    }
    [self.tableView endUpdates];
}

#pragma mark InitialDownloaderViewDelegate

- (void)initialDownloaderViewShouldBeDisappeared:(InitialDownloaderView *)view{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated:YES completion:nil];
        [self setFetchedResultsController];
    });
}

#pragma mark photo downloading

/*- (void) stopDownloading{
    [[self backgroundSession] getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks){
        for ( NSURLSessionDownloadTask *task in downloadTasks){
            [task cancel];
        }
    }];
}*/

- (NSURLSession *) backgroundSession{
    static NSURLSession *session = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfiguration:@"ru.bva.VeryInterestingTestTask.backgroundSessoinPhotoDownloading"];
        config.HTTPMaximumConnectionsPerHost = 3;
        config.timeoutIntervalForRequest = 30;
        config.timeoutIntervalForResource = 60;
        session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    });
    return session;
}

- (void) startDownloadingPhoto:(Photo *) photo{
    if( [downloadPhotos containsObject:photo] )
        return;
    NSURLSessionDownloadTask *task = [[self backgroundSession] downloadTaskWithURL:[NSURL URLWithString:photo.url]];
    [downloadTasks addObject:task];
    [downloadPhotos addObject:photo];
    [task resume];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location{
    
    NSUInteger index = [downloadTasks indexOfObject:downloadTask];
    Photo *photo = [downloadPhotos objectAtIndex:index];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *urls = [fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *documentDirectory = [urls objectAtIndex:0];
    
    NSURL *originalUrl = [NSURL URLWithString:[downloadTask.originalRequest.URL lastPathComponent]];
    NSString *imageName = [originalUrl lastPathComponent];
    NSURL *destinationUrl = [documentDirectory URLByAppendingPathComponent:imageName];
    NSURL *thumbnailDestinationUrl = [documentDirectory URLByAppendingPathComponent:[NSString stringWithFormat:@"thumbnail_%@", [originalUrl lastPathComponent]]];
    NSError *fileManagerError;
    
    [fileManager removeItemAtURL:destinationUrl error:NULL];
    
    [fileManager copyItemAtURL:location toURL:destinationUrl error:&fileManagerError];
    
    if(fileManagerError == nil){
        
        UIImage *originalImage = [UIImage imageWithContentsOfFile:destinationUrl.path];
        CGSize destinationSize = CGSizeMake(100, 100);
        UIGraphicsBeginImageContext(destinationSize);
        [originalImage drawInRect:CGRectMake(0,0,destinationSize.width,destinationSize.height)];
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        NSString * imageType = [imageName substringFromIndex:MAX((int)[imageName length]-3, 0)];
        imageType = [imageType lowercaseString];
        if([imageType isEqualToString:@"jpg"]){
            [UIImageJPEGRepresentation(newImage, 1.0) writeToFile:thumbnailDestinationUrl.path atomically:YES];
        }
        else if ([imageType isEqualToString:@"png"]){
            [UIImagePNGRepresentation(newImage) writeToFile:thumbnailDestinationUrl.path atomically:YES];
        }
        
            dispatch_async(dispatch_get_main_queue(), ^{
                //NSLog(@"itemname : %@", photo.item.name);
                /*if(downloadTask.error)
                 NSLog(@"did finish with error : %@",[downloadTask.originalRequest.URL lastPathComponent]);
                 else
                 NSLog(@"did finish without error : %@",[downloadTask.originalRequest.URL lastPathComponent]);*/
                photo.filePath = destinationUrl.path;
                photo.thumbnail_filePath = thumbnailDestinationUrl.path;
                //NSLog(@"%@",photo.thumbnail_filePath);
                [self saveContext];
            });
    }
    else{
        NSLog(@"fileManagerError: %@",fileManagerError.localizedDescription);
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    if(error){
        NSUInteger index = [downloadTasks indexOfObject:task];
        Photo *photo = [downloadPhotos objectAtIndex:index];
        NSLog(@"downloadTask error: %@, \n url = %@, place: %@",error.localizedDescription,photo.url,photo.place.name);
        [downloadTasks removeObjectAtIndex:index];
        [downloadPhotos removeObjectAtIndex:index];
    } else {
        NSLog(@"downloading completed");
    }
}

/*- (void) callCompletionHandlerIfFinished{
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
}*/

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes{
    NSLog(@"didResumeAtOffSet : %lld",expectedTotalBytes);
}

-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    //NSLog(@"%lld %lld %lld",bytesWritten,totalBytesWritten,totalBytesExpectedToWrite);
}

@end