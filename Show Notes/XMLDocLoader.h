//
//  FBRemoteXMLLoader.h
//  FantasyFootball
//
//  Created by Todd Ditchendorf on 6/3/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libxml/tree.h>

@class XMLDocLoader;

@protocol XMLDocLoaderDelegate <NSObject>
- (void)docLoader:(XMLDocLoader *)l didSucceed:(xmlDocPtr)doc; // **NOTE** doc MUST be FREED by the delegate!!!
- (void)docLoader:(XMLDocLoader *)l didFail:(NSError *)err;

// this is for development purposes. allows you to 'fake' a remove XML document by providing your own XML String
@optional
- (NSString *)fakeXMLStringForURLString:(NSString *)URLString;
@end

@interface XMLDocLoader : NSObject 

- (id)initWithDelegate:(id <XMLDocLoaderDelegate>)d;

// GET
- (void)loadDocumentForURL:(NSURL *)URL;
- (void)loadDocumentForRequest:(NSMutableURLRequest *)request;
- (void)loadDocumentForFile:(NSString *)path;

// POST
- (void)putBody:(NSString *)s forURL:(NSURL *)URL;
- (void)postBody:(NSString *)s forURL:(NSURL *)URL;

- (void)cancel;

@property (nonatomic, assign) id <XMLDocLoaderDelegate>delegate;
@property (nonatomic, retain) NSURLConnection *connection;
@property (nonatomic, retain) NSMutableURLRequest *request;
@property (nonatomic, retain) NSMutableData *receivedData;
@property (nonatomic, retain) NSURL *baseURL;
@property (nonatomic, retain) NSString *textEncodingName;
@property (nonatomic, retain) NSString *errorMessage;
@property (nonatomic) NSStringEncoding defaultStringEncoding;
@property (nonatomic) NSInteger errorCount;
@property (nonatomic) NSInteger retryCount;
@end
