//
//  GetLocationByGeocoding.h
//  VeryInterestingTestTask
//
//  Created by Valeriy Buev on 07.08.14.
//  Copyright (c) 2014 bva. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GetLocationByGeocoding;

@protocol GetLocationByGeocodingDelegate

- (void) GetLocationByGeocoding:(GetLocationByGeocoding *) view didChangeLatitude:(double) latitude longitude:(double) longitude;

- (void) GetLocationByGeocoding:(GetLocationByGeocoding *) view didFinishGeocodingWithError: (NSError *) error;

@end

@interface GetLocationByGeocoding : UIViewController

@property (nonatomic, weak) id <GetLocationByGeocodingDelegate> delegate;

@end
