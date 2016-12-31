//
//  YBrowserWebAdvertViewController.m
//  FantasyFootball
//
//  Created by Todd Ditchendorf on 7/28/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import "TDBrowserViewController.h"
#import "SNAppDelegate.h"
#import "TDBackButton.h"
#import "TDUtils.h"
#import "TDHintView.h"
#import "TJReadLater.h"
#import <MobileCoreServices/MobileCoreServices.h>

#define INDEX_GOTO_SAFARI 0
#define INDEX_COPY_URL 1
#define INDEX_MAIL_URL 2
#define INDEX_TWEET_URL 3
#define INDEX_INSTAPAPER 4

#define LOAD_DID_END_TIMER_DELAY 2.0

#define LANDSCAPE_NAVBAR_HEIGHT 30.0

#define HINT_VIEW_HEIGHT 44.0

@interface TDBrowserViewController ()
- (void)setUpTitleLabel;
- (void)updateTitle;
- (void)updateToolbarFrame;
- (void)setUpToolbarItems;
- (void)updateToolbarItems;
- (void)setUpNavBar;
- (void)updateActionButtonEnabledState;
- (void)showActivityStarted;
- (void)showActivityStopped;
- (BOOL)isWebViewDoneLoading;

- (void)displayMailComposer;
- (void)launchMailApp;
- (void)fireRequest:(NSString *)s;
- (void)doSendToInstapaper;
- (CGRect)hintViewRectForBounds:(CGRect)bounds;

@property (nonatomic, retain) NSArray *idleToolbarItems;
@property (nonatomic, retain) NSArray *busyToolbarItems;
@end

@implementation TDBrowserViewController

- (id)init {
    return [self initWithNibName:@"BrowserView" bundle:nil];
}


- (id)initWithNibName:(NSString *)s bundle:(NSBundle *)b {
    self = [super initWithNibName:s bundle:nil];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(interfaceOrientationDidChange:) 
                                                     name:TDInterfaceOrientationDidChangeNotification 
                                                   object:nil];
    }
    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.delegate = nil;
    self.idleToolbarItems = nil;
    self.busyToolbarItems = nil;
    self.currentURL = nil;
    [super dealloc];
}


- (void)releaseOutlets {
    [webView stopLoading];
    webView.delegate = nil;

    self.navBar = nil;
    self.webView = nil;
    self.titleLabel = nil;
    self.bottomToolbar = nil;
    self.actionButtonItem = nil;
    self.backToolbarItem = nil;
    self.forwardToolbarItem = nil;
    self.stopToolbarItem = nil;
    self.reloadToolbarItem = nil;
    self.spinnerToolbarItem = nil;
    self.spinner = nil;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    defaultNavBarHeight = navBar.frame.size.height;
    
    [self setUpTitleLabel];
    [self setUpToolbarItems];
    [self setUpNavBar];
}


- (void)viewDidUnload {
    [super viewDidUnload];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateToolbarFrame];
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}


- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}


#pragma mark -
#pragma mark Actions

- (IBAction)dismiss:(id)sender {
    [webView stopLoading];
    webView.delegate = nil;

    [delegate browserViewControllerDidDismiss:self];
}


- (IBAction)goBack:(id)sender {
    [webView goBack];
}


- (IBAction)goForward:(id)sender {
    [webView goForward];
}


- (IBAction)stopLoading:(id)sender {
    [webView stopLoading];
    [self loadDidEnd];
}


- (IBAction)reload:(id)sender {
    [webView reload];
}


