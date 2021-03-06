//
//  MainViewController.h
//  RSSReader
//
//  Created by Oleg on 16.12.15.
//  Copyright © 2015 Oleg. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "MediaRSSParser.h"
#import "NewsController.h"

@interface MainViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>
{
    __weak IBOutlet UIButton *addFeedBtn;
    __weak IBOutlet UITextField *feedUrlTF;
    __weak IBOutlet UITableView *channelsTable;
    UIRefreshControl *refreshControl;
    int notRefrChannelsCnt;
    __weak NewsController *newsConroller;
}

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic) RSSParser *parser;

-(void)refreshChannelFromParent:(NSString *)url;

@end
