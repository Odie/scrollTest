//
//  UIScrollView+GKExtension.h
//  GraphitiKit-iOS
//
//  Created by apple on 5/24/15.
//  Copyright (c) 2015 Jason Chang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIScrollView (GKExtension)

- (void) aspectFillWithImageView:(UIImageView *)imageView;
- (void) scrollToCenterOfImageView:(UIImageView *)imageView;
- (CGRect) currentVisibleFrameInContentCoordinate;

@end
