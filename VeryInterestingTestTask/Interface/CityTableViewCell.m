//
//  CityTableViewCell.m
//  VeryInterestingTestTask
//
//  Created by Valeriy Buev on 19.07.14.
//  Copyright (c) 2014 bva. All rights reserved.
//

#import "CityTableViewCell.h"
#import "City+CityCategory.h"

@implementation CityTableViewCell
@synthesize labelName;
@synthesize imageViewIndicator;
@synthesize city = _city;
@synthesize delegate;

- (void)setCity:(City *)city{
    if(_city){
        [_city removeObserver:self forKeyPath:@"sectionHidden"];
        [_city removeObserver:self forKeyPath:@"name"];
    }
    _city = city;
    [city addObserver:self forKeyPath:@"sectionHidden" options:NSKeyValueObservingOptionInitial context:nil];
    [city addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionInitial context:nil];
}

- (void)dealloc{
    if(self.city){
        [self.city removeObserver:self forKeyPath:@"sectionHidden"];
        [self.city removeObserver:self forKeyPath:@"name"];
    }
    NSLog(@"dealloc");
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if( [keyPath isEqualToString:@"sectionHidden"] ){
#warning fill changing imageView content
    }
    else if ( [keyPath isEqualToString:@"name"] ){
        self.labelName.text = [self.city.name copy];
    }
}

- (IBAction)userClickedOnCell:(id)sender {
    if( self.delegate )
    {
        [self.delegate didTouchCityTableViewCell:self];
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
