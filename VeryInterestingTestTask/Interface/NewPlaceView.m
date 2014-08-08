//
//  NewPlaceView.m
//  VeryInterestingTestTask
//
//  Created by Valeriy Buev on 25.07.14.
//  Copyright (c) 2014 bva. All rights reserved.
//

#import "NewPlaceView.h"
#import "AppDelegate.h"

#import "Place+PlaceCategory.h"
#import "GetLocationByMapPinView.h"
#import "GetLocationByGeocoding.h"
#import "Photo+PhotoCategory.h"

@interface NewPlaceView ()
<GetLoactionByMapPinViewDelegate, GetLocationByGeocodingDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIAlertViewDelegate>{
    UIPopoverController *localPopover;
    NSMutableArray *addedPhotos;
    NSMutableArray *placePhotos;
    NSMutableArray *deletedPlacePhotos;
    Boolean collectionViewEditMode;
}

@property (nonatomic,retain) NSManagedObjectContext *context;

@property (weak, nonatomic) IBOutlet UITextField *textFieldName;
@property (weak, nonatomic) IBOutlet UITextField *textFieldLatitude;
@property (weak, nonatomic) IBOutlet UITextField *textFieldLongtitude;
@property (weak, nonatomic) IBOutlet UITextField *textFieldCityName;
@property (weak, nonatomic) IBOutlet UITableViewCell *cellLatitudeLongitude;
@property (weak, nonatomic) IBOutlet UICollectionView *photosCollectionView;
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


- (IBAction)btnOKClicked:(id)sender {
    
    NSString *placeName = self.textFieldName.text;
    NSNumber *latitude = [NSNumber numberWithDouble: self.textFieldLatitude.text.doubleValue];
    NSNumber *longitude = [NSNumber numberWithDouble: self.textFieldLongtitude.text.doubleValue];
    NSString *cityName = self.textFieldCityName.text;
    
    Place *place;
    if( !self.place ){
        place = [Place newPlaceWithName: placeName
                           city: cityName
                    description: @""
                       latitude: latitude
                     longtitude: longitude
                            MOC: self.context];
    } else {
        place = self.place;
        place.name = [placeName copy];
        place.latitude = [latitude copy];
        place.longtitude = [longitude copy];
        place.city = [cityName copy];
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    for (UIImage *image in addedPhotos) {
        NSArray *urls = [fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
        NSURL *documentsDirectory = [urls objectAtIndex:0];
        NSString *uniqueName = [[NSProcessInfo processInfo] globallyUniqueString];
        NSString *fileName = [NSString stringWithFormat:@"image%@.jpg",uniqueName];
        NSLog(@"%@",fileName);
        NSURL *filePath = [documentsDirectory URLByAppendingPathComponent:fileName];
        
        // Convert UIImage object into NSData (a wrapper for a stream of bytes) formatted according to PNG spec
        NSData *imageData = UIImageJPEGRepresentation(image, 1);
        [imageData writeToURL:filePath atomically:YES];
        uniqueName = [[NSProcessInfo processInfo] globallyUniqueString];
        fileName = [NSString stringWithFormat:@"image%@.png",uniqueName];
        NSLog(@"%@",fileName);
        Photo *photo = [Photo newPhotoWithUrl:@"" forPlace: place MOC: self.context];
        [Photo savePhotoAndItsThumbnail: photo
                           fromLocation: filePath
                              imageName: fileName];
    }
    
    [place removePhotos:[NSSet setWithArray:deletedPlacePhotos]];
    for(Photo *photo in deletedPlacePhotos){
        [fileManager removeItemAtPath: photo.filePath error:nil];
        [fileManager removeItemAtPath: photo.thumbnail_filePath error:nil];
        [self.context deleteObject:photo];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if( [self.context hasChanges] && ![self.context save:nil])
            NSLog(@"has changes but cant save");
    });
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)btnRemovePhotosClicked:(id)sender {
    [self removeSelectedPhotos];
}

- (void) removeSelectedPhotos {
    NSArray *indexPaths = self.photosCollectionView.indexPathsForSelectedItems;
    NSMutableArray *addedPhotosToRemove = [NSMutableArray array];
    NSMutableArray *placePhotosToRemove = [NSMutableArray array];
    for ( NSIndexPath *indexPath in indexPaths) {
            if(indexPath.row > placePhotos.count -1) {
                [addedPhotosToRemove addObject:[addedPhotos objectAtIndex: indexPath.row - placePhotos.count]];
            }
            else {
                [placePhotosToRemove addObject:[placePhotos objectAtIndex:indexPath.row]];
            }
    }
    [placePhotos removeObjectsInArray:placePhotosToRemove];
    [addedPhotos removeObjectsInArray:addedPhotosToRemove];
    if(placePhotosToRemove.count >0){
        //[self.place removePhotos:[NSSet setWithArray:placePhotosToRemove]];
        [deletedPlacePhotos addObjectsFromArray:placePhotosToRemove];
    }
    [self setCollectionViewEditMode:NO];
    [self.photosCollectionView deleteItemsAtIndexPaths:indexPaths];
}

- (void) setCollectionViewEditMode:(Boolean) editable {
    if( collectionViewEditMode == editable )
        return;
    collectionViewEditMode = editable;
    if(collectionViewEditMode == YES) {
        [self.viewBarButtonsRemoveAndCancel setHidden:NO];
    }
    else {
        NSArray *indexPaths = self.photosCollectionView.indexPathsForSelectedItems;
        for(NSIndexPath *indexPath in indexPaths){
            [self.photosCollectionView deselectItemAtIndexPath:indexPath animated:NO];
        }
        [self.viewBarButtonsRemoveAndCancel setHidden:YES];
    }
}

- (IBAction)btnCancelEditModeClicked:(id)sender {
    [self setCollectionViewEditMode:NO];
}


- (void)viewDidAppear:(BOOL)animated {
    [self.navigationController setToolbarHidden:NO animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.navigationController setToolbarHidden:YES animated:YES];
}

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

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.viewBarButtonsRemoveAndCancel setHidden:YES];
    // Do any additional setup after loading the view.
    addedPhotos = [NSMutableArray array];
    deletedPlacePhotos = [NSMutableArray array];
    if( self.place ){
        self.textFieldCityName.text = [self.place.city copy];
        self.textFieldLatitude.text = [self.place.latitude stringValue];
        self.textFieldLongtitude.text = [self.place.longtitude stringValue];
        self.textFieldName.text = [self.place.name copy];
        placePhotos = [self.place.photos.allObjects mutableCopy];
    }
    else {
        placePhotos = [NSMutableArray array];
    }
    UILongPressGestureRecognizer *recognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleCollectionViewLongPress:)];
    recognizer.minimumPressDuration = 1;
    [self.photosCollectionView addGestureRecognizer: recognizer];
    self.photosCollectionView.allowsMultipleSelection = YES;
    collectionViewEditMode = NO;
}

