//
//  BTGlassScrollView.m
//  BTGlassScrollViewExample
//
//  Created by Byte on 10/18/13.
//  Copyright (c) 2013 Byte. All rights reserved.
//

#import "BTGlassScrollView.h"
#import "FXBlurView.h"
#import "UIScrollView+CRScrollIndicator.h"
#import "MWZoomingScrollView.h"
#import "MWPhotoBrowser.h"
#import "MWPhoto.h"
#import "EBCommentsView.h"
#import "EBCommentCell.h"
#import "EBCommentsTableView.h"
#import "MWComment.h"
#import <Parse.h>
#import <MapKit/MapKit.h>
#import <InstagramEngine.h>

@implementation BTGlassScrollView
{
    MWZoomingScrollView __weak *_parentView;
    UIScrollView *_backgroundScrollView;
    UIView *_constraitView; // for autolayout
    CRMotionView *_backgroundImageView;
    FXBlurView *_blurredBackgroundImageView;
    
    CALayer *_topShadowLayer;
    CALayer *_botShadowLayer;
    
    UIView *_foregroundContainerView; // for masking
    UIImageView *_topMaskImageView;
    
    UILabel *albumTitle;
    UILabel *locationName;
    UILabel *description;
    UILabel *likeName;
    UILabel *likeCount;
    UILabel *commentName;
    UILabel *commentCount;
    UIButton *likeButton;
    UIButton *shareButton;
    UIButton *commentButton;
    UIButton *actionButton;
    UIView *descriptionBox;
    UIView *commentBox;
    EBCommentsView *commentView;
    UIButton *editDescriptionButton;
}

- (id)initWithFrame:(CGRect)frame BackgroundImage:(UIImage *)backgroundImage blurredImage:(UIImage *)blurredImage viewDistanceFromBottom:(CGFloat)viewDistanceFromBottom foregroundView:(UIView *)foregroundView parentView:(MWZoomingScrollView*)parentView
{
    self = [super initWithFrame:frame];
    if (self) {
        self.delegate2 = self;
        //initialize values
        _backgroundImage = backgroundImage;
        if (blurredImage) {
            _blurredBackgroundImage = blurredImage;
        }else{
            if ([_delegate respondsToSelector:@selector(glassScrollView:blurForImage:)]) {
                _blurredBackgroundImage = [_delegate glassScrollView:self blurForImage:_backgroundImage];
            } else {
                _blurredBackgroundImage = [backgroundImage applyBlurWithRadius:DEFAULT_BLUR_RADIUS tintColor:DEFAULT_BLUR_TINT_COLOR saturationDeltaFactor:DEFAULT_BLUR_DELTA_FACTOR maskImage:nil];
            }
        }
        _viewDistanceFromBottom = viewDistanceFromBottom;
        _foregroundView = foregroundView;
        _parentView = parentView;
        
        //autoresize
//        [self setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
        
        //create views
        [self createBackgroundView];
        [self createForegroundView];
        [self createTopShadow];
        [self createBottomShadow];
        [self beginObservations];
    }
    return self;
}


- (void)beginObservations
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidChangeFrame:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deleteCellWithNotification:) name:@"CellDidRequestSelfDeletion"
                                               object:nil];
}

- (void)stopObservations
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Public Functions

- (void)scrollHorizontalRatio:(CGFloat)ratio
{
    // when the view scroll horizontally, this works the parallax magic
    [_backgroundScrollView setContentOffset:CGPointMake(DEFAULT_MAX_BACKGROUND_MOVEMENT_HORIZONTAL + ratio * DEFAULT_MAX_BACKGROUND_MOVEMENT_HORIZONTAL, _backgroundScrollView.contentOffset.y)];
}

- (void)scrollVerticallyToOffset:(CGFloat)offsetY
{
    [_foregroundScrollView setContentOffset:CGPointMake(_foregroundScrollView.contentOffset.x, offsetY)];
}

#pragma mark - Setters
- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    //work background
    CGRect bounds = CGRectOffset(frame, -frame.origin.x, -frame.origin.y);
    
    [_backgroundScrollView setFrame:bounds];
    [_backgroundScrollView setContentSize:CGSizeMake(bounds.size.width + 2*DEFAULT_MAX_BACKGROUND_MOVEMENT_HORIZONTAL, self.bounds.size.height + DEFAULT_MAX_BACKGROUND_MOVEMENT_VERTICAL)];
    [_backgroundScrollView setContentOffset:CGPointMake(DEFAULT_MAX_BACKGROUND_MOVEMENT_HORIZONTAL, 0)];

    [_constraitView setFrame:CGRectMake(0, 0, bounds.size.width + 2*DEFAULT_MAX_BACKGROUND_MOVEMENT_HORIZONTAL, bounds.size.height + DEFAULT_MAX_BACKGROUND_MOVEMENT_VERTICAL)];
    
    //foreground
    [_foregroundContainerView setFrame:bounds];
    [_foregroundScrollView setFrame:bounds];
    [_foregroundView setFrame:CGRectOffset(_foregroundView.bounds, (_foregroundScrollView.frame.size.width - _foregroundView.bounds.size.width)/2, _foregroundScrollView.frame.size.height - _foregroundScrollView.contentInset.top - _viewDistanceFromBottom)];
    [_foregroundScrollView setContentSize:CGSizeMake(bounds.size.width, _foregroundView.frame.origin.y + _foregroundView.bounds.size.height)];
    
    //shadows
    //[self createTopShadow];
    [_topShadowLayer setFrame:CGRectMake(0, 0, bounds.size.width, _foregroundScrollView.contentInset.top + DEFAULT_TOP_FADING_HEIGHT_HALF)];
    [_botShadowLayer setFrame:CGRectMake(0, bounds.size.height - _viewDistanceFromBottom, bounds.size.width, bounds.size.height)];

    if (_delegate && [_delegate respondsToSelector:@selector(glassScrollView:didChangedToFrame:)]) {
        [_delegate glassScrollView:self didChangedToFrame:frame];
    }
}

