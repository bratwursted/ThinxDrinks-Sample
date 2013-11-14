//
//  NearbyListViewController.h
//  Thinx Drinks
//
//  Created by Joe on 2/5/13.
//  Copyright (c) 2013 Thinx. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "TDFlipTabViewController.h"

@class EventInfo;

@interface NearbyListViewController : UITableViewController <TDFlipViewDelegate, UIGestureRecognizerDelegate, CLLocationManagerDelegate>

@property (nonatomic, strong) NSMutableArray *eventsList;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext; 

@end
