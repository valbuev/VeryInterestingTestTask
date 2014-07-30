//
//  Place+PlaceCategory.m
//  VeryInterestingTestTask
//
//  Created by Valeriy Buev on 19.07.14.
//  Copyright (c) 2014 bva. All rights reserved.
//

#import "Place+PlaceCategory.h"
#import <MapKit/MapKit.h>

@implementation Place (PlaceCategory)

static NSString *entityName = @"Place";

// Creates new Place object with attributes
+ (Place *) newPlaceWithName:(NSString *) name description:(NSString *) description latitude:(NSNumber *) latitude longtitude:(NSNumber *) longtitude MOC:(NSManagedObjectContext *) context{
    
    Place *place;
    NSEntityDescription *entity = [NSEntityDescription entityForName: entityName
                                              inManagedObjectContext: context];
    place = [[Place alloc] initWithEntity:entity
           insertIntoManagedObjectContext:context];
    place.name = [name copy];
    if(description)
        place.placeDescription = [description copy];
    else
        place.placeDescription = @"";
    place.latitude = [latitude copy];
    place.longtitude = [longtitude copy];
    
    return place;
}

// Creates and returns new NSFetchedResultsController with Places grouped by city.name
+ (NSFetchedResultsController *) newFetchedResultsControllerForMOC:(NSManagedObjectContext *) context{
    
    NSFetchedResultsController *controller;
    NSEntityDescription *entity = [NSEntityDescription entityForName: entityName
                                              inManagedObjectContext: context];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entity];
    
//    NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@" { {{ latitude - %@ } *  { latitude - %@ } }  / {%@ * %@} } +  { { { longtitude - -70 } * { longtitude - -70 } } * 4 }  < 225 ",
//                               [NSNumber numberWithDouble:10],[NSNumber numberWithDouble:10],[NSNumber numberWithDouble:0.5],[NSNumber numberWithDouble:0.5]];
    //[request setPredicate:predicate2];
    
    NSSortDescriptor *sort1 = [NSSortDescriptor sortDescriptorWithKey:@"city.name" ascending:YES];
    NSSortDescriptor *sort2 = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    
    [request setSortDescriptors:[NSArray arrayWithObjects:sort1,sort2, nil]];
    
    controller = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                     managedObjectContext:context
                                                       sectionNameKeyPath:@"city.name"
                                                                cacheName:nil];
    
    return controller;
}

// Creates and returns new NSFetchRequest with Places grouped by City.name and filter by location with center at centerLat, centerLon and ellipce-koefficients: kLat, kLon.
//  (lat - centerLat)^2 / kLat^2 + (lon - centerLon)^2 / klon^2  <= 1
+ (NSFetchRequest *) newFetchRequestWithMOC: (NSManagedObjectContext *) context centerLatitude:(double) centerLat centerLongitude:(double) centerLon kLatitude:(double) kLat kLongitude:(double) klon {
    
    // request
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName: entityName
                                              inManagedObjectContext: context];
    [request setEntity:entity];
    
    // predicate
    NSPredicate *predicate = [NSPredicate predicateWithFormat:
                              @" { {{ latitude - %f } *  { latitude - %f } }  / { %f * %f } } +  { { { longtitude - %f } * { longtitude - %f } } / { %f * %f } }  <= 1 ", centerLat, centerLat, kLat, kLat, centerLon, centerLon, klon, klon ];
    [request setPredicate:predicate];
    
    // sort descriptors
    NSSortDescriptor *sort1 = [NSSortDescriptor sortDescriptorWithKey:@"city.name" ascending:YES];
    NSSortDescriptor *sort2 = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    [request setSortDescriptors:[NSArray arrayWithObjects:sort1,sort2, nil]];
    
    return request;
}

// Creates and returns new NSPredicate for Places grouped by City.name and filter by location with center at centerLat, centerLon and ellipce-koefficients: kLat, kLon.
//  (lat - centerLat)^2 / kLat^2 + (lon - centerLon)^2 / klon^2  <= 1
+ (NSPredicate *) newPredicateWithMOC: (NSManagedObjectContext *) context centerLatitude:(double) centerLat centerLongitude:(double) centerLon kLatitude:(double) kLat kLongitude:(double) klon {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:
                              @" { {{ latitude - %f } *  { latitude - %f } }  / { %f * %f } } +  { { { longtitude - %f } * { longtitude - %f } } / { %f * %f } }  <= 1 ", centerLat, centerLat, kLat, kLat, centerLon, centerLon, klon, klon ];
    return predicate;
}

@end