- (void)setTopLayoutGuideLength:(CGFloat)topLayoutGuideLength
{
    if (topLayoutGuideLength == 0) {
        return;
    }
    
    //set inset
    [_foregroundScrollView setContentInset:UIEdgeInsetsMake(topLayoutGuideLength, 0, 0, 0)];
    
    //reposition
    [_foregroundView setFrame:CGRectOffset(_foregroundView.bounds, (_foregroundScrollView.frame.size.width - _foregroundView.bounds.size.width)/2, _foregroundScrollView.frame.size.height - _foregroundScrollView.contentInset.top - _viewDistanceFromBottom)];
    
    //resize contentSize
    [_foregroundScrollView setContentSize:CGSizeMake(self.frame.size.width, _foregroundView.frame.origin.y + _foregroundView.frame.size.height)];
    
    //reset the offset
    if (_foregroundScrollView.contentOffset.y == 0) {
        [_foregroundScrollView setContentOffset:CGPointMake(0, -_foregroundScrollView.contentInset.top)];
    }
    
    //adding new mask
    _foregroundContainerView.layer.mask = [self createTopMaskWithSize:CGSizeMake(_foregroundContainerView.frame.size.width, _foregroundContainerView.frame.size.height) startFadeAt:_foregroundScrollView.contentInset.top - DEFAULT_TOP_FADING_HEIGHT_HALF endAt:_foregroundScrollView.contentInset.top + DEFAULT_TOP_FADING_HEIGHT_HALF topColor:[UIColor colorWithWhite:1.0 alpha:0.0] botColor:[UIColor colorWithWhite:1.0 alpha:1.0]];
    
    //recreate shadow
    [self createTopShadow];
}


- (void)setViewDistanceFromBottom:(CGFloat)viewDistanceFromBottom
{
    _viewDistanceFromBottom = viewDistanceFromBottom;
    
    [_foregroundView setFrame:CGRectOffset(_foregroundView.bounds, (_foregroundScrollView.frame.size.width - _foregroundView.bounds.size.width)/2, _foregroundScrollView.frame.size.height - _foregroundScrollView.contentInset.top - _viewDistanceFromBottom)];
    [_foregroundScrollView setContentSize:CGSizeMake(self.frame.size.width, _foregroundView.frame.origin.y + _foregroundView.frame.size.height)];
    
    //shadows
    [_botShadowLayer setFrame:CGRectOffset(_botShadowLayer.bounds, 0, self.frame.size.height - _viewDistanceFromBottom)];
}

- (void)setBackgroundImage:(UIImage *)backgroundImage overWriteBlur:(BOOL)overWriteBlur animated:(BOOL)animated duration:(NSTimeInterval)interval
{
    _backgroundImage = backgroundImage;
    if (backgroundImage && overWriteBlur) {
        _blurredBackgroundImage = [backgroundImage applyBlurWithRadius:DEFAULT_BLUR_RADIUS tintColor:DEFAULT_BLUR_TINT_COLOR saturationDeltaFactor:DEFAULT_BLUR_DELTA_FACTOR maskImage:nil];
    }
    
    if (animated) {
        CRMotionView *previousBackgroundImageView = _backgroundImageView;
        FXBlurView *previousBlurredBackgroundImageView = _blurredBackgroundImageView;
        [self createBackgroundImageView];
        
        [_backgroundImageView setAlpha:0];
        [_blurredBackgroundImageView setAlpha:0];
        
        // blur needs to get animated first if the background is blurred
        if (previousBlurredBackgroundImageView.alpha == 1) {
            [UIView animateWithDuration:interval animations:^{
                [_blurredBackgroundImageView setAlpha:previousBlurredBackgroundImageView.alpha];
            } completion:^(BOOL finished) {
                [_backgroundImageView setAlpha:previousBackgroundImageView.alpha];
                [previousBackgroundImageView removeFromSuperview];
                [previousBlurredBackgroundImageView removeFromSuperview];
            }];
        } else {
            [UIView animateWithDuration:interval animations:^{
                [_backgroundImageView setAlpha:previousBackgroundImageView.alpha];
                [_blurredBackgroundImageView setAlpha:previousBlurredBackgroundImageView.alpha];
            } completion:^(BOOL finished) {
                [previousBackgroundImageView removeFromSuperview];
                [previousBlurredBackgroundImageView removeFromSuperview];
            }];
        }
        
        
    } else {
        [_backgroundImageView setImage:_backgroundImage];
        [_backgroundImageView positionIndictatorToForegroundView:_foregroundView originY:locationName.frame.origin.y + locationName.frame.size.height + PADDING*2];
    }
}

- (void)setPhoto:(id<MWPhoto>)photo
{
    _photo = photo;
    [self foregroundView];
    
    [_foregroundView setFrame:CGRectOffset(_foregroundView.bounds, (_foregroundScrollView.frame.size.width - _foregroundView.bounds.size.width)/2, _foregroundScrollView.frame.size.height - _viewDistanceFromBottom)];
    
    [_foregroundScrollView setContentSize:CGSizeMake(self.frame.size.width, _foregroundView.frame.origin.y + _foregroundView.frame.size.height)];
}

- (void)blurBackground:(BOOL)shouldBlur
{
    [_blurredBackgroundImageView setAlpha:shouldBlur?1:0];
}

- (void)setBlurNeedDisplay:(UIImage*)img {
    UIImageView *imageView;
    if (((UIScreen*)[UIScreen mainScreen]).scale) {
        if (img.size.width <= 1280 || img.size.height <= 2272) {
            imageView = [[UIImageView alloc] initWithFrame:CGRectMake(-496, 0, 2272, 2272)];
            imageView.image = img;
        } else {
            imageView = [[UIImageView alloc] initWithFrame:CGRectMake(-140, 0, 1420, 2272)];
            imageView.image = img;
        }
    } else {
        if (img.size.width <= 640 || img.size.height <= 1136) {
            imageView = [[UIImageView alloc] initWithFrame:CGRectMake(-248, 0, 1136, 1136)];
            imageView.image = img;
        } else {
            imageView = [[UIImageView alloc] initWithFrame:CGRectMake(-70, 0, 710, 1136)];
            imageView.image = img;
        }
    }
    _blurredBackgroundImageView.underlyingView = imageView;
}

- (void)resetForegroundOffset
{
    [_foregroundScrollView setContentOffset:CGPointMake(0, 0)];
}

