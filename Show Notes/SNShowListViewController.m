//
//  SNMasterViewController.m
//  Show Notes
//
//  Created by Todd Ditchendorf on 10/21/12.
//  Copyright (c) 2012 Todd Ditchendorf. All rights reserved.
//

#import "SNShowListViewController.h"
#import "SNEpisodeListViewController.h"
#import "XMLDocLoader.h"
#import "XMLUtils.h"
#import "SNShowListCell.h"
#import "SNSettingsViewController.h"

#define CACHE_NAME @"ShowList"
#define EDIT_CACHE_NAME @"EditShowList"

@interface SNShowListViewController ()

// private
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath withFetchedResultsController:(NSFetchedResultsController *)frc;
- (void)fetchShowList;
@end

@implementation SNShowListViewController

- (id)init {
    NSString *nibName = TDIsPhone() ? @"SNShowListViewController_iPhone" : @"SNShowListViewController_iPad";
    return [self initWithNibName:nibName bundle:nil];
}


- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)b {
    self = [super initWithNibName:nibName bundle:b];
    if (self) {
        self.title = NSLocalizedString(@"Shows", @"");

        self.clearsSelectionOnViewWillAppear = YES;

        if (TDIsPad()) {
            self.clearsSelectionOnViewWillAppear = NO;
            self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
        }
    }
    return self;
}


- (void)dealloc {
    [self killXMLDocLoader];
}


- (void)killXMLDocLoader {
    TDAssertMainThread();
    if (_showsDocLoader) {
        self.showsDocLoader.delegate = nil;
        [self.showsDocLoader cancel];
        self.showsDocLoader = nil;
    }
}


#pragma mark -
#pragma mark UIViewController

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    if (!editing) {
        [self didFinishEditing];
    }
    
    [super setEditing:editing animated:animated];
    [self.tableView reloadData];

    if (editing) {
        [self didBeginEditing];
    }
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.cellNib = [UINib nibWithNibName:[SNShowListCell nibName] bundle:nil];
    //[self.tableView registerClass:[SNShowListCell class] forCellReuseIdentifier:[SNShowListCell identifier]];
    [self.tableView registerNib:self.cellNib forCellReuseIdentifier:[SNShowListCell identifier]];
    self.tableView.allowsSelectionDuringEditing = YES;
    self.tableView.allowsMultipleSelectionDuringEditing = YES;

    self.navigationItem.rightBarButtonItem = self.editButtonItem;

    BOOL hasRun = [[NSUserDefaults standardUserDefaults] boolForKey:@"hasRun"];
    if (!hasRun) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasRun"];
        [self fetchShowList];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [self killXMLDocLoader];

}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.episodeListViewController = nil;
}


#pragma mark -
#pragma mark Actions

- (IBAction)showSettings:(id)sender {
    SNSettingsViewController *svc = [[SNSettingsViewController alloc] init];
    
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:svc];
    [self.navigationController presentViewController:nc animated:YES completion:nil];
}


#pragma mark -
#pragma mark Private

