//
//  RSSEntry.h
//  RSSReader
//
//  Created by Oleg on 16.12.15.
//  Copyright © 2015 Oleg. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RSSEntry : NSObject

@property NSString *blogTitle;
@property NSString *articleTitle;
@property NSString *articleUrl;
@property NSDate *articleDate;


- (id)initWithBlogTitle:(NSString*)blogTitle articleTitle:(NSString*)articleTitle articleUrl:(NSString*)articleUrl articleDate:(NSDate*)articleDate;

@end
