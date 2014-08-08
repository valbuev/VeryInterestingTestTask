//
//  PlaceTableViewCell.h
//  VeryInterestingTestTask
//
//  Created by Valeriy Buev on 19.07.14.
//  Copyright (c) 2014 bva. All rights reserved.
//



//
//  This class is used for cells of UITableView with Place-objects
//

#import <UIKit/UIKit.h>

// classes from CoreData-Model
@class Place, Photo;

@interface PlaceTableViewCell : UITableViewCell

// ImageView, that will contain Place's photo
@property (weak, nonatomic) IBOutlet UIImageView *imageViewPhoto;
// Place's name
@property (weak, nonatomic) IBOutlet UILabel *labelName;
// Main Place's photo
@property (nonatomic, retain) Photo *photo;

@end
