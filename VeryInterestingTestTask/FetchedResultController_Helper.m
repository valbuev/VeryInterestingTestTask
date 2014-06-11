//
//  FetchedResultController_Helper.m
//  VeryInterestingTestTask
//
//  Created by Valeriy Buev on 28.05.14.
//  Copyright (c) 2014 bva. All rights reserved.
//

#import "FetchedResultController_Helper.h"

@implementation FetchedResultController_Helper

-(void) clickButton{
    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
}

-(void) reloadData{
    [self.citiesAndPlacesList removeAllObjects];
    int sections_count = [[self.citiesController sections] count];
    for ( int sectionIndex = 0; sectionIndex < sections_count; sectionIndex ++ ){
        //int rowIndex = 0;
        NSString *currentCityName = @"";
        NSMutableArray *section = [[NSMutableArray alloc] init];
        int places_count = [[[self.placesController sections] objectAtIndex:sectionIndex] numberOfObjects];
        for (int placesIndex = 0; placesIndex < places_count; placesIndex++) {
            NSIndexPath *placesIndexPath = [NSIndexPath indexPathForRow:placesIndex inSection:sectionIndex];
            NSManagedObject *place = [self.placesController objectAtIndexPath:placesIndexPath];
            NSManagedObject *city = [place valueForKey:@"city"];
            NSString *placeCityName = [self getCityName:city];
            if( ! [currentCityName isEqualToString:placeCityName] && placeCityName != nil ){
                currentCityName = [city valueForKey:@"name"];
                [section addObject:city];
            }
            [section addObject:place];
        }
        [self.citiesAndPlacesList addObject:section];
    }
    [self.tableView reloadData];
}

