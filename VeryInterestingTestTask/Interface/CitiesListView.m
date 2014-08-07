//
//  CitiesListView.m
//  VeryInterestingTestTask
//
//  Created by Valeriy Buev on 19.07.14.
//  Copyright (c) 2014 bva. All rights reserved.
//

#import "CitiesListView.h"
#import "PlaceTableViewCell.h"
#import "Place+PlaceCategory.h"
#import "AppSettings+AppSettingsCategory.h"
#import "AppDelegate.h"
#import "InitialDownloaderView.h"
#import "CitySectionHeaderView.h"
#import "Photo+PhotoCategory.h"
#import "FilterPopupView.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "NewPlaceView.h"

static NSString *SectionHeaderViewIdentifier = @"SectionHeaderViewIdentifier";
static NSString *PlaceCellIdentifier = @"CellPlace";

@interface CitiesListView ()
<NSFetchedResultsControllerDelegate, CitySectionHeaderViewDelegate, InitialDownloaderViewDelegate, FilterPopupViewDelegate, CLLocationManagerDelegate>
{
    NSFetchedResultsController *controller;
    NSMutableArray *hiddenSections;
    
    NSMutableArray *downloadPhotos;
    
    LocationFilterRadius locationFilterRadius;
    UIPopoverController *filterViewPopoverController;
    
    
    CLLocationManager *locationManager;
    CLLocation *currentLocation;
}

@property (nonatomic,retain) AppSettings *appSettings;
@property  (nonatomic, retain) NSManagedObjectContext *context;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *filterBarButton;

@end

@implementation CitiesListView
@synthesize appSettings = _appSettings;
@synthesize context = _context;
@synthesize filterBarButton;

#pragma mark initialization and basic functions


- (void)saveContext {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSError *error = nil;
        NSManagedObjectContext *managedObjectContext = self.context;
        
        if(managedObjectContext != nil) {
            if([managedObjectContext hasChanges] && ![managedObjectContext save:&error]){
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                abort();
            }
        }
    });
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
    
    locationFilterRadius = LocationFilterRadiusNone;
    downloadPhotos = [NSMutableArray array];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"CitySectionHeaderView_iPad" bundle:nil] forHeaderFooterViewReuseIdentifier:SectionHeaderViewIdentifier];
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:PlaceCellIdentifier];
    [self.tableView setRowHeight:cell.frame.size.height];
    [self.tableView setSectionHeaderHeight:44];
    if ( self.appSettings.didDataBeLoaded.boolValue == NO ){
        [self showInitialDownloaderView];
    }
    else {
        [self initCLLocationManager];
        [self setFetchedResultsController];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_mocDidSaveNotification:) name:NSManagedObjectContextDidSaveNotification object:nil];
}

- (void)_mocDidSaveNotification:(NSNotification *)notification
{
    NSLog(@"did save");
    NSManagedObjectContext *savedContext = [notification object];
    
    // ignore change notifications for the main MOC
    if (self.context == savedContext)
    {
        return;
    }
    
    if (self.context.persistentStoreCoordinator != savedContext.persistentStoreCoordinator)
    {
        // that's another database
        return;
    }
    
    //dispatch_sync(dispatch_get_main_queue(), ^{
        [self.context mergeChangesFromContextDidSaveNotification:notification];
    //[self.context performSelectorOnMainThread:@selector(mergeChangesFromContextDidSaveNotification:) withObject:notification waitUntilDone:YES];
    //});
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
    [self reloadFetchedResultsController];
}

- (void) reloadFetchedResultsController {
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
    [self.tableView reloadData];
}