- (IBAction)action:(id)sender {
    UIActionSheet *sheet = nil;
    if ([TJInstapaper isLoggedIn]) {
        sheet = [[[UIActionSheet alloc] initWithTitle:nil
                                             delegate:self
                                    cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
                               destructiveButtonTitle:nil
                                    otherButtonTitles:NSLocalizedString(@"Open in Safari", @""),
                                                      NSLocalizedString(@"Copy Link", @""),
                                                      NSLocalizedString(@"Email Link", @""),
                                                      NSLocalizedString(@"Tweet Link", @""),
                                                      NSLocalizedString(@"Send to Instapaper", @""),
                                                      nil] autorelease];
    } else {
        sheet = [[[UIActionSheet alloc] initWithTitle:nil
                                             delegate:self
                                    cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
                               destructiveButtonTitle:nil
                                    otherButtonTitles:NSLocalizedString(@"Open in Safari", @""),
                                                      NSLocalizedString(@"Copy Link", @""),
                                                      NSLocalizedString(@"Email Link", @""),
                                                      NSLocalizedString(@"Tweet Link", @""),
                                                      nil] autorelease];
    }
    
    [sheet showInView:self.view];
}


- (IBAction)gotoSafari:(id)sender {
    NSURL *url = currentURL;
    if (url) {
        [[UIApplication sharedApplication] openURL:url];
    }
}


- (IBAction)mailURL:(id)sender {
    if (!currentURL) {
        return;
    }

    if ([MFMailComposeViewController canSendMail]) {
        [self displayMailComposer];
    } else {
        [self launchMailApp];
    }
}


- (IBAction)tweetURL:(id)sender {
    if (!currentURL) {
        return;
    }
    
    // try tweetie
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"tweetie:%@", [currentURL absoluteString]]];
    
    // fallback to twitter mobile web
    if (![[UIApplication sharedApplication] canOpenURL:url]) {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"http://twitter.com/home?status=%@", [currentURL absoluteString]]];
    }
    
    [[UIApplication sharedApplication] openURL:url];
}


- (IBAction)sendToInstapaper:(id)sender {
    if (!currentURL) {
        return;
    }

    if ([TJInstapaper isLoggedIn]) {
        [self doSendToInstapaper];
    } else {
        
    }

}


- (void)doSendToInstapaper {
    TDAssertMainThread();
    
    NSString *title = titleLabel.text;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    [TJInstapaper saveURL:[currentURL absoluteString] title:title callback:^(BOOL success) {
        TDAssertMainThread();
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
        CGRect bounds = self.view.bounds;
        CGRect r = [self hintViewRectForBounds:bounds];
        TDHintView *hv = [[[TDHintView alloc] initWithFrame:r] autorelease];
        
        NSString *txt = nil;
        if (success) {
            txt = NSLocalizedString(@"Sent to Instapaper.", @"");
        } else {
            txt = NSLocalizedString(@"Could not send to Instapaper.", @"");
        }
        hv.hintText = txt;
        hv.alpha = 0.0;
        [self.view addSubview:hv];
        [UIView animateWithDuration:0.5 animations:^{
            hv.alpha = 1.0;
        }];
        
        TDPerformOnMainThreadAfterDelay(2.0, ^{
            [UIView animateWithDuration:0.5 animations:^{
                hv.alpha = 0.0;
            } completion:^(BOOL finished) {
                [hv removeFromSuperview];
            }];
        });
    }];
}


- (CGRect)hintViewRectForBounds:(CGRect)bounds {
    CGFloat w = bounds.size.width * 0.75;

    CGFloat x = CGRectGetMidX(bounds) - w / 2.0;
    CGFloat y = 0.0;
    CGFloat h = HINT_VIEW_HEIGHT;

    CGRect r = CGRectMake(x, y, w, h);
    return r;
}


- (IBAction)copyURL:(id)sender {
    if (currentURL) {
        [[UIPasteboard generalPasteboard] setValue:currentURL forPasteboardType:@"public.url"]; //(id)kUTTypeURL];
    }
}


- (void)loadURL:(NSURL *)URL {
    [self loadRequest:[NSURLRequest requestWithURL:URL]];
}


- (void)loadRequest:(NSURLRequest *)req {
    self.currentURL = [req URL];
    [webView loadRequest:req];
}


