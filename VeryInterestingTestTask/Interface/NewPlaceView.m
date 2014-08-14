//
//  NewPlaceView.m
//  VeryInterestingTestTask
//
//  Created by Valeriy Buev on 25.07.14.
//  Copyright (c) 2014 bva. All rights reserved.
//

#define ALERTVIEW_TAG_ASK_USER_GALARY_OR_CAMERA 1
#define ALERTVIEW_TAG_ASK_USER_ABOUT_SAVING_BEFORE_QUIT 2

#import "NewPlaceView.h"
#import "AppDelegate.h"

#import "Place+PlaceCategory.h"
#import "GetLocationByMapPinView.h"
#import "GetLocationByGeocoding.h"
#import "Photo+PhotoCategory.h"
#import "FullScreenImageView.h"

@interface NewPlaceView ()
<GetLoactionByMapPinViewDelegate, GetLocationByGeocodingDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIAlertViewDelegate>{
    // popover controller for geocoding-view and mapView
    UIPopoverController *localPopover;
    // An array of images (UIImage *), which were been added from Galary or Camera
    NSMutableArray *addedPhotos;
    // An array of photos (Photo *), which initialy was in Place.
    NSMutableArray *placePhotos;
    // An array of photos (Photo *) which have been removed by user
    NSMutableArray *deletedPlacePhotos;
    // if collectionView is in editMode then this flag is YES
    Boolean collectionViewEditMode;
}

@property (nonatomic,retain) NSManagedObjectContext *context;

// UI-properties
@property (weak, nonatomic) IBOutlet UITextField *textFieldName;
@property (weak, nonatomic) IBOutlet UITextField *textFieldLatitude;
@property (weak, nonatomic) IBOutlet UITextField *textFieldLongtitude;
@property (weak, nonatomic) IBOutlet UITextView *textViewDescription;
@property (weak, nonatomic) IBOutlet UITextField *textFieldCityName;
// a cell contains textFieldLatitude, textFieldLongtitude, "by geocoding" buttun, "by map pin button"
@property (weak, nonatomic) IBOutlet UITableViewCell *cellLatitudeLongitude;
// A UICollectionView contains photos of the place
@property (weak, nonatomic) IBOutlet UICollectionView *photosCollectionView;
// A view on navigationBar contains buttons "remove" and "cancel" for editing collection
@property (weak, nonatomic) IBOutlet UIView *viewBarButtonsRemoveAndCancel;

@end

@implementation NewPlaceView

@synthesize context = _context;
@synthesize textFieldCityName;
@synthesize textFieldLongtitude;
@synthesize textFieldLatitude;
@synthesize textFieldName;
@synthesize cellLatitudeLongitude;
@synthesize photosCollectionView;
//@synthesize place;


#pragma mark initialization

- (void)viewDidAppear:(BOOL)animated {
    // show toolbar when view is appear
    [self.navigationController setToolbarHidden:NO animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    // hide toolbar when view is disappear
    [self.navigationController setToolbarHidden:YES animated:YES];
}

// getter of NSManagedObject context from AppDelegate
- (NSManagedObjectContext *)context{
    if( _context )
        return _context;
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    //NSPersistentStoreCoordinator *coordinator = [appDelegate persistentStoreCoordinator];
    //_context = [[NSManagedObjectContext alloc] init];
    //[_context setPersistentStoreCoordinator:coordinator];
    _context = [appDelegate managedObjectContext];
    return _context;
}

// Initial actions, when view did appear first time
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // initial state of collection editMode is NO
    [self.viewBarButtonsRemoveAndCancel setHidden:YES];
    
    addedPhotos = [NSMutableArray array];
    deletedPlacePhotos = [NSMutableArray array];
    
    // if NewPlaceView already has place, show it
    if( self.place ){
        self.textFieldCityName.text = [self.place.city copy];
        self.textFieldLatitude.text = [self.place.latitude stringValue];
        self.textFieldLongtitude.text = [self.place.longtitude stringValue];
        self.textFieldName.text = [self.place.name copy];
        self.textViewDescription.text = [self.place.placeDescription copy];
        placePhotos = [self.place.photos.allObjects mutableCopy];
        [self.navigationItem setTitle:@"Edit location"];
    }
    else {
        placePhotos = [NSMutableArray array];
    }
    
    // catch long press notification for set collectionView to editMode
    UILongPressGestureRecognizer *recognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleCollectionViewLongPress:)];
    recognizer.minimumPressDuration = 1;
    [self.photosCollectionView addGestureRecognizer: recognizer];
    self.photosCollectionView.allowsMultipleSelection = YES;
    collectionViewEditMode = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark navigation

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if ( [identifier isEqualToString:@"FullScreenImage"] ) {
        if( collectionViewEditMode == YES )
            return NO;
        NSIndexPath *indexPath = [self.photosCollectionView.indexPathsForSelectedItems firstObject];
        if( indexPath.row < placePhotos.count ) {
            Photo *photo = [placePhotos objectAtIndex: indexPath.row];
            if( [photo.filePath isEqualToString:@""] || photo.filePath == nil )
                return NO;
            else
                return YES;
        }
        else {
            return YES;
        }
    }
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ( [segue.identifier isEqualToString:@"FullScreenImage"] ) {
        NSIndexPath *indexPath = [self.photosCollectionView.indexPathsForSelectedItems firstObject];
        UIImage *image;
        if( indexPath.row < placePhotos.count ) {
            Photo *photo = [placePhotos objectAtIndex: indexPath.row];
            image = [UIImage imageWithContentsOfFile: photo.filePath];
        }
        else {
            image = [addedPhotos objectAtIndex: indexPath.row - placePhotos.count ];
        }
        FullScreenImageView *view = segue.destinationViewController;
        view.image = image;
    }
}