- (void) reloadFetchedResultsControllerIfNeed {
    
    if ( locationFilterRadius == LocationFilterRadiusNone ) {
        return;
    }
    
    if ( currentLocation == nil ) {
        return;
    }
    
    double radius;
    switch (locationFilterRadius) {
        case LocationFilterRadiusOneHundredMiles:
            radius = 100000 * 1.609344; // 100 miles
            break;
        case LocationFilterRadiusOneMile:
            radius = 1000 * 1.609344; // 1 mile
            break;
        case LocationFilterRadiusTenMiles:
            radius = 10000 * 1.609344; // 10 miles
            break;
            
        default:
            radius = 0;
            break;
    }
    //NSLog(@"radius : %f ", radius);
    
    double dLat = 0.001;
    double dLon = 0.001;
    
    CLLocationCoordinate2D dLatCoordinate = currentLocation.coordinate;
    if ( dLatCoordinate.latitude >= 85 ){
        dLatCoordinate.latitude = - dLat + dLatCoordinate.latitude;
    }
    else {
        dLatCoordinate.latitude = dLat + dLatCoordinate.latitude;
    }
    CLLocationCoordinate2D dLonCoordinate = currentLocation.coordinate;
    dLonCoordinate.longitude = dLon + dLonCoordinate.longitude;
    
    //NSLog( @"dLat: %f dlon: %f", dLat, dLon );
    //NSLog( @"dLatCoordinate: %f %f dlonCoordinate: %f %f", dLatCoordinate.latitude, dLatCoordinate.longitude, dLonCoordinate.latitude, dLonCoordinate.longitude );
    
    MKMapPoint dLatPoint = MKMapPointForCoordinate( dLatCoordinate );
    MKMapPoint dLonPoint = MKMapPointForCoordinate( dLonCoordinate );
    MKMapPoint currentPoint = MKMapPointForCoordinate( currentLocation.coordinate );
    
    //NSLog( @"dLatPoint: %f, %f dLonPoint: %f %f currentPoint %f %f", dLatPoint.x, dLatPoint.y, dLonPoint.x, dLonPoint.y, currentPoint.x, currentPoint.y );
    
    CLLocationDistance dLatRadius = MKMetersBetweenMapPoints( currentPoint, dLatPoint );
    CLLocationDistance dLonRadius = MKMetersBetweenMapPoints( currentPoint, dLonPoint );
    
    //NSLog( @"dLatR: %f dlonR: %f", dLatRadius, dLonRadius );
    
    double RLat = ABS( dLat ) * ( radius / dLatRadius );
    double RLon = dLon * ( radius / dLonRadius );
    
    //NSLog( @"kLat: %f klon: %f", kLat, kLon );
    
    NSPredicate *predicate = [Place newPredicateWithMOC: self.context
                                         centerLatitude: currentLocation.coordinate.latitude
                                        centerLongitude: currentLocation.coordinate.longitude
                                              RLatitude: RLat
                                             RLongitude: RLon];
    [controller.fetchRequest setPredicate: predicate];
    
    [self reloadFetchedResultsController];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if( !controller )
        return 0;
    else {
        //NSLog(@"sections count; %d",controller.sections.count);
        return controller.sections.count;
    }
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
    NSLog(@"latitude: %@ longitude:%@",place.latitude,place.longtitude);
    
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
            [downloadPhotos removeObjectAtIndex:searchResult];
        }
        [self.context deleteObject:place];
        [self saveContext];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
    return UITableViewCellEditingStyleDelete;
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if( [[segue identifier] isEqualToString:@"FilterView"]){
        
    } else if ( [[segue identifier] isEqualToString:@"NewPlace"] ) {
        //NewPlaceView *newPlaceView = (NewPlaceView *) segue.destinationViewController;
    }
    else if ( [[segue identifier] isEqualToString:@"NewPlaceFromCell"] ) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        Place *place = [controller objectAtIndexPath:indexPath];
        NewPlaceView *newPlaceView = segue.destinationViewController;
        newPlaceView.place = place;
    }
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender{
    if( [identifier isEqualToString:@"NewPlace"] ) {
        
    }
    return YES;
}

