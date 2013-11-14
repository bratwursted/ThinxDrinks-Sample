//
//  AppDelegate.m
//  Thinx Drinks
//
//  Created by Joe on 2/3/13.
//  Copyright (c) 2013 Thinx. All rights reserved.
//

#import "AppDelegate.h"
#import "TDSyncEngine.h"
#import "TDFlipTabViewController.h"
#import "NearbyMapViewController.h"
#import "NearbyListViewController.h"
#import "DateListViewController.h"
#import "FavoriteEventsViewController.h"
#import "TDFlipTabSearchViewController.h"
#import "SearchListViewController.h"
#import "MapSearchViewController.h"
#import "SharedEventStore.h"

#import "Venue.h"
#import "EventInfo.h"
#import "Day.h"

const NSInteger kMaxLaunches = 5;

@implementation AppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize backgroundManagedObjectContext = _backgroundManagedObjectContext;

- (void)customizeAppearance
{
    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"toolbar"] forBarMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setBackgroundImage:[UIImage imageNamed:@"redbackbutton"] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setBackgroundImage:[UIImage imageNamed:@"redbackbutton"] forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], UITextAttributeTextColor, nil];
    [[UIBarButtonItem appearance] setTitleTextAttributes:attributes forState:UIControlStateNormal];

    [[UIBarButtonItem appearance] setBackButtonBackgroundImage:[UIImage imageNamed:@"redbackbutton"] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setBackButtonBackgroundImage:[UIImage imageNamed:@"redbackbutton"] forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];

    [[UISearchBar appearance] setBackgroundImage:[UIImage imageNamed:@"redbackground"]];
}

- (void)maxLaunchCounter
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"AppLaunchCounter"]) {
        NSInteger launchCounter = [[defaults objectForKey:@"AppLaunchCounter"] integerValue];
        launchCounter = kMaxLaunches + 1;
        [defaults setObject:[NSNumber numberWithInteger:launchCounter] forKey:@"AppLaunchCounter"];
        [defaults synchronize];
    }
}

- (void)resetLaunchCounter
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithInteger:0] forKey:@"AppLaunchCounter"];
    [defaults synchronize];
}

- (void)userRatingAlert
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"AppLaunchCounter"]) {
        NSInteger launchCount = [[defaults objectForKey:@"AppLaunchCounter"] integerValue];
        if (launchCount < kMaxLaunches) {
            launchCount++;
            [defaults setObject:[NSNumber numberWithInteger:launchCount] forKey:@"AppLaunchCounter"];
            [defaults synchronize];
        } else {
            if (launchCount == kMaxLaunches) {
                // present the ratings alert
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Rate this app" message:@"Please take a moment to rate Thinx Drinks in the iTunes App Store." delegate:self cancelButtonTitle:nil otherButtonTitles:@"Rate it now", @"Ask me later", @"Stop asking", nil];
                [alert setAlertViewStyle:UIAlertViewStyleDefault];
                [alert setDelegate:self];
                alert.cancelButtonIndex = -1;
                [alert show];
            }
        }
    } else {
        // first launch, create counter
        [defaults setObject:[NSNumber numberWithInteger:1] forKey:@"AppLaunchCounter"];
        [defaults synchronize];
    }
}

