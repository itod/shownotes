//
//  SNEpisodeListViewController.m
//  Show Notes
//
//  Created by Todd Ditchendorf on 10/21/12.
//  Copyright (c) 2012 Todd Ditchendorf. All rights reserved.
//

#import "SNEpisodeListViewController.h"
#import "SNEpisodeDetailViewController.h"
#import "NSDate+SNAdditions.h"
#import "XMLUtils.h"

#define CACHE_NAME @"EpisodeList"
#define SEARCH_CACHE_NAME @"EpisodeSearchList"

static NSDateFormatter *sDateFmt = nil;

@interface SNEpisodeListViewController ()
- (void)configureView;
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath withFetchedResultsController:(NSFetchedResultsController *)frc;
- (void)fetchEpisodeList;
- (NSDictionary *)storedEpisodesDictionary;

@property (strong, nonatomic) UIPopoverController *masterPopoverController;
@end

@implementation SNEpisodeListViewController

+ (void)initialize {
    if ([SNEpisodeListViewController class] == self) {
        sDateFmt = [[NSDateFormatter alloc] init];
        [sDateFmt setDateStyle:kCFDateFormatterShortStyle];
    }
}

- (id)init {
    NSString *nibName = TDIsPhone() ? @"SNEpisodeListViewController_iPhone" : @"SNEpisodeListViewController_iPad";
    return [self initWithNibName:nibName bundle:nil];
}


- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)b {
    self = [super initWithNibName:nibName bundle:b];
    if (self) {
        self.title = NSLocalizedString(@"Episodes", @"");
        self.clearsSelectionOnViewWillAppear = YES;
    }
    return self;
}


- (void)dealloc {
    [self killXMLDocLoader];
}


- (void)killXMLDocLoader {
    TDAssertMainThread();
    
    if (_episodesDocLoader) {
        self.episodesDocLoader.delegate = nil;
        [self.episodesDocLoader cancel];
        self.episodesDocLoader = nil;
    }
}


#pragma mark -
#pragma mark UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self configureView];

    self.title = [self.show valueForKey:@"name"];
    
    //[self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self killXMLDocLoader];
}


- (void)didReceiveMemoryWarning {
    [self killXMLDocLoader];
    
    self.fetchedResultsController.delegate = nil;
    self.fetchedResultsController = nil;
    self.searchFetchedResultsController.delegate = nil;
    self.searchFetchedResultsController = nil;

    [super didReceiveMemoryWarning];
}


#pragma mark -
#pragma mark Private

- (NSFetchedResultsController *)fetchedResultsControllerForTableView:(UITableView *)tv {
    return tv == self.tableView ? self.fetchedResultsController : self.searchFetchedResultsController;
}


- (void)configureView {
    [NSFetchedResultsController deleteCacheWithName:CACHE_NAME];
    [NSFetchedResultsController deleteCacheWithName:SEARCH_CACHE_NAME];
    self.fetchedResultsController = nil;
    self.searchFetchedResultsController = nil;
    [self.tableView reloadData];
}


- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath withFetchedResultsController:(NSFetchedResultsController *)frc {
    NSManagedObject *ep = [frc objectAtIndexPath:indexPath];
    
    cell.textLabel.text = [ep valueForKey:@"shortTitle"];
    
    NSDate *date = [ep valueForKey:@"pubDate"];
    NSString *str = [sDateFmt stringFromDate:date];
    cell.detailTextLabel.text = str;
}


- (void)fetchEpisodeList {
    TDAssertMainThread();
    NSAssert(_show, @"");
    NSString *str = [_show valueForKey:@"link"];
    NSURL *URL = [NSURL URLWithString:str];
    self.episodesDocLoader = [[XMLDocLoader alloc] initWithDelegate:self];
    [_episodesDocLoader loadDocumentForURL:URL];
}


