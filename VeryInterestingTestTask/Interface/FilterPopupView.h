//
//  FilterPopupView.h
//  VeryInterestingTestTask
//
//  Created by Valeriy Buev on 22.07.14.
//  Copyright (c) 2014 bva. All rights reserved.
//

#import <UIKit/UIKit.h>

enum LocationFilterRadius {
    LocationFilterRadiusNone,
    LocationFilterRadiusOneMile,
    LocationFilterRadiusTenMiles,
    LocationFilterRadiusOneHundredMiles
};
typedef enum LocationFilterRadius LocationFilterRadius;


@protocol FilterPopupViewDelegate

- (void) setLocationFilterRadius:(LocationFilterRadius) locationFilterRadius;

@end

@interface FilterPopupView : UITableViewController

@property (nonatomic, retain) id <FilterPopupViewDelegate> delegate;
@property (nonatomic) LocationFilterRadius locationFilterRadius;

@end