#pragma mark UI-actions

// User wants return back
- (IBAction)btnBackPressed:(id)sender {
    if( [self isDataChanged] ){
        [self askUserAboutSavingBeforeQuit];
    }
    else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

// User want to save data
- (IBAction)btnSaveClicked:(id)sender {
    
    //  save and return If data is valid
    if ( [self isDataChanged]) {
        if ( [self validatePlaceData] )
        {
            [self savePlaceData];
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}

// Remove selected images
- (IBAction)btnRemovePhotosClicked:(id)sender {
    [self removeSelectedPhotos];
}

// Cancel collectionView edit mode
- (IBAction)btnCancelEditModeClicked:(id)sender {
    [self setCollectionViewEditMode:NO];
}

// Long press on collectionView
-  (void)handleCollectionViewLongPress:(UILongPressGestureRecognizer*)sender
{
    // if there is at least one image and long press ended, continue
    if (sender.state != UIGestureRecognizerStateEnded || (placePhotos.count + addedPhotos.count)==0 ) {
        return;
    }
    
    // set collectionView to editMode
    [self setCollectionViewEditMode:YES];
    
    // get long press point for searching collectionCell-indexPath
    CGPoint p = [sender locationInView:self.photosCollectionView];
    // search indexPath
    NSIndexPath *indexPath = [self.photosCollectionView indexPathForItemAtPoint:p];
    if (indexPath == nil){
        NSLog(@"couldn't find index path");
    } else {
        // if user selected "add_photo"-cell, then do nothing,
        // else set this cell selected
        if(indexPath.row != (placePhotos.count + addedPhotos.count))
            [self.photosCollectionView selectItemAtIndexPath: indexPath
                                                    animated: YES
                                              scrollPosition: UICollectionViewScrollPositionNone];
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    //[self.photosCollectionView.collectionViewLayout invalidateLayout];
}

// User want to set location coordinates by geocoding
- (IBAction)btnGetLocationByGeocodingClicked:(id)sender
{
    // create geocoding-view
    GetLocationByGeocoding *view = [self.storyboard instantiateViewControllerWithIdentifier:@"Geocoding"];
    // set self as delegate
    view.delegate = self;
    // present geocoding-view
    localPopover = [[UIPopoverController alloc] initWithContentViewController: view];
    [localPopover presentPopoverFromRect: self.cellLatitudeLongitude.bounds
                                  inView: self.cellLatitudeLongitude
                permittedArrowDirections: UIPopoverArrowDirectionDown | UIPopoverArrowDirectionUp
                                animated: YES];
}

// User want to set location coordinates by dropping map pin
- (IBAction)btnGetLocationByDroppingMapPinClicked:(id)sender
{
    // create map-view
    GetLocationByMapPinView *view = [self.storyboard instantiateViewControllerWithIdentifier:@"MapView"];
    // set self as delegate
    view.delegate = self;
    // present map-view
    localPopover = [[UIPopoverController alloc] initWithContentViewController:view];
    [localPopover presentPopoverFromRect: self.cellLatitudeLongitude.bounds
                                  inView: self.cellLatitudeLongitude.contentView
                permittedArrowDirections: UIPopoverArrowDirectionDown | UIPopoverArrowDirectionUp
                                animated:YES ];
}

# pragma mark Alerts

// Asks user what he wants: to select image from galary or to get it by Camera
- (void) askUserGaleryOrCamera {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" message:@"Do You want to get photo from Galary or to create photo by Camera?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"from Galary", @"by Camera", nil];
    alertView.tag = ALERTVIEW_TAG_ASK_USER_GALARY_OR_CAMERA;
    [alertView show];
}

// Asks user does he want save unsaved place data
- (void) askUserAboutSavingBeforeQuit {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" message:@"Do you really want to quit without saving?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"YES", nil];
    alertView.tag = ALERTVIEW_TAG_ASK_USER_ABOUT_SAVING_BEFORE_QUIT;
    [alertView show];
}

// AlertView delegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    // User answered the question "Galary or Camera?"
    if(alertView.tag == ALERTVIEW_TAG_ASK_USER_GALARY_OR_CAMERA){
        switch ( buttonIndex ) {
            case 0:
                break;
            case 1:
                [self getPhotoFromGalery];
                break;
            case 2:
                [self getPhotoFromCamera];
                break;
            default:
                break;
        }
    }
    // User answered the question "Do you want save?"
    else if( alertView.tag == ALERTVIEW_TAG_ASK_USER_ABOUT_SAVING_BEFORE_QUIT ) {
        switch ( buttonIndex ) {
            case 0:
                break;
            case 1:
                [self.navigationController popViewControllerAnimated:YES];
                break;
            default:
                break;
        }
    }
}

# pragma mark Getting photo from Camera/Galary

// getting photo from Galary
- (void) getPhotoFromGalery {
    
    if( [UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypePhotoLibrary] ){
        // creating of ImagePicherController
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        
        picker.allowsEditing = NO;
        picker.delegate = self;
        
        // presenting of ImagePickerController
        [self presentViewController: picker animated: YES completion:nil];
    }
}

// getting phoro from Camera
- (void) getPhotoFromCamera {
    
    if( [UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera] ){
        // creating of ImagePicherController
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        
        picker.allowsEditing = NO;
        picker.delegate = self;
        
        // presenting of ImagePickerController
        [self presentViewController: picker animated: YES completion:nil];
    }
}

// User has chosen an image
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    // choose  edited- or original- image
    UIImage * editedImage, * originalImage, *imageToUse;
    editedImage = (UIImage *) [info objectForKey:
                               UIImagePickerControllerEditedImage];
    originalImage = (UIImage *) [info objectForKey:
                                 UIImagePickerControllerOriginalImage];
    
    if (editedImage) {
        imageToUse = editedImage;
    } else {
        imageToUse = originalImage;
    }
    
    // add image to array of addedPhotos
    [addedPhotos addObject: imageToUse];
    // add collectionViewCell with chosen image
    [self.photosCollectionView insertItemsAtIndexPaths:
     [NSArray arrayWithObject:
      [NSIndexPath indexPathForRow:
       (placePhotos.count + addedPhotos.count - 1) inSection: 0]]];
    
    // dismiss ImagePickerController
    [self dismissViewControllerAnimated: YES completion: nil];
}

