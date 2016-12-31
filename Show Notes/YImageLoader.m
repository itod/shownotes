//
//  YImageLoader.m
//  FantasyFootball
//
//  Created by Todd Ditchendorf on 8/4/09.
//  Copyright 2009 Yahoo! Inc.. All rights reserved.
//

#import "YImageLoader.h"

@interface YImageLoader ()
- (void)releaseRequestData;
- (void)handleNetworkErrorForURL:(NSURL *)URL;
- (void)handleErrorForURL:(NSURL *)URL message:(NSString *)msg domain:(NSString *)domain;
@end

@implementation YImageLoader

- (id)initWithDelegate:(id <YImageLoaderDelegate>)d {
    if (self = [super init]) {
        delegate = d;
    }
    return self;
}


- (void)dealloc {
    delegate = nil;
    [self releaseRequestData];
    [super dealloc];
}


#pragma mark -
#pragma mark Private

- (void)releaseRequestData {
    self.connection = nil;
    self.receivedData = nil;
    self.errorMessage = nil;
}


#pragma mark -
#pragma mark Public

- (void)loadImageForRequest:(NSURLRequest *)req {
    NSParameterAssert(req);
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];

    self.connection = [[[NSURLConnection alloc] initWithRequest:req delegate:self startImmediately:YES] autorelease];
    if (connection) {
        self.receivedData = [NSMutableData data];
    } else {
        [self handleNetworkErrorForURL:[req URL]];
    }
}


- (void)loadImageForURL:(NSURL *)URL {
    NSParameterAssert([[URL absoluteString] length]);
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:URL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    
    [self loadImageForRequest:req];
}


- (void)cancel {
    [connection cancel];
    [self releaseRequestData];
}


- (void)handleImageResponse:(UIImage *)image {
    if (image) {
        // success
        [delegate imageLoader:self didSucceed:image];
    } else {
        [self handleNetworkErrorForURL:baseURL];
    }
    
    // dont release here causes race condition if this docLoader is used multiple times.
    // [self releaseRequestData];
}


- (void)handleNetworkErrorForURL:(NSURL *)URL {
    NSString *msg = NSLocalizedString(@"Unable to establish network connection", @"");    
    [self handleErrorForURL:URL message:msg domain:@"YImageLoaderNetworkConnectionErrorDomain"];
}


- (void)handleErrorForURL:(NSURL *)URL message:(NSString *)msg domain:(NSString *)domain {
    id userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                   URL, NSURLErrorKey,
#if defined(__IPHONE_4_0)
                   [URL absoluteString], NSURLErrorFailingURLStringErrorKey,
#else
                   [URL absoluteString], NSErrorFailingURLStringKey,
#endif
                   msg, NSLocalizedDescriptionKey,
                   nil];
    
    [delegate imageLoader:self didFail:[NSError errorWithDomain:domain code:-1 userInfo:userInfo]];
    
    OKLog(@"NETWORK FAIL");    
}


#pragma mark -
#pragma mark NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)c didReceiveResponse:(NSURLResponse *)response {
    [receivedData setLength:0];
    
    self.baseURL = [response URL];
}


- (NSURLRequest *)connection:(NSURLConnection *)c willSendRequest:(NSURLRequest *)req redirectResponse:(NSURLResponse *)response {
    return req;
}


- (void)connection:(NSURLConnection *)c didReceiveData:(NSData *)data {
    [receivedData appendData:data];
}


- (void)connection:(NSURLConnection *)c didFailWithError:(NSError *)err {
    [delegate imageLoader:self didFail:err];
    
    // dont release here causes race condition if this docLoader is used multiple times.
    // [self releaseRequestData];
	
	OKLog(@"Connection failed! Error - %@ %@", [err localizedDescription], [[err userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
}


- (NSCachedURLResponse *)connection:(NSURLConnection *)c willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    // no cache-y :|
    return nil;
}


- (void)connectionDidFinishLoading:(NSURLConnection *)c {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    UIImage *image = [UIImage imageWithData:receivedData];
    [self handleImageResponse:image];
}

@synthesize connection;
@synthesize receivedData;
@synthesize baseURL;
@synthesize errorMessage;
@end
