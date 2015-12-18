//
//  NewsItemCell.h
//  RSSReader
//
//  Created by Oleg on 18.12.15.
//  Copyright © 2015 Oleg. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NewsItemCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@end
