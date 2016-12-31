//
//  SNAppDelegate.m
//  Show Notes
//
//  Created by Todd Ditchendorf on 10/21/12.
//  Copyright (c) 2012 Todd Ditchendorf. All rights reserved.
//

#import "SNAppDelegate.h"
#import "SNShowListViewController.h"
#import "SNEpisodeListViewController.h"

NSString * const TDInterfaceOrientationDidChangeNotification = @"TDInterfaceOrientationDidChange";

@interface SNAppDelegate ()
@property (readwrite, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readwrite, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readwrite, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@end

@implementation SNAppDelegate

#pragma mark -
#pragma mark NSApplication Delegate

- (BOOL)application:(UIApplication *)app didFinishLaunchingWithOptions:(NSDictionary *)opts {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    SNShowListViewController *showvc = [[SNShowListViewController alloc] init];

    if (TDIsPhone()) {
        self.navigationController = [[UINavigationController alloc] initWithRootViewController:showvc];
        self.window.rootViewController = self.navigationController;
        showvc.managedObjectContext = self.managedObjectContext;

    } else {
        UINavigationController *shownc = [[UINavigationController alloc] initWithRootViewController:showvc];
        
        SNEpisodeListViewController *epvc = [[SNEpisodeListViewController alloc] init];
        epvc.managedObjectContext = self.managedObjectContext;
    	showvc.episodeListViewController = epvc;
        
        UINavigationController *epnc = [[UINavigationController alloc] initWithRootViewController:epvc];

        self.splitViewController = [[UISplitViewController alloc] init];
        self.splitViewController.delegate = epvc;
        self.splitViewController.viewControllers = @[shownc, epnc];
        
        self.window.rootViewController = self.splitViewController;
        showvc.managedObjectContext = self.managedObjectContext;
    }

    [self.window makeKeyAndVisible];
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)app {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)app {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)app {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)app {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)app {
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}


- (void)application:(UIApplication *)app didChangeStatusBarOrientation:(UIInterfaceOrientation)oldOrientation {
    SEL sel = @selector(postInterfaceOrientationDidChangeNotification);
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:sel object:nil];
    [self performSelector:sel withObject:nil afterDelay:0];
}


- (void)postInterfaceOrientationDidChangeNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:TDInterfaceOrientationDidChangeNotification object:nil];
}


- (void)saveContext {
    NSError *error = nil;
    NSManagedObjectContext *moc = self.managedObjectContext;
    if (moc && [moc hasChanges] && ![moc save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
}


#pragma mark -
#pragma mark Core Data

- (NSManagedObjectContext *)managedObjectContext {
    if (!_managedObjectContext) {
        NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
        if (coordinator != nil) {
            _managedObjectContext = [[NSManagedObjectContext alloc] init];
            [_managedObjectContext setPersistentStoreCoordinator:coordinator];
        }
    }
    
    return _managedObjectContext;
}


- (NSManagedObjectModel *)managedObjectModel {
    if (!_managedObjectModel) {
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Show_Notes" withExtension:@"momd"];
        _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    }
    
    return _managedObjectModel;
}


- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (!_persistentStoreCoordinator) {
    
        NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Show_Notes.sqlite"];
        
        NSError *error = nil;
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
        if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
             
             Typical reasons for an error here include:
             * The persistent store is not accessible;
             * The schema for the persistent store is incompatible with current managed object model.
             Check the error message to determine what the actual problem was.
             
             
             If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
             
             If you encounter schema incompatibility errors during development, you can reduce their frequency by:
             * Simply deleting the existing store:
             [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
             
             * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
             @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
             
             Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
             
             */
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
    
    return _persistentStoreCoordinator;
}


#pragma mark - 
#pragma mark Properties

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
