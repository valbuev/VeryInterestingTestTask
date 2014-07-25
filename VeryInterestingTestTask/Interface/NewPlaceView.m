//
//  NewPlaceView.m
//  VeryInterestingTestTask
//
//  Created by Valeriy Buev on 25.07.14.
//  Copyright (c) 2014 bva. All rights reserved.
//

#import "NewPlaceView.h"
#import "AppDelegate.h"

#import "City+CityCategory.h"
#import "Place+PlaceCategory.h"

@interface NewPlaceView ()

@property (nonatomic,retain) NSManagedObjectContext *context;

@property (weak, nonatomic) IBOutlet UITextField *textFieldName;
@property (weak, nonatomic) IBOutlet UITextField *textFieldLatitude;
@property (weak, nonatomic) IBOutlet UITextField *textFieldLongtitude;
@property (weak, nonatomic) IBOutlet UITextField *textFieldCityName;

@end

@implementation NewPlaceView

@synthesize context = _context;
@synthesize textFieldCityName;
@synthesize textFieldLongtitude;
@synthesize textFieldLatitude;
@synthesize textFieldName;


- (IBAction)btnOKClicked:(id)sender {
    
    //dispatch_async(dispatch_get_main_queue(), ^{
        NSString *cityName = self.textFieldCityName.text;
        City *city;
        if ( ![cityName isEqualToString:@""] ){
            city = [City findCityByNameOrCreate: cityName MOC: self.context];
        } else {
            city = nil;
            NSLog(@"city = nil");
        }
        
        NSString *placeName = self.textFieldName.text;
        NSNumber *latitude = [NSNumber numberWithDouble: self.textFieldLatitude.text.doubleValue];
        NSNumber *longitude = [NSNumber numberWithDouble: self.textFieldLongtitude.text.doubleValue];
        
        Place *place  = [Place newPlaceWithName: placeName
                                   description: @""
                                      latitude: latitude
                                    longtitude: longitude
                                           MOC: self.context];
        place.city = city;
    
    if( [self.context hasChanges] && ![self.context save:nil])
        NSLog(@"has changes");
    //});
    [self.navigationController popViewControllerAnimated:NO];
}

- (NSManagedObjectContext *)context{
    if( _context )
        return _context;
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSPersistentStoreCoordinator *coordinator = [appDelegate persistentStoreCoordinator];
    _context = [[NSManagedObjectContext alloc] init];
    [_context setPersistentStoreCoordinator:coordinator];
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

@end
