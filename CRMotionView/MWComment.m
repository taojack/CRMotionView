//
//  MWComment.m
//  Pods
//
//  Created by Shih-Chieh Tao on 11/20/14.
//
//

#import "MWComment.h"
#import "SDWebImageManager.h"

@implementation MWComment

+ (instancetype)commentWithProperties:(NSDictionary*)commentInfo
{
    return [[MWComment alloc] initWithProperties:commentInfo];
}

- (id)initWithProperties:(NSDictionary *)commentInfo
{
    self = [super init];
    if (self) {
        [self setText:commentInfo[@"commentText"]];
        [self setAttributedText:commentInfo[@"attributedCommentText"]];
        [self setDate:commentInfo[@"commentDate"]];
        [self setUser:commentInfo[@"user"]];
        [self setImage:commentInfo[@"authorImage"]];
        [self setMetaData:commentInfo[@"metaData"]];
    }
    return self;
}

- (NSAttributedString *)attributedCommentText
{
    return self.attributedText;
}

- (NSString *)commentText
{
    return self.text;
}

//This is the date when the comment was posted.
- (NSDate *)postDate
{
//    return self.date;
    return nil;
}

//This is the name that will be displayed for whoever posted the comment.
- (NSString *)authorName
{
    return self.user[@"fullname"];
}

//This is an image of the person who posted the comment
- (NSString *)authorAvatar
{
    return self.user[@"profileThumbUrl"];
}

- (NSDictionary *)metaInfo
{
    NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:self.user, @"user", nil];
    return dict;
}

@end
