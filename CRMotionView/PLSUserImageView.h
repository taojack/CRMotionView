//
//  PLSUserImageView.h
//  Pods
//
//  Created by Shih-Chieh Tao on 12/11/14.
//
//

#import <UIKit/UIKit.h>
#import "Parse.h"
#import "MWPhotoBrowser.h"

@interface PLSUserImageView : UIImageView

@property (nonatomic, strong)PFUser *user;
@property (nonatomic, weak)MWPhotoBrowser *browser;

@end