- (NSDictionary *)storedEpisodesDictionary {
    NSArray *eps = [self.fetchedResultsController fetchedObjects];
    NSMutableDictionary *epsDict = nil;
    if ([eps count]) {
        epsDict = [NSMutableDictionary dictionaryWithCapacity:[eps count]];
        for (id ep in eps) {
            NSString *link = [ep valueForKey:@"link"];
            NSAssert([link length], @"");
            if (link) [epsDict setObject:ep forKey:link];
        }
    }

    return epsDict;
}


#pragma mark -
#pragma mark Content Filtering

- (void)filterContentForSearchText:(NSString *)searchText scope:(NSInteger)scope {
    // update the filter, in this case just blow away the FRC and let lazy evaluation create another with the relevant search info
    self.searchFetchedResultsController.delegate = nil;
    self.searchFetchedResultsController = nil;
    // if you care about the scope save off the index to be used by the serchFetchedResultsController
    //self.savedScopeButtonIndex = scope;
}


#pragma mark -
#pragma mark UISearchDisplayControllerDelegate

- (void)searchDisplayController:(UISearchDisplayController *)sdc willUnloadSearchResultsTableView:(UITableView *)tv {
    // search is done so get rid of the search FRC and reclaim memory
    self.searchFetchedResultsController.delegate = nil;
    self.searchFetchedResultsController = nil;
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)sdc shouldReloadTableForSearchString:(NSString *)searchStr {
    [self filterContentForSearchText:searchStr scope:[self.searchDisplayController.searchBar selectedScopeButtonIndex]];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)sdc shouldReloadTableForSearchScope:(NSInteger)searchOption {
    [self filterContentForSearchText:[self.searchDisplayController.searchBar text]
                               scope:[self.searchDisplayController.searchBar selectedScopeButtonIndex]];
    
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}


#pragma mark -
#pragma mark UISplitViewDelegate

- (void)splitViewController:(UISplitViewController *)sc willHideViewController:(UIViewController *)vc withBarButtonItem:(UIBarButtonItem *)item forPopoverController:(UIPopoverController *)pc
{
    item.title = NSLocalizedString(@"Shows", @"");
    [self.navigationItem setLeftBarButtonItem:item animated:YES];
    self.masterPopoverController = pc;
}


- (void)splitViewController:(UISplitViewController *)sc willShowViewController:(UIViewController *)vc invalidatingBarButtonItem:(UIBarButtonItem *)item {
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}


#pragma mark -
#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv {
    NSFetchedResultsController *frc = [self fetchedResultsControllerForTableView:tv];
    NSInteger c = [[frc sections] count];
    return c;
}


- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)section {
    NSFetchedResultsController *frc = [self fetchedResultsControllerForTableView:tv];
    id <NSFetchedResultsSectionInfo> sectionInfo = [frc sections][section];
    NSInteger c = [sectionInfo numberOfObjects];
    return c;
}


- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:15.0];
        cell.textLabel.minimumScaleFactor = 0.75;
        cell.textLabel.adjustsFontSizeToFitWidth = YES;

        cell.detailTextLabel.font = [UIFont boldSystemFontOfSize:11.0];
        cell.detailTextLabel.minimumScaleFactor = 1.0;
        cell.detailTextLabel.adjustsFontSizeToFitWidth = NO;

        if (TDIsPhone()) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }
    
    NSFetchedResultsController *frc = [self fetchedResultsControllerForTableView:tv];
    [self configureCell:cell atIndexPath:indexPath withFetchedResultsController:frc];
    return cell;
}


- (BOOL)tableView:(UITableView *)tv canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}


- (void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSFetchedResultsController *frc = [self fetchedResultsControllerForTableView:tv];
        NSManagedObjectContext *context = [frc managedObjectContext];
        [context deleteObject:[frc objectAtIndexPath:indexPath]];
        
        NSError *error = nil;
        if (![context save:&error]) {
            
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}


- (BOOL)tableView:(UITableView *)tv canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}


- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSFetchedResultsController *frc = [self fetchedResultsControllerForTableView:tv];

    NSManagedObject *ep = [frc objectAtIndexPath:indexPath];
    
    SNEpisodeDetailViewController *dvc = [[SNEpisodeDetailViewController alloc] init];
    dvc.episode = ep;

    if (TDIsPhone()) {
        [self.navigationController pushViewController:dvc animated:YES];
    } else {
        [self.navigationController pushViewController:dvc animated:YES];
    }
}


#pragma mark -
#pragma mark NSFetchedResultsControllerDelegate

//- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
//    [self.tableView beginUpdates];
//}
//
//
//- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
//           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
//{
//    switch(type) {
//        case NSFetchedResultsChangeInsert:
//            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
//            break;
//            
//        case NSFetchedResultsChangeDelete:
//            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
//            break;
//    }
//}
//
//
//- (void)controller:(NSFetchedResultsController *)frc didChangeObject:(id)anObject
//       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
//      newIndexPath:(NSIndexPath *)newIndexPath
//{
//    UITableView *tableView = self.tableView;
//    
//    switch(type) {
//        case NSFetchedResultsChangeInsert:
//            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
//            break;
//            
//        case NSFetchedResultsChangeDelete:
//            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
//            break;
//            
//        case NSFetchedResultsChangeUpdate:
//            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath withFetchedResultsController:frc];
//            break;
//            
//        case NSFetchedResultsChangeMove:
//            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
//            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
//            break;
//    }
//}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)frc {
    //    [self.tableView endUpdates];
    [self.tableView reloadData];
}


/*
 // Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed.
 
 - (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
 {
 // In the simplest, most efficient, case, reload the table view.
 [self.tableView reloadData];
 }
 */

#pragma mark -
#pragma mark - XMLDocLoaderDelegate

- (void)docLoader:(XMLDocLoader *)l didSucceed:(xmlDocPtr)doc {
    TDAssertMainThread();
    NSParameterAssert(doc);
    if (!doc) return;
    
    TDPerformOnBackgroundThread(^{
        [self parseXMLDocument:doc];
    });
}


- (void)parseXMLDocument:(xmlDocPtr)doc {
    NSParameterAssert(doc);
    if (!doc) return;
    //NSString *str = XMLGetXMLStringFromDocument(doc); NSLog(@"%@", str);
    
    NSMutableArray *epInfos = [NSMutableArray array];
    
    xmlNodePtr rssEl = xmlDocGetRootElement(doc);
    xmlNodePtr channelEl = XMLGetFirstChildOfTagName(rssEl, "channel");
    
    for (xmlNodePtr child = channelEl->children; child; child = child->next) {
        if (!XMLTagNameEquals(child, "item")) continue;
        
        xmlNodePtr itemEl = child;
        xmlNodePtr titleEl = XMLGetFirstChildOfTagName(itemEl, "title");
        xmlNodePtr linkEl = XMLGetFirstChildOfTagName(itemEl, "link");
        xmlNodePtr pubDateEl = XMLGetFirstChildOfTagName(itemEl, "pubDate");
        xmlNodePtr descEl = XMLGetFirstChildOfTagName(itemEl, "description");
        xmlNodePtr encodedEl = XMLGetFirstChildOfTagName(itemEl, "encoded");
        
        NSMutableDictionary *d = [NSMutableDictionary dictionary];
        
        NSAssert(_show, @"");
        [d setObject:_show forKey:@"show"];
        
        NSString *title = XMLGetStringContent(titleEl);
        [d setObject:title ? title : @"" forKey:@"title"];
        
        static NSRegularExpression *sRegex = nil;
        if (!sRegex) {
            sRegex = [NSRegularExpression regularExpressionWithPattern:@".+?\\s+(\\d+:.+)" options:0 error:nil];
        }
        
        NSRange r = NSMakeRange(0.0, [title length]);
        NSString *shortTitle = [sRegex stringByReplacingMatchesInString:title options:0 range:r withTemplate:@"$1"];
        [d setObject:shortTitle ? shortTitle : @"" forKey:@"shortTitle"];
        
        NSString *link = XMLGetStringContent(linkEl);
        [d setObject:link ? link : @"" forKey:@"link"];
        
        NSString *pubDateStr = XMLGetStringContent(pubDateEl);
        NSDate *pubDate = [NSDate pubDateFromString:pubDateStr];
        [d setObject:pubDate ? pubDate : @"" forKey:@"pubDate"];
        
        NSString *summary = XMLGetStringContent(descEl);
        [d setObject:summary ? summary : @"" forKey:@"summary"];
        
        NSString *body = XMLGetStringContent(encodedEl);
        [d setObject:body ? body : @"" forKey:@"body"];
        
        [epInfos addObject:d];
    }

    // free the xml doc
    xmlFreeDoc(doc);
    
    TDPerformOnMainThread(^{
        [self didFetchEpisodeInfos:epInfos];
    });
}