#pragma mark -
#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)sheet clickedButtonAtIndex:(NSInteger)i {
    if (sheet.cancelButtonIndex == i) return;
    
    switch (i) {
        case INDEX_GOTO_SAFARI:
            [self gotoSafari:nil];
            break;
        case INDEX_COPY_URL:
            [self copyURL:nil];
            break;
        case INDEX_MAIL_URL:
            [self mailURL:nil];
            break;
        case INDEX_TWEET_URL:
            [self tweetURL:nil];
            break;
        case INDEX_INSTAPAPER:
            [self sendToInstapaper:nil];
            break;
        default:
            NSAssert1(0, @"unknown action sheet index: %d", i);
            break;
    }
}


#pragma mark -
#pragma mark Mail

- (void)displayMailComposer {
    MFMailComposeViewController *picker = [[[MFMailComposeViewController alloc] init] autorelease];
    picker.mailComposeDelegate = self;
    
    NSString *emailBody = [currentURL absoluteString];
    if ([emailBody length]) {
        [picker setMessageBody:emailBody isHTML:NO];
    }
    
    [self presentViewController:picker animated:YES completion:nil];
    //[self presentModalViewController:picker animated:YES];
}


- (void)launchMailApp {
    NSString *recipients = @"mailto:first@example.com";
    NSString *body = @"";
    
    NSString *s = [currentURL absoluteString];
    if ([s length]) {
        body = [NSString stringWithFormat:@"?body=%@", s];
    }
    
    NSString *email = [[NSString stringWithFormat:@"%@%@", recipients, body] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:email]];
}


- (void)fireRequest:(NSString *)s {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:s]];
    [NSURLConnection sendSynchronousRequest:req returningResponse:nil error:nil];
    [pool release];
}


#pragma mark -
#pragma mark MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
    //[self dismissModalViewControllerAnimated:YES];
}


#pragma mark -
#pragma mark UIWebViewDelegate

- (BOOL)webView:(UIWebView *)wv shouldStartLoadWithRequest:(NSURLRequest *)req navigationType:(UIWebViewNavigationType)type {
    //NSLog(@"%s %@", __PRETTY_FUNCTION__, req);
    if (!currentURL) {
        self.currentURL = [req URL];
    }
    [self updateTitle];
    return YES;
}


- (void)webViewDidStartLoad:(UIWebView *)wv {
    //NSLog(@"%s %@", __PRETTY_FUNCTION__, [[webView request] URL]);
    [self showActivityStarted];
    [self updateTitle];
}


- (void)webViewDidFinishLoad:(UIWebView *)wv {
    //NSLog(@"%s %@", __PRETTY_FUNCTION__, [[webView request] URL]);
    if ([self isWebViewDoneLoading]) {
        [self loadDidEnd];
    }
}


- (void)webView:(UIWebView *)wv didFailLoadWithError:(NSError *)err {
    [self loadDidEnd];
}


#pragma mark -
#pragma mark Private

- (void)setUpTitleLabel {
    self.titleLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 40)] autorelease];
    self.navigationItem.titleView = titleLabel;
    [titleLabel setBackgroundColor:[UIColor clearColor]];
    [titleLabel setTextAlignment:NSTextAlignmentCenter];
    [titleLabel setAdjustsFontSizeToFitWidth:YES];
    [titleLabel setMinimumScaleFactor:0.8];
    [titleLabel setFont:[UIFont boldSystemFontOfSize:12]];
    [titleLabel setTextColor:[UIColor colorWithRed:60.0/255.0 green:70.0/255.0 blue:81.0/255.0 alpha:1]];
    [titleLabel setShadowColor:[UIColor colorWithWhite:1 alpha:.3]];
    [titleLabel setShadowOffset:CGSizeMake(0, 1)];    
}


- (void)updateTitle {
    titleLabel.text = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
}