-  (void)handleCollectionViewLongPress:(UILongPressGestureRecognizer*)sender {
    if (sender.state != UIGestureRecognizerStateEnded || (placePhotos.count + addedPhotos.count)==0 ) {
        return;
    }
    
    [self setCollectionViewEditMode:YES];
    
    CGPoint p = [sender locationInView:self.photosCollectionView];
    NSIndexPath *indexPath = [self.photosCollectionView indexPathForItemAtPoint:p];
    if (indexPath == nil){
        NSLog(@"couldn't find index path");
    } else {
        if(indexPath.row != (placePhotos.count + addedPhotos.count))
            [self.photosCollectionView selectItemAtIndexPath: indexPath
                                                    animated: YES
                                              scrollPosition: UICollectionViewScrollPositionNone];
    }
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self.photosCollectionView.collectionViewLayout invalidateLayout];
}


- (IBAction)btnGetLocationByGeocodingClicked:(id)sender {
    GetLocationByGeocoding *view = [self.storyboard instantiateViewControllerWithIdentifier:@"Geocoding"];
    view.delegate = self;
    localPopover = [[UIPopoverController alloc] initWithContentViewController: view];
    [localPopover presentPopoverFromRect: self.cellLatitudeLongitude.bounds
                                  inView: self.cellLatitudeLongitude
                permittedArrowDirections: UIPopoverArrowDirectionDown | UIPopoverArrowDirectionUp
                                animated: YES];
}
- (IBAction)btnGetLocationByDroppingMapPinClicked:(id)sender {
    
    GetLocationByMapPinView *view = [self.storyboard instantiateViewControllerWithIdentifier:@"MapView"];
    view.delegate = self;
    localPopover = [[UIPopoverController alloc] initWithContentViewController:view];
    [localPopover presentPopoverFromRect: self.cellLatitudeLongitude.bounds
                                  inView: self.cellLatitudeLongitude.contentView
                permittedArrowDirections: UIPopoverArrowDirectionDown | UIPopoverArrowDirectionUp
                                animated:YES ];
}

- (IBAction)btnBackPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark UITableViewDataSource

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0;
}

