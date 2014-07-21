//
//  CitySectionHeaderView.m
//  VeryInterestingTestTask
//
//  Created by Valeriy Buev on 19.07.14.
//  Copyright (c) 2014 bva. All rights reserved.
//

#import "CitySectionHeaderView.h"

@implementation CitySectionHeaderView
@synthesize delegate;
@synthesize sectionInfo;
@synthesize isSectionHidden = _isSectionHidden;
@synthesize labelCityName;
@synthesize  imageViewHiddenIndicator;


- (void)setIsSectionHidden:(Boolean)isSectionHidden{
    _isSectionHidden = isSectionHidden;
    if(isSectionHidden == YES){
        self.imageViewHiddenIndicator.image = [UIImage imageNamed:@"disclosure_indicator_right.jpg"];
    }
    else {
        self.imageViewHiddenIndicator.image = [UIImage imageNamed:@"disclosure_indicator_down.jpg"];
    }
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if(self){
    }
    return self;
}

- (void)awakeFromNib{
    NSLog(@"CitySectionHeaderView awake from nib");
}

- (IBAction)btnToggleClicked:(id)sender {
    self.isSectionHidden = !self.isSectionHidden;
    if(self.delegate){
        [self.delegate citySectionHeaderView:self didHidden:self.isSectionHidden];
    }
}

-(void)dealloc{
    NSLog(@"CitySectionHeaderView dealloc");
}



@end
