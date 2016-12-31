//
//  FBRemoteXMLLoader.m
//  FantasyFootball
//
//  Created by Todd Ditchendorf on 6/3/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import "XMLDocLoader.h"
#import <libxml/parser.h>
#import <libxml/xmlerror.h>
#import "NSString+libxml2Support.h"

#define MAX_RETRIES 4

@interface XMLDocLoader ()
- (void)sendBody:(NSString *)s withMethod:(NSString *)method forURL:(NSURL *)URL;

- (void)releaseRequestData;
- (NSMutableURLRequest *)copyRequestWithURL:(NSURL *)URL;
- (void)setupXMLErrorHandlers;
- (void)incrementErrorCount;
- (void)handleNetworkErrorForURL:(NSURL *)URL;
- (void)handleXMLErrorForURL:(NSURL *)URL;
//- (void)handleXMLResponse:(NSString *)XMLString;
- (void)handleXMLResponseData:(NSData *)data;
- (void)handleErrorForURL:(NSURL *)URL message:(NSString *)msg domain:(NSString *)domain;

- (NSStringEncoding)currentStringEncoding;
- (NSString *)currentStringEncodingName;
@end

static void myGenericErrorHandler(XMLDocLoader *self, const char *msg, ...) {
    @try {
        va_list vargs;
        va_start(vargs, msg);
        
        NSString *s = [[[NSString alloc] initWithFormat:[NSString stringWithUTF8String:msg] arguments:vargs] autorelease];
        
        if (self) {
            [self setErrorMessage:s];
            [self incrementErrorCount];
        }
        
        NSLog(@"%@", s); // format for safety
        
        va_end(vargs);
    } @catch (NSException *e) {
        
    }
}

@implementation XMLDocLoader

- (id)initWithDelegate:(id <XMLDocLoaderDelegate>)d {
    if (self = [super init]) {
        self.delegate = d;
        self.retryCount = 0;
        self.defaultStringEncoding = NSUTF8StringEncoding;
        [self setupXMLErrorHandlers];
    }
    return self;
}


- (void)dealloc {
    //TDAssertMainThread();
    self.delegate = nil;
    [self releaseRequestData];
    [super dealloc];
}


#pragma mark -
#pragma mark Private

- (void)releaseRequestData {
    //TDAssertMainThread();
    [self.connection cancel];
    self.connection = nil;
    self.request = nil;
    self.receivedData = nil;
    self.baseURL = nil;
    self.textEncodingName = nil;
    self.errorMessage = nil;
}


- (void)setupXMLErrorHandlers {
    //xmlSetGenericErrorFunc((void *)self, (xmlGenericErrorFunc)myGenericErrorHandler);
}


- (void)incrementErrorCount {
    _errorCount++;
}


//- (void)handleXMLResponse:(NSString *)XMLString {
//    //NSLog(@"XMLString:%@", XMLString);
//    
//    xmlDocPtr doc = xmlReadDoc((const xmlChar *)[XMLString UTF8String], 
//                               [[baseURL absoluteString] UTF8String], 
//                               "utf-8", 
//                               XML_PARSE_NONET|XML_PARSE_NOENT|XML_PARSE_NOCDATA); // forbid network access|merge CDATA nodes to surrounding text nodes
//    
//    if (doc && xmlDocGetRootElement(doc)) { // TODO check for errorCount here?
//        
//        // success
//        if (delegate) {
//            [delegate docLoader:self didSucceed:doc];
//        } else {
//            xmlFreeDoc(doc);
//            doc = NULL;
//        }
//    } else {
//        [self handleXMLErrorForURL:baseURL];
//    }
//    
//    // dont release here causes race condition if this docLoader is used multiple times.
//    // [self releaseRequestData];
//}


- (void)handleXMLResponseData:(NSData *)data {
//    xmlParserCtxtPtr ctx = xmlNewParserCtxt();
//    xmlCtxtUseOptions(ctx, XML_PARSE_NONET|XML_PARSE_NOENT|XML_PARSE_NOCDATA);
//    
//    xmlDocPtr doc = xmlCtxtReadMemory(ctx,
//                                      [receivedData bytes], 
//                                      [receivedData length], 
//                                      [[baseURL absoluteString] UTF8String], 
//                                      [[self currentStringEncodingName] UTF8String], 
//                                      0);
   
#if DEBUG
    NSString *s = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    (void)s;
#endif

    xmlDocPtr doc = xmlReadMemory([data bytes],
                                  [data length],
                                  [[self.baseURL absoluteString] UTF8String],
                                  [[self currentStringEncodingName] UTF8String], 
                                  XML_PARSE_RECOVER|XML_PARSE_NONET|XML_PARSE_NOCDATA);
    
    TDPerformOnMainThread(^{
        [self handleParsedDoc:doc];
    });
}


