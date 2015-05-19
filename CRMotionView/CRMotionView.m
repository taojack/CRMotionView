//
//  CRMotionView.m
//  CRMotionView
//
//  Created by Christian Roman on 06/02/14.
//  Copyright (c) 2014 Christian Roman. All rights reserved.
//

#import "CRMotionView.h"
#import "CRZoomScrollView.h"
#import "UIScrollView+CRScrollIndicator.h"

@import CoreMotion;

static const CGFloat CRMotionViewRotationMinimumTreshold = 0.1f;
static const CGFloat CRMotionGyroUpdateInterval = 1 / 100;
static const CGFloat CRMotionViewRotationFactor = 4.0f;
static NSString *kPAPUserDefaultsUserPhotoDetailPreferenceKey    = @"com.journey.userDefaults.userPhotoDetail.preference";

@interface CRMotionView () <CRZoomScrollViewDelegate>

@property (nonatomic, assign) CGRect viewFrame;

@property (nonatomic, strong) CMMotionManager *motionManager;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) CRZoomScrollView *zoomScrollView;

@property (nonatomic, assign) CGFloat motionRate;
@property (nonatomic, assign) NSInteger minimumXOffset;
@property (nonatomic, assign) NSInteger maximumXOffset;
@property (nonatomic, assign) BOOL stopTracking;

@end

