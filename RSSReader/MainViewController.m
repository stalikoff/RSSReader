//
//  MainViewController.m
//  RSSReader
//
//  Created by Oleg on 16.12.15.
//  Copyright © 2015 Oleg. All rights reserved.
//

#import "MainViewController.h"
#import "MediaRSSParser.h"
#import "MediaRSSModels.h"
#import "ChannelEntity.h"
#import "AppDelegate.h"
#import "FeedsViewController.h"
#import "ItemEntity.h"

@interface MainViewController ()

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    self.managedObjectContext = delegate.managedObjectContext;

}
- (IBAction)addChannelPress:(id)sender
{
//    NSString *feedURLString = @"http://feeds.feedburner.com/RayWenderlich";
    
    NSString *feedURLString = feedUrlTF.text;
   
    if (feedUrlTF.text.length < 3) {
        return;
    }
    
    
    UIAlertController *contr;
    
    if (![self isValidFeedUrl]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Feed url is not valid!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    
    // check
    if ([self isUrlInDatabase:feedURLString]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"This feed url is already addeed!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    
    [self getChannel:feedURLString];
    
}

-(BOOL)isValidFeedUrl
{
    return YES;
}

-(BOOL)isUrlInDatabase:(NSString *)feedUrl
{
    NSError *error;
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ChannelEntity"];
    [request setPredicate:[NSPredicate predicateWithFormat:@"url = %@", feedUrl]];
    [request setFetchLimit:1];
    NSUInteger count = [context countForFetchRequest:request error:&error];

    if (count == 0){
        return NO;
    }
    else{
        return YES;
    }
}

-(void)saveToCoreData:(RSSChannel*)channel andUrl:(NSString*)feedUrl
{
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    NSEntityDescription *entity = [[self.fetchedResultsController fetchRequest] entity];
    ChannelEntity *newChannel = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:context];
    newChannel.title = channel.title;
    newChannel.url = feedUrl;
    newChannel.addedDate = [NSDate date];
    newChannel.lastUpdateDate = [NSDate date];
    newChannel.unreadCount = [NSNumber numberWithInt:channel.items.count];
    
    NSMutableSet *itemsSet = [NSMutableSet new];
    
    for (RSSItem *item in channel.items) {
        ItemEntity *itemEnt = [NSEntityDescription insertNewObjectForEntityForName:@"ItemEntity" inManagedObjectContext:context];
        itemEnt.title = item.title;
        itemEnt.pubDate = item.pubDate;
        itemEnt.link = item.link.absoluteString;
        itemEnt.guid = item.guid;
        itemEnt.isNew = @YES;
        [itemsSet addObject:itemEnt];
    }
    
    [newChannel addItems:itemsSet];

    //    newChannel.newCount = [NSNumber numberWithInt:channel.items.count];
//    for (RSSItem *item in channel.items) {
//        ItemEntity *itemEnt = [NSEntityDescription insertNewObjectForEntityForName:@"ItemEntity" inManagedObjectContext:context];
//        itemEnt.title = item.title;
//        itemEnt.pubDate = item.pubDate;
//        itemEnt.link = item.link.absoluteString;
//        NSLog(@"link: %@", item.link.absoluteString);
//        
//        [newChannel addItemsObject:itemEnt];
//    }
    
    NSError *error = nil;
    if (![context save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
}

#pragma mark TableView

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView: (UITableView *)tableView cellForRowAtIndexPath: (NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                       reuseIdentifier:CellIdentifier];
    }

    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    [self configureCell:cell atIndexPath:indexPath];

    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
  
    if (editingStyle == UITableViewCellEditingStyleDelete) {    // delete object from database
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        [context deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
        
        NSError *error = nil;
        if (![context save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"showFeedSegue" sender:nil];
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    ChannelEntity *object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = object.title;
    
    if (object.unreadCount.integerValue > 0) {
        cell.detailTextLabel.text = object.unreadCount.stringValue;
    }
    else{
        cell.detailTextLabel.text = @"";
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [NSFetchRequest new];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ChannelEntity" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSSortDescriptor *dateSD = [NSSortDescriptor sortDescriptorWithKey:@"addedDate" ascending:YES];

    [fetchRequest setSortDescriptors:@[dateSD]];
    
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"Master"];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
    NSError *error = nil;
    if (![self.fetchedResultsController performFetch:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _fetchedResultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [channelsTable beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [channelsTable insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [channelsTable deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        default:
            return;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = channelsTable;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
//            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
//            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [channelsTable endUpdates];
}


#pragma mark Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showFeedSegue"]) {
        NSIndexPath *indexPath = [channelsTable indexPathForSelectedRow];
        ChannelEntity *object = [[self fetchedResultsController] objectAtIndexPath:indexPath];
        FeedsViewController *controller = (FeedsViewController *)segue.destinationViewController;
        [controller setDetailItem:object];
        controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
        controller.navigationItem.leftItemsSupplementBackButton = YES;
    }
}

// TODO: need to check

-(void)viewWillDisappear:(BOOL)animated
{
    [NSFetchedResultsController deleteCacheWithName:nil];
}

#pragma mark request 
-(void)getChannel:(NSString*)url
{
    RSSParser *parser = [[RSSParser alloc] init];
    self.parser = parser;
    NSString *feedURLString = url;
    NSDictionary *parameters = nil;
    [self.parser parseRSSFeed:feedURLString
                   parameters:parameters
                      success:^(RSSChannel *channel) {
                          [self saveToCoreData:channel andUrl:feedURLString];
                      }
                      failure:^(NSError *error) {
                          NSLog(@"An error occurred: %@", error);
                      }];
}

- (void)updateAllNews
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ChannelEntity"];
    NSError *error = nil;
    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&error];

    for (ChannelEntity *channel in results) {
        [self getChannel:channel.url];
    }
}

- (void)getChannelFromUrl:(NSString*)url
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ChannelEntity"];
    NSError *error = nil;
    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&error];
    
    for (ChannelEntity *channel in results) {
        [self getChannel:channel.url];
    }
}


@end
