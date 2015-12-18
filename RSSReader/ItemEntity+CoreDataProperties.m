//
//  ItemEntity+CoreDataProperties.m
//  RSSReader
//
//  Created by Oleg on 18.12.15.
//  Copyright © 2015 Oleg. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "ItemEntity+CoreDataProperties.h"

@implementation ItemEntity (CoreDataProperties)

@dynamic guid;
@dynamic link;
@dynamic pubDate;
@dynamic title;
@dynamic isNew;
@dynamic channel;

@end