- (void)didFetchEpisodeInfos:(NSArray *)epInfos {
    [self killXMLDocLoader];

    TDAssertMainThread();
    NSFetchedResultsController *frc = self.fetchedResultsController;
    NSManagedObjectContext *moc = [frc managedObjectContext];
    NSEntityDescription *epEntity = [[frc fetchRequest] entity];
    
    // build dictionary of shows already in local store. keyed by name.
    NSDictionary *epsDict = [self storedEpisodesDictionary];
    
    for (NSDictionary *d in epInfos) {
        NSString *link = [d objectForKey:@"link"];
        
        // lookup existing ep first
        NSManagedObject *ep = [epsDict objectForKey:link];
        
        // create if doesn't exist
        if (!ep) {
            ep = [NSEntityDescription insertNewObjectForEntityForName:[epEntity name] inManagedObjectContext:moc];
        }
        
        // update ep attributes
        NSArray *keys = [d allKeys];
        
        for (NSString *key in keys) {
            [ep willChangeValueForKey:key];
        }
        
        for (NSString *key in d) {
            id val = [d objectForKey:key];
            [ep setPrimitiveValue:val forKey:key];
        }
        
        for (NSString *key in keys) {
            [ep didChangeValueForKey:key];
        }
        
        //NSLog(@"%@", ep);
    }
    
    // save all shows in the context
    NSError *err = nil;
    if (![moc save:&err]) {
        NSLog(@"Unresolved error %@, %@", err, [err userInfo]);
        abort();
    }
}


- (void)docLoader:(XMLDocLoader *)l didFail:(NSError *)err {
    TDAssertMainThread();

}


#pragma mark -
#pragma mark Properties

- (void)setShow:(id)newShow {
    if (_show != newShow) {
        _show = newShow;
        
        // Update the view.
        [self configureView];
        [self fetchEpisodeList];
    }
    
    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }
}