#pragma mark UITableViewDataSource

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0;
}

#pragma mark GetLocationByMapPinViewDelegate

// User has set map pin
- (void)GetLoactionByMapPinView:(GetLocationByMapPinView *)view didChangePinLatitude:(double)latitude longitude:(double)longitude {
    self.textFieldLatitude.text = [[NSNumber numberWithDouble: latitude] stringValue];
    self.textFieldLongtitude.text = [[NSNumber numberWithDouble: longitude] stringValue];
}

#pragma mark GetLocationByGeocodingDelegate

// Geocoding finished correctly
- (void)GetLocationByGeocoding:(GetLocationByGeocoding *)view didChangeLatitude:(double)latitude longitude:(double)longitude {
    self.textFieldLatitude.text = [[NSNumber numberWithDouble: latitude] stringValue];
    self.textFieldLongtitude.text = [[NSNumber numberWithDouble: longitude] stringValue];
}

// Geocoding finished with error
- (void)GetLocationByGeocoding:(GetLocationByGeocoding *)view didFinishGeocodingWithError:(NSError *)error {
    self.textFieldLatitude.text = @"";
    self.textFieldLongtitude.text = @"";
}

#pragma mark UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return placePhotos.count + addedPhotos.count + 1;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionViewCell *cell;
    // if current cell is "add" cell
    if(indexPath.row == (addedPhotos.count + placePhotos.count)) {
        static NSString *identifier = @"add_image";
        cell = [collectionView dequeueReusableCellWithReuseIdentifier: identifier
                                                                               forIndexPath: indexPath];
    }
    // if current cell is added image
    else if ((int)indexPath.row > (int)(placePhotos.count -1)) {
        static NSString *identifier = @"image";
        cell = [collectionView dequeueReusableCellWithReuseIdentifier: identifier forIndexPath:indexPath];
        UIImageView * imageView = (UIImageView *) [cell viewWithTag:1];
        imageView.image = [addedPhotos objectAtIndex: indexPath.row - placePhotos.count];
    }
    // if current cell is place's photo
    else {
        static NSString *identifier = @"image";
        cell = [collectionView dequeueReusableCellWithReuseIdentifier: identifier forIndexPath:indexPath];
        UIImageView * imageView = (UIImageView *) [cell viewWithTag:1];
        Photo *photo = [placePhotos objectAtIndex: indexPath.row];
        // if photo doesnt have downloaded image
        if( photo.thumbnail_filePath != nil && ![photo.thumbnail_filePath isEqualToString:@""] )
            imageView.image = [UIImage imageWithContentsOfFile: photo.thumbnail_filePath];
        else
            imageView.image = [UIImage imageNamed:@"no_photo.jpg"];
    }
    
    cell.selectedBackgroundView = [[UIView alloc] init];
    cell.selectedBackgroundView.backgroundColor = [UIColor blueColor];
    return cell;
}

