//
//  GetLocationByMapPinView.h
//  VeryInterestingTestTask
//
//  Created by Valeriy Buev on 05.08.14.
//  Copyright (c) 2014 bva. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GetLocationByMapPinView;

@protocol GetLoactionByMapPinViewDelegate

- (void) GetLoactionByMapPinView: (GetLocationByMapPinView *) view didChangePinLatitude:(double) latitude longitude: (double) longitude;

@end

@interface GetLocationByMapPinView : UIViewController

@property (nonatomic, weak) id <GetLoactionByMapPinViewDelegate> delegate;

@end
