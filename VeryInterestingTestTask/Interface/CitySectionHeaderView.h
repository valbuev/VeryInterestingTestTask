//
//  CitySectionHeaderView.h
//  VeryInterestingTestTask
//
//  Created by Valeriy Buev on 19.07.14.
//  Copyright (c) 2014 bva. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@class CitySectionHeaderView;

@protocol CitySectionHeaderViewDelegate
- (void) citySectionHeaderView:(CitySectionHeaderView *) view didHidden:(Boolean) isHidden;
@end

@interface CitySectionHeaderView : UITableViewHeaderFooterView

@property (weak, nonatomic) IBOutlet UILabel *labelCityName;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewHiddenIndicator;

- (IBAction)btnToggleClicked:(id)sender;

@property (nonatomic, weak) id <CitySectionHeaderViewDelegate> delegate;
@property (nonatomic, retain) id <NSFetchedResultsSectionInfo> sectionInfo;
@property (nonatomic) Boolean isSectionHidden;

@end
