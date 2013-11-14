//
//  TDFlipTabViewController.m
//  Thinx Drinks
//
//  Created by Joe on 2/5/13.
//  Copyright (c) 2013 Thinx. All rights reserved.
//

#import "TDFlipTabViewController.h"

@interface TDFlipTabViewController ()

@property (nonatomic, weak) IBOutlet UIView *viewContainer;

@end

@implementation TDFlipTabViewController
{
    IBOutlet UIBarButtonItem *flipButton;
    UIViewController *currentContainedView;
    UIButton *mapButton;
    UIButton *listButton; 
}

@synthesize containedViews = _containedViews;
@synthesize delegate = _delegate; 

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)mapButton
{
    mapButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [mapButton setImage:[UIImage imageNamed:@"07-map-marker"] forState:UIControlStateNormal];
    [mapButton addTarget:self action:@selector(flipToNewView) forControlEvents:UIControlEventTouchUpInside];
    [mapButton setFrame:listButton.frame];
}

- (void)listButton
{
    listButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [listButton setImage:[UIImage imageNamed:@"list-icon"] forState:UIControlStateNormal];
    [listButton addTarget:self action:@selector(flipToNewView) forControlEvents:UIControlEventTouchUpInside];
    [listButton setFrame:CGRectMake(0, 0, 32, 32)]; 
}

- (void)flipButton
{
    flipButton = [[UIBarButtonItem alloc] initWithCustomView:listButton];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    currentContainedView = [self.containedViews objectAtIndex:0];
    [self listButton];
    [self flipButton];
    [self mapButton];
    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    spacer.width = 25.0; 
    NSArray *barButtonItems = [NSArray arrayWithObjects: spacer, flipButton, nil];
    self.navigationItem.rightBarButtonItems = barButtonItems;
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"thinxdrinks"]];
    UIImage *arrow = [UIImage imageNamed:@"back-arrow"];
    UIBarButtonItem *backArrow = [[UIBarButtonItem alloc] initWithImage:arrow landscapeImagePhone:arrow style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.backBarButtonItem = backArrow;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self displayContentController:currentContainedView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController *destinationVC = [segue destinationViewController];
    [self.delegate willPerformSegue:segue withDesination:destinationVC];
}

- (void)flipToNewView
{
    UIViewController *currentVC = [self.childViewControllers objectAtIndex:0];
    NSUInteger currentIndex = [self.containedViews indexOfObject:currentVC];
    NSUInteger newIndex = abs(currentIndex - 1);
    UIViewController *newVC = [self.containedViews objectAtIndex:newIndex];
    newVC.view.frame = self.viewContainer.bounds;
    
    NSUInteger flipDirection = newIndex > currentIndex ? UIViewAnimationOptionTransitionFlipFromLeft : UIViewAnimationOptionTransitionFlipFromRight;

    UIButton *newButton = currentIndex < newIndex ? mapButton : listButton;
    
    [currentVC willMoveToParentViewController:nil];
    [self addChildViewController:newVC];
    
    if ([self.delegate respondsToSelector:@selector(willperformFlipToViewController:)]) {
        [self.delegate willperformFlipToViewController:newVC];
    }
    
    [self transitionFromViewController:currentVC toViewController:newVC duration:1.0 options:flipDirection animations:^{
    }completion:^(BOOL finished) {
        [flipButton setCustomView:newButton];
        [currentVC removeFromParentViewController];
        [newVC didMoveToParentViewController:self];
        currentContainedView = newVC; 
    }];
}

- (void)displayContentController:(UIViewController *)contentController
{
    [self addChildViewController:contentController];
    contentController.view.frame = [self frameForContent];
    [self.viewContainer addSubview:contentController.view];
    [contentController didMoveToParentViewController:self];
    currentContainedView = contentController;
}

- (CGRect)frameForContent
{
    return self.viewContainer.bounds;
}

@end
