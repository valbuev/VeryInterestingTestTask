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

// Saves the image and the thumbnail  of photo to document directory
+ (void) savePhotoAndItsThumbnail:(Photo *) photo fromLocation: (NSURL *) location imageName:(NSString *) imageName {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // get document directory's url
    NSArray *urls = [fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *documentsDirectory = [urls objectAtIndex:0];
    
    if( ! ( !imageName || [imageName isEqualToString:@""] )  ){
        
        // constructing of destination urls for image and thumbnail
        NSURL *destinationUrl = [documentsDirectory URLByAppendingPathComponent:imageName];
        NSURL *thumbnailDestinationUrl = [documentsDirectory URLByAppendingPathComponent:[NSString stringWithFormat:@"thumbnail_%@", imageName]];
        NSError *fileManagerError;
        
        // prepare for copying
        [fileManager removeItemAtURL:destinationUrl error:NULL];
        // copying
        [fileManager copyItemAtURL:location toURL:destinationUrl error:&fileManagerError];
        // removing original file
        [fileManager removeItemAtURL: location error: NULL];
        
        if(fileManagerError == nil){
            
            // saving thumbnail
            [self saveThumbnailOfImage: imageName originalImagePath: destinationUrl.path
                         thumbnailPath: thumbnailDestinationUrl.path];
            
            // setting of photo's filepathes
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

// saves thumbnail of image
+ (void) saveThumbnailOfImage: (NSString *) imageName originalImagePath: (NSString *) imagePath thumbnailPath: (NSString *) thumbnailPath{
    
    // load original image
    UIImage *originalImage = [UIImage imageWithContentsOfFile:imagePath];
    double stretchingCoeff = 1;
    if(originalImage.size.width > 0)
        stretchingCoeff = (originalImage.size.height * 1.0) / originalImage.size.width;
    
    // stretch the size of image
    CGSize destinationSize = CGSizeMake( 200, (int)(200*stretchingCoeff) );
    UIGraphicsBeginImageContext(destinationSize);
    [originalImage drawInRect:CGRectMake(0,0,destinationSize.width,destinationSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // saving thumbnail
    NSString * imageType = [imageName substringFromIndex:MAX((int)[imageName length]-3, 0)];
    imageType = [imageType lowercaseString];
    if([imageType isEqualToString:@"jpg"]){
        [UIImageJPEGRepresentation(newImage, 1.0) writeToFile:thumbnailPath atomically:NO];
    }
    else if ([imageType isEqualToString:@"png"]){
        [UIImagePNGRepresentation(newImage) writeToFile:thumbnailPath atomically:NO];
    }
}

// does some actions before the object be deleted
- (void)prepareForDeletion {
    // deleting of thumbnail
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if( self.thumbnail_filePath != nil && ![self.thumbnail_filePath isEqualToString:@""]){
        [fileManager removeItemAtPath: self.thumbnail_filePath error:nil];
    }
    // deleting of image
    if( self.filePath != nil && ![self.filePath isEqualToString:@""]){
        [fileManager removeItemAtPath: self.filePath error:nil];
    }
}

@end