- (UIButton*)likeButton
{
    if (!likeButton) {
        likeButton = [[UIButton alloc] initWithFrame:CGRectMake(LEFT_ICON_PADDING, locationName.frame.origin.y + locationName.frame.size.height + PADDING*5, 0, 0)];
        [likeButton setImage:[UIImage imageNamed:@"Like"] forState:UIControlStateNormal];
        [likeButton sizeToFit];
        CGRect frame = likeButton.frame;
        frame.size = CGSizeMake(frame.size.width/2, frame.size.height/2);
        likeButton.frame = frame;
        
        [likeButton addTarget:self action:@selector(likeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    return likeButton;
}

- (UIButton*)commentButton
{
    if (!commentButton) {
        commentButton = [[UIButton alloc] initWithFrame:CGRectMake(LEFT_ICON_PADDING + likeButton.frame.size.width + PADDING*2, locationName.frame.origin.y + locationName.frame.size.height + PADDING*5, 0, 0)];
        [commentButton setImage:[UIImage imageNamed:@"Comment"] forState:UIControlStateNormal];
        [commentButton sizeToFit];
        CGRect frame = commentButton.frame;
        frame.size = CGSizeMake(frame.size.width/2, frame.size.height/2);
        commentButton.frame = frame;
        
        [commentButton addTarget:self action:@selector(commentButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    }
    return commentButton;
}

- (UIButton*)shareButton
{
    if (!shareButton) {
        shareButton = [[UIButton alloc] initWithFrame:CGRectMake(commentButton.frame.origin.x + commentButton.frame.size.width + PADDING*2, locationName.frame.origin.y + locationName.frame.size.height + PADDING*5, 0, 0)];
        [shareButton setImage:[UIImage imageNamed:@"SharePhoto"] forState:UIControlStateNormal];
        [shareButton sizeToFit];
        CGRect frame = shareButton.frame;
        frame.size = CGSizeMake(frame.size.width/2, frame.size.height/2);
        shareButton.frame = frame;
        
        [shareButton addTarget:self action:@selector(shareButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    return shareButton;
}

- (UIButton*)actionButton
{
    if (!actionButton) {
        actionButton = [[UIButton alloc] initWithFrame:        CGRectMake(CGRectGetWidth(self.bounds) - 55 - PADDING, locationName.frame.origin.y + locationName.frame.size.height + PADDING*5, 0, 0)];
        [actionButton setTitle:NSLocalizedString(@"● ● ●", @"Title for Action button") forState:UIControlStateNormal];
        [actionButton setBackgroundColor:[UIColor clearColor]];
        [actionButton setTitleColor:[UIColor colorWithWhite:0.9 alpha:0.9] forState:UIControlStateNormal];
        [actionButton setTitleColor:[UIColor colorWithWhite:0.9 alpha:0.9] forState:UIControlStateHighlighted];
        [actionButton.titleLabel setFont:[UIFont boldSystemFontOfSize:14.0f]];
        
        [actionButton sizeToFit];
        
        [actionButton addTarget:[_parentView getPhotoBrowser] action:@selector(actionButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    return actionButton;
}

#pragma mark - Actions

- (void)likeButtonPressed:(id)sender {
    [likeButton setUserInteractionEnabled:NO];
    PFObject *userLikeObject = ((MWPhoto*)self.photo).userLikeObject;
    PFObject *photo = ((MWPhoto*)self.photo).object;
    if (userLikeObject) {
        photo[@"likeCount"] = [NSString stringWithFormat:@"%d", [((NSString*)photo[@"likeCount"]) intValue] - 1];
        [likeButton setImage:[UIImage imageNamed:@"Like"] forState:UIControlStateNormal];
        [likeCount setText:photo[@"likeCount"] ?: @"0"];
        [likeCount sizeToFit];
        [userLikeObject deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (!error) {
                [photo saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (!error) {
                        ((MWPhoto*)self.photo).likeCount = photo[@"likeCount"];
                        ((MWPhoto*)self.photo).userLikeObject = nil;
                    } else {
                        photo[@"likeCount"] = [NSString stringWithFormat:@"%d", [((NSString*)photo[@"likeCount"]) intValue] + 1];
                        [likeButton setImage:[UIImage imageNamed:@"LikeRed"] forState:UIControlStateNormal];
                        [likeCount setText:photo[@"likeCount"] ?: @"0"];
                        [likeCount sizeToFit];
                    }
                    [likeButton setUserInteractionEnabled:YES];
                }];
            }
        }];
    } else {
        userLikeObject = [PFObject objectWithClassName:@"UserPhotoAction"];
        photo[@"likeCount"] = [NSString stringWithFormat:@"%d", [((NSString*)photo[@"likeCount"]) intValue] + 1];
        userLikeObject[@"user"] = [PFUser currentUser];
        userLikeObject[@"photo"] = photo;
        userLikeObject[@"like"] = [NSNumber numberWithBool:YES];
        [likeButton setImage:[UIImage imageNamed:@"LikeRed"] forState:UIControlStateNormal];
        [likeCount setText:photo[@"likeCount"] ?: @"0"];
        [likeCount sizeToFit];
        [userLikeObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (!error) {
                ((MWPhoto*)self.photo).likeCount = photo[@"likeCount"];
                ((MWPhoto*)self.photo).userLikeObject = userLikeObject;
            } else {
                photo[@"likeCount"] = [NSString stringWithFormat:@"%d", [((NSString*)photo[@"likeCount"]) intValue] - 1];
                [likeButton setImage:[UIImage imageNamed:@"Like"] forState:UIControlStateNormal];
                [likeCount setText:photo[@"likeCount"] ?: @"0"];
                [likeCount sizeToFit];
            }
            [likeButton setUserInteractionEnabled:YES];
        }];
    }
}

- (void)shareButtonPressed:(id)sender {
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Alert", nil) message:@"This functionality is not currently available"  delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
}


#pragma mark - Views creation
#pragma mark ScrollViews

- (void)createBackgroundView
{
    //background
    _backgroundScrollView = [[UIScrollView alloc] initWithFrame:self.frame];
    [_backgroundScrollView setUserInteractionEnabled:NO];
    [_backgroundScrollView setContentSize:CGSizeMake(self.frame.size.width + 2*DEFAULT_MAX_BACKGROUND_MOVEMENT_HORIZONTAL, self.frame.size.height + DEFAULT_MAX_BACKGROUND_MOVEMENT_VERTICAL)];
    [_backgroundScrollView setContentOffset:CGPointMake(DEFAULT_MAX_BACKGROUND_MOVEMENT_HORIZONTAL, 0)];
    [self addSubview:_backgroundScrollView];
    
    _constraitView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width + 2*DEFAULT_MAX_BACKGROUND_MOVEMENT_HORIZONTAL, self.frame.size.height + DEFAULT_MAX_BACKGROUND_MOVEMENT_VERTICAL)];
    [_backgroundScrollView addSubview:_constraitView];
    
    [self createBackgroundImageView];
}

- (void)createBackgroundImageView
{
    _backgroundImageView = [[CRMotionView alloc] initWithFrame:self.bounds image:_backgroundImage];
    [_backgroundImageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_backgroundImageView setContentMode:UIViewContentModeScaleAspectFill];
    [_constraitView addSubview:_backgroundImageView];
    _blurredBackgroundImageView = [[FXBlurView alloc] init];
    [_blurredBackgroundImageView setTintColor:[UIColor darkTextColor]];
    [_blurredBackgroundImageView setBlurRadius:40];
    [_blurredBackgroundImageView setUpdateInterval:0.3];
    _blurredBackgroundImageView.underlyingView = [[UIImageView alloc] initWithImage:_blurredBackgroundImage];
    [_blurredBackgroundImageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_blurredBackgroundImageView setContentMode:UIViewContentModeScaleAspectFill];
    [_blurredBackgroundImageView setAlpha:0];
    [_constraitView addSubview:_blurredBackgroundImageView];
    
    [_constraitView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_backgroundImageView]|" options:0 metrics:0 views:NSDictionaryOfVariableBindings(_backgroundImageView)]];
    [_constraitView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-150-[_backgroundImageView]" options:0 metrics:0 views:NSDictionaryOfVariableBindings(_backgroundImageView)]];
    [_constraitView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_blurredBackgroundImageView]|" options:0 metrics:0 views:NSDictionaryOfVariableBindings(_blurredBackgroundImageView)]];
    [_constraitView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_blurredBackgroundImageView]|" options:0 metrics:0 views:NSDictionaryOfVariableBindings(_blurredBackgroundImageView)]];
}

#warning TODO: figure out why commentView has to manually remove
- (void)dealloc {
    [commentView removeFromSuperview];
    commentView = nil;
    [self stopObservations];
}

- (UIView*)foregroundView
{
    if (!_foregroundView) {
        _foregroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 0)];
    
        UIImage *albumTitleImg = [UIImage imageNamed:@"AlbumTitleWhite"];
        UIImageView *albumTitleImgView = [[UIImageView alloc] initWithImage:albumTitleImg];
        [albumTitleImgView setFrame:CGRectMake(LEFT_ICON_PADDING, PADDING, albumTitleImgView.frame.size.width/2, albumTitleImgView.frame.size.height/2)];
        albumTitle = [[UILabel alloc] initWithFrame:CGRectMake(LEFT_ICON_PADDING + PADDING + albumTitleImgView.frame.size.width, PADDING, [[UIScreen mainScreen] bounds].size.width - LEFT_ICON_PADDING - albumTitleImgView.frame.size.width, albumTitleImgView.frame.size.height)];
        [albumTitle setFont:[UIFont fontWithName:@"AdelleSans-Light" size:16]];
        [albumTitle setTextColor:[UIColor whiteColor]];
        [albumTitle setShadowColor:[UIColor blackColor]];
        [albumTitle setShadowOffset:CGSizeMake(1, 1)];
    
        [_foregroundView addSubview:albumTitleImgView];
        [_foregroundView addSubview:albumTitle];
    
        UIImage *locaitonImg = [UIImage imageNamed:@"PlaceXSmall"];
        UIImageView *locationImgView = [[UIImageView alloc] initWithImage:locaitonImg];
        [locationImgView setFrame:CGRectMake(LEFT_SMALL_ICON_PADDING, PADDING + albumTitleImgView.frame.size.height + PADDING, locationImgView.frame.size.width/2, locationImgView.frame.size.height/2)];
        locationName = [[UILabel alloc] initWithFrame:CGRectMake(LEFT_SMALL_ICON_PADDING + 5 + PADDING + locationImgView.frame.size.width, albumTitleImgView.frame.origin.y + albumTitleImgView.frame.size.height + PADDING, 320 - LEFT_SMALL_ICON_PADDING - locationImgView.frame.size.width, albumTitle.frame.size.height)];
        [locationName setFont:[UIFont fontWithName:@"AdelleSans-Light" size:16]];
        [locationName setTextColor:[UIColor whiteColor]];
        [locationName setShadowColor:[UIColor blackColor]];
        [locationName setShadowOffset:CGSizeMake(1, 1)];
    
        [_foregroundView addSubview:locationImgView];
        [_foregroundView addSubview:locationName];
        
        [_foregroundView addSubview:[self actionButton]];
        [_foregroundView addSubview:[self likeButton]];
        [_foregroundView addSubview:[self commentButton]];
        [_foregroundView addSubview:[self shareButton]];
    }
    
    if (((MWPhoto*)self.photo).userLikeObject) {
        [likeButton setImage:[UIImage imageNamed:@"LikeRed"] forState:UIControlStateNormal];
    } else {
        [likeButton setImage:[UIImage imageNamed:@"Like"] forState:UIControlStateNormal];
    }
    
    [albumTitle setText:((MWPhoto*)self.photo).albumTitle];
    [locationName setText:((MWPhoto*)self.photo).locationName];

    if (!likeName) {
        likeName = [[UILabel alloc] initWithFrame:CGRectMake(actionButton.frame.origin.x - PADDING*14, locationName.frame.origin.y + locationName.frame.size.height + PADDING*5, 0, 0)];
        [likeName setFont:[UIFont fontWithName:@"AdelleSans-Light" size:12]];
        [likeName setTextColor:[UIColor whiteColor]];
        [likeName setShadowColor:[UIColor blackColor]];
        [likeName setShadowOffset:CGSizeMake(1, 1)];
        [likeName setText:@"likes"];
        [likeName sizeToFit];
        [_foregroundView addSubview:likeName];
    }
    
    if (!likeCount) {
        likeCount = [[UILabel alloc] initWithFrame:CGRectMake(likeName.frame.origin.x - PADDING, locationName.frame.origin.y + locationName.frame.size.height + PADDING*5, 0, 0)];
        [likeCount setFont:[UIFont fontWithName:@"AdelleSans-Light" size:12]];
        [likeCount setTextColor:[UIColor whiteColor]];
        [likeCount setShadowColor:[UIColor blackColor]];
        [likeCount setShadowOffset:CGSizeMake(1, 1)];
        [_foregroundView addSubview:likeCount];
    } else {
        [likeCount setFrame:CGRectMake(likeName.frame.origin.x - PADDING, locationName.frame.origin.y + locationName.frame.size.height + PADDING*5, 0, 0)];
    }

    [likeCount setText:((MWPhoto*)self.photo).likeCount ?: @"0"];
    [likeCount sizeToFit];
    CGRect frame = likeCount.frame;
    frame.origin.x = frame.origin.x - frame.size.width;
    likeCount.frame = frame;
    
    if (!commentName) {
        commentName = [[UILabel alloc] initWithFrame:CGRectMake(actionButton.frame.origin.x - PADDING*14, locationName.frame.origin.y + locationName.frame.size.height + PADDING*4 + likeCount.frame.size.height + PADDING, 0, 0)];
        [commentName setFont:[UIFont fontWithName:@"AdelleSans-Light" size:12]];
        [commentName setTextColor:[UIColor whiteColor]];
        [commentName setShadowColor:[UIColor blackColor]];
        [commentName setShadowOffset:CGSizeMake(1, 1)];
        [commentName setText:@"comments"];
        [_foregroundView addSubview:commentName];
    } else {
        [commentName setFrame:CGRectMake(actionButton.frame.origin.x - PADDING*14, locationName.frame.origin.y + locationName.frame.size.height + PADDING*4 + likeCount.frame.size.height + PADDING, 0, 0)];
    }
    
    [commentName sizeToFit];

    if (!commentCount) {
        commentCount = [[UILabel alloc] initWithFrame:CGRectMake(commentName.frame.origin.x - PADDING, locationName.frame.origin.y + locationName.frame.size.height + PADDING*4 + likeCount.frame.size.height + PADDING, 0, 0)];
        [commentCount setFont:[UIFont fontWithName:@"AdelleSans-Light" size:12]];
        [commentCount setTextColor:[UIColor whiteColor]];
        [commentCount setShadowColor:[UIColor blackColor]];
        [commentCount setShadowOffset:CGSizeMake(1, 1)];
        [_foregroundView addSubview:commentCount];
    } else {
        [commentCount setFrame:CGRectMake(commentName.frame.origin.x - PADDING, locationName.frame.origin.y + locationName.frame.size.height + PADDING*4 + likeCount.frame.size.height + PADDING, 0, 0)];
    }
    
    [commentCount setText:((MWPhoto*)self.photo).commentCount ?: @"0"];
    [commentCount sizeToFit];
    frame = commentCount.frame;
    frame.origin.x = frame.origin.x - frame.size.width;
    commentCount.frame = frame;
    
    if (!description) {
        
        descriptionBox = [[UIView alloc] initWithFrame:CGRectMake(PADDING, commentCount.frame.origin.y + commentCount.frame.size.height + PADDING*4, [[UIScreen mainScreen] bounds].size.width - PADDING*2, 0)];
        descriptionBox.layer.cornerRadius = 3;
        descriptionBox.backgroundColor = [UIColor colorWithWhite:0 alpha:.3];
        
        UITapGestureRecognizer *_tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(descriptionTapped:)];
        [descriptionBox addGestureRecognizer:_tapRecognizer];
        
        description = [[UILabel alloc] initWithFrame:CGRectMake(PADDING, PADDING*2, [[UIScreen mainScreen] bounds].size.width - PADDING*4, 0)];
        [description setFont:[UIFont fontWithName:@"AdelleSans-Light" size:12]];
        [description setTextColor:[UIColor whiteColor]];
        [description setShadowColor:[UIColor blackColor]];
        [description setShadowOffset:CGSizeMake(1, 1)];
        [description setNumberOfLines:0];

        [descriptionBox addSubview:description];
        [_foregroundView addSubview:descriptionBox];
    } else {
        [descriptionBox setFrame:CGRectMake(PADDING, commentCount.frame.origin.y + commentCount.frame.size.height + PADDING*4, [[UIScreen mainScreen] bounds].size.width - PADDING*2, 0)];
        [description setFrame:CGRectMake(PADDING, PADDING*2, [[UIScreen mainScreen] bounds].size.width - PADDING*4, 0)];
    }
    
    [description setText:((MWPhoto*)self.photo).photoDescription ?: @"No Description"];
    [description sizeToFit];
    frame = descriptionBox.frame;
    frame.size.height = description.frame.origin.y*2 + description.frame.size.height;
    descriptionBox.frame = frame;
    
    MKMapView *mapView = [InstagramEngine sharedEngine].mapView;
//    [mapView removeFromSuperview];
    [mapView setFrame:CGRectMake(PADDING, descriptionBox.frame.origin.y + descriptionBox.frame.size.height + PADDING*4, [[UIScreen mainScreen] bounds].size.width - PADDING*2, 150)];
//    [_foregroundView addSubview:mapView];
    
    CLLocationCoordinate2D picLocation;
    picLocation.latitude = [((MWPhoto*)self.photo).latitude floatValue];
    picLocation.longitude= [((MWPhoto*)self.photo).longitude floatValue];
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(picLocation, 0.5*METERS_PER_MILE, 0.5*METERS_PER_MILE);
    
    MKPointAnnotation *locationAnnotation = [[MKPointAnnotation alloc] init];
    [locationAnnotation setCoordinate:picLocation];
    [mapView setRegion:viewRegion];
    [mapView addAnnotation:locationAnnotation];
    
#warning TODO: rewrite EBCommentView so this commentView doesn't get recreated everytime
// Also need to calculate the height more efficiently
// Potentially memory leak problem
// Add maximum height so it will get more comments that way
    [commentView removeFromSuperview];
    commentView = [[EBCommentsView alloc] initWithFrame:CGRectMake(0, 0, 310, ((MWPhoto*)self.photo).comments.count * 64.08 + 40)];
    [commentView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [commentView.tableView setDataSource:self];
    [commentView.tableView setDelegate:self];
    [commentView.tableView setScrollEnabled:NO];
    [commentView setCommentCellHighlightColor:[UIColor colorWithWhite:0.99 alpha:0.35]];
    
    static NSString *CellReuseIdentifier= @"Cell";
    [commentView.tableView registerClass:[EBCommentCell class] forCellReuseIdentifier:CellReuseIdentifier];
    [commentView.commentTextView setDelegate:self];
    [commentView setCommentsDelegate:self];
    
    if (!commentBox) {
        commentBox = [[UIView alloc] initWithFrame:CGRectMake(PADDING, mapView.frame.origin.y + mapView.frame.size.height + PADDING*4, [[UIScreen mainScreen] bounds].size.width - PADDING*2, 0)];
        commentBox.layer.cornerRadius = 3;
        commentBox.backgroundColor = [UIColor colorWithWhite:0 alpha:.3];
        [commentBox addSubview:commentView];
        [_foregroundView addSubview:commentBox];
    } else {
        [commentBox setFrame:CGRectMake(PADDING, mapView.frame.origin.y + mapView.frame.size.height + PADDING*4, [[UIScreen mainScreen] bounds].size.width - PADDING*2, 0)];
        [commentBox addSubview:commentView];
    }
    
    [commentView setNeedsLayout];
    
    frame = commentBox.frame;
    frame.size.height = commentView.frame.size.height;
    commentBox.frame = frame;
    
    frame = _foregroundView.frame;
    frame.size.height = commentBox.frame.origin.y + commentBox.frame.size.height + PADDING*2;
    _foregroundView.frame = frame;
    
    return _foregroundView;
}

- (void)createForegroundView
{
    [self foregroundView];
    
    _foregroundContainerView = [[UIView alloc] initWithFrame:self.frame];
    [self addSubview:_foregroundContainerView];
    
    _foregroundScrollView = [[UIScrollView alloc] initWithFrame:self.frame];
    [_foregroundScrollView setDelegate:self];
    [_foregroundScrollView setShowsVerticalScrollIndicator:NO];
    [_foregroundScrollView setShowsHorizontalScrollIndicator:NO];
    [_foregroundContainerView addSubview:_foregroundScrollView];
    
    UITapGestureRecognizer *singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(foregroundTapped:)];
    singleTapRecognizer.numberOfTapsRequired = 1;
    [_foregroundScrollView addGestureRecognizer:singleTapRecognizer];
    
    UITapGestureRecognizer *doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    doubleTapRecognizer.numberOfTapsRequired = 2;
    [_foregroundScrollView addGestureRecognizer:doubleTapRecognizer];
    
    [singleTapRecognizer requireGestureRecognizerToFail:doubleTapRecognizer];
    
    [_foregroundView setFrame:CGRectOffset(_foregroundView.bounds, (_foregroundScrollView.frame.size.width - _foregroundView.bounds.size.width)/2, _foregroundScrollView.frame.size.height - _viewDistanceFromBottom)];
    [_foregroundScrollView addSubview:_foregroundView];
    
    [_foregroundScrollView setContentSize:CGSizeMake(self.frame.size.width, _foregroundView.frame.origin.y + _foregroundView.frame.size.height)];
}

- (void)addMapView {
    MKMapView *mapView = [InstagramEngine sharedEngine].mapView;
    [mapView removeFromSuperview];
    [_foregroundView addSubview:mapView];
}

#pragma mark Shadow and Mask Layer
- (CALayer *)createTopMaskWithSize:(CGSize)size startFadeAt:(CGFloat)top endAt:(CGFloat)bottom topColor:(UIColor *)topColor botColor:(UIColor *)botColor;
{
    top = top/size.height;
    bottom = bottom/size.height;
    
    CAGradientLayer *maskLayer = [CAGradientLayer layer];
    maskLayer.anchorPoint = CGPointZero;
    maskLayer.startPoint = CGPointMake(0.5f, 0.0f);
    maskLayer.endPoint = CGPointMake(0.5f, 1.0f);
    
    //an array of colors that dictatates the gradient(s)
    maskLayer.colors = @[(id)topColor.CGColor, (id)topColor.CGColor, (id)botColor.CGColor, (id)botColor.CGColor];
    maskLayer.locations = @[@0.0, @(top), @(bottom), @1.0f];
    maskLayer.frame = CGRectMake(0, 0, size.width, size.height);
    
    return maskLayer;
}

- (void)createTopShadow
{
    //changing the top shadow
    [_topShadowLayer removeFromSuperlayer];
    _topShadowLayer = [self createTopMaskWithSize:CGSizeMake(_foregroundContainerView.frame.size.width, _foregroundScrollView.contentInset.top + DEFAULT_TOP_FADING_HEIGHT_HALF) startFadeAt:_foregroundScrollView.contentInset.top - DEFAULT_TOP_FADING_HEIGHT_HALF endAt:_foregroundScrollView.contentInset.top + DEFAULT_TOP_FADING_HEIGHT_HALF topColor:[UIColor colorWithWhite:0 alpha:.15] botColor:[UIColor colorWithWhite:0 alpha:0]];
    [self.layer insertSublayer:_topShadowLayer below:_foregroundContainerView.layer];
}
- (void)createBottomShadow
{
    [_botShadowLayer removeFromSuperlayer];
    _botShadowLayer = [self createTopMaskWithSize:CGSizeMake(self.frame.size.width,_viewDistanceFromBottom) startFadeAt:0 endAt:_viewDistanceFromBottom topColor:[UIColor colorWithWhite:0 alpha:0] botColor:[UIColor colorWithWhite:0 alpha:.8]];
    [_botShadowLayer setFrame:CGRectOffset(_botShadowLayer.bounds, 0, self.frame.size.height - _viewDistanceFromBottom)];
    [self.layer insertSublayer:_botShadowLayer below:_foregroundContainerView.layer];
}


#pragma mark - Button

- (void)handleTap:(UITapGestureRecognizer *)gesture
{
    [_backgroundImageView handleTap:gesture];
    if ([_backgroundImageView isInZoom]) {
        [_blurredBackgroundImageView setAlpha:0];
        [_foregroundScrollView setContentOffset:CGPointMake(0, 0 - _foregroundScrollView.contentInset.top) animated:YES];
    } else {
        [_foregroundScrollView setContentOffset:CGPointMake(0, 0 - _foregroundScrollView.contentInset.top) animated:YES];
    }
}

- (void)foregroundTapped:(UITapGestureRecognizer *)tapRecognizer
{
    //TODO: eventually find a better way to handle this problem
    if ([likeButton isUserInteractionEnabled]) {
        CGPoint tappedPoint = [tapRecognizer locationInView:_foregroundScrollView];
        if (tappedPoint.y < _foregroundScrollView.frame.size.height) {
            CGFloat ratio = _foregroundScrollView.contentOffset.y == -_foregroundScrollView.contentInset.top? 1:0;
            //        [_foregroundScrollView setContentOffset:CGPointMake(0, ratio * _foregroundView.frame.origin.y - _foregroundScrollView.contentInset.top) animated:YES];
            [_foregroundScrollView setContentOffset:CGPointMake(0, ratio * (_foregroundView.frame.origin.y + _foregroundView.frame.size.height - 568) - _foregroundScrollView.contentInset.top) animated:YES];
        }
    }
}

- (void)descriptionTapped:(UITapGestureRecognizer *)tapRecognizer
{
    // NOTE: maxCount = 0 to hide count
    YIPopupTextView* popupTextView = [[YIPopupTextView alloc] initWithPlaceHolder:@"Enter your story" maxCount:1000 buttonStyle:YIPopupTextViewButtonStyleRightCancelAndDone];
    popupTextView.delegate = self;
    popupTextView.caretShiftGestureEnabled = YES;   // default = NO
    
    [popupTextView showInView:self];
    [_parentView.backButton setHidden:YES];
}

- (void)popupTextView:(YIPopupTextView*)textView willDismissWithText:(NSString*)text cancelled:(BOOL)cancelled {
    if (!cancelled) {
        PFObject *photo = ((MWPhoto*)self.photo).object;
        photo[@"description"] = text;
        [photo saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (!error) {
                ((MWPhoto*)self.photo).photoDescription = text;
                [self foregroundView];
                [_foregroundView setFrame:CGRectOffset(_foregroundView.bounds, (_foregroundScrollView.frame.size.width - _foregroundView.bounds.size.width)/2, _foregroundScrollView.frame.size.height - _viewDistanceFromBottom)];
                
                [_foregroundScrollView setContentSize:CGSizeMake(self.frame.size.width, _foregroundView.frame.origin.y + _foregroundView.frame.size.height)];
            }
        }];
    }
    [_parentView.backButton setHidden:NO];
}

- (void)commentButtonTapped:(id)sender
{
    [_foregroundScrollView setContentOffset:CGPointMake(0, _foregroundView.frame.origin.y + _foregroundView.frame.size.height - 568 - _foregroundScrollView.contentInset.top) animated:YES];
    [commentView.commentTextView becomeFirstResponder];
}

#pragma mark - Delegate
#pragma mark UIScrollView
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == self.foregroundScrollView) {
        //translate into ratio to height
        CGFloat ratio = (scrollView.contentOffset.y + _foregroundScrollView.contentInset.top)/(_foregroundScrollView.frame.size.height - _foregroundScrollView.contentInset.top - _viewDistanceFromBottom);
        ratio = ratio<0?0:ratio;
        ratio = ratio>1?1:ratio;
        
        //set background scroll
        [_backgroundScrollView setContentOffset:CGPointMake(DEFAULT_MAX_BACKGROUND_MOVEMENT_HORIZONTAL, ratio * DEFAULT_MAX_BACKGROUND_MOVEMENT_VERTICAL)];
        
        if (![_backgroundImageView isInZoom]) {
            //set alpha
            [_blurredBackgroundImageView setAlpha:ratio];
            if (ratio == 0) {
                if (![_backgroundImageView isMotionEnabled]) {
                    [_backgroundImageView setMotionEnabled:YES];
                }
            } else {
                if ([_backgroundImageView isMotionEnabled]) {
                    [_backgroundImageView setMotionEnabled:NO];
                }
            }
        }
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    
//    CGPoint point = *targetContentOffset;
//    CGFloat ratio = (point.y + _foregroundScrollView.contentInset.top)/(_foregroundScrollView.frame.size.height - _foregroundScrollView.contentInset.top - _viewDistanceFromBottom);
//    
//    //it cannot be inbetween 0 to 1 so if it is >.5 it is one, otherwise 0
//    if (ratio > 0 && ratio < 1) {
//        if (velocity.y == 0) {
//            ratio = ratio > .5?1:0;
//        }else if(velocity.y > 0){
//            ratio = ratio > .1?1:0;
//        }else{
//            ratio = ratio > .9?1:0;
//        }
//        targetContentOffset->y = ratio * _foregroundView.frame.origin.y - _foregroundScrollView.contentInset.top;
//    }
//    
}

#pragma mark - Comments Tableview Datasource & Delegate


- (void)deleteCellWithNotification:(NSNotification *)notification
{
    UITableViewCell *cell = notification.object;
    
    if([cell isKindOfClass:[UITableViewCell class]] == NO){
        return;
    }
    
    NSIndexPath *indexPath = [commentView.tableView indexPathForCell:cell];
    
    if(indexPath) {
        NSMutableArray *remainingComments = [NSMutableArray arrayWithArray:((MWPhoto*)self.photo).comments];
        [remainingComments removeObjectAtIndex:indexPath.row];
        ((MWPhoto*)self.photo).comments = [NSMutableArray arrayWithArray:remainingComments];
        
        [commentView.tableView beginUpdates];
        [commentView.tableView deleteRowsAtIndexPaths:@[indexPath]
                                           withRowAnimation:UITableViewRowAnimationLeft];
        [commentView.tableView endUpdates];
    
        id<EBPhotoCommentProtocol>deletedComment = ((MWPhoto*)self.photo).comments[indexPath.row];
        [self.delegate2 photoViewController:self didDeleteComment:deletedComment];
        
        [commentView.tableView reloadData];
    
    }
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return ((MWPhoto*)self.photo).comments.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    EBCommentCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    id <EBPhotoCommentProtocol> comment = ((MWPhoto*)self.photo).comments[indexPath.row];
    NSAssert([comment conformsToProtocol:@protocol(EBPhotoCommentProtocol)],
             @"Comment objects must conform to the EBPhotoCommentProtocol.");
    [self configureCell:cell
         atRowIndexPath:indexPath
            withComment:comment];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    const CGFloat MinimumRowHeight = 60;
    
    id<EBPhotoCommentProtocol> comment = ((MWPhoto*)self.photo).comments[indexPath.row];
    CGFloat rowHeight = 0;
    NSString *textForRow = nil;
    
    if([comment respondsToSelector:@selector(attributedCommentText)] &&
       [comment attributedCommentText]){
        textForRow = [[comment attributedCommentText] string];
    } else {
        textForRow = [comment commentText];
    }
    
    //Get values from the comment cell itself, as an abstract class perhaps.
    //OR better, from reference cells dequeued from the table
    //http://stackoverflow.com/questions/10239040/dynamic-uilabel-heights-widths-in-uitableviewcell-in-all-orientations
    /*
     NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:textForRow attributes:@{NSFontAttributeName:@"HelveticaNeue-Light"}];
     
     CGRect textViewRect = [attributedText boundingRectWithSize:(CGSize){285, CGFLOAT_MAX}
     options:NSStringDrawingUsesLineFragmentOrigin
     context:nil];
     CGSize textViewSize = textViewRect.size;
     */
    
    CGRect textViewSize = [textForRow boundingRectWithSize:CGSizeMake(285, 1000) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Bold" size:16]} context:nil];
    CGFloat textViewHeight = 25;
    const CGFloat additionalSpace = MinimumRowHeight - textViewHeight + 10;
    
    rowHeight = textViewSize.size.height + additionalSpace;
    
    return rowHeight;
}

- (void)configureCell:(EBCommentCell *)cell
       atRowIndexPath:(NSIndexPath *)indexPath
          withComment:(id<EBPhotoCommentProtocol>)comment
{
    EBCommentsView *commentsView = [self.delegate2 commentsViewForPhotoViewController:self];
    
    BOOL configureCell = [self.delegate2 respondsToSelector:@selector(photoViewController:shouldConfigureCommentCell:forRowAtIndexPath:withComment:)] ?
    [self.delegate2 photoViewController:self shouldConfigureCommentCell:cell forRowAtIndexPath:indexPath withComment:comment] : YES;
    
    if([cell isKindOfClass:[EBCommentCell class]] && configureCell){
        [cell setComment:comment];
        [cell setHighlightColor:commentsView.commentCellHighlightColor];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [cell setBackgroundColor:[UIColor clearColor]];
}

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    if (action == @selector(copy:)) {
        return YES;
    }
    
    if (action == @selector(delete:)) {
        id<EBPhotoCommentProtocol> commentToDelete = ((MWPhoto*)self.photo).comments[indexPath.row];
        if([self.delegate2 photoViewController:self
                             canDeleteComment:commentToDelete]){
            return YES;
        }
    }
    
    return NO;
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    if (action == @selector(copy:)) {
        id<EBPhotoCommentProtocol> comment = ((MWPhoto*)self.photo).comments[indexPath.row];
        NSString *copiedText = nil;
        if([comment respondsToSelector:@selector(attributedCommentText)]){
            copiedText = [[comment attributedCommentText] string];
        }
        
        if(copiedText == nil){
            copiedText = [comment commentText];
        }
        
        [[UIPasteboard generalPasteboard] setString:copiedText];
    } else if (action == @selector(delete:)) {
        [self tableView:tableView
     commitEditingStyle:UITableViewCellEditingStyleDelete
      forRowAtIndexPath:indexPath];
    }
}


- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSMutableArray *remainingComments = [NSMutableArray arrayWithArray:((MWPhoto*)self.photo).comments];
        [remainingComments removeObjectAtIndex:indexPath.row];
        ((MWPhoto*)self.photo).comments = [NSMutableArray arrayWithArray:remainingComments];
        
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        id<EBPhotoCommentProtocol>deletedComment = ((MWPhoto*)self.photo).comments[indexPath.row];
        [self.delegate2 photoViewController:self didDeleteComment:deletedComment];
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
}

#pragma mark - Comments View Delegate

- (void)commentsView:(id)view didPostNewComment:(NSString *)commentText
{
    [self.delegate2 photoViewController:self didPostNewComment:commentText];
}

#pragma mark - EBPhotoViewControllerDelegate

- (void)photoViewController:(BTGlassScrollView *)controller didPostNewComment:(NSString *)comment
{
    PFObject *photo = ((MWPhoto*)self.photo).object;
    photo[@"commentCount"] = [NSString stringWithFormat:@"%d", [((NSString*)photo[@"commentCount"]) intValue] + 1];
    
    PFObject *commentObject = [PFObject objectWithClassName:@"UserPhotoAction"];
    commentObject[@"user"] = [PFUser currentUser];
    commentObject[@"photo"] = photo;
    commentObject[@"comment"] = comment;
    [commentObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            MWComment *comment = [[MWComment alloc] init];
            comment.text = commentObject[@"comment"];
            comment.date = commentObject.createdAt;
            comment.user = commentObject[@"user"];
            if (!((MWPhoto*)self.photo).comments) {
                ((MWPhoto*)self.photo).comments = [[NSMutableArray alloc] init];
            }
            [((MWPhoto*)self.photo).comments addObject:comment];
            ((MWPhoto*)self.photo).commentCount = photo[@"commentCount"];
            [self loadCommentsForScrollView];
        }
    }];
}