- (void)handleParsedDoc:(xmlDocPtr)doc {
    TDAssertMainThread();

    if (doc && xmlDocGetRootElement(doc)) { // TODO check for errorCount here?
        
        id <XMLDocLoaderDelegate>d = self.delegate;
        // success
        if (d) {
            [d docLoader:self didSucceed:doc];
        } else {
            xmlFreeDoc(doc);
            doc = NULL;
//            xmlFreeParserCtxt(ctx);
//            ctx = NULL;
        }
    } else {
        [self handleXMLErrorForURL:self.baseURL];
    }
    
    // dont release here causes race condition if this docLoader is used multiple times.
    // [self releaseRequestData];
}


#pragma mark -
#pragma mark Public

- (void)loadDocumentForRequest:(NSMutableURLRequest *)req {
    TDAssertMainThread();
    NSParameterAssert(req);
    
    self.request = req;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    self.errorCount = 0;
    
//    // fake response
//    if (delegate && [delegate respondsToSelector:@selector(fakeXMLStringForURLString:)]) {
//        NSString *XMLString = [delegate fakeXMLStringForURLString:[[req URL] absoluteString]];
//        self.receivedData = [NSMutableData dataWithData:[XMLString dataUsingEncoding:NSUTF8StringEncoding]];
//        [self handleXMLResponse];
//        return;
//    }
    
    self.connection = [[[NSURLConnection alloc] initWithRequest:req delegate:self startImmediately:YES] autorelease];
    if (_connection) {
        self.receivedData = [NSMutableData data];
    } else {
        [self handleNetworkErrorForURL:[req URL]];
    }
}


- (void)loadDocumentForURL:(NSURL *)URL {
    NSParameterAssert([[URL absoluteString] length]);
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:URL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    
    [self loadDocumentForRequest:req];
}


- (void)loadDocumentForFile:(NSString *)path {
    TDPerformOnBackgroundThread(^{
        NSData *data = [NSData dataWithContentsOfFile:path options:NSDataReadingMappedIfSafe error:nil];
        [self handleXMLResponseData:data];
    });
}


- (void)putBody:(NSString *)s forURL:(NSURL *)URL {
    [self sendBody:s withMethod:@"PUT" forURL:URL];
}


- (void)postBody:(NSString *)s forURL:(NSURL *)URL {
    [self sendBody:s withMethod:@"POST" forURL:URL];
}


- (void)sendBody:(NSString *)s withMethod:(NSString *)method forURL:(NSURL *)URL {
    NSParameterAssert([s length]);
    NSParameterAssert([[URL absoluteString] length]);
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:URL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    [req setHTTPMethod:method];
    [req setHTTPBody:[s dataUsingEncoding:NSUTF8StringEncoding]];
    [req setValue:@"application/xml" forHTTPHeaderField:@"content-type"]; // required by api
        
    [self loadDocumentForRequest:req];    
}


- (void)cancel {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [self.connection cancel];
    [self releaseRequestData];
}


- (void)handleNetworkErrorForURL:(NSURL *)URL {
    NSString *msg = NSLocalizedString(@"Unable to establish network connection", @"");    
    [self handleErrorForURL:URL message:msg domain:@"XMLLoaderNetworkConnectionErrorDomain"];
}


- (void)handleXMLErrorForURL:(NSURL *)URL {
    NSString *msg = NSLocalizedString(@"Unable to parse XML Document", @"");
    if (_errorMessage) {
        msg = [NSString stringWithFormat:@"%@: %@", msg, _errorMessage];
    }
    
    [self handleErrorForURL:self.baseURL message:msg domain:@"XMLLoaderDocumentParsingErrorDomain"];
}


- (void)handleErrorForURL:(NSURL *)URL message:(NSString *)msg domain:(NSString *)domain {
    id userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                   URL, NSURLErrorKey,
                   [URL absoluteString], NSURLErrorFailingURLStringErrorKey,
                   msg, NSLocalizedDescriptionKey,
                   nil];
    
    [self.delegate docLoader:self didFail:[NSError errorWithDomain:domain code:-1 userInfo:userInfo]];
}


