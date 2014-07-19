//
//  Place+PlaceCategory.m
//  VeryInterestingTestTask
//
//  Created by Valeriy Buev on 19.07.14.
//  Copyright (c) 2014 bva. All rights reserved.
//

#import "Place+PlaceCategory.h"

@implementation Place (PlaceCategory)

// Creates new Place object with attributes
+ (Place *) newPlaceWithName:(NSString *) name description:(NSString *) description latitude:(NSNumber *) latitude longtitude:(NSNumber *) longtitude MOC:(NSManagedObjectContext *) context{
    
    Place *place;
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Place" inManagedObjectContext:context];
    place = [[Place alloc] initWithEntity:entity insertIntoManagedObjectContext:context];
    place.name = [name copy];
    if(description)
        place.placeDescription = [description copy];
    else
        place.placeDescription = @"";
    place.latitude = [latitude copy];
    place.longtitude = [longtitude copy];
    
    return place;
}

@end