-(NSString *) getCityName:(NSManagedObject *) cityObject{
    if(!cityObject)
        return nil;
    else
        return [cityObject valueForKey:@"name"];
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
    [self.tableView beginUpdates];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    
    UITableView *tableView = self.tableView;

    if ( [self.citiesController isEqual:controller]){
        NSLog(@"city index %d %d",indexPath.section,indexPath.row);
        NSLog(@"city new index %d %d",newIndexPath.section,newIndexPath.row);
        switch(type) {
            case NSFetchedResultsChangeInsert:
            {
                NSIndexPath * listIndexPath = [self getCityIndexPathInTableView:newIndexPath];
                NSMutableArray *array = [self.citiesAndPlacesList objectAtIndex:listIndexPath.section];
                [array insertObject:anObject atIndex:listIndexPath.row];
                [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:listIndexPath] withRowAnimation:UITableViewRowAnimationFade];
                NSLog(@"insert city");
            }
                break;
                
            case NSFetchedResultsChangeDelete:
            {
                NSIndexPath * listIndexPath = [self getCityIndexPathInTableView:indexPath];
                NSMutableArray *array = [self.citiesAndPlacesList objectAtIndex:listIndexPath.section];
                [array removeObjectAtIndex:listIndexPath.row];
                [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:listIndexPath] withRowAnimation:UITableViewRowAnimationFade];
                NSLog(@"remove city");
            }
                break;
                
            case NSFetchedResultsChangeUpdate:
            {
                NSIndexPath * listIndexPath = [self getCityIndexPathInTableView:indexPath];
                NSMutableArray *array = [self.citiesAndPlacesList objectAtIndex:listIndexPath.section];
                NSManagedObject *city = [array objectAtIndex:listIndexPath.row];
                [self.delegate configureCell:(UITableViewCell *)[tableView cellForRowAtIndexPath:listIndexPath] managedObject:city ];
                NSLog(@"update city");
            }
                break;
                
            case NSFetchedResultsChangeMove:
            {
                NSIndexPath * listIndexPath = [self getCityIndexPathInTableView:indexPath];
                NSMutableArray *array = [self.citiesAndPlacesList objectAtIndex:listIndexPath.section];
                NSManagedObject *city = [array objectAtIndex:listIndexPath.row];
                [array removeObjectAtIndex:listIndexPath.row];
                [tableView deleteRowsAtIndexPaths:[NSArray
                                                   arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
                listIndexPath = [self getCityIndexPathInTableView:newIndexPath];
                array = [self.citiesAndPlacesList objectAtIndex:listIndexPath.section];
                [array insertObject:city atIndex:listIndexPath.row];
                [tableView insertRowsAtIndexPaths:[NSArray
                                                   arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
                NSLog(@"move city");
            }
                break;
        }
    }
    else if ([self.placesController isEqual:controller]){
        NSLog(@"place index %d %d",indexPath.section,indexPath.row);
        NSLog(@"place new index %d %d",newIndexPath.section,newIndexPath.row);
        switch(type) {
            case NSFetchedResultsChangeInsert:
            {
                NSIndexPath * listIndexPath = [self getPlaceIndexPathInTableView:newIndexPath];
                NSMutableArray *array = [self.citiesAndPlacesList objectAtIndex:listIndexPath.section];
                [array insertObject:anObject atIndex:listIndexPath.row];
                [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:listIndexPath] withRowAnimation:UITableViewRowAnimationFade];
                NSLog(@"insert place");
            }
                break;
                
            case NSFetchedResultsChangeDelete:
            {
                NSIndexPath * listIndexPath = [self getPlaceIndexPathInTableView:indexPath];
                NSMutableArray *array = [self.citiesAndPlacesList objectAtIndex:listIndexPath.section];
                [array removeObjectAtIndex:listIndexPath.row];
                [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:listIndexPath] withRowAnimation:UITableViewRowAnimationFade];
                NSLog(@"remove place %d %d",listIndexPath.section ,listIndexPath.row);
            }
                break;
                
            case NSFetchedResultsChangeUpdate:
            {
                NSIndexPath * listIndexPath = [self getPlaceIndexPathInTableView:indexPath];
                NSMutableArray *array = [self.citiesAndPlacesList objectAtIndex:listIndexPath.section];
                NSManagedObject *place = [array objectAtIndex:listIndexPath.row];
                [self.delegate configureCell:(UITableViewCell *)[tableView cellForRowAtIndexPath:listIndexPath] managedObject:place ];
                NSLog(@"update place");
            }
                break;
                
            case NSFetchedResultsChangeMove:
            {
                NSIndexPath * listIndexPath = [self getPlaceIndexPathInTableView:indexPath];
                NSMutableArray *array = [self.citiesAndPlacesList objectAtIndex:listIndexPath.section];
                NSManagedObject *place = [array objectAtIndex:listIndexPath.row];
                [array removeObjectAtIndex:listIndexPath.row];
                [tableView deleteRowsAtIndexPaths:[NSArray
                                                   arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
                listIndexPath = [self getPlaceIndexPathInTableView:newIndexPath];
                array = [self.citiesAndPlacesList objectAtIndex:listIndexPath.section];
                [array insertObject:place atIndex:listIndexPath.row];
                [tableView insertRowsAtIndexPaths:[NSArray
                                                   arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
                NSLog(@"move place");
            }
                break;
        }
    }
}

- (NSIndexPath *) getCityIndexPathInTableView: (NSIndexPath *) indexPath{
    int rows = 0;
    NSManagedObject * city;
    for (int i=0; i<indexPath.row-2; i++) {
        city = [self.citiesController objectAtIndexPath:[NSIndexPath indexPathForRow:i inSection:indexPath.section]];
        NSArray *places = [city valueForKey:@"places"];
        rows += [places count] + 1;
    }
    return [NSIndexPath indexPathForRow:rows inSection:indexPath.section];
}

- (NSIndexPath *) getPlaceIndexPathInTableView: (NSIndexPath *) indexPath{
    NSManagedObject *place = [self.placesController objectAtIndexPath:indexPath];
    NSLog(@"%@",[place valueForKey:@"text"]);
    NSManagedObject *city = [place valueForKey:@"city"];
    NSLog(@"%@",[city valueForKey:@"name"]);
    NSIndexPath* cityIndexPath = [self.citiesController indexPathForObject:city];
    NSLog(@"cityIndexpath %d %d",cityIndexPath.section,cityIndexPath.row);
    return [NSIndexPath indexPathForRow: (cityIndexPath.row + indexPath.row + 1) inSection:indexPath.section];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id )sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    if ( [self.citiesController isEqual:controller]){
        switch(type) {
                
            case NSFetchedResultsChangeInsert:
                [self.citiesAndPlacesList insertObject:[[NSMutableArray alloc] init] atIndex:sectionIndex];
                [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
                NSLog(@"insert section");
                break;
                
            case NSFetchedResultsChangeDelete:
                NSLog(@"remove section");
                [self.citiesAndPlacesList removeObjectAtIndex:sectionIndex];
                [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
                break;
        }
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
    [self.tableView endUpdates];
}

@end