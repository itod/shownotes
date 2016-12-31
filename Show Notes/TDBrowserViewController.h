//
//  YBrowserWebAdvertViewController.h
//  FantasyFootball
//
//  Created by Todd Ditchendorf on 7/28/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import "TDBaseViewController.h"
#import <MessageUI/MessageUI.h>

@class TDBrowserViewController;

@protocol TDBrowserViewControllerDelegate <NSObject>
- (void)browserViewControllerDidDismiss:(TDBrowserViewController *)bvc;
@end

@interface TDBrowserViewController : TDBaseViewController <UIWebViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate> {
    id <TDBrowserViewControllerDelegate>delegate;

    UINavigationBar *navBar;
    UIWebView *webView;
    UILabel *titleLabel;
    UIToolbar *bottomToolbar;
    UIBarButtonItem *actionButtonItem;
    UIBarButtonItem *backToolbarItem;
    UIBarButtonItem *forwardToolbarItem;
    UIBarButtonItem *stopToolbarItem;
    UIBarButtonItem *reloadToolbarItem;
    UIBarButtonItem *spinnerToolbarItem;
    UIActivityIndicatorView *spinner;
    
    NSArray *idleToolbarItems;
    NSArray *busyToolbarItems;
    
    BOOL actionButtonHidden;
    NSURL *currentURL;
    
    CGFloat defaultNavBarHeight;
}

- (IBAction)dismiss:(id)sender;

- (IBAction)goBack:(id)sender;
- (IBAction)goForward:(id)sender;
- (IBAction)stopLoading:(id)sender;
- (IBAction)reload:(id)sender;
- (IBAction)action:(id)sender;

- (IBAction)gotoSafari:(id)sender;
- (IBAction)mailURL:(id)sender;
- (IBAction)tweetURL:(id)sender;
- (IBAction)copyURL:(id)sender;
- (IBAction)sendToInstapaper:(id)sender;

- (void)loadURL:(NSURL *)URL;
- (void)loadRequest:(NSURLRequest *)req;

- (void)loadDidEnd;

@property (nonatomic, assign) id <TDBrowserViewControllerDelegate>delegate;
@property (nonatomic, retain) NSURL *currentURL;

@property (nonatomic, retain) IBOutlet UINavigationBar *navBar;
@property (nonatomic, retain) IBOutlet UIWebView *webView;
@property (nonatomic, retain) IBOutlet UILabel *titleLabel;
@property (nonatomic, retain) IBOutlet UIToolbar *bottomToolbar;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *actionButtonItem;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *backToolbarItem;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *forwardToolbarItem;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *stopToolbarItem;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *reloadToolbarItem;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *spinnerToolbarItem;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *spinner;
@end
