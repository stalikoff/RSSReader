//
//  UIColor+RSSReader.m
//  RSSReader
//
//  Created by Oleg on 19.12.15.
//  Copyright © 2015 Oleg. All rights reserved.
//

#import "UIColor+RSSReader.h"

@implementation UIColor (RSSReader)

+(UIColor *)unreadDateColor { return [UIColor grayColor]; }
+(UIColor *)unreadTitleColor { return [UIColor blackColor]; }
+(UIColor *)readColor { return [UIColor lightGrayColor]; }

@end
