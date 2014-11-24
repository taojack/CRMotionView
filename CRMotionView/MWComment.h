//
//  MWComment.h
//  Pods
//
//  Created by Shih-Chieh Tao on 11/20/14.
//
//

#import <Foundation/Foundation.h>
#import "EBPhotoCommentProtocol.h"
#import <Parse.h>

@interface MWComment : NSObject <EBPhotoCommentProtocol>

+ (instancetype)commentWithProperties:(NSDictionary*)commentInfo;
- (id)initWithProperties:(NSDictionary *)commentInfo;

@property (strong) NSAttributedString *attributedText;
@property (strong) NSString *text;
@property (strong) NSDate *date;
@property (strong) PFUser *user;
@property (strong) UIImage *image;
@property (strong) NSDictionary *metaData;

@end
