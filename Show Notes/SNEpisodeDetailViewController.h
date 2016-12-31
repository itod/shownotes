//
//  SNEpisodeDetailViewController.h
//  Show Notes
//
//  Created by Todd Ditchendorf on 10/22/12.
//  Copyright (c) 2012 Todd Ditchendorf. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TDBrowserViewController.h"

@interface SNEpisodeDetailViewController : UIViewController <UIWebViewDelegate, TDBrowserViewControllerDelegate>

- (id)init;

@property (strong, nonatomic) IBOutlet UIWebView *webView;
@property (strong, nonatomic) IBOutlet UILabel *pubDateLabel;
@property (strong, nonatomic) id episode;
@end
