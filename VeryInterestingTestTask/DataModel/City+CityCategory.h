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

@end
