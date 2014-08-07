//
//  GetLocationByGeocoding.m
//  VeryInterestingTestTask
//
//  Created by Valeriy Buev on 07.08.14.
//  Copyright (c) 2014 bva. All rights reserved.
//

#import "GetLocationByGeocoding.h"
#import <CoreLocation/CoreLocation.h>

@interface GetLocationByGeocoding ()
<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *textFieldAddress;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicator;

@property (retain, nonatomic) CLGeocoder *geocoder;

@end

@implementation GetLocationByGeocoding
@synthesize delegate;

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

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if ( self.geocoder == nil ) {
        self.geocoder = [[CLGeocoder alloc] init];
    }
    NSString *address = self.textFieldAddress.text;
    
    [self.indicator startAnimating];
    
    [self.geocoder geocodeAddressString: address
                      completionHandler: ^(NSArray *placemarks, NSError *error){
                          
                          [self.indicator stopAnimating];
                          
                          if(placemarks.count > 0 && error == nil) {
                              CLPlacemark *placemark = [placemarks firstObject];
                              if( self.delegate != nil ) {
                                  CLLocationCoordinate2D coordinate = placemark.location.coordinate;
                                  [self.delegate GetLocationByGeocoding:self
                                                      didChangeLatitude:coordinate.latitude
                                                              longitude:coordinate.longitude];
                              }
                          }
                          else {
                              if ( self.delegate != nil ) {
                                  [self.delegate GetLocationByGeocoding: self didFinishGeocodingWithError: error];
                              }
                              UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Can't find this address.." delegate:nil cancelButtonTitle:@":(" otherButtonTitles: nil];
                              [alertView show];
                              NSLog(@"\nerror: %@ \nplacemarks.count = %d",error.localizedDescription, placemarks.count );
                          }
    }];
    return YES;
}

@end
