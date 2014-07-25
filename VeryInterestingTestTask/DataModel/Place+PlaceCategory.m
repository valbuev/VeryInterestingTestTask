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

// Creates and returns new NSFetchedResultsController with Places grouped by city.name
+ (NSFetchedResultsController *) newFetchedResultsControllerForMOC:(NSManagedObjectContext *) context{
    
    NSFetchedResultsController *controller;
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Place" inManagedObjectContext:context];
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

@end
