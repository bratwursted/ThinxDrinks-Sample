//
//  AppDelegate.h
//  Thinx Drinks
//
//  Created by Joe on 2/3/13.
//  Copyright (c) 2013 Thinx. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate, UITabBarControllerDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (strong, nonatomic) NSManagedObjectContext *backgroundManagedObjectContext;

- (NSManagedObjectContext *)backgroundManagedObjectContext;
- (void)saveManagedObjectContext;
- (void)saveBackgroundContext; 

@end
