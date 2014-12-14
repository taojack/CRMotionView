//
//  PLSUserButton.h
//  Pods
//
//  Created by Shih-Chieh Tao on 12/12/14.
//
//

#import <UIKit/UIKit.h>
#import "Parse.h"
#import "MWPhotoBrowser.h"

@interface PLSUserButton : UIButton

@property (nonatomic, strong)PFUser *user;
@property (nonatomic, strong)MWPhotoBrowser *browser;

@end