- (void)didBeginEditing {
    TDAssertMainThread();
    [NSFetchedResultsController deleteCacheWithName:EDIT_CACHE_NAME];
    if (_editFetchedResultsController) {
        self.editFetchedResultsController.delegate = nil;
        self.editFetchedResultsController = nil;
    }
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Settings", @"")
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(showSettings:)];
    
    [self.tableView reloadData];
    
    NSFetchedResultsController *frc = [self fetchedResultsControllerForEditing:YES];
    NSManagedObjectContext *moc = [frc managedObjectContext];
    
    NSArray *shows = [frc fetchedObjects];
    NSUInteger idx = 0;
    for (id show in shows) {
        BOOL hidden = [[show valueForKey:@"hidden"] boolValue];
        if (hidden) {
            NSIndexPath *path = [NSIndexPath indexPathForRow:idx inSection:0];
            [self.tableView selectRowAtIndexPath:path animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
        ++idx;
    }
}


- (void)didFinishEditing {
    TDAssertMainThread();
    self.navigationItem.leftBarButtonItem = nil;

    NSArray *selPaths = [self.tableView indexPathsForSelectedRows];
    
    NSFetchedResultsController *frc = [self fetchedResultsControllerForEditing:YES];
    NSManagedObjectContext *moc = [frc managedObjectContext];
    
    NSArray *shows = [frc fetchedObjects];
    NSUInteger idx = 0;
    for (id show in shows) {
        NSIndexPath *path = [NSIndexPath indexPathForRow:idx inSection:0];
        
        BOOL hidden = NO;
        if ([selPaths containsObject:path]) {
            hidden = YES;
            //        [moc deleteObject:show];
        }
        [show setValue:[NSNumber numberWithBool:hidden] forKey:@"hidden"];
        ++idx;
    }
    
    NSError *error = nil;
    if (![moc save:&error]) {
        
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    [NSFetchedResultsController deleteCacheWithName:CACHE_NAME];
    if (_fetchedResultsController) {
        self.fetchedResultsController.delegate = nil;
        self.fetchedResultsController = nil;
    }
    
    for (NSIndexPath *selPath in selPaths) {
        [self.tableView deselectRowAtIndexPath:selPath animated:NO];
    }
    
    [self.tableView reloadData];
}


- (NSFetchedResultsController *)fetchedResultsControllerForEditing:(BOOL)isEdit {
    return isEdit ? self.editFetchedResultsController : self.fetchedResultsController;
}


- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath withFetchedResultsController:(NSFetchedResultsController *)frc {
    NSManagedObject *show = [frc objectAtIndexPath:indexPath];
    NSString *name = [show valueForKey:@"name"];
    
    cell.textLabel.text = name;

    NSString *icon = [show valueForKey:@"icon"];
    UIImage *img = [UIImage imageNamed:icon];
    cell.imageView.image = img;
    
    [cell setNeedsDisplay];
}


- (void)fetchShowList {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"shows" ofType:@"xml"];
//    NSURL *URL = [NSURL URLWithString:@"http://tod.nu/shows.xml"]; //http://5by5.tv/rss"];
    self.showsDocLoader = [[XMLDocLoader alloc] initWithDelegate:self];
    //    [_showsDocLoader loadDocumentForURL:URL];
    [_showsDocLoader loadDocumentForFile:path];
}


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
    
    xmlNodePtr showsEl = xmlDocGetRootElement(doc);
    NSMutableArray *showInfos = [NSMutableArray array];

    NSInteger idx = 0;
    for (xmlNodePtr child = showsEl->children; child; child = child->next) {
        if (!XMLTagNameEquals(child, "show")) continue;
        
        xmlNodePtr showEl = child;
        xmlNodePtr nameEl = XMLGetFirstChildOfTagName(showEl, "name");
        xmlNodePtr feedURLEl = XMLGetFirstChildOfTagName(showEl, "feedURL");
        xmlNodePtr iconEl = XMLGetFirstChildOfTagName(showEl, "icon");
        
        NSMutableDictionary *d = [NSMutableDictionary dictionary];
        
        NSString *name = XMLGetStringContent(nameEl);
        [d setObject:name ? name : @"" forKey:@"name"];
        
        [d setObject:[NSNumber numberWithInteger:idx++] forKey:@"sortOrder"];
        
        NSString *link = XMLGetStringContent(feedURLEl);
        [d setObject:link ? link : @"" forKey:@"link"];
        
        NSString *icon = XMLGetStringContent(iconEl);
        [d setObject:icon ? icon : @"" forKey:@"icon"];
        
        [showInfos addObject:d];
    }
    
    // free the xml doc
    xmlFreeDoc(doc);
    
    TDPerformOnMainThread(^{
        [self didFetchShowInfos:showInfos];
    });
}


