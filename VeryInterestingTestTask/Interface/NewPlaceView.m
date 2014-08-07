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

@interface NewPlaceView ()
<GetLoactionByMapPinViewDelegate>{
    UIPopoverController *localPopover;
}

@property (nonatomic,retain) NSManagedObjectContext *context;

@property (weak, nonatomic) IBOutlet UITextField *textFieldName;
@property (weak, nonatomic) IBOutlet UITextField *textFieldLatitude;
@property (weak, nonatomic) IBOutlet UITextField *textFieldLongtitude;
@property (weak, nonatomic) IBOutlet UITextField *textFieldCityName;
@property (weak, nonatomic) IBOutlet UITableViewCell *cellLatitudeLongitude;

@end

@implementation NewPlaceView

@synthesize context = _context;
@synthesize textFieldCityName;
@synthesize textFieldLongtitude;
@synthesize textFieldLatitude;
@synthesize textFieldName;


- (IBAction)btnOKClicked:(id)sender {
    
    NSString *placeName = self.textFieldName.text;
    NSNumber *latitude = [NSNumber numberWithDouble: self.textFieldLatitude.text.doubleValue];
    NSNumber *longitude = [NSNumber numberWithDouble: self.textFieldLongtitude.text.doubleValue];
    NSString *cityName = self.textFieldCityName.text;
    
    [Place newPlaceWithName: placeName
                       city: cityName
                description: @""
                   latitude: latitude
                 longtitude: longitude
                        MOC: self.context];
    
    NSLog(@"before context saving");
    if( [self.context hasChanges] && ![self.context save:nil])
        NSLog(@"has changes but cant save");
    //});
    NSLog(@"before popviewControllerAnimated");
    [self.navigationController popViewControllerAnimated:YES];
}

- (NSManagedObjectContext *)context{
    if( _context )
        return _context;
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSPersistentStoreCoordinator *coordinator = [appDelegate persistentStoreCoordinator];
    _context = [[NSManagedObjectContext alloc] init];
    [_context setPersistentStoreCoordinator:coordinator];
    //_context = [appDelegate managedObjectContext];
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
    // Do any additional setup after loading the view.
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
- (IBAction)btnGetLocationByGeocodingClicked:(id)sender {
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

#pragma mark GetLoactionByMapPinViewDelegate
- (void)GetLoactionByMapPinView:(GetLocationByMapPinView *)view didChangePinLatitude:(double)latitude longitude:(double)longitude {
    self.textFieldLatitude.text = [[NSNumber numberWithDouble: latitude] stringValue];
    self.textFieldLongtitude.text = [[NSNumber numberWithDouble: longitude] stringValue];
}

@end
