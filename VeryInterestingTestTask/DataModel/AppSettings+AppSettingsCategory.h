//
//  AppSettings+AppSettingsCategory.h
//  VeryInterestingTestTask
//
//  Created by Valeriy Buev on 19.07.14.
//  Copyright (c) 2014 bva. All rights reserved.
//

#import "AppSettings.h"

@interface AppSettings (AppSettingsCategory)

// Дает доступ к единственному объекту AppSettings в данном контексте
+ (AppSettings *) getInstance:(NSManagedObjectContext *) context;

// сохраняет контекст и выводит ошибку при надобности
+ (void) saveManagedObjectContext: (NSManagedObjectContext *) context;

@end
