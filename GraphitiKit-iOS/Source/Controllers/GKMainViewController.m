//
//  GKMainViewController.m
//  GraphitiKit-iOS
//
//  Created by apple on 12/23/14.
//  Copyright (c) 2014 Jason Chang. All rights reserved.
//

#import "GKMainViewController.h"
#import "GKSplatEngine.h"
#import "GKRenderView.h"
#import "GKRenderViewController.h"
#import "UIScrollView+GKExtension.h"
#import "GKViewportHelper.h"

#define SCROLL

@interface GKMainViewController () <GKRenderViewControllerDelegate,UIScrollViewDelegate> {
}
@property (weak,nonatomic) GKRenderViewController *renderViewController;
@property (weak,nonatomic) UIButton *navigationTitleButton;
@property (weak,nonatomic) UIScrollView *scrollView;
@property (weak,nonatomic) UIImageView *imageView;
@property (nonatomic) CGFloat imageContentIntialFillScale;
@property (strong,nonatomic) UIImage *originalImage;
@end

static NSString *const webURLString = @"http://www.buzzfeed.com";

@implementation GKMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;
    [self setupNavigationBar];

    CGRect frame = self.view.bounds;
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:frame];
    [self.view addSubview:scrollView];
    self.scrollView = scrollView;
    self.scrollView.bouncesZoom = NO;
    self.scrollView.bounces = NO;
    self.scrollView.minimumZoomScale = 1.0;
    self.scrollView.maximumZoomScale = 4.0;
    self.scrollView.delegate = self;
    
    self.originalImage = [UIImage imageNamed:@"testbackground.png"];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:self.originalImage];
    [self.scrollView addSubview:imageView];
    self.imageView = imageView;
    self.scrollView.contentSize = imageView.bounds.size;
    
    CGSize scrollViewSize = self.scrollView.bounds.size;
    CGSize contentSize = self.imageView.bounds.size;
    CGFloat zoomScaleWidth = scrollViewSize.width/contentSize.width;
    CGFloat zoomScaleHeight = scrollViewSize.height/contentSize.height;
    self.imageContentIntialFillScale = MAX(zoomScaleWidth,zoomScaleHeight);
    [self.scrollView aspectFillWithImageView:self.imageView];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
    [self createDrawViewWithScrollView:self.scrollView];
    [self.scrollView scrollToCenterOfImageView:self.imageView];
}

- (void) createDrawViewWithScrollView:(UIScrollView *)scrollView {
    if(!self.renderViewController) {
        GKRenderViewController* renderViewController = [[GKRenderViewController alloc] init];
        renderViewController.view.frame = scrollView.bounds;
        renderViewController.delegate = self;
        [self addChildViewController:renderViewController];
#ifdef SCROLL
        [self.view addSubview:renderViewController.view];
#else
        [scrollView addSubview:renderViewController.view];
#endif
        [renderViewController didMoveToParentViewController:self];
        self.renderViewController = renderViewController;
        self.renderViewController.view.userInteractionEnabled = YES;

        [scrollView setZoomScale:1];
        [scrollView setContentOffset:CGPointZero];
        self.renderViewController.scrollContentOffsetRatio = 1.0;
#ifndef SCROLL
        scrollView.delegate = self;
        CGFloat scale = scrollView.contentSize.width/scrollView.bounds.size.width;
        if(scrollView.contentSize.width > scrollView.contentSize.height) {
            scale = scrollView.contentSize.height/scrollView.bounds.size.height;
        }
        self.renderViewController.baseScale = scale;
        [self.renderViewController setupZoomLogicOnScrollView:scrollView];
#endif
        self.renderViewController.worldSize = scrollView.contentSize;
        self.renderViewController.worldMode = GKWorldFinite;
#ifdef SCROLL
        [self.renderViewController setWorldBackgroundImage:self.originalImage];
        self.scrollView.hidden = YES;
#endif
    }
}

#pragma mark <scrollview delegate>

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}
- (void) scrollViewDidZoom:(UIScrollView *)scrollView {
    [self.renderViewController scrollViewDidZoom:scrollView];
}
- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
    [self.renderViewController scrollViewWillBeginZooming:scrollView withView:view];
}
- (void) scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
    [self.renderViewController scrollViewDidEndZooming:scrollView withView:view atScale:scale];
}
- (void) scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self.renderViewController scrollViewWillBeginDragging:scrollView];
}
- (void) scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [self.renderViewController scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
}
- (void) scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self.renderViewController scrollViewDidEndDecelerating:scrollView];
}
- (void) scrollViewDidScroll:(UIScrollView *)scrollView {
#ifndef SCROLL
    CGRect frame = self.renderViewController.view.frame;
    frame.origin = scrollView.contentOffset;
    self.renderViewController.view.frame = frame;
#endif
    [self.renderViewController scrollViewDidScroll:scrollView];
}

#pragma mark - setup

- (void) setupNavigationBar {
//    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks target:self action:@selector(manageTools:)];
//    UIBarButtonItem *cropButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(crop)];
//    self.navigationItem.leftBarButtonItems = @[item,cropButton];
//    item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editTapped:)];
//    UIBarButtonItem *item2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFastForward target:self action:@selector(removeActiveObject:)];
//    self.navigationItem.rightBarButtonItems = @[item,item2];
//    self.stencilRemoveButton = item2;
//    self.stencilRemoveButton.enabled = NO;
//    UIButton *titleButton = [UIButton buttonWithType:UIButtonTypeCustom];
//    [titleButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
//    [titleButton addTarget:self action:@selector(titleTapped:) forControlEvents:UIControlEventTouchUpInside];
//    self.navigationItem.titleView = titleButton;
//    self.navigationTitleButton = titleButton;
//    
    // clear background image for navigationbar
    UIColor *color = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5];
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 2.0);
    [color setFill];
    UIRectFill(rect);
    UIImage *tempImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [self.navigationController.navigationBar setBackgroundImage:tempImage forBarMetrics:UIBarMetricsDefault];
}

@end