- (IBAction)filterBarButtonClicked:(id)sender {
    FilterPopupView *filterPopupView = [self.storyboard instantiateViewControllerWithIdentifier:@"FilterPopupView"];
    filterPopupView.delegate = self;
    filterPopupView.locationFilterRadius = locationFilterRadius;
    filterViewPopoverController = [[UIPopoverController alloc] initWithContentViewController:filterPopupView];
    [filterViewPopoverController presentPopoverFromBarButtonItem:self.filterBarButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:NO];
}


#pragma mark NSFetchResultsControllerDelegate ( + FilterPopupViewDelegate )

- (void)setLocationFilterRadius:(LocationFilterRadius)_locationFilterRadius{
    
    BOOL haveChanges = locationFilterRadius != _locationFilterRadius ;
    locationFilterRadius = _locationFilterRadius;
    [filterViewPopoverController dismissPopoverAnimated:YES];
    NSString *title;
    switch (locationFilterRadius) {
        case 0:
            title = @"Filter";
            break;
            
        case 1:
            title = @"1 mile";
            break;
            
        case 2:
            title = @"10 miles";
            break;
            
        case 3:
            title = @"100 miles";
            break;
            
        default:
            break;
    }
    self.filterBarButton.title = title;
    if (haveChanges == YES) {
        if ( locationFilterRadius != LocationFilterRadiusNone ){
            [self reloadFetchedResultsControllerIfNeed];
        }
        else {
            [controller.fetchRequest setPredicate:nil];
            [self reloadFetchedResultsController];
        }
    }
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller{
    [self.tableView endUpdates];
}

-(void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    NSLog(@"controller didChangeObject");
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
                    [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationNone];
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
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationNone];
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

- (NSURLSession *) getDownloadPhotoSession{
    static NSURLSession *session;
    if( !session ){
        NSURLSessionConfiguration* sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        sessionConfig.HTTPMaximumConnectionsPerHost = 3;
        session = [NSURLSession sessionWithConfiguration:sessionConfig];
    }
    return session;
}

- (void) startDownloadingPhoto:(Photo *) photo{
    if( [downloadPhotos containsObject:photo] )
        return;
    [downloadPhotos addObject:photo];
    NSURL * url = [NSURL URLWithString:photo.url];
    if( !url ){
        url = [NSURL URLWithString:[photo.url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        //NSLog(@"incorrect url? new url : %@",url);
    }
    else {
        //NSLog(@"correct url: %@",url);
    }
    
    NSURLSession *session = [self getDownloadPhotoSession];
    
    [[session downloadTaskWithURL: url
                completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
                    
                    if(error){
                        NSLog(@"error:  %@ \n url: %@",error.localizedDescription, url);
                        [downloadPhotos removeObject:photo];
                        return;
                    }
                    if( ![downloadPhotos containsObject:photo]){
                        return;
                    }
                    
                    NSString *imageName = [url lastPathComponent];
                    
                    [Photo savePhotoAndItsThumbnail:photo fromLocation:location imageName:imageName];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self saveContext];
                        if( ![downloadPhotos containsObject:photo] )
                            return;
                        [downloadPhotos removeObject:photo];
                    });
                    
                }] resume];
}



#pragma mark Location Manager

- (void) initCLLocationManager {
    locationManager = [CLLocationManager new];
    locationManager.delegate = self;
    locationManager.distanceFilter = kCLLocationAccuracyHundredMeters;
    locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    [locationManager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    if ( currentLocation == nil ){
        currentLocation = [locations lastObject];
        NSLog(@"location: %@",[locations lastObject]);
        [self reloadFetchedResultsControllerIfNeed];
    }
    else {
        MKMapPoint point1 = MKMapPointForCoordinate(currentLocation.coordinate);
        MKMapPoint point2 = MKMapPointForCoordinate([[locations lastObject] coordinate]);
        CLLocationDistance distance = MKMetersBetweenMapPoints(point1, point2);
        if( distance > 100 ){
            currentLocation = [locations lastObject];
            NSLog(@"location: %@ distance: %f",[locations lastObject], distance);
            [self reloadFetchedResultsControllerIfNeed];
        }
    }
}

@end