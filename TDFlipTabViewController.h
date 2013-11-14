//
//  TDFlipTabViewController.h
//  Thinx Drinks
//
//  Created by Joe on 2/5/13.
//  Copyright (c) 2013 Thinx. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TDFlipViewDelegate <NSObject>

- (void)willPerformSegue:(UIStoryboardSegue *)segue withDesination:(UIViewController *)destination;

@optional
- (void)willperformFlipToViewController:(UIViewController *)viewController;

@end

@interface TDFlipTabViewController : UIViewController

@property (nonatomic, strong) NSArray *containedViews;
@property (nonatomic, assign) id<TDFlipViewDelegate>delegate;

@end