- (void)didFetchShowInfos:(NSArray *)showInfos {
    TDAssertMainThread();
    [self killXMLDocLoader];

    NSFetchedResultsController *frc = [self fetchedResultsControllerForEditing:NO];
    NSManagedObjectContext *moc = [frc managedObjectContext];
    NSEntityDescription *showEntity = [[frc fetchRequest] entity];
    
    // build dictionary of shows already in local store. keyed by name.
    NSArray *shows = [frc fetchedObjects];
    
    NSUInteger c = [shows count];
    NSMutableSet *oldShowSet = [NSMutableSet setWithCapacity:c];
    NSMutableSet *newShowSet = [NSMutableSet setWithCapacity:c];
    
    NSMutableDictionary *showsDict = nil;
    if (c > 0) {
        showsDict = [NSMutableDictionary dictionaryWithCapacity:c];
        for (id show in shows) {
            [oldShowSet addObject:show];
            
            NSString *name = [show valueForKey:@"name"];
            NSAssert([name length], @"");
            if (name) [showsDict setObject:show forKey:name];
        }
    }
    
    for (NSDictionary *d in showInfos) {
        NSString *name = [d objectForKey:@"name"];

        // lookup existing show first
        NSManagedObject *show = [showsDict objectForKey:name];
        
        // create if doesn't exist
        if (!show) {
            show = [NSEntityDescription insertNewObjectForEntityForName:[showEntity name] inManagedObjectContext:moc];
        }
        
        [newShowSet addObject:show];
        
        // update show attributes
        NSArray *keys = [d allKeys];
        
        for (NSString *key in keys) {
            [show willChangeValueForKey:key];
        }

        for (NSString *key in d) {
            id val = [d objectForKey:key];
            [show setPrimitiveValue:val forKey:key];
        }
        
        for (NSString *key in keys) {
            [show didChangeValueForKey:key];
        }

    }

    // save all shows in the context
    NSError *err = nil;
    if (![moc save:&err]) {
        NSLog(@"Unresolved error %@, %@", err, [err userInfo]);
        abort();
    }


    // remove stale locally-stored shows that are no loner reported by the server
    [oldShowSet minusSet:newShowSet];
    NSLog(@"%@", oldShowSet);
    
    if ([oldShowSet count]) {
        for (id show in oldShowSet) {
            [moc deleteObject:show];
        }
        
        // save all shows in the context
        err = nil;
        if (![moc save:&err]) {
            NSLog(@"Unresolved error %@, %@", err, [err userInfo]);
            abort();
        }
        
    }
}


- (void)docLoader:(XMLDocLoader *)l didFail:(NSError *)err {
    TDAssertMainThread();
}


#pragma mark -
#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv {
    NSFetchedResultsController *frc = [self fetchedResultsControllerForEditing:self.isEditing];
    return [[frc sections] count];
}


- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)section {
    NSFetchedResultsController *frc = [self fetchedResultsControllerForEditing:self.isEditing];
    id <NSFetchedResultsSectionInfo> sectionInfo = [frc sections][section];
    return [sectionInfo numberOfObjects];
}


- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SNShowListCell *cell = [tv dequeueReusableCellWithIdentifier:[SNShowListCell identifier] forIndexPath:indexPath];
    NSFetchedResultsController *frc = [self fetchedResultsControllerForEditing:self.isEditing];
    [self configureCell:cell atIndexPath:indexPath withFetchedResultsController:frc];
    return cell;
}


- (BOOL)tableView:(UITableView *)tv canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}


- (UITableViewCellEditingStyle)tableView:(UITableView *)tv editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}


- (NSString *)tableView:(UITableView *)tv titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return NSLocalizedString(@"Hide", @"");
}


- (void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {

    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSFetchedResultsController *frc = [self fetchedResultsControllerForEditing:self.isEditing];
        NSManagedObjectContext *moc = [frc managedObjectContext];
        
        id show = [frc objectAtIndexPath:indexPath];
        [moc deleteObject:show];
        
        NSError *error = nil;
        if (![moc save:&error]) {

            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}


- (BOOL)tableView:(UITableView *)tv canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}


- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.isEditing) return;
    
    NSFetchedResultsController *frc = [self fetchedResultsControllerForEditing:self.isEditing];

    NSManagedObject *show = [frc objectAtIndexPath:indexPath];

    if (TDIsPhone()) {
        self.episodeListViewController.show = show;
        [self.navigationController pushViewController:self.episodeListViewController animated:YES];
    } else {
        self.episodeListViewController.show = show;
    }
}


#pragma mark -
#pragma mark NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)frc {
    //[self.tableView beginUpdates];
}


