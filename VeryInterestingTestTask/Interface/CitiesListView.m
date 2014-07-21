//
//  CitiesListView.m
//  VeryInterestingTestTask
//
//  Created by Valeriy Buev on 19.07.14.
//  Copyright (c) 2014 bva. All rights reserved.
//

#import "CitiesListView.h"
#import "City+CityCategory.h"
#import "PlaceTableViewCell.h"
#import "Place+PlaceCategory.h"
#import "AppSettings+AppSettingsCategory.h"
#import "AppDelegate.h"
#import "InitialDownloaderView.h"
#import "CitySectionHeaderView.h"

static NSString *SectionHeaderViewIdentifier = @"SectionHeaderViewIdentifier";
static NSString *PlaceCellIdentifier = @"CellPlace";

@interface CitiesListView ()
<NSFetchedResultsControllerDelegate, CitySectionHeaderViewDelegate, InitialDownloaderViewDelegate>
{
    NSFetchedResultsController *controller;
    NSMutableArray *hiddenSections;
}

@property (nonatomic,retain) AppSettings *appSettings;
@property  (nonatomic, retain) NSManagedObjectContext *context;

@end

@implementation CitiesListView
@synthesize appSettings = _appSettings;
@synthesize context = _context;

#pragma mark initialization and basic functions

- (NSManagedObjectContext *) context{
    if ( _context != nil )
        return _context;
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    _context = appDelegate.managedObjectContext;
    return _context;
}
- (AppSettings *) appSettings{
    if(_appSettings != nil)
        return _appSettings;
    _appSettings = [AppSettings getInstance:self.context];
    return _appSettings;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"CitySectionHeaderView_iPad" bundle:nil] forHeaderFooterViewReuseIdentifier:SectionHeaderViewIdentifier];
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:PlaceCellIdentifier];
    [self.tableView setRowHeight:cell.frame.size.height];
    [self.tableView setSectionHeaderHeight:44];
    if ( self.appSettings.didDataBeLoaded.boolValue == NO ){
        [self showInitialDownloaderView];
    }
    else {
        [self setFetchedResultsController];
    }
}

- (void) showInitialDownloaderView{
    InitialDownloaderView *view = [self.storyboard instantiateViewControllerWithIdentifier:@"InitialDownloaderView"];
    view.delegate = self;
    view.context = self.context;
    [self presentViewController: view animated: NO completion:nil];
}

- (void) setFetchedResultsController{
    controller = [Place newFetchedResultsControllerForMOC:self.context];
    controller.delegate = self;
    NSError *error;
    [controller performFetch:&error];
    if( error ){
        NSLog(@"Error while performing fetch: %@",error.localizedDescription);
        controller = nil;
    }
    else{
        hiddenSections = [NSMutableArray array];
        NSUInteger sectionsCount = controller.sections.count;
        for ( NSUInteger i=0; i < sectionsCount; i++ ) {
            [hiddenSections addObject:[NSNumber numberWithBool:NO]];
        }
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    //NSLog(@"sections count; %d",controller.sections.count);
    if( !controller )
        return 0;
    else
        return controller.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //CitySectionHeaderView *view = (CitySectionHeaderView *) [self.tableView headerViewForSection:section];
    NSNumber *isSectionHidden = [hiddenSections objectAtIndex:section];
    if( isSectionHidden.boolValue == YES )
        return 0;
    else{
        id <NSFetchedResultsSectionInfo> sectionInfo = [controller.sections objectAtIndex:section];
        return [sectionInfo numberOfObjects];
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PlaceTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:PlaceCellIdentifier forIndexPath:indexPath];
    
    [self configureCell:cell forIndexPath:indexPath];
    
    return cell;
}

- (void) configureCell: (PlaceTableViewCell *) cell forIndexPath: (NSIndexPath *) indexPath {
    Place *place = [controller objectAtIndexPath:indexPath];
    cell.labelName.text = place.name;
#warning fill setting image code
}



// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    CitySectionHeaderView *view = [self.tableView dequeueReusableHeaderFooterViewWithIdentifier:SectionHeaderViewIdentifier];
    [self configureHeaderView:view sectionIndex:section];
    return view;
}

