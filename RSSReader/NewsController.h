//
//  NewsController.h
//  RSSReader
//
//  Created by Oleg on 16.12.15.
//  Copyright © 2015 Oleg. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "ChannelEntity.h"
@class MainViewController;

@interface NewsController : UIViewController <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>
{    
    __weak IBOutlet UITableView *newsTable;
    UIRefreshControl *refreshControl;
}

@property (weak, nonatomic) MainViewController *mainControler;
@property (strong, nonatomic) ChannelEntity *detailItem;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

-(void)endRefreshControl;

@end
