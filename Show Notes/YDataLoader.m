//
//  YDataLoader.m
//  FantasyFootball
//
//  Created by Todd Ditchendorf on 8/10/09.
//  Copyright 2009 Yahoo! Inc.. All rights reserved.
//

#import "YDataLoader.h"
#import "NSMutableURLRequest+AppGateway.h"

@interface YDataLoader ()
- (void)handleDataResponse:(NSData *)data;
- (void)handleErrorForURL:(NSURL *)URL message:(NSString *)msg domain:(NSString *)domain;
- (void)failWithError:(NSError *)err;
- (void)handleNetworkErrorForURL:(NSURL *)URL;
- (void)releaseRequestData;
@end

@implementation YDataLoader

- (id)initWithDelegate:(id <YDataLoaderDelegate>)d {
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

- (void)loadDataForRequest:(NSURLRequest *)req {
    NSParameterAssert(req);
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    self.connection = [[[NSURLConnection alloc] initWithRequest:req delegate:self startImmediately:YES] autorelease];
    if (connection) {
        self.receivedData = [NSMutableData data];
    } else {
        [self handleNetworkErrorForURL:[req URL]];
    }
}


- (void)loadDataForURL:(NSURL *)URL {
    NSParameterAssert([[URL absoluteString] length]);
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:URL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    [req addYahooHeaders];
    
    [self loadDataForRequest:req];
}


- (void)cancel {
    [connection cancel];
    [self releaseRequestData];
}


- (void)handleDataResponse:(NSData *)data {
    if (data) {
        // success
        [delegate dataLoader:self didSucceed:data];
    } else {
        [self handleNetworkErrorForURL:baseURL];
    }
    
    // dont release here causes race condition if this docLoader is used multiple times.
    // [self releaseRequestData];
}


- (void)handleNetworkErrorForURL:(NSURL *)URL {
    NSString *msg = NSLocalizedString(@"Unable to establish network connection", @"");    
    [self handleErrorForURL:URL message:msg domain:[NSString stringWithFormat:@"%@NetworkConnectionErrorDomain", [self class]]];
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
    
    [self failWithError:[NSError errorWithDomain:domain code:-1 userInfo:userInfo]];
    
    OKLog(@"NETWORK FAIL");    
}


- (void)failWithError:(NSError *)err {
    [delegate dataLoader:self didFail:err];
}


#pragma mark -
#pragma mark NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)c didReceiveResponse:(NSURLResponse *)response {
    [receivedData setLength:0];
    
    self.baseURL = [response URL];
    
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *rsp = (NSHTTPURLResponse *)response;
        
        NSArray *pathComponents = [[[rsp URL] path] componentsSeparatedByString:@"/"];
        if ([pathComponents count] < 2) return;
            
        NSString *uriFragment = [NSString stringWithFormat:@"/%@/", [pathComponents objectAtIndex:1]];
        
        switch ([rsp statusCode]) {
            case 200:
                break;
            case 401:
            case 407:
                [NSMutableURLRequest handle407Response:response withURIFragment:uriFragment];
                [connection cancel];
                [self loadDataForURL:[rsp URL]];
                break;
            default:
                //OKLog(@"HTTP Response Code: %d", [rsp statusCode]);
                break;
        }
    }
}


- (void)connection:(NSURLConnection *)c didReceiveData:(NSData *)data {
    [receivedData appendData:data];
}


- (void)connection:(NSURLConnection *)c didFailWithError:(NSError *)err {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [self failWithError:err];
    
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

    [self handleDataResponse:receivedData];
}

@synthesize connection;
@synthesize receivedData;
@synthesize baseURL;
@synthesize errorMessage;
@end
