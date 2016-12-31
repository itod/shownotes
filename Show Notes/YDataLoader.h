//
//  YDataLoader.h
//  FantasyFootball
//
//  Created by Todd Ditchendorf on 8/10/09.
//  Copyright 2009 Yahoo! Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>

@class YDataLoader;

@protocol YDataLoaderDelegate <NSObject>
- (void)dataLoader:(YDataLoader *)l didSucceed:(NSData *)data;
- (void)dataLoader:(YDataLoader *)l didFail:(NSError *)err;
@end

@interface YDataLoader : NSObject {
    id <YDataLoaderDelegate>delegate;
    NSURLConnection *connection;
    NSMutableData *receivedData;
    NSURL *baseURL;
    NSString *errorMessage;
}

- (id)initWithDelegate:(id <YDataLoaderDelegate>)d;

// GET
- (void)loadDataForRequest:(NSURLRequest *)req; // creates request with Yahoo headers
- (void)loadDataForURL:(NSURL *)URL; // if u dont want yahoo headers, create your own req and use this

- (void)cancel;

@property (nonatomic, retain) NSURLConnection *connection;
@property (nonatomic, retain) NSMutableData *receivedData;
@property (nonatomic, retain) NSURL *baseURL;
@property (nonatomic, retain) NSString *errorMessage;
@end
