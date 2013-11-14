//
//  NearbyMapViewController.h
//  Thinx Drinks
//
//  Created by Joe on 2/5/13.
//  Copyright (c) 2013 Thinx. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "TDFlipTabViewController.h"

@interface NearbyMapViewController : UIViewController <TDFlipViewDelegate, MKMapViewDelegate, CLLocationManagerDelegate>

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext; 
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@end
