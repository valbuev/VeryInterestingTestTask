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
// indicator of process
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicator;

@property (retain, nonatomic) CLGeocoder *geocoder;

@end

@implementation GetLocationByGeocoding
@synthesize delegate;

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

// User entered address
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    // init geocoder
    if ( self.geocoder == nil ) {
        self.geocoder = [[CLGeocoder alloc] init];
    }
    NSString *address = self.textFieldAddress.text;
    
    // start animating process
    [self.indicator startAnimating];
    
    // start geocoding
    [self.geocoder geocodeAddressString: address
                      completionHandler: ^(NSArray *placemarks, NSError *error){
                          
                          // stop animating process
                          [self.indicator stopAnimating];
                          
                          // success
                          if(placemarks.count > 0 && error == nil) {
                              CLPlacemark *placemark = [placemarks firstObject];
                              if( self.delegate != nil ) {
                                  CLLocationCoordinate2D coordinate = placemark.location.coordinate;
                                  // notificate delegate
                                  [self.delegate GetLocationByGeocoding:self
                                                      didChangeLatitude:coordinate.latitude
                                                              longitude:coordinate.longitude];
                              }
                          }
                          // error
                          else {
                              if ( self.delegate != nil ) {
                                  // notificate delegate
                                  [self.delegate GetLocationByGeocoding: self didFinishGeocodingWithError: error];
                              }
                              // Say user about error
                              UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Can't find this address.." delegate:nil cancelButtonTitle:@":(" otherButtonTitles: nil];
                              [alertView show];
                          }
    }];
    return YES;
}

@end