- (void)openAppStore
{
    NSString *itunesURL = @"https://itunes.apple.com/us/app/thinx-drinks/id607866764?ls=1&mt=8";
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:itunesURL]];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0:
            // user wants to rate the app
            // set max launch count
            // then open app store link
            [self maxLaunchCounter];
            [self openAppStore];
            break;
            
        case 1:
            // dismiss alert and reset launch counter
            [self resetLaunchCounter];
            break;
            
        case 2:
            // max the counter, stop bothering the user
            [self maxLaunchCounter];
            break;
            
        default:
            break;
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [self customizeAppearance];
    
    // init the eshared events store
    [[SharedEventStore sharedInstance] sharedEventStore];
    
    // register classes for data sync
    [[TDSyncEngine sharedEngine] registerCloudDataClassToSync:@"Venues" forNSManagedObjectClass:[Venue class]]; 
    [[TDSyncEngine sharedEngine] registerCloudDataClassToSync:@"Events" forNSManagedObjectClass:[EventInfo class]];
    
    // prompt user for itunes review on fifth launch
    [self userRatingAlert];
    
    // prepare view controllers 
    UITabBarController *tabController = (UITabBarController *)self.window.rootViewController;
    
    // set up flip tab view controller
    UINavigationController *navController = [tabController.viewControllers objectAtIndex:0];
    TDFlipTabViewController *flipVC = (TDFlipTabViewController *)navController.topViewController;
    NearbyMapViewController *mapVC = [tabController.storyboard instantiateViewControllerWithIdentifier:@"nearby-map"];
    mapVC.managedObjectContext = self.managedObjectContext;
    NearbyListViewController *listVC = [tabController.storyboard instantiateViewControllerWithIdentifier:@"nearby-list"];
    listVC.managedObjectContext = self.managedObjectContext;
    flipVC.containedViews = [NSArray arrayWithObjects:mapVC, listVC, nil];
    
    // set up flip tab search VC
    UINavigationController *nc = [tabController.viewControllers objectAtIndex:2];
    TDFlipTabSearchViewController *flipSearchVC = (TDFlipTabSearchViewController *)nc.topViewController;
    MapSearchViewController *mapSearchVC = [tabController.storyboard instantiateViewControllerWithIdentifier:@"search-map"];
    SearchListViewController *searchListVC = [tabController.storyboard instantiateViewControllerWithIdentifier:@"search-list"];
    mapSearchVC.managedObjectContext = self.managedObjectContext;
    searchListVC.managedObjectContext = self.managedObjectContext;
    flipSearchVC.containedViews = @[mapSearchVC, searchListVC];
    
    tabController.delegate = self;
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.

    [[TDSyncEngine sharedEngine] startSync];

}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Tab bar controller delegate

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
    if ([viewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navController = (UINavigationController *)viewController;
        UIViewController *topVC = navController.topViewController;
        
        if ([topVC isKindOfClass:[TDFlipTabViewController class]]) {
            // something
        } else if ([topVC isKindOfClass:[DateListViewController class]]) {
            DateListViewController *dateListVC = (DateListViewController *)topVC;
            dateListVC.managedObjectContext = self.managedObjectContext;
        } else if ([topVC isKindOfClass:[FavoriteEventsViewController class]]) {
            FavoriteEventsViewController *favEventsVC = (FavoriteEventsViewController *)topVC;
            favEventsVC.managedObjectContext = self.managedObjectContext;
        } 
    }
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }

    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    
    return _managedObjectContext;
}

- (NSManagedObjectContext *)backgroundManagedObjectContext
{
    // create a background context for data syncing
    if (_backgroundManagedObjectContext != nil) {
        return _backgroundManagedObjectContext;
    }
    
    NSManagedObjectContext *masterContext = self.managedObjectContext;
    if (masterContext != nil) {
        _backgroundManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [_backgroundManagedObjectContext performBlockAndWait:^{
            [_backgroundManagedObjectContext setParentContext:_managedObjectContext];
        }];
    }
    
    return _backgroundManagedObjectContext; 
}

- (void)saveManagedObjectContext
{
    [self.managedObjectContext performBlockAndWait:^{
        NSError *error = nil;
        BOOL saved = [self.managedObjectContext save:&error];
        if (!saved) {
            NSLog(@"Core data error. Could not save MOC due to %@", error);
        }
    }];
}

- (void)saveBackgroundContext
{
    [self.backgroundManagedObjectContext performBlockAndWait:^{
        NSError *error = nil;
        BOOL saved = [self.backgroundManagedObjectContext save:&error];
        if (!saved) {
            NSLog(@"Core data error. Could not save background MOC due to %@", error);
        }
    }]; 
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"ThinxDrinksCD" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"ThinxDrinks.sqlite"];
    
    // preload data store
    if (![[NSFileManager defaultManager] fileExistsAtPath:[storeURL path]]) {
        NSURL *preloadedURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"ThinxDrinksCD" ofType:@"sqlite"]];
        NSError *fileError = nil;
        if (![[NSFileManager defaultManager] copyItemAtURL:preloadedURL toURL:storeURL error:&fileError]) {
            NSLog(@"Error initializing data store");
        }
    }
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {

        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