//- (NSFetchedResultsController *)fetchedResultsController {
//    if (!_fetchedResultsController) {
//        NSManagedObjectContext *moc = self.managedObjectContext;
//        
//        NSFetchRequest *req = [[NSFetchRequest alloc] init];
//        
//        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Episode" inManagedObjectContext:moc];
//        [req setEntity:entity];
//        [req setFetchBatchSize:20];
//        
//        NSPredicate *pred = [NSPredicate predicateWithFormat:@"self.show == %@", _show];
//        [req setPredicate:pred];
//        
//        NSSortDescriptor *sortDesc = [[NSSortDescriptor alloc] initWithKey:@"pubDate" ascending:NO];
//        [req setSortDescriptors:@[sortDesc]];
//        
//        self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:req
//                                                                            managedObjectContext:moc
//                                                                              sectionNameKeyPath:nil
//                                                                                       cacheName:CACHE_NAME];
//        self.fetchedResultsController.delegate = self;
//        
//        NSError *error = nil;
//        if (![self.fetchedResultsController performFetch:&error]) {
//            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
//            abort();
//        }
//    }
//    
//    return _fetchedResultsController;
//}
//
//
//- (NSFetchedResultsController *)searchFetchedResultsController {
//    if (!_searchFetchedResultsController) {
//        NSManagedObjectContext *moc = self.managedObjectContext;
//        
//        NSFetchRequest *req = [[NSFetchRequest alloc] init];
//        
//        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Episode" inManagedObjectContext:moc];
//        [req setEntity:entity];
//        [req setFetchBatchSize:20];
//        
//        NSString *filterStr = self.searchFilterString;
//        NSPredicate *pred = [NSPredicate predicateWithFormat:@"(self.show == %@) AND (self.title CONTAINS[cd] '%@')", _show, filterStr];
//        [req setPredicate:pred];
//        
//        NSSortDescriptor *sortDesc = [[NSSortDescriptor alloc] initWithKey:@"pubDate" ascending:NO];
//        [req setSortDescriptors:@[sortDesc]];
//        
//        self.searchFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:req
//                                                                                  managedObjectContext:moc
//                                                                                    sectionNameKeyPath:nil
//                                                                                             cacheName:SEARCH_CACHE_NAME];
//        self.searchFetchedResultsController.delegate = self;
//        
//        NSError *error = nil;
//        if (![self.searchFetchedResultsController performFetch:&error]) {
//            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
//            abort();
//        }
//    }
//    
//    return _searchFetchedResultsController;
//}


- (NSFetchedResultsController *)newFetchedResultsControllerWithSearch:(NSString *)searchStr {
    searchStr = [searchStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    NSSortDescriptor *sortDesc = [[NSSortDescriptor alloc] initWithKey:@"pubDate" ascending:NO];
    NSArray *sortDescriptors = @[sortDesc];
    NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"self.show == %@", _show];
    
    // Create the fetch request for the entity.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSManagedObjectContext *moc = self.managedObjectContext;
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Episode" inManagedObjectContext:moc];
    [fetchRequest setEntity:entity];
    
    if ([searchStr length]) {
        NSMutableArray *predicateArray = [NSMutableArray array];

        // your search predicate(s) are added to this array
        [predicateArray addObject:[NSPredicate predicateWithFormat:@"self.shortTitle CONTAINS[cd] %@", searchStr]];
        //[predicateArray addObject:[NSPredicate predicateWithFormat:@"self.summary CONTAINS[cd] %@", searchStr]];
        [predicateArray addObject:[NSPredicate predicateWithFormat:@"self.body CONTAINS[cd] %@", searchStr]];

        // finally add the filter predicate for this view
        if (filterPredicate) {
            NSArray *subs = @[filterPredicate, [NSCompoundPredicate orPredicateWithSubpredicates:predicateArray]];
            filterPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:subs];
        } else {
            filterPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:predicateArray];
        }
    }
    [fetchRequest setPredicate:filterPredicate];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                          managedObjectContext:moc
                                                                            sectionNameKeyPath:nil
                                                                                     cacheName:nil]; //]searchStr ? SEARCH_CACHE_NAME : CACHE_NAME];
    frc.delegate = self;
        
    NSError *error = nil;
    if (![frc performFetch:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return frc;
}


- (NSFetchedResultsController *)fetchedResultsController {
    if (!_fetchedResultsController) {
        _fetchedResultsController = [self newFetchedResultsControllerWithSearch:nil];
    }
    
    return _fetchedResultsController;
}


- (NSFetchedResultsController *)searchFetchedResultsController {
    if (!_searchFetchedResultsController) {
        _searchFetchedResultsController = [self newFetchedResultsControllerWithSearch:self.searchDisplayController.searchBar.text];
    }
    return _searchFetchedResultsController;
}

@end
