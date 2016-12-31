//
//  SNMasterViewController.h
//  Show Notes
//
//  Created by Todd Ditchendorf on 10/21/12.
//  Copyright (c) 2012 Todd Ditchendorf. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "XMLDocLoader.h"

@class SNEpisodeListViewController;
@class SNShowListCell;

@interface SNShowListViewController : UITableViewController <NSFetchedResultsControllerDelegate, XMLDocLoaderDelegate>

- (id)init;

@property (strong, nonatomic) SNEpisodeListViewController *episodeListViewController;
@property (strong, nonatomic) UINib *cellNib;

@property (strong, nonatomic) XMLDocLoader *showsDocLoader;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSFetchedResultsController *editFetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@end