- (void)setUpToolbarItems {
    self.idleToolbarItems = bottomToolbar.items;
    
    NSMutableArray *a = [[idleToolbarItems mutableCopy] autorelease];
    // remove refresh button
    [a removeLastObject];
    
    // add spinner
    spinner.frame = CGRectMake(0, 0, 18, 18);
    self.spinnerToolbarItem = [[[UIBarButtonItem alloc] initWithCustomView:spinner] autorelease];
    [a addObject:spinnerToolbarItem];
    
    self.busyToolbarItems = a;
    [self updateToolbarItems];
}


- (void)setUpNavBar {
    //    UIButton *b = [TDBackButton backButton];
    //    [b addTarget:self action:@selector(dismiss:) forControlEvents:UIControlEventTouchUpInside];
    //    b.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    //
    //    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:b] autorelease];

    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", @"")
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(dismiss:)] autorelease];

    if (!actionButtonHidden) {
        self.actionButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                               target:self
                                                                               action:@selector(action:)] autorelease];
        self.navigationItem.rightBarButtonItem = actionButtonItem;
        [self updateActionButtonEnabledState];
    }
    
    [navBar setItems:[NSArray arrayWithObject:self.navigationItem] animated:NO];    
}


- (void)updateToolbarFrame {
    CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    //    NSLog(@"appFrame %@", NSStringFromCGRect(appFrame));
    UIInterfaceOrientation o = [[UIApplication sharedApplication] statusBarOrientation];
    CGFloat toolbarHeight = 0;
    if (UIInterfaceOrientationIsLandscape(o)) {
        appFrame = CGRectMake(appFrame.origin.y, appFrame.origin.x, appFrame.size.height, appFrame.size.width);
        toolbarHeight = LANDSCAPE_NAVBAR_HEIGHT;
    } else {
        toolbarHeight = defaultNavBarHeight;
    }
    CGRect toolbarFrame = CGRectMake(0, appFrame.size.height - toolbarHeight, appFrame.size.width, toolbarHeight);
    //    NSLog(@"frame %@", NSStringFromCGRect(frame));
    [bottomToolbar setFrame:toolbarFrame];
    [bottomToolbar setNeedsLayout];
    
    CGRect webFrame = [webView frame];
    webFrame.size.height = appFrame.size.height - defaultNavBarHeight - toolbarHeight;
    [webView setFrame:webFrame];
}


- (void)updateToolbarItems {
    [self updateActionButtonEnabledState];
    backToolbarItem.enabled = webView.canGoBack;
    forwardToolbarItem.enabled = webView.canGoForward;
}


- (void)updateActionButtonEnabledState {
    actionButtonItem.enabled = (nil != currentURL);
}


- (void)showActivityStarted {
    [self updateActionButtonEnabledState];
    bottomToolbar.items = busyToolbarItems;
    stopToolbarItem.enabled = YES;
    [spinner startAnimating];
}


- (void)showActivityStopped {
    bottomToolbar.items = idleToolbarItems;
    stopToolbarItem.enabled = NO;
    [spinner stopAnimating];
}


- (BOOL)isWebViewDoneLoading {
    NSString *s = [webView stringByEvaluatingJavaScriptFromString:@"document.readyState"];
    //NSLog(@"%s %@", _cmd, s);
    return [[s lowercaseString] isEqualToString:@"complete"];
}


- (void)loadDidEnd {
    [self updateTitle];
    [self updateToolbarItems];
    [self showActivityStopped];
}


#pragma mark -
#pragma mark Notifications

- (void)interfaceOrientationDidChange:(NSNotification *)n {
    [self updateToolbarFrame];
}

@synthesize delegate;
@synthesize navBar;
@synthesize webView;
@synthesize backToolbarItem;
@synthesize bottomToolbar;
@synthesize actionButtonItem;
@synthesize forwardToolbarItem;
@synthesize stopToolbarItem;
@synthesize reloadToolbarItem;
@synthesize titleLabel;
@synthesize spinnerToolbarItem;
@synthesize spinner;
@synthesize idleToolbarItems;
@synthesize busyToolbarItems;
@synthesize currentURL;
@end