- (void)loadCommentsForScrollView {
    [self foregroundView];
    
    [_foregroundView setFrame:CGRectOffset(_foregroundView.bounds, (_foregroundScrollView.frame.size.width - _foregroundView.bounds.size.width)/2, _foregroundScrollView.frame.size.height - _viewDistanceFromBottom)];
    
    [_foregroundScrollView setContentSize:CGSizeMake(self.frame.size.width, _foregroundView.frame.origin.y + _foregroundView.frame.size.height)];
}

- (BOOL)photoViewController:(BTGlassScrollView *)controller
           canDeleteComment:(id<EBPhotoCommentProtocol>)comment
{
    #warning TODO: current users and profile match
    return YES;
}

- (void)photoViewController:(BTGlassScrollView *)controller
           didDeleteComment:(id<EBPhotoCommentProtocol>)comment {
    [self loadCommentsForScrollView];
}

- (EBCommentsView *)commentsViewForPhotoViewController:(BTGlassScrollView *)controller {
    return commentView;
}

- (BOOL)photoViewController:(BTGlassScrollView *)controller
 shouldConfigureCommentCell:(EBCommentCell *)cell
          forRowAtIndexPath:(NSIndexPath *)indexPath
                withComment:(id<EBPhotoCommentProtocol>)comment {
    return YES;
}

