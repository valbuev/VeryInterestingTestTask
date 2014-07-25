//
//  City+CityCategory.h
//  VeryInterestingTestTask
//
//  Created by Valeriy Buev on 19.07.14.
//  Copyright (c) 2014 bva. All rights reserved.
//

#import "City.h"

@interface City (CityCategory)

// Creates new object of City class with nested name
+ (City *) newCityWithName:(NSString *) name MOC:(NSManagedObjectContext *) context;

// Searches city with givven name. If cant find, creates new city and returns it;
+ (City *) findCityByNameOrCreate: (NSString *) name MOC: (NSManagedObjectContext *) context;

@end
