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

#define MILE 1609.344

static NSString *SectionHeaderViewIdentifier = @"SectionHeaderViewIdentifier";
static NSString *PlaceCellIdentifier = @"CellPlace";

@interface CitiesListView ()
<NSFetchedResultsControllerDelegate, CitySectionHeaderViewDelegate, InitialDownloaderViewDelegate, FilterPopupViewDelegate, CLLocationManagerDelegate>
{
    // A FetchedResultsController of Places grouped by cities, filtered by locationFilterRadius
    NSFetchedResultsController *controller;
    // An array of boolean flags of section's states (YES = hidden, NO = shown)
    NSMutableArray *hiddenSections;
    
    // An array of photos, which are being downloaded or will be downloaded
    NSMutableArray *downloadPhotos;
    
    // Radius, by which controller filter places around user location
    LocationFilterRadius locationFilterRadius;
    // popover controller for FilterPopupView
    UIPopoverController *filterViewPopoverController;
    
    // CLLocationManager for getting user location
    CLLocationManager *locationManager;
    // Current user location
    CLLocation *currentLocation;
}

// Application settings
@property (nonatomic,retain) AppSettings *appSettings;
// NSManagedObjectContext
@property  (nonatomic, retain) NSManagedObjectContext *context;
// BarButton for FilterPopupView
@property (weak, nonatomic) IBOutlet UIBarButtonItem *filterBarButton;

@end

@implementation CitiesListView
@synthesize appSettings = _appSettings;
@synthesize context = _context;
@synthesize filterBarButton;

#pragma mark initialization and basic functions

// Saving of NSmanagedObjectContext
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
// Getting of NSManagedObjectContext from AppDelegate
- (NSManagedObjectContext *) context{
    if ( _context != nil )
        return _context;
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    _context = appDelegate.managedObjectContext;
    return _context;
}
// Getting of AppSettings-object
- (AppSettings *) appSettings{
    if(_appSettings != nil)
        return _appSettings;
    _appSettings = [AppSettings getInstance:self.context];
    return _appSettings;
}
// When main View did load first time
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    locationFilterRadius = LocationFilterRadiusNone;
    downloadPhotos = [NSMutableArray array];
    
    // Registering nib for SectionHeader
    [self.tableView registerNib:[UINib nibWithNibName:@"CitySectionHeaderView_iPad" bundle:nil] forHeaderFooterViewReuseIdentifier:SectionHeaderViewIdentifier];
    //Setting a height of tableView-cells and headers
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:PlaceCellIdentifier];
    [self.tableView setRowHeight:cell.frame.size.height];
    [self.tableView setSectionHeaderHeight:44];
    // If initial json-data was not loaded yet, then load it
    if ( self.appSettings.didDataBeLoaded.boolValue == NO ){
        [self showInitialDownloaderView];
    }
    // else init LocationManager and set NSFetchedResultsController
    else {
        [self initCLLocationManager];
        [self setFetchedResultsController];
    }
    // Subscription for notifications of NSManagedObjectContextDidSaveNotification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_mocDidSaveNotification:) name:NSManagedObjectContextDidSaveNotification object:nil];
}

// NSManagedObjectContextDidSaveNotification
- (void)_mocDidSaveNotification:(NSNotification *)notification
{
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
    
        [self.context mergeChangesFromContextDidSaveNotification:notification];
    //[self.context performSelectorOnMainThread:@selector(mergeChangesFromContextDidSaveNotification:) withObject:notification waitUntilDone:YES];
}

// Showing of InitialDownloaderView
- (void) showInitialDownloaderView{
    InitialDownloaderView *view = [self.storyboard instantiateViewControllerWithIdentifier:@"InitialDownloaderView"];
    view.delegate = self;
    view.context = self.context;
    [self presentViewController: view animated: NO completion:nil];
}

// Setting of NSFetchedResultsController (Places grouped by Cities)
- (void) setFetchedResultsController{
    controller = [Place newFetchedResultsControllerForMOC:self.context];
    controller.delegate = self;
    [self reloadFetchedResultsController];
}

