//
//  SNDetailViewController.h
//  Show Notes
//
//  Created by Todd Ditchendorf on 10/21/12.
//  Copyright (c) 2012 Todd Ditchendorf. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XMLDocLoader.h"

@interface SNEpisodeListViewController : UITableViewController <UISplitViewControllerDelegate, UISearchBarDelegate, NSFetchedResultsControllerDelegate, XMLDocLoaderDelegate>

- (id)init;

@property (strong, nonatomic) id show;

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@property (strong, nonatomic) XMLDocLoader *episodesDocLoader;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSFetchedResultsController *searchFetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@end
