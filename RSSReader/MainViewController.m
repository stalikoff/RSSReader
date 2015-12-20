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
#import "NewsController.h"
#import "ItemEntity.h"

@interface MainViewController ()

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    self.managedObjectContext = delegate.managedObjectContext;

    refreshControl = [UIRefreshControl new];
    [channelsTable addSubview:refreshControl];
    [refreshControl addTarget:self action:@selector(refreshData) forControlEvents:UIControlEventValueChanged];
    
    NSTimer *t = [NSTimer scheduledTimerWithTimeInterval: 30.0
                                                  target: self
                                                selector:@selector(updateAllNews)
                                                userInfo: nil repeats:YES];
    
    [self updateAllNews];
}

- (IBAction)addChannelPress:(id)sender
{
    NSString *feedURLString = feedUrlTF.text;
   
    if (feedUrlTF.text.length < 3) {
        return;
    }
    
    if (![self isValidFeedUrl:feedURLString]) {

        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Error"
                                                                                 message:@"Feed url is not valid!"
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *actionOk = [UIAlertAction actionWithTitle:@"Ok"
                                                           style:UIAlertActionStyleDefault
                                                         handler:nil];
        [alertController addAction:actionOk];
        [self presentViewController:alertController animated:YES completion:nil];

        return;
    }
    
    if ([self isUrlInDatabase:feedURLString]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Error"
                                                                                 message:@"This feed url is already addeed!"
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *actionOk = [UIAlertAction actionWithTitle:@"Ok"
                                                           style:UIAlertActionStyleDefault
                                                         handler:nil];
        [alertController addAction:actionOk];
        [self presentViewController:alertController animated:YES completion:nil];
        
        return;
    }
    
    
    [self getChannel:feedURLString andFromAdd:YES];
}

-(BOOL)isValidFeedUrl:(NSString *)urlString
{
    NSURL *candidateURL = [NSURL URLWithString:urlString];
    if (candidateURL && candidateURL.scheme && candidateURL.host) {
        return YES;
    }
    return NO;
}

-(void)saveToCoreData:(RSSChannel*)channel andUrl:(NSString*)feedUrl
{
    BOOL isNewChannel = NO;
    
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    NSEntityDescription *entity = [[self.fetchedResultsController fetchRequest] entity];
    
    ChannelEntity *newChannel = [self getSavedChannelFromUrl:feedUrl];
    
    if (newChannel) { // if is in db
        if (newChannel.lastUpdateDate) {
            if ([newChannel.lastUpdateDate compare:channel.lastBuildDate] == NSOrderedSame) { // is update
                // if no updates
                NSLog(@"new date: %@  saved date: %@", newChannel.lastUpdateDate, channel.lastBuildDate);
                return;
            }
        }
    
        NSLog(@"new date: %@  saved date: %@", newChannel.lastUpdateDate, channel.lastBuildDate);
        newChannel.lastUpdateDate = channel.lastBuildDate;
    }
    else{ // new
        isNewChannel = YES;
        newChannel = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:context];
        newChannel.title = channel.title;
        newChannel.url = feedUrl;
        newChannel.addedDate = [NSDate date];
        newChannel.lastUpdateDate = channel.lastBuildDate;
        newChannel.unreadCount = [NSNumber numberWithInt:channel.items.count];
    }
    
    // ------- items -------
    NSMutableSet *itemsSet = [NSMutableSet new];
    
    if (isNewChannel) {
        for (RSSItem *item in channel.items) {
            ItemEntity *itemEnt = [NSEntityDescription insertNewObjectForEntityForName:@"ItemEntity" inManagedObjectContext:context];
            itemEnt.title = item.title;
            itemEnt.pubDate = item.pubDate;
            itemEnt.link = item.link.absoluteString;
            itemEnt.guid = item.guid;
            itemEnt.isNew = @YES;
            [itemsSet addObject:itemEnt];
        }
    }
    else{
        for (RSSItem *item in channel.items) {
            if ([self isNewsDatabase:item.guid]) { // is in db
                continue;
            }
            
            newChannel.unreadCount = [NSNumber numberWithInt: newChannel.unreadCount.intValue + 1];
            
            ItemEntity *itemEnt = [NSEntityDescription insertNewObjectForEntityForName:@"ItemEntity" inManagedObjectContext:context];
            itemEnt.title = item.title;
            itemEnt.pubDate = item.pubDate;
            itemEnt.link = item.link.absoluteString;
            itemEnt.guid = item.guid;
            itemEnt.isNew = @YES;
            [itemsSet addObject:itemEnt];
        }
    }
    
    if (itemsSet.count) {
        [newChannel addItems:itemsSet];
    }
    
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
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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
    
    NSSortDescriptor *dateSD = [NSSortDescriptor sortDescriptorWithKey:@"addedDate" ascending:NO];

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
        newsConroller = (NewsController *)segue.destinationViewController;
        [newsConroller setDetailItem:object];
        newsConroller.mainControler = self;
        newsConroller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
        newsConroller.navigationItem.leftItemsSupplementBackButton = YES;
    }
}

