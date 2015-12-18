//
//  ItemEntity+CoreDataProperties.h
//  RSSReader
//
//  Created by Oleg on 18.12.15.
//  Copyright © 2015 Oleg. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "ItemEntity.h"

NS_ASSUME_NONNULL_BEGIN

@interface ItemEntity (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *guid;
@property (nullable, nonatomic, retain) NSString *link;
@property (nullable, nonatomic, retain) NSDate *pubDate;
@property (nullable, nonatomic, retain) NSString *title;
@property (nullable, nonatomic, retain) NSNumber *isNew;
@property (nullable, nonatomic, retain) ChannelEntity *channel;

@end

NS_ASSUME_NONNULL_END
