//
//  City+CityCategory.m
//  VeryInterestingTestTask
//
//  Created by Valeriy Buev on 19.07.14.
//  Copyright (c) 2014 bva. All rights reserved.
//

#import "City+CityCategory.h"

@implementation City (CityCategory)

// Creates new object of City class with nested name
+ (City *) newCityWithName:(NSString *) name MOC:(NSManagedObjectContext *) context{
    
    City *city;
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"City" inManagedObjectContext:context];
    city = [[City alloc] initWithEntity:entity insertIntoManagedObjectContext:context];
    city.name = [name copy];
    
    return city;
}

@end
