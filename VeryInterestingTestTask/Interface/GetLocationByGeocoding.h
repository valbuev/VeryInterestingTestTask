//
//  GetLocationByGeocoding.h
//  VeryInterestingTestTask
//
//  Created by Valeriy Buev on 07.08.14.
//  Copyright (c) 2014 bva. All rights reserved.
//

//
//  This view is used for geocoding
//

#import <UIKit/UIKit.h>

@class GetLocationByGeocoding;

@protocol GetLocationByGeocodingDelegate

// geolocation completed successfully
- (void) GetLocationByGeocoding:(GetLocationByGeocoding *) view didChangeLatitude:(double) latitude longitude:(double) longitude;

// completed with error
- (void) GetLocationByGeocoding:(GetLocationByGeocoding *) view didFinishGeocodingWithError: (NSError *) error;

@end

@interface GetLocationByGeocoding : UIViewController

// delegate
@property (nonatomic, weak) id <GetLocationByGeocodingDelegate> delegate;

@end
