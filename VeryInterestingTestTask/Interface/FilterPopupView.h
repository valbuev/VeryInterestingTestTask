//
//  FilterPopupView.h
//  VeryInterestingTestTask
//
//  Created by Valeriy Buev on 22.07.14.
//  Copyright (c) 2014 bva. All rights reserved.
//


//
//  uses for implementing ViewController, which provide user to choose location filter radius
//

#import <UIKit/UIKit.h>

// enum-type of location filter radiuses
enum LocationFilterRadius {
    LocationFilterRadiusNone,
    LocationFilterRadiusOneMile,
    LocationFilterRadiusTenMiles,
    LocationFilterRadiusOneHundredMiles
};
typedef enum LocationFilterRadius LocationFilterRadius;


@protocol FilterPopupViewDelegate

// notificate delegate about location filter radius has been changed
- (void) setLocationFilterRadius:(LocationFilterRadius) locationFilterRadius;

@end

@interface FilterPopupView : UITableViewController

// delegate
@property (nonatomic, retain) id <FilterPopupViewDelegate> delegate;
// uses for initializing location filter radius
@property (nonatomic) LocationFilterRadius locationFilterRadius;

@end