// makes size of collectionViewCell as prototype
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGSize viewSize = collectionView.frame.size;
    return CGSizeMake( viewSize.height, viewSize.height );
}

// Removes selected images in collectionView
- (void) removeSelectedPhotos {
    
    // getting indexPaths of selected collectionView cells
    NSArray *indexPaths = self.photosCollectionView.indexPathsForSelectedItems;
    // Arrays of images for deleting
    NSMutableArray *addedPhotosToRemove = [NSMutableArray array];
    NSMutableArray *placePhotosToRemove = [NSMutableArray array];
    
    for ( NSIndexPath *indexPath in indexPaths) {
        // if it is added image, add it to addedPhotosToRemove
        if(indexPath.row > placePhotos.count -1) {
            [addedPhotosToRemove addObject:[addedPhotos objectAtIndex: indexPath.row - placePhotos.count]];
        }
        // if it is place's photo, add it to placePhotosToRemove
        else {
            [placePhotosToRemove addObject:[placePhotos objectAtIndex:indexPath.row]];
        }
    }
    
    // removing images from arrays
    [placePhotos removeObjectsInArray:placePhotosToRemove];
    [addedPhotos removeObjectsInArray:addedPhotosToRemove];
    if(placePhotosToRemove.count >0){
        // remember photos needs to be deleted if user wants save changes
        [deletedPlacePhotos addObjectsFromArray:placePhotosToRemove];
    }
    // cancel editMode
    [self setCollectionViewEditMode:NO];
    // remove cells from collectionView
    [self.photosCollectionView deleteItemsAtIndexPaths:indexPaths];
}

// Set collectionView in/out of editMode
- (void) setCollectionViewEditMode:(Boolean) editable
{
    if( collectionViewEditMode == editable )
        return;
    collectionViewEditMode = editable;

    if(collectionViewEditMode == YES) {
        // show bar Buttons "remove" and "cancel"
        [self.viewBarButtonsRemoveAndCancel setHidden:NO];
    }
    else {
        // deselect selected collectionViewCells
        NSArray *indexPaths = self.photosCollectionView.indexPathsForSelectedItems;
        for(NSIndexPath *indexPath in indexPaths){
            [self.photosCollectionView deselectItemAtIndexPath:indexPath animated:NO];
        }
        // hide bar Buttons "remove" and "cancel"
        [self.viewBarButtonsRemoveAndCancel setHidden:YES];
    }
}



