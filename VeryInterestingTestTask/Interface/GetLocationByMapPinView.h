//
//  GetLocationByMapPinView.h
//  VeryInterestingTestTask
//
//  Created by Valeriy Buev on 05.08.14.
//  Copyright (c) 2014 bva. All rights reserved.
//

//
//  This view is used for dropping map pin
//

#import <UIKit/UIKit.h>

@class GetLocationByMapPinView;

//
@protocol GetLoactionByMapPinViewDelegate
// User changed latitude & longitude
- (void) GetLoactionByMapPinView: (GetLocationByMapPinView *) view didChangePinLatitude:(double) latitude longitude: (double) longitude;
@end

@interface GetLocationByMapPinView : UIViewController

// delegate
@property (nonatomic, weak) id <GetLoactionByMapPinViewDelegate> delegate;

@end