- (NSStringEncoding)currentStringEncoding {
    NSStringEncoding enc = self.defaultStringEncoding;
    
    if ([self.textEncodingName length]) {
        CFStringEncoding cfenc = CFStringConvertIANACharSetNameToEncoding((CFStringRef)self.textEncodingName);
        if (kCFStringEncodingInvalidId != cfenc && CFStringIsEncodingAvailable(cfenc)) {
            enc = CFStringConvertEncodingToNSStringEncoding(cfenc);
        } else {
            enc = self.defaultStringEncoding;
        }
    }
    
    return enc;
}


- (NSString *)currentStringEncodingName {
    NSStringEncoding enc = [self currentStringEncoding];
    NSString *name = (id)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(enc));
//    NSLog(@"encoding Name: %@", name);
    return name;
}


#pragma mark -
#pragma mark NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)c didReceiveResponse:(NSURLResponse *)response {
    TDAssertMainThread();
    [self.receivedData setLength:0];
    
    self.baseURL = [response URL];
    self.textEncodingName = [response textEncodingName];
    
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *rsp = (NSHTTPURLResponse *)response;

        if (self.retryCount++ > MAX_RETRIES || 403 == [rsp statusCode]) {
            [self.connection cancel];
            return;
        }
                
        switch ([rsp statusCode]) {
            case 200:
                break;
            case 401:
            case 407: {
                //NSArray *pathComponents = [[[rsp URL] path] componentsSeparatedByString:@"/"];
                //NSString *uriFragment = [NSString stringWithFormat:@"/%@/", [pathComponents objectAtIndex:1]];
                
                NSString *method = [[self.request HTTPMethod] uppercaseString];
                //[NSMutableURLRequest handle407Response:response withURIFragment:uriFragment method:method];
                
                BOOL isPut = [@"PUT" isEqualToString:method];
                BOOL isPost = [@"POST" isEqualToString:method];
                if (isPut || isPost) {
                    [self.connection cancel];
                    
                    NSString *body = [[[NSString alloc] initWithData:[self.request HTTPBody] encoding:[self currentStringEncoding]] autorelease];
                    
                    if (isPut) {
                        [self putBody:body forURL:[rsp URL]];
                    } else {
                        [self postBody:body forURL:[rsp URL]];
                    }
                } else {
                    [self.connection cancel];
                    [self loadDocumentForURL:[rsp URL]];
                }
            } break;
            default:
                NSLog(@"HTTP Response Code: %d", [rsp statusCode]);
                break;
        }
    }
}


- (void)connection:(NSURLConnection *)c didReceiveData:(NSData *)data {
    TDAssertMainThread();
    [self.receivedData appendData:data];
}


- (void)connection:(NSURLConnection *)c didFailWithError:(NSError *)err {
    TDAssertMainThread();
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [self.delegate docLoader:self didFail:err];
    
    // dont release here causes race condition if this docLoader is used multiple times.
    // [self releaseRequestData];
	NSLog(@"Connection failed! Error - %@ %@", [err localizedDescription], [[err userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
}


- (NSCachedURLResponse *)connection:(NSURLConnection *)c willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    // no cache-y :|
    return nil;
}


- (void)connectionDidFinishLoading:(NSURLConnection *)c {
    TDAssertMainThread();
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
//    NSMutableString *XMLString = [[[NSMutableString alloc] initWithBytes:[receivedData bytes] 
//                                                                  length:[receivedData length]
//                                                                encoding:[self currentStringEncoding]] autorelease];    
//    [self handleXMLResponse:XMLString];
    
    NSData *data = [[self.receivedData copy] autorelease];
    TDPerformOnBackgroundThread(^{
        [self handleXMLResponseData:data];
    });
}


- (NSMutableURLRequest *)copyRequestWithURL:(NSURL *)URL {
    // must preserve all aspects of old request incluing method and headers. so make a copy of the old one
    NSURLRequest *req = self.request;
    NSMutableURLRequest *newRequest = [[NSMutableURLRequest alloc] initWithURL:URL cachePolicy:[req cachePolicy] timeoutInterval:[req timeoutInterval]];
    
    [newRequest setAllHTTPHeaderFields:[req allHTTPHeaderFields]];
    
    if ([req HTTPMethod]) {
        [newRequest setHTTPMethod:[req HTTPMethod]];
    }
    
    if ([req HTTPBody]) {
        [newRequest setHTTPBody:[req HTTPBody]];
    }
    
    [newRequest setHTTPShouldHandleCookies:[req HTTPShouldHandleCookies]];

    return newRequest;
}

@end
