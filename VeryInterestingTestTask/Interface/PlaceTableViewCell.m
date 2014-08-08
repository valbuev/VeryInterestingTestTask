//
//  PlaceTableViewCell.m
//  VeryInterestingTestTask
//
//  Created by Valeriy Buev on 19.07.14.
//  Copyright (c) 2014 bva. All rights reserved.
//

#import "PlaceTableViewCell.h"
#import "Photo+PhotoCategory.h"

@implementation PlaceTableViewCell
@synthesize labelName;
@synthesize imageViewPhoto;
@synthesize photo = _photo;

- (void)setPhoto:(Photo *)photo{
    if(_photo == photo)
        return;
    // if we allready have other photo-reference, than we must remove observer, before change reference
    if( _photo ){
        [_photo removeObserver:self forKeyPath:@"thumbnail_filePath"];
    }
    _photo = photo;
    // Add observer because photo can be changed in process
    if( _photo ){
        [_photo addObserver:self forKeyPath:@"thumbnail_filePath" options:NSKeyValueObservingOptionInitial context:nil];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    
    // photo was changed, change image
    if( [keyPath isEqualToString:@"thumbnail_filePath"] ){
        [self configureImage];
    }
}

// Configuring of image using Photo
- (void) configureImage{
    
    // if Photo-object contain real thumbnail, then we use it, else we use "no_photo"
    if( self.photo ){
        if(self.photo.thumbnail_filePath)
            if( ![self.photo.thumbnail_filePath isEqualToString:@""]){
                self.imageViewPhoto.image = [UIImage imageWithContentsOfFile: self.photo.thumbnail_filePath];
                return;
            }
    }
    self.imageViewPhoto.image = [UIImage imageNamed:@"no_photo.jpg"];
}


// if cell will be dealloced, then we must remove observer of photo
- (void)dealloc{
    if( self.photo ){
        [self.photo removeObserver:self forKeyPath:@"thumbnail_filePath"];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

@end