// Performing  controller's fetch
- (void) reloadFetchedResultsController {
    NSError *error;
    [controller performFetch:&error];
    if( error ){
        NSLog(@"Error while performing fetch: %@",error.localizedDescription);
        controller = nil;
    }
    else{
        // ReInitialization of hiddenSections-array
        hiddenSections = [NSMutableArray array];
        NSUInteger sectionsCount = controller.sections.count;
        for ( NSUInteger i=0; i < sectionsCount; i++ ) {
            [hiddenSections addObject:[NSNumber numberWithBool:NO]];
        }
    }
    // Reloading tableView-data
    [self.tableView reloadData];
}

// Reloading FetchedResultsController if need
- (void) reloadFetchedResultsControllerIfNeed {
    
    // If current filter == none, then controller doesnt need to update
    if ( locationFilterRadius == LocationFilterRadiusNone ) {
        return;
    }
    
    // Or if we dont know current user location
    if ( currentLocation == nil ) {
        return;
    }
    
    [self setPredicateByLocationFilterRadius];
    
    // fetching predicate
    [self reloadFetchedResultsController];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source and delegating

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if( !controller )
        return 0;
    else {
        return controller.sections.count;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    // if section is hidden, then return 0
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

// configuring of cells
- (void) configureCell: (PlaceTableViewCell *) cell forIndexPath: (NSIndexPath *) indexPath {

    // getting Place-object of appropriate indexPath
    Place *place = [controller objectAtIndexPath:indexPath];
    
    cell.labelName.text = place.name;
    
    // if Place does not have photos, then set standart "no_photo" image
    if( place.photos.count > 0){
        
        // getting of first photo
        Photo *photo;
        for( Photo *photo_ in place.photos){
            photo = photo_;
            break;
        }
        
        // setting photo reference of cell
        cell.photo = photo;
        
        // if Photo does not have thumbnail, but has url, then add Photo to donload-stack
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

// Configuring of HeaderView of section at sectionIndex
- (void) configureHeaderView:(CitySectionHeaderView *) view sectionIndex:(NSUInteger ) sectionIndex{
    
    // Getting of sectionInfo and setting reference of HeaderView to it
    id <NSFetchedResultsSectionInfo> sectioninfo = [controller.sections objectAtIndex:sectionIndex];
    view.sectionInfo = sectioninfo;
    
    // setting self as delegate of HeaderView
    view.delegate = self;
    // First time section is noo hidden
    NSNumber *isSectionHidden = [hiddenSections objectAtIndex:sectionIndex];
    view.isSectionHidden = isSectionHidden.boolValue;
    
    //setting the name of section
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
        
        // if place's photo is in donload-stack now, then remove it out from there
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
        
        // commit deleting of place
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

// Setting some properties of destination ViewControllers
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if( [[segue identifier] isEqualToString:@"FilterView"]){
        
    } else if ( [[segue identifier] isEqualToString:@"NewPlace"] ) {
        
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

// Presenting of FilterPopupView
- (IBAction)filterBarButtonClicked:(id)sender {
    FilterPopupView *filterPopupView = [self.storyboard instantiateViewControllerWithIdentifier:@"FilterPopupView"];
    filterPopupView.delegate = self;
    filterPopupView.locationFilterRadius = locationFilterRadius;
    filterViewPopoverController = [[UIPopoverController alloc] initWithContentViewController:filterPopupView];
    [filterViewPopoverController presentPopoverFromBarButtonItem:self.filterBarButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:NO];
}

#pragma mark FilterPopupViewDelegate

// Setting of new locationFilterRadius
- (void)setLocationFilterRadius:(LocationFilterRadius)_locationFilterRadius{
    
    BOOL hasChanges = locationFilterRadius != _locationFilterRadius ;
    locationFilterRadius = _locationFilterRadius;
    [filterViewPopoverController dismissPopoverAnimated:YES];
    // Setting of filter bar button's title
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
    // if locationFilterRadius was changed, then reload NSFetchedResultsController
    if (hasChanges == YES) {
        if ( locationFilterRadius != LocationFilterRadiusNone ){
            [self reloadFetchedResultsControllerIfNeed];
        }
        else {
            [controller.fetchRequest setPredicate:nil];
            [self reloadFetchedResultsController];
        }
    }
}

#pragma mark NSFetchResultsController

// setting Predicate of controller by LocationFilterRadius
- (void) setPredicateByLocationFilterRadius {
    // setting of radius
    double radius ;
    switch (locationFilterRadius) {
        case LocationFilterRadiusOneHundredMiles:
            radius = 100 * MILE; // 100 miles
            break;
        case LocationFilterRadiusOneMile:
            radius = 1 * MILE; // 1 mile
            break;
        case LocationFilterRadiusTenMiles:
            radius = 10 * MILE; // 10 miles
            break;
            
        default:
            radius = 0;
            break;
    }
    
    // Здесь мы вычисляем приращения долготы и широты, используя функцию расстояния.
    // Для этого сначала сдвигаем координаты на фиксированное число по широте, вычисляем коэффициент,
    // Затем так же делаем по долготе
    
    // variables for calculate latitude and longitude coefficients
    double dLat = 0.001;
    double dLon = 0.001;
    
    // Moving coordinate by Latitude and Longitude
    CLLocationCoordinate2D dLatCoordinate = currentLocation.coordinate;
    if ( dLatCoordinate.latitude >= 85 ){
        dLatCoordinate.latitude = - dLat + dLatCoordinate.latitude;
    }
    else {
        dLatCoordinate.latitude = dLat + dLatCoordinate.latitude;
    }
    CLLocationCoordinate2D dLonCoordinate = currentLocation.coordinate;
    dLonCoordinate.longitude = dLon + dLonCoordinate.longitude;
    
    // Making MKMapPoint variables for calculating distance
    MKMapPoint dLatPoint = MKMapPointForCoordinate( dLatCoordinate );
    MKMapPoint dLonPoint = MKMapPointForCoordinate( dLonCoordinate );
    MKMapPoint currentPoint = MKMapPointForCoordinate( currentLocation.coordinate );
    
    // Calculating distance between user location and moved locations
    CLLocationDistance dLatRadius = MKMetersBetweenMapPoints( currentPoint, dLatPoint );
    CLLocationDistance dLonRadius = MKMetersBetweenMapPoints( currentPoint, dLonPoint );
    
    // Calculating Radiuses
    double RLat = ABS( dLat ) * ( radius / dLatRadius );
    double RLon = dLon * ( radius / dLonRadius );
    
    // Making predicate
    NSPredicate *predicate = [Place newPredicateWithMOC: self.context
                                         centerLatitude: currentLocation.coordinate.latitude
                                        centerLongitude: currentLocation.coordinate.longitude
                                              RLatitude: RLat
                                             RLongitude: RLon];
    // Setting predicate for controller
    [controller.fetchRequest setPredicate: predicate];
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller{
    [self.tableView endUpdates];
}

-(void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    
    // if section is hidden then do nothing
        BOOL isSectionHidden = [[hiddenSections objectAtIndex:indexPath.section] boolValue];
        BOOL isNewSectionHidden = [[hiddenSections objectAtIndex:newIndexPath.section] boolValue];
        switch (type) {
            case NSFetchedResultsChangeDelete:
                if(isSectionHidden == NO){
                    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
                }
                break;
                
            case NSFetchedResultsChangeInsert:
                if(isNewSectionHidden == NO){
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
                if(isSectionHidden == NO){
                    PlaceTableViewCell *cell = (PlaceTableViewCell *) [self.tableView cellForRowAtIndexPath:indexPath];
                    [self configureCell:cell forIndexPath:indexPath];
                }
            }
                break;
                
            default:
                break;
        }
}

-(void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    switch (type) {
        case NSFetchedResultsChangeDelete:{
            // remove section hidden-flag from array of boolean flags
            [hiddenSections removeObjectAtIndex:sectionIndex];
            // remove section from table
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
        }
            break;
            
        case NSFetchedResultsChangeInsert:{
            // insert section hidden-flag into array of boolean flags
            [hiddenSections insertObject:[NSNumber numberWithBool:NO] atIndex:sectionIndex];
            // insert section into table
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

// section of (CitySectionHeaderView *)view has been hidden/shown
- (void)citySectionHeaderView:(CitySectionHeaderView *)view didHidden:(Boolean)isHidden{
    
    // get section info for searching sectionIndex
    id <NSFetchedResultsSectionInfo> sectionInfo = view.sectionInfo;
    NSUInteger sectionIndex = [controller.sections indexOfObject:sectionInfo];
    // settting section-hidden flag to hidden/shown
    [hiddenSections setObject:[NSNumber numberWithBool:isHidden] atIndexedSubscript:sectionIndex];
    
    //getting of indexPatthes of cells in this section
    NSMutableArray *indexPathes = [NSMutableArray arrayWithCapacity:[sectionInfo numberOfObjects]];
    for(int i=0;i<[sectionInfo numberOfObjects];i++){
        [indexPathes addObject:[NSIndexPath indexPathForRow:i inSection:sectionIndex]];
    }
    
    // inserting/deleting of cells
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

// Data initialization has been done
- (void)initialDownloaderViewShouldBeDisappeared:(InitialDownloaderView *)view{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated:YES completion:nil];
        [self setFetchedResultsController];
    });
}

#pragma mark photo downloading

// Creating of a NSURLSession for photo downloading
- (NSURLSession *) getDownloadPhotoSession{
    static NSURLSession *session;
    // create once
    if( !session ){
        NSURLSessionConfiguration* sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        // 3 photo downloading maximum per time
        sessionConfig.HTTPMaximumConnectionsPerHost = 3;
        // infinitive interval for request
        sessionConfig.timeoutIntervalForRequest = 0;
        session = [NSURLSession sessionWithConfiguration:sessionConfig];
    }
    return session;
}

// Adding a photo to downloading stack
- (void) startDownloadingPhoto:(Photo *) photo{
    
    //if photo is contained already in downloading stack then return
    if( [downloadPhotos containsObject:photo] )
        return;
    // else add photo in  stack
    [downloadPhotos addObject:photo];
    
    NSURL * url = [NSURL URLWithString:photo.url];
    if( !url ){
        // correcting of URL
        url = [NSURL URLWithString:[photo.url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    }
    
    NSURLSession *session = [self getDownloadPhotoSession];
    
    // creating and of download task with completionHandler
    [[session downloadTaskWithURL: url
                completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
                    
                    // if error, remove photo from stack and return;
                    if(error){
                        NSLog(@"error:  %@ \n url: %@",error.localizedDescription, url);
                        [downloadPhotos removeObject:photo];
                        return;
                    }
                    // if stack doesnt contain photo, return
                    if( ![downloadPhotos containsObject:photo]){
                        return;
                    }
                    
                    NSString *imageName = [url lastPathComponent];
                    
                    // save photo and its thumbnail
                    [Photo savePhotoAndItsThumbnail:photo fromLocation:location imageName:imageName];
                    
                    // save context and remove photo from stack
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self saveContext];
                        if( ![downloadPhotos containsObject:photo] )
                            return;
                        [downloadPhotos removeObject:photo];
                    });
                    
                }] resume];
}



#pragma mark Location Manager

// initialization of location manager
- (void) initCLLocationManager {
    locationManager = [CLLocationManager new];
    locationManager.delegate = self;
    locationManager.distanceFilter = kCLLocationAccuracyHundredMeters;
    locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    [locationManager startUpdatingLocation];
}

// user location did change
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    // if it is first calling, remember location and reload fetchedcontroller if need
    if ( currentLocation == nil ){
        currentLocation = [locations lastObject];
        //NSLog(@"location: %@",[locations lastObject]);
        [self reloadFetchedResultsControllerIfNeed];
    }
    // else if distance between new point and old point is more then 100 meters,
    // remember location and reload fetchedcontroller if need
    else {
        MKMapPoint point1 = MKMapPointForCoordinate(currentLocation.coordinate);
        MKMapPoint point2 = MKMapPointForCoordinate([[locations lastObject] coordinate]);
        CLLocationDistance distance = MKMetersBetweenMapPoints(point1, point2);
        if( distance > 100 ){
            currentLocation = [locations lastObject];
            //NSLog(@"location: %@ distance: %f",[locations lastObject], distance);
            [self reloadFetchedResultsControllerIfNeed];
        }
    }
}

@end