#pragma mark UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    // if collectionView is in editMode and collectionView has no more selected items, then set collectionView out of editMode
    if( collectionViewEditMode == YES ){
        NSArray *indexPaths = self.photosCollectionView.indexPathsForSelectedItems;
        if( indexPaths.count == 0 )
            [self setCollectionViewEditMode:NO];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    // deselect item, if collectionView is out of editMode
    if (collectionViewEditMode == NO) {
        [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    }
    // if it is "add_image" cell
    if ( indexPath.row == addedPhotos.count + placePhotos.count ) {
        // if collectionView is out of editMode then get image from Galary or Camera
        if(collectionViewEditMode == NO)
            [self askUserGaleryOrCamera];
        // else deselect and do noting
        else {
            [collectionView deselectItemAtIndexPath:indexPath animated:NO];
        }
    }
}

# pragma mark DATA

// Validates Place-data from ui-inputs
// Returns YES if data is valid
- (Boolean) validatePlaceData {
    //
    NSString *placeName = self.textFieldName.text;
    NSString *latitude = self.textFieldLatitude.text;
    NSString *longitude = self.textFieldLongtitude.text;
    //NSString *description = self.textViewDescription.text;
    if ( [placeName isEqualToString:@""] ) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Location name is incorrect!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
        return NO;
    }
    if( [latitude isEqualToString:@""] || [longitude isEqualToString:@""] ) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Get latitude and longitude by geocoding or by dropping map pin" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
        return NO;
    }
    return YES;
}

// Saves place-data
- (void) savePlaceData {
    // text data
    NSString *placeName = self.textFieldName.text;
    NSNumber *latitude = [NSNumber numberWithDouble: self.textFieldLatitude.text.doubleValue];
    NSNumber *longitude = [NSNumber numberWithDouble: self.textFieldLongtitude.text.doubleValue];
    NSString *cityName = self.textFieldCityName.text;
    NSString *description = self.textViewDescription.text;
    
    Place *place;
    // if it is a new place, then create it
    if( !self.place ){
        place = [Place newPlaceWithName: placeName
                                   city: cityName
                            description: @""
                               latitude: latitude
                             longtitude: longitude
                                    MOC: self.context];
    }
    // else set attributes of current place
    else {
        place = self.place;
        place.name = [placeName copy];
        place.latitude = [latitude copy];
        place.longtitude = [longitude copy];
        place.city = [cityName copy];
    }
    place.placeDescription = [description copy];
    
    // save images
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // images from galary or camera
    for (UIImage *image in addedPhotos) {
        
        // give image unique name and save it in document directory
        NSArray *urls = [fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
        NSURL *documentsDirectory = [urls objectAtIndex:0];
        NSString *uniqueName = [[NSProcessInfo processInfo] globallyUniqueString];
        NSString *fileName = [NSString stringWithFormat:@"image%@.jpg",uniqueName];
        NSURL *filePath = [documentsDirectory URLByAppendingPathComponent:fileName];
        NSData *imageData = UIImageJPEGRepresentation(image, 1);
        [imageData writeToURL:filePath atomically:YES];
        
        // give new unique name to give it to Photo method savePhotoAndItsThumbnail
        uniqueName = [[NSProcessInfo processInfo] globallyUniqueString];
        fileName = [NSString stringWithFormat:@"image%@.png",uniqueName];
        Photo *photo = [Photo newPhotoWithUrl:@"" forPlace: place MOC: self.context];
        [Photo savePhotoAndItsThumbnail: photo
                           fromLocation: filePath
                              imageName: fileName];
    }
    
    // remove deleted photos
    [place removePhotos:[NSSet setWithArray:deletedPlacePhotos]];
    for(Photo *photo in deletedPlacePhotos){
        [self.context deleteObject:photo];
    }
    
    // save context
    dispatch_async(dispatch_get_main_queue(), ^{
        if( [self.context hasChanges] && ![self.context save:nil])
            NSLog(@"has changes but cant save");
    });
    
}

// returns NO if data has no changes, else returns YES
- (BOOL) isDataChanged {
    
    // Photos
    if( addedPhotos.count > 0
       || deletedPlacePhotos.count > 0)
        return YES;
    
    // Strings and numbers
    if( ![self.textFieldName.text isEqualToString: self.place.name] ||
       ![self.textFieldCityName.text isEqualToString: self.place.city] ||
       ![self.textViewDescription.text isEqualToString: self.place.placeDescription] ||
       self.textFieldLatitude.text.floatValue != self.place.latitude.floatValue ||
       self.textFieldLongtitude.text.floatValue != self.place.longtitude.floatValue
       )
        return YES;
    
    return NO;
}


@end
