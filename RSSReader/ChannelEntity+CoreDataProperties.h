//
//  ChannelEntity+CoreDataProperties.h
//  RSSReader
//
//  Created by Oleg on 18.12.15.
//  Copyright © 2015 Oleg. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "ChannelEntity.h"

NS_ASSUME_NONNULL_BEGIN

@interface ChannelEntity (CoreDataProperties)

@property (nullable, nonatomic, retain) NSDate *addedDate;
@property (nullable, nonatomic, retain) NSDate *lastUpdateDate;
@property (nullable, nonatomic, retain) NSString *title;
@property (nullable, nonatomic, retain) NSString *url;
@property (nullable, nonatomic, retain) NSNumber *unreadCount;
@property (nullable, nonatomic, retain) NSSet<ItemEntity *> *items;

@end

@interface ChannelEntity (CoreDataGeneratedAccessors)

- (void)addItemsObject:(ItemEntity *)value;
- (void)removeItemsObject:(ItemEntity *)value;
- (void)addItems:(NSSet<ItemEntity *> *)values;
- (void)removeItems:(NSSet<ItemEntity *> *)values;

@end

NS_ASSUME_NONNULL_END
