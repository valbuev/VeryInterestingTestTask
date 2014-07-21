//
//  PlaceTableViewCell.h
//  VeryInterestingTestTask
//
//  Created by Valeriy Buev on 19.07.14.
//  Copyright (c) 2014 bva. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Place, Photo;

@interface PlaceTableViewCell : UITableViewCell


@property (weak, nonatomic) IBOutlet UIImageView *imageViewPhoto;
@property (weak, nonatomic) IBOutlet UILabel *labelName;
@property (nonatomic, retain) Photo *photo;

@end
