//
//  CityTableViewCell.h
//  VeryInterestingTestTask
//
//  Created by Valeriy Buev on 19.07.14.
//  Copyright (c) 2014 bva. All rights reserved.
//

#import <UIKit/UIKit.h>

@class City, CityTableViewCell;

@protocol CityTableViewCellDelegate

- (void) didTouchCityTableViewCell: (CityTableViewCell *) cityTableViewCell;

@end

@interface CityTableViewCell : UITableViewCell


@property (weak, nonatomic) IBOutlet UILabel *labelName;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewIndicator;

@property (nonatomic, retain) City *city;

@property (nonatomic, weak) id <CityTableViewCellDelegate> delegate;

- (IBAction)userClickedOnCell:(id)sender;

@end
