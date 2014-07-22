//
//  FilterPopupView.m
//  VeryInterestingTestTask
//
//  Created by Valeriy Buev on 22.07.14.
//  Copyright (c) 2014 bva. All rights reserved.
//

#import "FilterPopupView.h"

@interface FilterPopupView (){
    
}

@end

@implementation FilterPopupView
@synthesize delegate;
@synthesize locationFilterRadius;

- (id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if( self ) {
        //self.locationFilterRadius = LocationFilterRadiusNone;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:(self.locationFilterRadius - LocationFilterRadiusNone) inSection:0] animated:YES scrollPosition:UITableViewScrollPositionTop];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    NSInteger row = indexPath.row;
    
    if( self.delegate ){
        [self.delegate setLocationFilterRadius: (LocationFilterRadiusNone + row)];
    }
}

@end
