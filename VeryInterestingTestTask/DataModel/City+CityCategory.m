//
//  City+CityCategory.m
//  VeryInterestingTestTask
//
//  Created by Valeriy Buev on 19.07.14.
//  Copyright (c) 2014 bva. All rights reserved.
//

#import "City+CityCategory.h"

@implementation City (CityCategory)

static NSString *entityName = @"City";

// Creates new object of City class with nested name
+ (City *) newCityWithName:(NSString *) name MOC:(NSManagedObjectContext *) context{
    
    City *city;
    NSEntityDescription *entity = [NSEntityDescription entityForName: entityName inManagedObjectContext:context];
    city = [[City alloc] initWithEntity:entity insertIntoManagedObjectContext:context];
    city.name = [name copy];
    
    return city;
}

// Searches city with givven name. If cant find, creates new city and returns it;
+ (City *) findCityByNameOrCreate: (NSString *) name MOC: (NSManagedObjectContext *) context{
    
    City *city;
    NSEntityDescription *entity = [NSEntityDescription entityForName: entityName inManagedObjectContext:context];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entity];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name like %@", name];
    [request setPredicate:predicate];
    
    NSError *error;
    NSArray *searchResults = [context executeFetchRequest:request error:&error];
    
    if( !error ) {
        if( searchResults.count > 0 ){
            NSLog(@"city - search results count: %d",searchResults.count);
            city = [searchResults objectAtIndex:0];
        }
        else {
            city = [City newCityWithName:name MOC:context];
        }
    }
    else {
        NSLog(@" Unresolved error while getting city");
        city = nil;
    }
    
    return city;
}

@end
