//
//  UIScrollView+CRScrollIndicator.h
//  CRMotionView
//
//  Created by Christian Roman on 07/02/14.
//  Copyright (c) 2014 Christian Roman. All rights reserved.
//

#import <UIKit/UIKit.h>

#define BACKGROUND_VIEW_SCROLL_INDICTATOR @"BACKGROUND_VIEW_SCROLL_INDICTATOR"
#define VIEW_SCROLL_INDICTATOR            @"VIEW_SCROLL_INDICTATOR"

@interface UIScrollView (CRScrollIndicator)

- (NSMutableDictionary*)cr_enableScrollIndicatorInCurrentView:(BOOL)inCurrentView;
- (void)cr_disableScrollIndicator;
- (void)cr_refreshScrollIndicator;

@end
