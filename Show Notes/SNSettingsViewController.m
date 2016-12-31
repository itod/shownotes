//
//  SNSettingsViewController.m
//  Show Notes
//
//  Created by Todd Ditchendorf on 11/17/12.
//  Copyright (c) 2012 Todd Ditchendorf. All rights reserved.
//

#import "SNSettingsViewController.h"
#import "TJReadLater.h"

@interface SNSettingsViewController ()

@end

@implementation SNSettingsViewController

- (id)init {
    self = [self initWithStyle:UITableViewStyleGrouped];
    return self;
}


- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {

    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Settings", @"");
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                           target:self
                                                                                           action:@selector(done:)];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark -
#pragma mark Actions

- (IBAction)done:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - 
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)section {
    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.text = NSLocalizedString(@"Instapaper", @"");
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}


#pragma mark -
#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIViewController *avc = [[TJReadingServiceViewController alloc] initWithService:[TJInstapaper class]];
    [self.navigationController pushViewController:avc animated:YES];
}

@end
