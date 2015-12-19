//
//  NewsDetailController.h
//  RSSReader
//
//  Created by Oleg on 19.12.15.
//  Copyright © 2015 Oleg. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NewsDetailController : UIViewController
{
    __weak IBOutlet UIWebView *newsWebView;
}

@property (strong, nonatomic) NSString *newsUrl;


@end