#pragma mark request 

-(void)getChannel:(NSString*)url andFromAdd:(BOOL)isFromAdd
{
    if (isFromAdd) {
        feedUrlTF.text = @"";
        feedUrlTF.enabled = NO;
        addFeedBtn.enabled = NO;
    }
    
    RSSParser *parser = [[RSSParser alloc] init];
    self.parser = parser;
    NSString *feedURLString = url;
    NSDictionary *parameters = nil;
    [self.parser parseRSSFeed:feedURLString
                   parameters:parameters
                      success:^(RSSChannel *channel) {
                          [self saveToCoreData:channel andUrl:feedURLString];
                          [self decreaseNotRefrChannels];
                          
                          if (isFromAdd) {
                              addFeedBtn.enabled = YES;
                              feedUrlTF.enabled = YES;
                          }
                      }
                      failure:^(NSError *error) {
                          [self decreaseNotRefrChannels];

                          if (isFromAdd) {
                              addFeedBtn.enabled = YES;
                              feedUrlTF.enabled = YES;
                          }
                          
                          NSLog(@"An error occurred: %@", error);
                      }];
}

- (void)updateAllNews
{
    NSError *error;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ChannelEntity"];
    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&error];

    for (ChannelEntity *channel in results) {
        [self getChannel:channel.url andFromAdd:NO];
    }
}

-(void)refreshChannelFromParent:(NSString *)url
{
    notRefrChannelsCnt ++;
    [self getChannel:url andFromAdd:NO];
}

#pragma mark database

-(int)savedChannelsCnt
{
    NSError *error;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ChannelEntity"];
    NSUInteger count = [self.managedObjectContext countForFetchRequest:request error:&error];
    return count;
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

-(BOOL)isNewsDatabase:(NSString *)newsGuid
{
    NSError *error;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ItemEntity"];
    [request setPredicate:[NSPredicate predicateWithFormat:@"guid = %@", newsGuid]];
    [request setFetchLimit:1];
    NSUInteger count = [self.managedObjectContext countForFetchRequest:request error:&error];
    
    if (count == 0){
        return NO;
    }
    else{
        return YES;
    }
}

- (ChannelEntity *)getSavedChannelFromUrl:(NSString*)url
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"ChannelEntity"];
    [request setPredicate:[NSPredicate predicateWithFormat:@"url = %@", url]];
    [request setFetchLimit:1];
    NSError *error = nil;
    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&error];

    if (results.count) {
        return results.firstObject;
    }
    else
    {
        return nil;
    }
}

-(void)decreaseNotRefrChannels
{
    if (notRefrChannelsCnt) {
        if (notRefrChannelsCnt == 1) {
            notRefrChannelsCnt = 0;
            
            if (newsConroller) {
                [newsConroller endRefreshControl];
            }
            
            if (refreshControl.refreshing) {
                [refreshControl endRefreshing];
            }
            return;
        }
        notRefrChannelsCnt --;
    }
}

-(void)refreshData
{
    int channelsCnt = [self savedChannelsCnt];
    if (! channelsCnt) {
        [refreshControl endRefreshing];
        return;
    }

    notRefrChannelsCnt = channelsCnt;
    [self updateAllNews];
}

-(void)viewWillDisappear:(BOOL)animated
{
    notRefrChannelsCnt = 0;
    if (refreshControl.refreshing) {
        [refreshControl endRefreshing];
    }
    [NSFetchedResultsController deleteCacheWithName:nil];
}



@end