- (void) configureHeaderView:(CitySectionHeaderView *) view sectionIndex:(NSUInteger ) sectionIndex{
    id <NSFetchedResultsSectionInfo> sectioninfo = [controller.sections objectAtIndex:sectionIndex];
    view.delegate = self;
    view.sectionInfo = sectioninfo;
    NSNumber *isSectionHidden = [hiddenSections objectAtIndex:sectionIndex];
    view.isSectionHidden = isSectionHidden.boolValue;
    NSString *name = [sectioninfo name];
    if(!name || [name isEqualToString:@""]){
        view.labelCityName.text = @"Without city";
    }
    else {
        view.labelCityName.text = [sectioninfo name];
    }
}


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark NSFetchResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller{
    [self.tableView endUpdates];
}

-(void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    BOOL isSectionHidden = [[hiddenSections objectAtIndex:indexPath.section] boolValue];
    BOOL isNewSectionHidden = [[hiddenSections objectAtIndex:newIndexPath.section] boolValue];
    switch (type) {
        case NSFetchedResultsChangeDelete:
            if(isSectionHidden == NO){
                [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            }
            break;
            
        case NSFetchedResultsChangeInsert:
            if(isSectionHidden == NO){
                [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            }
            break;
            
        case NSFetchedResultsChangeMove:{
            if(isSectionHidden == NO){
                [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            }
            if(isNewSectionHidden == NO){
                [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            }
        }
            break;
            
        case NSFetchedResultsChangeUpdate:{
            PlaceTableViewCell *cell = (PlaceTableViewCell *) [self.tableView cellForRowAtIndexPath:indexPath];
            [self configureCell:cell forIndexPath:indexPath];
        }
            break;
            
        default:
            break;
    }
}

-(void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    switch (type) {
        case NSFetchedResultsChangeDelete:{
            [hiddenSections removeObjectAtIndex:sectionIndex];
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
        }
            break;
            
        case NSFetchedResultsChangeInsert:{
            [hiddenSections insertObject:[NSNumber numberWithBool:NO] atIndex:sectionIndex];
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
        }
            break;
            
        case NSFetchedResultsChangeMove:
            break;
            
        case NSFetchedResultsChangeUpdate:{
            CitySectionHeaderView *view = (CitySectionHeaderView *) [self.tableView headerViewForSection:sectionIndex];
            [self configureHeaderView:view sectionIndex:sectionIndex];
        }
            break;
            
        default:
            break;
    }
}

#pragma mark CitySectionHeaderViewDelegate

- (void)citySectionHeaderView:(CitySectionHeaderView *)view didHidden:(Boolean)isHidden{
    id <NSFetchedResultsSectionInfo> sectionInfo = view.sectionInfo;
    NSUInteger sectionIndex = [controller.sections indexOfObject:sectionInfo];
    [hiddenSections setObject:[NSNumber numberWithBool:isHidden] atIndexedSubscript:sectionIndex];
    NSMutableArray *indexPathes = [NSMutableArray arrayWithCapacity:[sectionInfo numberOfObjects]];
    for(int i=0;i<[sectionInfo numberOfObjects];i++){
        [indexPathes addObject:[NSIndexPath indexPathForRow:i inSection:sectionIndex]];
    }
    [self.tableView beginUpdates];
    if(isHidden == NO){
        [self.tableView insertRowsAtIndexPaths:indexPathes withRowAnimation:UITableViewRowAnimationRight];
    }
    else {
        [self.tableView deleteRowsAtIndexPaths:indexPathes withRowAnimation:UITableViewRowAnimationRight];
    }
    [self.tableView endUpdates];
}

#pragma mark InitialDownloaderViewDelegate

- (void)initialDownloaderViewShouldBeDisappeared:(InitialDownloaderView *)view{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated:YES completion:nil];
        [self setFetchedResultsController];
    });
}

@end