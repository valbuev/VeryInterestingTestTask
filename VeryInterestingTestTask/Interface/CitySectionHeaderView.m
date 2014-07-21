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
@synthesize isSectionHidden;
@synthesize labelCityName;
@synthesize  imageViewHiddenIndicator;

- (id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if(self){
        self.isSectionHidden = NO;
    }
    return self;
}

- (void)awakeFromNib{
    NSLog(@"awake from nib");
}

- (IBAction)btnToggleClicked:(id)sender {
    self.isSectionHidden = !self.isSectionHidden;
    if(self.delegate){
        [self.delegate citySectionHeaderView:self didHidden:self.isSectionHidden];
    }
}

-(void)dealloc{
    NSLog(@"dealloc");
}



@end
