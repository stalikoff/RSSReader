//
//  NewsDetailController.m
//  RSSReader
//
//  Created by Oleg on 19.12.15.
//  Copyright © 2015 Oleg. All rights reserved.
//

#import "NewsDetailController.h"

@interface NewsDetailController ()

@end

@implementation NewsDetailController

- (void)viewDidLoad {
    [super viewDidLoad];

    [newsWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.newsUrl]]];
}

@end