//- (void)controller:(NSFetchedResultsController *)frc didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
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
//- (void)controller:(NSFetchedResultsController *)frc didChangeObject:(id)show
//       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
//      newIndexPath:(NSIndexPath *)newIndexPath
//{
//    UITableView *tv = self.tableView;
//    
//    switch (type) {
//        case NSFetchedResultsChangeInsert:
//            //[tv reloadSections:[NSIndexSet indexSetWithIndex:newIndexPath.section] withRowAnimation:UITableViewRowAnimationFade];
//            [tv insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
//            break;
//            
//        case NSFetchedResultsChangeDelete:
//            [tv deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
//            break;
//            
//        case NSFetchedResultsChangeUpdate: {
//            NSFetchedResultsController *frc = [self fetchedResultsControllerForEditing:self.isEditing];
//            [self configureCell:(SNShowListCell *)[tv cellForRowAtIndexPath:indexPath] atIndexPath:indexPath withFetchedResultsController:frc];
//        } break;
//            
//        case NSFetchedResultsChangeMove:
//            [tv deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
//            [tv insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
//            break;
//    }
//}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)frc {
    //[self.tableView endUpdates];
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
#pragma mark Properties

- (SNEpisodeListViewController *)episodeListViewController {
    if (!_episodeListViewController) {
        _episodeListViewController = [[SNEpisodeListViewController alloc] init];
        _episodeListViewController.managedObjectContext = self.managedObjectContext;
    }
    return _episodeListViewController;
}


//- (NSFetchedResultsController *)fetchedResultsController {
//    if (!_fetchedResultsController) {
//        NSManagedObjectContext *moc = self.managedObjectContext;
//        
//        NSFetchRequest *req = [[NSFetchRequest alloc] init];
//
//        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Show" inManagedObjectContext:moc];
//        [req setEntity:entity];
//        
//        NSPredicate *pred = [NSPredicate predicateWithFormat:@"self.hidden = NO"];
//        [req setPredicate:pred];
//        
//        // Set the batch size to a suitable number.
//        [req setFetchBatchSize:20];
//        
//        NSSortDescriptor *sortDesc = [[NSSortDescriptor alloc] initWithKey:@"sortOrder" ascending:YES];
//        [req setSortDescriptors:@[sortDesc]];
//        
//        // Edit the section name key path and cache name if appropriate. nil for section name key path means "no sections".
//        self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:req
//                                                                            managedObjectContext:moc
//                                                                              sectionNameKeyPath:nil
//                                                                                       cacheName:@"ShowList"];
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


- (NSFetchedResultsController *)newFetchedResultsControllerForEditing:(BOOL)isEditing {
    NSManagedObjectContext *moc = self.managedObjectContext;
    NSFetchRequest *req = [[NSFetchRequest alloc] init];
    
    NSSortDescriptor *sortDesc = [[NSSortDescriptor alloc] initWithKey:@"sortOrder" ascending:YES];
    [req setSortDescriptors:@[sortDesc]];

    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Show" inManagedObjectContext:moc];
    [req setEntity:entity];
    
    NSPredicate *pred = nil;
    if (!isEditing) {
        NSMutableArray *predicateArray = [NSMutableArray array];
        
        [predicateArray addObject:[NSPredicate predicateWithFormat:@"self.hidden = NO"]];
        
        if (pred) {
            NSArray *subs = @[pred, [NSCompoundPredicate orPredicateWithSubpredicates:predicateArray]];
            pred = [NSCompoundPredicate andPredicateWithSubpredicates:subs];
        } else {
            pred = [NSCompoundPredicate orPredicateWithSubpredicates:predicateArray];
        }
    }
    [req setPredicate:pred];
    
    [req setFetchBatchSize:20];

    NSFetchedResultsController *frc = [[NSFetchedResultsController alloc] initWithFetchRequest:req
                                                                          managedObjectContext:moc
                                                                            sectionNameKeyPath:nil
                                                                                     cacheName:nil];// isEditing ? CACHE_NAME : EDIT_CACHE_NAME];
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
        _fetchedResultsController = [self newFetchedResultsControllerForEditing:NO];
    }
    
    return _fetchedResultsController;
}


- (NSFetchedResultsController *)editFetchedResultsController {
    if (!_editFetchedResultsController) {
        _editFetchedResultsController = [self newFetchedResultsControllerForEditing:YES];
    }
    return _editFetchedResultsController;
}

@end
