//
//  PlacesListViewController.m
//  VeryInterestingTestTask
//
//  Created by Valeriy Buev on 27.05.14.
//  Copyright (c) 2014 bva. All rights reserved.
//

#import "PlacesListViewController.h"
#import "CityTableViewCell.h"

@interface PlacesListViewController ()

@end

@implementation PlacesListViewController

@synthesize placesTableView;

- (IBAction)clickButton:(id)sender{
    //[FRC_Helper reloadData];
    [FRC_Helper clickButton];
}

- (NSFetchedResultsController *) citiesFetchedResultsController{
    if (_citiesFetchedResultsController != nil) {
        return _citiesFetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"City" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSSortDescriptor *sortByFirstLetter = [[NSSortDescriptor alloc]
                              initWithKey:@"first_letter.letter" ascending:YES];
    NSSortDescriptor *sortByName = [[NSSortDescriptor alloc]
                               initWithKey:@"name" ascending:YES];
    NSArray *sortList = [NSArray arrayWithObjects:sortByFirstLetter, sortByName, nil];
    [fetchRequest setSortDescriptors:sortList];
    
    NSFetchedResultsController *theFetchedResultsController =
    [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                        managedObjectContext:self.managedObjectContext sectionNameKeyPath:@"first_letter.letter"
                                                   cacheName:@"City_cache"];
    self.citiesFetchedResultsController = theFetchedResultsController;
    [self initFRC_Helper];
    FRC_Helper.citiesController = self.citiesFetchedResultsController;
    self.citiesFetchedResultsController.delegate = FRC_Helper;
    
    return _citiesFetchedResultsController;
}

- (NSFetchedResultsController *) placesFetchedResultsController{
    if (_placesFetchedResultsController != nil) {
        return _placesFetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"Place" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSSortDescriptor *sortByFirstLetter = [[NSSortDescriptor alloc]
                                           initWithKey:@"city.first_letter.letter" ascending:YES];
    NSSortDescriptor *sortByCityName = [[NSSortDescriptor alloc]
                                    initWithKey:@"city.name" ascending:YES];
    NSSortDescriptor *sortByText = [[NSSortDescriptor alloc]
                                        initWithKey:@"text" ascending:YES];
    NSArray *sortList = [NSArray arrayWithObjects:sortByFirstLetter, sortByCityName,sortByText, nil];
    [fetchRequest setSortDescriptors:sortList];
    
    NSFetchedResultsController *theFetchedResultsController =
    [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                        managedObjectContext:self.managedObjectContext sectionNameKeyPath:@"city.first_letter.letter"
                                                   cacheName:@"Place_cache"];
    self.placesFetchedResultsController = theFetchedResultsController;
    [self initFRC_Helper];
    FRC_Helper.placesController = self.placesFetchedResultsController;
    self.placesFetchedResultsController.delegate = FRC_Helper;
    
    return _placesFetchedResultsController;
}
- (NSMutableArray *) citiesAndPlacesList{
    if(_citiesAndPlacesList != nil){
        return _citiesAndPlacesList;
    }
    self.citiesAndPlacesList = [[NSMutableArray alloc] init];
    return _citiesAndPlacesList;
}

- (void) initFRC_Helper{
    if(!FRC_Helper){
        FRC_Helper = [[FetchedResultController_Helper alloc] init];
        FRC_Helper.context = self.managedObjectContext;
        FRC_Helper.tableView = self.placesTableView;
        FRC_Helper.citiesAndPlacesList = [self citiesAndPlacesList];
        FRC_Helper.delegate = self;
    }
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
    NSLog(@"view did load");
    FRC_Helper.tableView = self.placesTableView;
    //[self.placesTableView reloadData];
}

-(void)performFetch{
    NSError *error;
	if (![[self citiesFetchedResultsController] performFetch:&error]) {
		NSLog(@"fetchedResultsController Unresolved error %@, %@", error, [error userInfo]);
		exit(-1);  // Fail
	}
    if (![[self placesFetchedResultsController] performFetch:&error]) {
		NSLog(@"fetchedResultsController Unresolved error %@, %@", error, [error userInfo]);
		exit(-1);  // Fail
	}
    [FRC_Helper reloadData];
}

- (void)didReceiveMemoryWarning
{
    NSLog(@"didReceiveMemoryWarning");
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (Boolean) isManagedObjectNamedCity: (NSManagedObject *) object{
    if([[[object entity] name] isEqualToString:@"City"])
        return TRUE;
    else
        return FALSE;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    NSMutableArray *currentLetter = [[self citiesAndPlacesList] objectAtIndex:indexPath.section];
    NSManagedObject *managedObject = (NSManagedObject *) [currentLetter objectAtIndex:indexPath.row];

    static NSString *cityCellIdentifier = @"City";
    static NSString *placeCellIdentifier = @"Place";
    
    UITableViewCell *cell;
    
    Boolean isCity = [self isManagedObjectNamedCity:managedObject];
    if(isCity)
        cell = [tableView dequeueReusableCellWithIdentifier:cityCellIdentifier];
    else
        cell = [tableView dequeueReusableCellWithIdentifier:placeCellIdentifier];
    
    if(nil == cell){
        if(isCity)
            cell = [[UITableViewCell alloc]
                initWithStyle:UITableViewCellStyleSubtitle
                reuseIdentifier:cityCellIdentifier];
        else
            cell = [[UITableViewCell alloc]
                    initWithStyle:UITableViewCellStyleSubtitle
                    reuseIdentifier:placeCellIdentifier];
    }
    
    // Set up the cell...
    [self configureCell:cell managedObject:managedObject];
    
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell managedObject:(NSManagedObject *)object{
    Boolean isCity = [self isManagedObjectNamedCity:object];
    if(isCity){
        cell.textLabel.text = [object valueForKey:@"name"];
    }
    else{
        cell.textLabel.text = [object valueForKey:@"text"];
        NSSet *photos = (NSSet *) [object valueForKey:@"photos"];
        if(photos != nil){
            @autoreleasepool {
                if ([photos count] > 0) {
                    NSManagedObject * photo = [photos anyObject];
                    NSString *imagePath = [photo valueForKey:@"image"];
                    if(imagePath){
                        [cell.imageView setImage:[UIImage imageWithContentsOfFile:imagePath]];
                    }
                    else{
                        NSString *url = [photo valueForKey:@"url"];
                        if(url){
                            id<UIApplicationDelegate> appDelegate = [[UIApplication sharedApplication] delegate];
                            //[(AppDelegate *)appDelegate downloadPhoto:url forPhotoManagedObject:photo];
                        }
                        [cell.imageView setImage:[UIImage imageNamed:@"question_mark.jpg"]];
                    }
                }
                else{
                    [cell.imageView setImage:[UIImage imageNamed:@"question_mark.jpg"]];
                }
            }
        }
        else{
            [cell.imageView setImage:[UIImage imageNamed:@"question_mark.jpg"]];
        }
    }
}

- (void)saveContext {
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    
    if(managedObjectContext != nil) {
        @try {
            if([managedObjectContext hasChanges] && ![managedObjectContext save:&error]){
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                abort();
            }
        }
        @catch (NSException *exception) {
            NSLog(@"Fail when managedObjContext was saving:\n %@",exception);
        }
    }
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    NSArray *array = [self.citiesAndPlacesList objectAtIndex:section];
    return [array count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    //NSLog(@"number of sections in tableView %d",[self.citiesAndPlacesList count]);
    return [self.citiesAndPlacesList count];
}


-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    id sectionInfo = [[self.citiesFetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo name];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableArray *currentLetter = [[self citiesAndPlacesList] objectAtIndex:indexPath.section];
    NSManagedObject *managedObject = (NSManagedObject *) [currentLetter objectAtIndex:indexPath.row];
    Boolean isCity = [self isManagedObjectNamedCity:managedObject];
    return !isCity;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSMutableArray *currentLetter = [[self citiesAndPlacesList] objectAtIndex:indexPath.section];
        NSManagedObject *managedObject = (NSManagedObject *) [currentLetter objectAtIndex:indexPath.row];
        NSManagedObject *city = [managedObject valueForKey:@"city"];
        NSSet *places = [city valueForKey:@"places"];
        NSManagedObject *letter = [city valueForKey:@"first_letter"];
        NSSet *cities = [letter valueForKey:@"cities"];
        [self.managedObjectContext deleteObject:managedObject];
        [self saveContext];
        if([places count] == 0){
            [self.managedObjectContext deleteObject:city];
            NSLog(@"delete city");
            [self saveContext];
            if([cities count] == 1){
                NSLog(@"selete letter");
                [self.managedObjectContext deleteObject:letter];
                [self saveContext];
            }
        }
        //[placesTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSMutableArray *currentLetter = [[self citiesAndPlacesList] objectAtIndex:indexPath.section];
    NSManagedObject *managedObject = (NSManagedObject *) [currentLetter objectAtIndex:indexPath.row];
    Boolean isCity = [self isManagedObjectNamedCity:managedObject];
    CGFloat height = isCity ? 44.0f : 88.0f;
    return height;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
