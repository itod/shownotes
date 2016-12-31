//
//  TDBaseViewController.m
//  ShortURL
//
//  Created by Todd Ditchendorf on 9/19/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import "TDBaseViewController.h"

@implementation TDBaseViewController

- (void)dealloc {
    [self releaseOutlets];
    [super dealloc];
}


- (void)releaseOutlets {
//    NSAssert1(0, @"%s is abstract and must be overriden", __PRETTY_FUNCTION__);
}


//- (void)viewDidLoad {
//    [super viewDidLoad];
//}


- (void)viewDidUnload {
    [super viewDidUnload];
    [self releaseOutlets]; 
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)o {
    return UIInterfaceOrientationIsLandscape(o) || o == UIInterfaceOrientationPortrait;
}


//- (void)viewWillAppear:(BOOL)animated {
//    [super viewWillAppear:animated];
//}
//
//
//- (void)viewDidAppear:(BOOL)animated {
//    [super viewDidAppear:animated];
//}
//
//
//- (void)viewWillDisappear:(BOOL)animated {
//    [super viewWillDisappear:animated];
//}
//
//
//- (void)viewDidDisappear:(BOOL)animated {
//    [super viewDidDisappear:animated];
//}

@end

