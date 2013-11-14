//
//  NearbyMapViewController.m
//  Thinx Drinks
//
//  Created by Joe on 2/5/13.
//  Copyright (c) 2013 Thinx. All rights reserved.
//

#import "NearbyMapViewController.h" 
#import "EventDetailViewController.h"
#import "NearbyListViewController.h"
#import "EventLocation.h"
#import "EventInfo.h"
#import "Venue.h"

static const CLLocationCoordinate2D austinLocation = {30.2669, -97.7428};

@interface NearbyMapViewController ()

@end

@implementation NearbyMapViewController
{
    CLLocationManager *locationManager;
    NSInteger selectedEventIndex; 
}

@synthesize managedObjectContext = _managedObjectContext;
@synthesize mapView = _mapView;

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
	// Do any additional setup after loading the view.
    if (![CLLocationManager locationServicesEnabled]) {
        [_mapView setShowsUserLocation:NO];
    }
    [self startLocationManager];
    MKCoordinateRegion austinRegion = MKCoordinateRegionMakeWithDistance(austinLocation, 1500, 1500);
    [_mapView setRegion:austinRegion animated:YES];
    _mapView.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.view.frame = self.parentViewController.view.bounds;
}

- (void)viewDidAppear:(BOOL)animated
{
    [self plotLocatons];
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
}

- (void)plotLocatons
{
    for (id<MKAnnotation>annotation in _mapView.annotations) {
        [_mapView removeAnnotation:annotation];
    }
    NSArray *events = [self fetchEvents];
    for (EventInfo *event in events) {
        NSInteger index = [events indexOfObjectIdenticalTo:event];
        CLLocationCoordinate2D eventCoordinate;
        eventCoordinate.latitude = [event.location.latitude doubleValue];
        eventCoordinate.longitude = [event.location.longitude doubleValue];
        EventLocation *annotation = [[EventLocation alloc] initWithTitle:event.title venueName:event.location.name andFavoriteStatus:[event.favorite boolValue] index:index andCoordinates:eventCoordinate];
        [_mapView addAnnotation:annotation];
    }
}

#pragma mark - Flip tab view delegate

- (void)willPerformSegue:(UIStoryboardSegue *)segue withDesination:(EventDetailViewController *)destination
{
    destination.eventInfo = [[self fetchEvents] objectAtIndex:selectedEventIndex];
    destination.managedObjectContext = _managedObjectContext; 
}

- (void)willperformFlipToViewController:(NearbyListViewController *)viewController
{
    viewController.eventsList = [[self fetchEvents] mutableCopy];
}

#pragma mark - Map view annotation methods

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(EventLocation *)annotation
{
    static NSString *identifier = @"location";
    if ([annotation isKindOfClass:[EventLocation class]]) {
        MKPinAnnotationView *annotationView = (MKPinAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
        if (annotationView == nil) {
            annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
        } else {
            annotationView.annotation = annotation;
        }
        annotationView.enabled = YES;
        annotationView.canShowCallout = YES;
        UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        annotationView.rightCalloutAccessoryView = rightButton;
        
        NSString *filename = annotation.favorite ? @"favstar_selected" : @"favstar_unselected";
        annotationView.leftCalloutAccessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:filename]]; 
        
        return annotationView;
    }
    return nil;
}

#pragma mark - Map view delegate

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    EventLocation *selectedEvent = view.annotation;
    selectedEventIndex = selectedEvent.index;
    [self.parentViewController performSegueWithIdentifier:@"detail" sender:self];
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    [self plotLocatons];
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
        // update the map view
        CLLocationCoordinate2D mapLocation;
        mapLocation.latitude = location.coordinate.latitude;
        mapLocation.longitude = location.coordinate.longitude;
        [_mapView setCenterCoordinate:mapLocation animated:YES];
        [self plotLocatons];
    }
}

#pragma mark - Core data fetch events

- (NSArray *)fetchEvents
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"EventInfo" inManagedObjectContext:_managedObjectContext];
    [request setEntity:entity];
    
    // predicate
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(date.date = %@) AND (location.latitude > %f) AND (location.latitude < %f) AND (location.longitude > %f) AND (location.longitude < %f)", [self todaysDate], [self minLatitudeForRegion:_mapView.region], [self maxLatitudeForRegion:_mapView.region], [self minLongitudeForRegion:_mapView.region], [self maxLongitudeForRegion:_mapView.region]];
    [request setPredicate:predicate];

    // sort by favorites
    [request setSortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"favorite" ascending:YES]]];
    
    NSError *error;
    NSArray *events = [_managedObjectContext executeFetchRequest:request error:&error];
    if (events == nil) {
        NSLog(@"Core data error %@, %@", error, [error userInfo]);
    }
    return events;
}

#pragma mark - region helper functions

- (double)maxLatitudeForRegion:(MKCoordinateRegion)region
{
    return region.center.latitude + (region.span.latitudeDelta / 2);
}

- (double)minLatitudeForRegion:(MKCoordinateRegion)region
{
    return region.center.latitude - (region.span.latitudeDelta / 2);
}

- (double)maxLongitudeForRegion:(MKCoordinateRegion)region
{
    return region.center.longitude + (region.span.longitudeDelta / 2);
}

- (double)minLongitudeForRegion:(MKCoordinateRegion)region
{
    return region.center.longitude - (region.span.longitudeDelta / 2);
}

#pragma mark - Helper date functions

- (NSDate *)todaysDate
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *date = [NSDate date];
    NSDateComponents *adjComps = [[NSDateComponents alloc] init];
    [adjComps setHour:-2];
    
    NSUInteger comps = (NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit);
    NSDateComponents *todaysComps = [calendar components:comps fromDate:[calendar dateByAddingComponents:adjComps toDate:date options:0]];

    return [calendar dateFromComponents:todaysComps];
}

@end
