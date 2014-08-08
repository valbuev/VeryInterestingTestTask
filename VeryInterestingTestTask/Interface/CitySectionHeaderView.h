//
//  CitySectionHeaderView.h
//  VeryInterestingTestTask
//
//  Created by Valeriy Buev on 19.07.14.
//  Copyright (c) 2014 bva. All rights reserved.
//
//
//  This view is used as sectionHeader in UITableView
//
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@class CitySectionHeaderView;

@protocol CitySectionHeaderViewDelegate
// User tapped on view (section must be hidden or shown)
- (void) citySectionHeaderView:(CitySectionHeaderView *) view didHidden:(Boolean) isHidden;
@end

@interface CitySectionHeaderView : UITableViewHeaderFooterView

// label with city name
@property (weak, nonatomic) IBOutlet UILabel *labelCityName;
// indicator
@property (weak, nonatomic) IBOutlet UIImageView *imageViewHiddenIndicator;

// user tapped on view
- (IBAction)btnToggleClicked:(id)sender;

// delegate
@property (nonatomic, weak) id <CitySectionHeaderViewDelegate> delegate;
// uses for search index of object in NSFetchResultsController
@property (nonatomic, retain) id <NSFetchedResultsSectionInfo> sectionInfo;

@property (nonatomic) Boolean isSectionHidden;

@end
