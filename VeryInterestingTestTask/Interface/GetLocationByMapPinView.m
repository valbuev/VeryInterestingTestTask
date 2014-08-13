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
@synthesize delegate;



- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Catching taps on mapView
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(foundTap:)];
    recognizer.numberOfTapsRequired = 1;
    recognizer.numberOfTouchesRequired = 1;
    [self.mapView addGestureRecognizer: recognizer];
}

// User tapped on mapView
-(IBAction)foundTap:(UITapGestureRecognizer *)recognizer {
    
    CGPoint point = [recognizer locationInView:self.mapView];
    // Calculating coordinates by tap-point
    CLLocationCoordinate2D tapPoint = [self.mapView convertPoint:point toCoordinateFromView:self.mapView];
    
    // Creating MKPointAnnotation
    MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
    annotation.coordinate = tapPoint;
    
    // remove all other annotations from mapview
    [self.mapView removeAnnotations: self.mapView.annotations];
    // add created annotation
    [self.mapView addAnnotation: annotation];
    
    // notificate delegate
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

// Cant find users location
- (void)mapView:(MKMapView *)mapView didFailToLocateUserWithError:(NSError *)error {
    NSLog(@"didFailToLocateUserWithError: %@",error.localizedDescription);
}


- (void) mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    NSLog(@"didSelectAnnotationView");
}

@end
