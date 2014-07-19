//
//  Photo+PhotoCategory.m
//  VeryInterestingTestTask
//
//  Created by Valeriy Buev on 19.07.14.
//  Copyright (c) 2014 bva. All rights reserved.
//

#import "Photo+PhotoCategory.h"

@implementation Photo (PhotoCategory)

// Creates new Photo object with url_str and place relationShip for "place"
+ (Photo *) newPhotoWithUrl:(NSString *) url_str forPlace:(Place *) place MOC:(NSManagedObjectContext *) context{
    
    Photo *photo;
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Photo" inManagedObjectContext:context];
    photo = [[Photo alloc] initWithEntity:entity insertIntoManagedObjectContext:context];
    photo.url = [url_str copy];
    photo.place = place;
    
    return photo;
}

@end
