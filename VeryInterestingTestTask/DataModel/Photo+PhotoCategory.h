//
//  Photo+PhotoCategory.h
//  VeryInterestingTestTask
//
//  Created by Valeriy Buev on 19.07.14.
//  Copyright (c) 2014 bva. All rights reserved.
//

#import "Photo.h"

@interface Photo (PhotoCategory)

// Creates new Photo object with url_str and place relationShip for "place"
+ (Photo *) newPhotoWithUrl:(NSString *) url_str forPlace:(Place *) place MOC:(NSManagedObjectContext *) context;

@end
