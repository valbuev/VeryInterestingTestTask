//
//  AppSettings+AppSettingsCategory.m
//  VeryInterestingTestTask
//
//  Created by Valeriy Buev on 19.07.14.
//  Copyright (c) 2014 bva. All rights reserved.
//

#define ENTITY_NAME @"AppSettings"

#import "AppSettings+AppSettingsCategory.h"

@interface AppSettings (){
}

@end

@implementation AppSettings (AppSettingsCategory)

// сохраняет контекст и выводит ошибку при надобности
+ (void) saveManagedObjectContext: (NSManagedObjectContext *) context{
    NSError *error;
    [context save:&error];
    if(error){
        NSLog(@"Unresolved error while saving managedObjectContext: %@",error.localizedDescription);
        abort();
    }
}

// Дает доступ к единственному объекту AppSettings в данном контексте
+ (AppSettings *) getInstance:(NSManagedObjectContext *) context{
    AppSettings *instance;
    
    // можно было сделать статическую переменную и использовать dispatch_once, но тогда нужно либо хранить еще и context, либо не использовать другой.
    NSEntityDescription *entity = [NSEntityDescription entityForName:ENTITY_NAME inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entity];
    
    NSError *error;
    NSArray *array = [context executeFetchRequest:request error:&error];
    if(array) {
        if( array.count > 0 ){
            instance = (AppSettings *) [array objectAtIndex:0];
        }
        else {
            instance = [[AppSettings alloc] initWithEntity:entity insertIntoManagedObjectContext:context];
            [AppSettings saveManagedObjectContext:context];
        }
    }
    else {
        NSLog(@"Unresolved error while getting AppSettings: %@",error.localizedDescription);
        abort();
    }
    
    return instance;
}

@end
