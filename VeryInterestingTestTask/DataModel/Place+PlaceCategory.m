//
//  Place+PlaceCategory.m
//  VeryInterestingTestTask
//
//  Created by Valeriy Buev on 19.07.14.
//  Copyright (c) 2014 bva. All rights reserved.
//

#import "Place+PlaceCategory.h"
#import "Photo+PhotoCategory.h"
#import <MapKit/MapKit.h>

@implementation Place (PlaceCategory)

static NSString *entityName = @"Place";

// Creates new Place object with attributes
+ (Place *) newPlaceWithName:(NSString *) name city:(NSString *) city description:(NSString *) description latitude:(NSNumber *) latitude longtitude:(NSNumber *) longtitude MOC:(NSManagedObjectContext *) context {
    
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
    place.city = [city copy];
    
    return place;
}

// Creates and returns new NSFetchedResultsController with Places grouped by city
+ (NSFetchedResultsController *) newFetchedResultsControllerForMOC:(NSManagedObjectContext *) context{
    
    NSFetchedResultsController *controller;
    NSEntityDescription *entity = [NSEntityDescription entityForName: entityName
                                              inManagedObjectContext: context];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entity];
    
    NSSortDescriptor *sort1 = [NSSortDescriptor sortDescriptorWithKey:@"city" ascending:YES];
    NSSortDescriptor *sort2 = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    
    [request setSortDescriptors:[NSArray arrayWithObjects:sort1,sort2, nil]];
    
    controller = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                     managedObjectContext:context
                                                       sectionNameKeyPath:@"city"
                                                                cacheName:nil];
    
    return controller;
}

/*// Creates and returns new NSFetchRequest with Places grouped by City.name and filter by location with center at centerLat, centerLon and ellipce-koefficients: kLat, kLon.
//  (lat - centerLat)^2 / kLat^2 + (lon - centerLon)^2 / klon^2  <= 1
+ (NSFetchRequest *) newFetchRequestWithMOC: (NSManagedObjectContext *) context centerLatitude:(double) centerLat centerLongitude:(double) centerLon kLatitude:(double) kLat kLongitude:(double) klon {
    
    // request
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName: entityName
                                              inManagedObjectContext: context];
    [request setEntity:entity];
    
    // predicate
    NSPredicate *predicate = [NSPredicate predicateWithFormat:
                              @" { devide: { multiply: { latitude - %f } by:  { latitude - %f } }  by: { %f } } +  { devide: { multiply: { longtitude - %f } by: { longtitude - %f } } by: { %f } }  <= 1 ", centerLat, centerLat, kLat * kLat, centerLon, centerLon, klon * klon ];
    [request setPredicate:predicate];
    
    // sort descriptors
    NSSortDescriptor *sort1 = [NSSortDescriptor sortDescriptorWithKey:@"city.name" ascending:YES];
    NSSortDescriptor *sort2 = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    [request setSortDescriptors:[NSArray arrayWithObjects:sort1,sort2, nil]];
    
    return request;
}*/

// Creates and returns new NSPredicate for Places grouped by city and filter by location with center at centerLat, centerLon and square-radiuses RLat and RLon.
//  ( centerLat - RLat < latitude < centerLat + RLat )  AND   ( centerLon - RLon < latitude < centerLon + RLon )
+ (NSPredicate *) newPredicateWithMOC: (NSManagedObjectContext *) context centerLatitude:(double) centerLat centerLongitude:(double) centerLon RLatitude:(double) RLat RLongitude:(double) RLon {

    
    NSPredicate *latPredicate1 = [NSPredicate
                                  predicateWithFormat:@" (latitude > %f) AND (latitude < %f)",
                                  centerLat - RLat, centerLat + RLat ];
    NSPredicate *latPredicate2 = [NSPredicate
                                  predicateWithFormat:@" latitude > %f ",
                                  180 + centerLat - RLat ];
    NSPredicate *latPredicate3 = [NSPredicate
                                  predicateWithFormat:@" latitude < %f ",
                                  -180 + centerLat + RLat ];
    NSPredicate *latPredicate = [NSCompoundPredicate
                                 orPredicateWithSubpredicates: [NSArray
                                                                arrayWithObjects:
                                                                latPredicate1,
                                                                latPredicate2,
                                                                latPredicate3,
                                                                nil]];
    
    NSPredicate *lonPredicate1 = [NSPredicate
                                  predicateWithFormat:@" (longtitude > %f) AND (longtitude < %f)",
                                  centerLon - RLon, centerLon + RLon ];
    NSPredicate *lonPredicate2 = [NSPredicate
                                  predicateWithFormat:@" longtitude > %f ",
                                  360 + centerLon - RLon ];
    NSPredicate *lonPredicate3 = [NSPredicate
                                  predicateWithFormat:@" longtitude < %f ",
                                  -360 + centerLon + RLon ];
    NSPredicate *lonPredicate = [NSCompoundPredicate
                                 orPredicateWithSubpredicates: [NSArray
                                                                arrayWithObjects:
                                                                lonPredicate1,
                                                                lonPredicate2,
                                                                lonPredicate3,
                                                                nil]];

    
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:
                              [NSArray arrayWithObjects:latPredicate, lonPredicate, nil]];
    
    NSLog(@"predicate: \n%@",predicate);
    
    return predicate;
}

@end
