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
    if( _photo ){
        [_photo removeObserver:self forKeyPath:@"thumbnail_filePath"];
    }
    _photo = photo;
    if( _photo ){
        [_photo addObserver:self forKeyPath:@"thumbnail_filePath" options:NSKeyValueObservingOptionInitial context:nil];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if( [keyPath isEqualToString:@"thumbnail_filePath"] ){
        [self configureImage];
    }
}

- (void) configureImage{
    if( self.photo ){
        if(self.photo.thumbnail_filePath)
            if( ![self.photo.thumbnail_filePath isEqualToString:@""]){
                self.imageViewPhoto.image = [UIImage imageWithContentsOfFile: self.photo.thumbnail_filePath];
                return;
            }
    }
    self.imageViewPhoto.image = [UIImage imageNamed:@"no_photo.jpg"];
}

- (void)dealloc{
    if( self.photo ){
        [self.photo removeObserver:self forKeyPath:@"thumbnail_filePath"];
    }
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
