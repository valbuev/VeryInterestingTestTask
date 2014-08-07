//
//  GetLocationByMapPinView.m
//  VeryInterestingTestTask
//
//  Created by Valeriy Buev on 05.08.14.
//  Copyright (c) 2014 bva. All rights reserved.
//

#import "GetLocationByMapPinView.h"
#import <MapKit/MapKit.h>

@interface GetLocationByMapPinView ()
<MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@end

@implementation GetLocationByMapPinView

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
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(foundTap:)];
    recognizer.numberOfTapsRequired = 1;
    recognizer.numberOfTouchesRequired = 1;
    [self.mapView addGestureRecognizer: recognizer];
    //NSLog(@" *** \n ****** location %@", [self.mapView userLocation]);
    //MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
    //point.coordinate = self.mapView.userLocation.coordinate;
    //[self.mapView addAnnotation:point];
}


-(IBAction)foundTap:(UITapGestureRecognizer *)recognizer {
    CGPoint point = [recognizer locationInView:self.mapView];
    
    CLLocationCoordinate2D tapPoint = [self.mapView convertPoint:point toCoordinateFromView:self.mapView];
    
    MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
    
    annotation.coordinate = tapPoint;
    
    [self.mapView removeAnnotations: self.mapView.annotations];
    
    [self.mapView addAnnotation: annotation];
    
    if (self.delegate) {
        [self.delegate GetLoactionByMapPinView: self
                          didChangePinLatitude: annotation.coordinate.latitude
                                     longitude: annotation.coordinate.longitude];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)mapView:(MKMapView *)mapView didFailToLocateUserWithError:(NSError *)error {
    NSLog(@"didFailToLocateUserWithError: %@",error.localizedDescription);
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    //NSLog(@"didUpdateUserLocation: %@",userLocation);
}


- (void) mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    NSLog(@"didSelectAnnotationView");
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