#pragma mark - UITextView Delegate


- (BOOL)textViewShouldEndEditing:(UITextView *)textView
{
    //clear out text
    [textView setText:nil];
    return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
//    [[NSNotificationCenter defaultCenter] postNotificationName:EBPhotoViewControllerDidBeginCommentingNotification object:self];
}


- (void)textViewDidEndEditing:(UITextView *)textView
{
//    [[NSNotificationCenter defaultCenter] postNotificationName:EBPhotoViewControllerDidEndCommentingNotification object:self];
    
    [commentView setInputPlaceholderEnabled:YES];
    [commentView setPostButtonHidden:YES];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    //check message length
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView
{
    if(textView.isFirstResponder){
        if(textView.text == nil || [textView.text isEqualToString:@""]){
            [commentView setPostButtonHidden:YES];
            [commentView setInputPlaceholderEnabled:YES];
        } else {
            [commentView setPostButtonHidden:NO];
            [commentView setInputPlaceholderEnabled:NO];
        }
    }
}

#pragma mark - Keyboard Handling

- (void)keyboardDidChangeFrame:(NSNotification *)notification
{
    NSDictionary* info = [notification userInfo];
    CGRect keyboardFrame = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSValue* value = [info objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval duration;
    [value getValue:&duration];
    
    //NSLog(@"Keyboard frame with conversion is %f,%f,%f,%f", keyboardFrame.origin.x, keyboardFrame.origin.y, keyboardFrame.size.width, keyboardFrame.size.height);
    
    CGPoint newCenter = CGPointMake(_foregroundScrollView.frame.size.width*0.5,
                                    keyboardFrame.origin.y - (_foregroundScrollView.frame.size.height*0.5));
    [UIView animateWithDuration:duration
                          delay:0
                        options:UIViewAnimationCurveEaseOut|
     UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [_foregroundScrollView setCenter:newCenter];
                     }completion:nil];
    
    [_parentView.backButton removeTarget:[_parentView getPhotoBrowser] action:@selector(doneButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [_parentView.backButton addTarget:self action:@selector(doneButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)doneButtonPressed:(id)sender
{
    [commentView.commentTextView resignFirstResponder];
}

- (void)keyboardWillBeHidden:(NSNotification*)notification
{
    NSDictionary* info = [notification userInfo];
    //CGSize keyboardSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    NSValue* value = [info objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval duration;
    [value getValue:&duration];
    
    CGPoint newCenter = CGPointMake(_foregroundScrollView.frame.size.width*0.5,
                                    _foregroundScrollView.frame.size.height*0.5);
    
    //This happens because of TAGS
    [UIView animateWithDuration:duration
                          delay:0
                        options:UIViewAnimationCurveEaseOut|UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         [_foregroundScrollView setCenter:newCenter];
                     }completion:nil];
    
    [_parentView.backButton addTarget:[_parentView getPhotoBrowser] action:@selector(doneButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [_parentView.backButton removeTarget:self action:@selector(doneButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
}



@end
