//
//  SNEpisodeDetailViewController.m
//  Show Notes
//
//  Created by Todd Ditchendorf on 10/22/12.
//  Copyright (c) 2012 Todd Ditchendorf. All rights reserved.
//

#import "SNEpisodeDetailViewController.h"

@interface SNEpisodeDetailViewController ()
- (void)setUpTitleLabel;
- (void)presentBrowserWithRequest:(NSURLRequest *)req;
@end

@implementation SNEpisodeDetailViewController

- (id)init {
    self = [self initWithNibName:NSStringFromClass([self class]) bundle:nil];
    return self;
}


- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)b {
    self = [super initWithNibName:nibName bundle:b];
    if (self) {

    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];

    [self setUpTitleLabel];
    
    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    [fmt setDateStyle:kCFDateFormatterFullStyle];
    
    NSDate *pubDate = [self.episode valueForKey:@"pubDate"];
    self.pubDateLabel.text = [fmt stringFromDate:pubDate];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"detail" ofType:@"html"];
    NSString *htmlFmt = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    NSString *body = [self.episode valueForKey:@"body"];
    NSString *htmlStr = [NSString stringWithFormat:htmlFmt, body];
    [self.webView loadHTMLString:htmlStr baseURL:nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];

}


#pragma mark -
#pragma mark UIWebViewDelegate

- (BOOL)webView:(UIWebView *)wv shouldStartLoadWithRequest:(NSURLRequest *)req navigationType:(UIWebViewNavigationType)type {
    BOOL result = NO;
    
    switch (type) {
        case UIWebViewNavigationTypeOther: // initial load
            result = YES;
            break;
        case UIWebViewNavigationTypeLinkClicked:
        default:
            [self presentBrowserWithRequest:req];
            break;
    }
    
    return result;
}


#pragma mark -
#pragma mark TDBrowserViewControllerDelegate

- (void)browserViewControllerDidDismiss:(TDBrowserViewController *)bvc {
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark -
#pragma mark Private

- (void)setUpTitleLabel {
    self.title = [self.episode valueForKey:@"shortTitle"];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100.0, 40.0)];
    self.navigationItem.titleView = titleLabel;
    
    [titleLabel setBackgroundColor:[UIColor clearColor]];
    [titleLabel setTextAlignment:NSTextAlignmentCenter];
    [titleLabel setFont:[UIFont boldSystemFontOfSize:15.0]];
    [titleLabel setTextColor:[UIColor whiteColor]];
    [titleLabel setShadowColor:[UIColor colorWithWhite:0.0 alpha:0.5]];
    [titleLabel setShadowOffset:CGSizeMake(0.0, -1.0)];
    
    titleLabel.adjustsFontSizeToFitWidth = YES;
    titleLabel.minimumScaleFactor = 0.75;
    
    titleLabel.text = self.title;
    self.navigationItem.titleView = titleLabel;
}


- (void)presentBrowserWithRequest:(NSURLRequest *)req {
    TDBrowserViewController *bvc = [[TDBrowserViewController alloc] init];
    bvc.delegate = self;
    
    [self presentViewController:bvc animated:YES completion:^{
        [bvc loadRequest:req];
    }];
}

@end