@implementation CRMotionView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _viewFrame = CGRectMake(0.0, 0.0, CGRectGetWidth(frame), CGRectGetHeight(frame));
        _scrollIndicatorEnabled = YES;
        _scrollIndicatorAtParentView = YES;
        [self commonInit];
        
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame image:(UIImage *)image
{
    self = [self initWithFrame:frame];
    if (self) {
        [self setImage:image];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame contentView:(UIView *)contentView;
{
    self = [self initWithFrame:frame];
    if (self) {
        [self setContentView:contentView];
    }
    return self;
}

- (void)commonInit
{
    _scrollView = [[UIScrollView alloc] initWithFrame:_viewFrame];
    [_scrollView setUserInteractionEnabled:NO];
    [_scrollView setBounces:NO];
    [_scrollView setContentSize:CGSizeZero];
    [self addSubview:_scrollView];
    
    _containerView = [[UIView alloc] initWithFrame:_viewFrame];
    [_scrollView addSubview:_containerView];
    
    _minimumXOffset = 0;
    _zoomEnabled   = YES;
    // Tap gesture to open zoomable view
//    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
//    [tapGesture setNumberOfTouchesRequired : 2];
//    [self addGestureRecognizer:tapGesture];
    [self setMotionEnabled:YES];
}

#pragma mark - Public Method

- (BOOL)isInZoom
{
    return (self.zoomScrollView != nil);
}

#pragma mark - UI actions


- (void)handleTap:(UITapGestureRecognizer *)gesture
{
    // Only work if the content view is an image
    if ([self.contentView isKindOfClass:[UIImageView class]] && self.isZoomEnabled) {
        
        UIImageView *imageView = (UIImageView *)self.contentView;
        if (CGRectGetWidth(self.contentView.frame) >= imageView.image.size.width) {
            if (self.zoomScrollView != nil) {
                [self.zoomScrollView removeFromSuperview];
                self.zoomScrollView = nil;
                [self.contentView setHidden:YES];
            }
            return;
        }
        
        if (self.zoomScrollView != nil) {
            [self.zoomScrollView removeFromSuperview];
            self.zoomScrollView = nil;
            [self.contentView setHidden:NO];
            [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:kPAPUserDefaultsUserPhotoDetailPreferenceKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
        } else {
            // Stop motion to avoid transition jump between two views
            //        [self stopMonitoring];
            // Init and setup the zoomable scroll view
            self.zoomScrollView = [[CRZoomScrollView alloc] initFromScrollView:self.scrollView withImage:imageView.image];
            self.zoomScrollView.zoomDelegate = self;
            [self.contentView setHidden:YES];
            [self addSubview:self.zoomScrollView];
            NSInteger preference = (NSInteger)[[NSUserDefaults standardUserDefaults] integerForKey:kPAPUserDefaultsUserPhotoDetailPreferenceKey];
            if (preference != 1) {
                [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:kPAPUserDefaultsUserPhotoDetailPreferenceKey];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
        }
    }
}

- (void)pinch:(UIPinchGestureRecognizer *)gesture {
    [self.zoomScrollView pinch:gesture];
}

#pragma mark - Setters

- (void)setContentView:(UIView *)contentView
{
    if (_contentView) {
        [_contentView removeFromSuperview];
    }
    
    CGFloat width = _viewFrame.size.height / contentView.frame.size.height * contentView.frame.size.width;
    [contentView setFrame:CGRectMake(0, 0, width, _viewFrame.size.height)];
    
    [_containerView addSubview:contentView];
    
    _scrollView.contentSize = CGSizeMake(contentView.frame.size.width, _scrollView.frame.size.height);
    _scrollView.contentOffset = CGPointMake((_scrollView.contentSize.width - _scrollView.frame.size.width) / 2, 0);
    
    [self setScrollIndicatorEnabled:_scrollIndicatorEnabled];
    
    _motionRate = contentView.frame.size.width / _viewFrame.size.width * CRMotionViewRotationFactor;
    _maximumXOffset = _scrollView.contentSize.width - _scrollView.frame.size.width;
    
    _contentView = contentView;
}

- (void)setImage:(UIImage *)image
{
    if (image) {
        _image = image;
        
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        [self setContentView:imageView];
        NSInteger preference = (NSInteger)[[NSUserDefaults standardUserDefaults] integerForKey:kPAPUserDefaultsUserPhotoDetailPreferenceKey];
        if (preference == 1) {
            [self handleTap:nil];
        }
    } else {
        _image = nil;
    }
}

- (void)setMotionEnabled:(BOOL)motionEnabled
{
    _motionEnabled = motionEnabled;
    if (_motionEnabled) {
        [self startMonitoring];
    } else {
        [self stopMonitoring];
    }
}

- (void)setScrollIndicatorEnabled:(BOOL)scrollIndicatorEnabled
{
    _scrollIndicatorEnabled = scrollIndicatorEnabled;
    if (scrollIndicatorEnabled) {
        NSDictionary *dict = [_scrollView cr_enableScrollIndicatorInCurrentView:!_scrollIndicatorAtParentView];
        if (!_backgroundViewScrollIndicator) {
            _backgroundViewScrollIndicator = [dict objectForKey:BACKGROUND_VIEW_SCROLL_INDICTATOR];
            _viewScrollIndicator = [dict objectForKey:VIEW_SCROLL_INDICTATOR];
        }
    } else {
        [_scrollView cr_disableScrollIndicator];
    }
}

#pragma mark - ZoomScrollView delegate

// When user dismisses zoomable view, put back motion tracking
- (void)zoomScrollViewWillDismiss:(CRZoomScrollView *)zoomScrollView
{
    self.stopTracking = YES;
}

// When user dismisses zoomable view, put back motion tracking
- (void)zoomScrollViewDidDismiss:(CRZoomScrollView *)zoomScrollView
{
    // Put back motion if it was enabled
    self.stopTracking = NO;
}

- (void)positionIndictatorToForegroundView:(UIView*)foregroundView originY:(NSUInteger)originY
{
    [_scrollView cr_refreshScrollIndicator];
    [_backgroundViewScrollIndicator setFrame:CGRectMake(_backgroundViewScrollIndicator.frame.origin.x, originY, _backgroundViewScrollIndicator.frame.size.width, _backgroundViewScrollIndicator.frame.size.height)];
    [_viewScrollIndicator setFrame:CGRectMake(_viewScrollIndicator.frame.origin.x, originY, _viewScrollIndicator.frame.size.width, _viewScrollIndicator.frame.size.height)];
    
    for (UIView *view in [foregroundView subviews]) {
        if (view == _backgroundViewScrollIndicator)
            return;
    }
    [foregroundView addSubview:_backgroundViewScrollIndicator];
    [foregroundView addSubview:_viewScrollIndicator];
}

#pragma mark - Core Motion

- (void)startMonitoring
{
    if ([self.contentView isKindOfClass:[UIImageView class]]) {
        UIImageView *imageView = (UIImageView *)self.contentView;
        if (CGRectGetWidth(self.contentView.frame) >= imageView.image.size.width) {
            return;
        }
    }
    
    if (!_motionManager) {
        _motionManager = [[CMMotionManager alloc] init];
        _motionManager.gyroUpdateInterval = CRMotionGyroUpdateInterval;
    }
    
    if (![_motionManager isGyroActive] && [_motionManager isGyroAvailable] ) {
        [_motionManager startGyroUpdatesToQueue:[NSOperationQueue currentQueue]
                                    withHandler:^(CMGyroData *gyroData, NSError *error) {
                                        CGFloat rotationRate = gyroData.rotationRate.y;
                                        if (fabs(rotationRate) >= CRMotionViewRotationMinimumTreshold) {
                                            CGFloat offsetX = _scrollView.contentOffset.x - rotationRate * _motionRate;
                                            if (offsetX > _maximumXOffset) {
                                                offsetX = _maximumXOffset;
                                            } else if (offsetX < _minimumXOffset) {
                                                offsetX = _minimumXOffset;
                                            }
                                            
                                            if (!self.stopTracking) {
                                                [UIView animateWithDuration:0.3f
                                                                      delay:0.0f
                                                                    options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseOut
                                                                 animations:^{
                                                                     [_scrollView setContentOffset:CGPointMake(offsetX, 0) animated:NO];
                                                                     self.zoomScrollView.startOffset = CGPointMake(offsetX, 0);
                                                                 }
                                                                 completion:nil];
                                            }
                                        }
                                    }];
    } else {
        NSLog(@"There is not available gyro.");
    }
}

- (void)stopMonitoring
{
    [_motionManager stopGyroUpdates];
}

- (void)dealloc
{
    [self.scrollView cr_disableScrollIndicator];
}

@end
