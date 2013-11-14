//
//  NearbyListViewController.m
//  Thinx Drinks
//
//  Created by Joe on 2/5/13.
//  Copyright (c) 2013 Thinx. All rights reserved.
//

#import "NearbyListViewController.h"
#import "EventDetailViewController.h"
#import "TDEventTableViewCell.h"
#import "EventInfo.h"
#import "Venue.h"

#define kMeters2Miles 0.000621371

@interface NearbyListViewController ()

@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController; 

@end

@implementation NearbyListViewController
{
    CLLocationManager *locationManager;
    CLLocation *currentLocation;
    BOOL locationServices; 
}

@synthesize managedObjectContext = _managedObjectContext;
@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize eventsList = _eventsList; 

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if ([CLLocationManager locationServicesEnabled]) {
        [self startLocationManager];
        locationServices = YES;
    } else {
        locationServices = NO; 
    }
    [self sortEvents];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)didMoveToParentViewController:(TDFlipTabViewController *)parent
{
    [super didMoveToParentViewController:parent];
    parent.delegate = self;
    [self sortEvents];
    [self.tableView reloadData];
}

- (void)tapFavorite:(UITapGestureRecognizer *)gesture
{
    NSInteger index = gesture.view.tag;
    [self updateFavoriteStatusForEvent:[_eventsList objectAtIndex:index] atIndex:index];
}

- (void)updateFavoriteStatusForEvent:(EventInfo *)event atIndex:(NSInteger)index
{
    EventInfo *fetchedEvent = [self fetchEvent:event];
    
    // change favorite status
    switch ([fetchedEvent.favorite integerValue]) {
        case 0:
            fetchedEvent.favorite = [NSNumber numberWithBool:YES];
            break;
            
        case 1:
            fetchedEvent.favorite = [NSNumber numberWithBool:NO];
            break;
            
        default:
            break;
    }
    
    // replace this in the events array
    [_eventsList replaceObjectAtIndex:index withObject:fetchedEvent];
    
    // save to data store
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Core data error %@, %@", error, [error userInfo]);
        abort();
    }
    [self.tableView reloadData];
}

- (EventInfo *)fetchEvent:(EventInfo *)event
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"EventInfo" inManagedObjectContext:_managedObjectContext];
    [request setEntity:entity];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"detail.info == %@", event];
    [request setPredicate:predicate];
    
    NSError *error;
    NSArray *result = [_managedObjectContext executeFetchRequest:request error:&error];
    if (result == nil) {
        NSLog(@"Core data error %@, %@", error, [error userInfo]);
    }
    return [result objectAtIndex:0];
}

- (NSString *)distanceToLocation:(Venue *)location
{
    if (!locationServices) {
        return @""; 
    }
    CLLocation *eventLocation = [[CLLocation alloc] initWithLatitude:[location.latitude doubleValue] longitude:[location.longitude doubleValue]];
    CLLocationDistance distance = [eventLocation distanceFromLocation:currentLocation];
    double miles = distance * kMeters2Miles;
    if (miles < 0.1) {
        return [NSString stringWithFormat:@"%f feet", (miles * 5280)];
    }
    return [NSString stringWithFormat:@"%.1f mi", miles];
}

- (void)configureCell:(TDEventTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    EventInfo *event = [self.eventsList objectAtIndex:indexPath.row];
    Venue *venue = event.location;
    cell.textLabel.text = event.title;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"@ %@", venue.name];
    cell.eventTimeLabel.text = event.timeString; 
    cell.distanceLabel.text = [self distanceToLocation:venue]; 
    
    NSString *favImageName = [event.favorite boolValue] ? @"favstar_selected" : @"favstar_unselected";
    cell.imageView.image = [UIImage imageNamed:favImageName];
    cell.imageView.userInteractionEnabled = YES;
    cell.imageView.tag = indexPath.row;
    
    UITapGestureRecognizer *favTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapFavorite:)];
    favTap.delegate = self;
    [cell.imageView addGestureRecognizer:favTap];
}

- (void)sortEvents
{
    NSSortDescriptor *timeSort = [NSSortDescriptor sortDescriptorWithKey:@"eventTime" ascending:YES];
    NSSortDescriptor *titleSort = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];
    [self.eventsList sortUsingDescriptors:@[timeSort, titleSort]];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.eventsList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    TDEventTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    TDFlipTabViewController *parent = (TDFlipTabViewController *)self.parentViewController;
    [parent performSegueWithIdentifier:@"detail" sender:self];
}

#pragma mark - Flip view delegate

- (void)willPerformSegue:(UIStoryboardSegue *)segue withDesination:(EventDetailViewController *)destination
{
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    destination.eventInfo = [self.eventsList objectAtIndex:indexPath.row];
    destination.managedObjectContext = _managedObjectContext; 
}

#pragma mark - Location manager

- (void)startLocationManager
{
    if (nil == locationManager) {
        locationManager = [[CLLocationManager alloc] init];
    }
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    locationManager.distanceFilter = 100;
    [locationManager startUpdatingLocation];
}

#pragma mark - Location manager delegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *location = [locations lastObject];
    NSDate *eventDate = location.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    if (abs(howRecent) < 15.0) {
        // update the current location
        currentLocation = location;
        [self.tableView reloadData];
    }
}

@end
