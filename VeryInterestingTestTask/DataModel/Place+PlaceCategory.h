//
//  Place+PlaceCategory.h
//  VeryInterestingTestTask
//
//  Created by Valeriy Buev on 19.07.14.
//  Copyright (c) 2014 bva. All rights reserved.
//

#import "Place.h"

@interface Place (PlaceCategory)

// Creates new Place object with attributes
+ (Place *) newPlaceWithName:(NSString *) name description:(NSString *) description latitude:(NSNumber *) latitude longtitude:(NSNumber *) longtitude MOC:(NSManagedObjectContext *) context;

// Creates and returns new NSFetchedResultsController with Places grouped by city.name
+ (NSFetchedResultsController *) newFetchedResultsControllerForMOC:(NSManagedObjectContext *) context;

// Creates and returns new NSPredicate for Places grouped by City.name and filter by location with center at centerLat, centerLon and ellipce-koefficients: kLat, kLon.
//  (lat - centerLat)^2 / kLat^2 + (lon - centerLon)^2 / klon^2  <= 1
+ (NSPredicate *) newPredicateWithMOC: (NSManagedObjectContext *) context centerLatitude:(double) centerLat centerLongitude:(double) centerLon kLatitude:(double) kLat kLongitude:(double) klon;

@end
