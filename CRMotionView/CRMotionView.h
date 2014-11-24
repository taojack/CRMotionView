//
//  CRMotionView.h
//  CRMotionView
//
//  Created by Christian Roman on 06/02/14.
//  Copyright (c) 2014 Christian Roman. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CRMotionView : UIView

@property (nonatomic, strong) UIImage  *image;
@property (nonatomic, strong) UIView   *contentView;
@property (nonatomic, assign, getter = isMotionEnabled) BOOL motionEnabled;
@property (nonatomic, assign, getter = isScrollIndicatorEnabled) BOOL scrollIndicatorEnabled;
@property (nonatomic, assign, getter = isScrollIndicatorAtParentView) BOOL scrollIndicatorAtParentView;
@property (nonatomic, assign, getter = isZoomEnabled) BOOL zoomEnabled;

@property (nonatomic, strong) UIView *backgroundViewScrollIndicator;
@property (nonatomic, strong) UIView *viewScrollIndicator;

- (instancetype)initWithFrame:(CGRect)frame image:(UIImage *)image;
- (instancetype)initWithFrame:(CGRect)frame contentView:(UIView *)contentView;
- (void)positionIndictatorToForegroundView:(UIView*)foregroundView originY:(NSUInteger)originY;
- (void)handleTap:(UITapGestureRecognizer *)gesture;
- (BOOL)isInZoom;

@end
