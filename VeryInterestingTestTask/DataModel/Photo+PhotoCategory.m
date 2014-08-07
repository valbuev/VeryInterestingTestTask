//
//  Photo+PhotoCategory.m
//  VeryInterestingTestTask
//
//  Created by Valeriy Buev on 19.07.14.
//  Copyright (c) 2014 bva. All rights reserved.
//

#import "Photo+PhotoCategory.h"

@implementation Photo (PhotoCategory)

// Creates new Photo object with url_str and place relationShip for "place"
+ (Photo *) newPhotoWithUrl:(NSString *) url_str forPlace:(Place *) place MOC:(NSManagedObjectContext *) context{
    
    Photo *photo;
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Photo" inManagedObjectContext:context];
    photo = [[Photo alloc] initWithEntity:entity insertIntoManagedObjectContext:context];
    photo.url = [url_str copy];
    photo.place = place;
    
    return photo;
}

+ (void) savePhotoAndItsThumbnail:(Photo *) photo fromLocation: (NSURL *) location imageName:(NSString *) imageName {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSArray *urls = [fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *documentsDirectory = [urls objectAtIndex:0];
    
    //
    //NSLog(@"imageName : %@",imageName);
    
    if( ! ( !imageName || [imageName isEqualToString:@""] )  ){
        NSURL *destinationUrl = [documentsDirectory URLByAppendingPathComponent:imageName];
        NSURL *thumbnailDestinationUrl = [documentsDirectory URLByAppendingPathComponent:[NSString stringWithFormat:@"thumbnail_%@", imageName]];
        NSError *fileManagerError;
        
        [fileManager removeItemAtURL:destinationUrl error:NULL];
        [fileManager copyItemAtURL:location toURL:destinationUrl error:&fileManagerError];
        
        if(fileManagerError == nil){
            
            [self saveThumbnailOfImage: imageName originalImagePath: destinationUrl.path
                         thumbnailPath: thumbnailDestinationUrl.path];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                photo.filePath = destinationUrl.path;
                photo.thumbnail_filePath = thumbnailDestinationUrl.path;
                //[self saveContext];
            });
        }
        else{
            NSLog(@"fileManagerError: %@",fileManagerError.localizedDescription);
        }
    }
}

+ (void) saveThumbnailOfImage: (NSString *) imageName originalImagePath: (NSString *) imagePath thumbnailPath: (NSString *) thumbnailPath{
    UIImage *originalImage = [UIImage imageWithContentsOfFile:imagePath];
    CGSize destinationSize = CGSizeMake(100, 100);
    UIGraphicsBeginImageContext(destinationSize);
    [originalImage drawInRect:CGRectMake(0,0,destinationSize.width,destinationSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    NSString * imageType = [imageName substringFromIndex:MAX((int)[imageName length]-3, 0)];
    imageType = [imageType lowercaseString];
    if([imageType isEqualToString:@"jpg"]){
        [UIImageJPEGRepresentation(newImage, 1.0) writeToFile:thumbnailPath atomically:YES];
    }
    else if ([imageType isEqualToString:@"png"]){
        [UIImagePNGRepresentation(newImage) writeToFile:thumbnailPath atomically:YES];
    }
}

@end