#pragma mark GetLocationByMapPinViewDelegate
- (void)GetLoactionByMapPinView:(GetLocationByMapPinView *)view didChangePinLatitude:(double)latitude longitude:(double)longitude {
    self.textFieldLatitude.text = [[NSNumber numberWithDouble: latitude] stringValue];
    self.textFieldLongtitude.text = [[NSNumber numberWithDouble: longitude] stringValue];
}

#pragma mark GetLocationByGeocodingDelegate

- (void)GetLocationByGeocoding:(GetLocationByGeocoding *)view didChangeLatitude:(double)latitude longitude:(double)longitude {
    self.textFieldLatitude.text = [[NSNumber numberWithDouble: latitude] stringValue];
    self.textFieldLongtitude.text = [[NSNumber numberWithDouble: longitude] stringValue];
}

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
    // if current cell is "add" cell
    UICollectionViewCell *cell;
    if(indexPath.row == (addedPhotos.count + placePhotos.count)) {
        NSString *identifier = @"add_image";
        cell = [collectionView dequeueReusableCellWithReuseIdentifier: identifier
                                                                               forIndexPath: indexPath];
    }
    else if ((int)indexPath.row > (int)(placePhotos.count -1)) {
        NSString *identifier = @"image";
        cell = [collectionView dequeueReusableCellWithReuseIdentifier: identifier forIndexPath:indexPath];
        UIImageView * imageView = (UIImageView *) [cell viewWithTag:1];
        imageView.image = [addedPhotos objectAtIndex: indexPath.row - placePhotos.count];
    }
    else {
        NSString *identifier = @"image";
        cell = [collectionView dequeueReusableCellWithReuseIdentifier: identifier forIndexPath:indexPath];
        UIImageView * imageView = (UIImageView *) [cell viewWithTag:1];
        Photo *photo = [placePhotos objectAtIndex: indexPath.row];
        imageView.image = [UIImage imageWithContentsOfFile: photo.thumbnail_filePath];
    }
    cell.selectedBackgroundView = [[UIView alloc] init];
    cell.selectedBackgroundView.backgroundColor = [UIColor blueColor];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGSize viewSize = collectionView.frame.size;
    return CGSizeMake( viewSize.height, viewSize.height );
}

/*- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    CGFloat cellWidth = collectionView.frame.size.height;
    NSInteger numberOfCells = photos.count + 1;
    NSInteger edgeInsets = (collectionView.frame.size.width - (cellWidth * numberOfCells))/(numberOfCells + 1);
    if ( edgeInsets < 0 ) {
        edgeInsets = 0;
    }
    return UIEdgeInsetsMake(0, edgeInsets, 0, edgeInsets);
}*/


#pragma mark UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    if( collectionViewEditMode == YES ){
        NSArray *indexPaths = self.photosCollectionView.indexPathsForSelectedItems;
        if( indexPaths.count == 0 )
            [self setCollectionViewEditMode:NO];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionViewEditMode == NO) {
        [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    }
    if ( indexPath.row == addedPhotos.count + placePhotos.count ) {
        if(collectionViewEditMode == NO)
            [self askUserGaleryOrCamera];
        else {
            [collectionView deselectItemAtIndexPath:indexPath animated:NO];
        }
    }
}

- (void) askUserGaleryOrCamera {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" message:@"Do You want get photo from Galary or create photo by Camera?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"from Galary", @"by Camera", nil];
    alertView.tag = 1;
    [alertView show];
}

- (void) askUserAboutSavingBeforeQuit {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" message:@"Do you really want quit without saving?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"YES", nil];
    alertView.tag = 2;
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if(alertView.tag == 1){
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
    else if( alertView.tag == 2 ) {
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

- (void) getPhotoFromGalery {
    if( [UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypePhotoLibrary] ){
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        
        picker.allowsEditing = NO;
        picker.delegate = self;
        
        [self presentViewController: picker animated: YES completion:nil];
    }
}

- (void) getPhotoFromCamera {
    if( [UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera] ){
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        
        picker.allowsEditing = NO;
        picker.delegate = self;
        
        [self presentViewController: picker animated: YES completion:nil];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
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
    [addedPhotos addObject: imageToUse];
    [self.photosCollectionView insertItemsAtIndexPaths:
     [NSArray arrayWithObject:
      [NSIndexPath indexPathForRow:
       (placePhotos.count + addedPhotos.count - 1) inSection: 0]]];
    
    
    [self dismissViewControllerAnimated: YES completion: nil];
}

@end
