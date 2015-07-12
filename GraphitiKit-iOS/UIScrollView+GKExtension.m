//
//  UIScrollView+GKExtension.m
//  GraphitiKit-iOS
//
//  Created by apple on 5/24/15.
//  Copyright (c) 2015 Jason Chang. All rights reserved.
//

#import "UIScrollView+GKExtension.h"

@implementation UIScrollView (GKExtension)

- (void) aspectFillWithImageView:(UIImageView *)imageView {
    if(!imageView.image || CGSizeEqualToSize(CGSizeZero, imageView.bounds.size)) {
        return;
    }
//    NSCAssert(imageView.superview == self, @"expect imageView to be direct child of scrollView");
    CGSize scrollViewSize = self.bounds.size;
    CGSize contentSize = imageView.bounds.size;
    CGFloat zoomScaleWidth = scrollViewSize.width/contentSize.width;
    CGFloat zoomScaleHeight = scrollViewSize.height/contentSize.height;
    CGFloat zoomScale = MAX(zoomScaleWidth,zoomScaleHeight);
    if(isnan(zoomScale) || zoomScale == 0) {
        return;
    }
    CGRect frame = imageView.bounds;
    frame = CGRectApplyAffineTransform(frame, CGAffineTransformMakeScale(zoomScale, zoomScale));
    imageView.frame = frame;
    self.contentSize = imageView.bounds.size;
}

- (void) scrollToCenterOfImageView:(UIImageView *)imageView {
    if(!imageView.image || CGSizeEqualToSize(CGSizeZero, imageView.bounds.size)) {
        return;
    }
//    NSCAssert(imageView.superview == self, @"expect imageView to be direct child of scrollView");
    CGSize scrollViewSize = self.bounds.size;
    CGSize contentSize = imageView.bounds.size;
    CGPoint offset = CGPointZero;
    if(contentSize.width > scrollViewSize.width) {
        offset.x = (contentSize.width-scrollViewSize.width)/2;
    }
    if(contentSize.height > scrollViewSize.height) {
        offset.y = (contentSize.height-scrollViewSize.height)/2;
    }
    self.contentOffset = offset;
}

- (CGRect) currentVisibleFrameInContentCoordinate {
    CGFloat scale = self.minimumZoomScale/self.zoomScale;
    CGRect visibleRect = self.bounds;
    visibleRect.origin = self.contentOffset;
    visibleRect = CGRectApplyAffineTransform(visibleRect, CGAffineTransformMakeScale(scale, scale));
    return visibleRect;
}

@end
