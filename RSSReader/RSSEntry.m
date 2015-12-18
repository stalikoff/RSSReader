//
//  RSSEntry.m
//  RSSReader
//
//  Created by Oleg on 16.12.15.
//  Copyright © 2015 Oleg. All rights reserved.
//

#import "RSSEntry.h"

@implementation RSSEntry

- (id)initWithBlogTitle:(NSString*)blogTitle articleTitle:(NSString*)articleTitle articleUrl:(NSString*)articleUrl articleDate:(NSDate*)articleDate
{
    if ((self = [super init])) {
        _blogTitle = blogTitle;
        _articleTitle = articleTitle;
        _articleUrl = articleUrl;
        _articleDate = articleDate;
    }
    return self;
}


@end
