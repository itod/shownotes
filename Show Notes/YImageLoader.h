//
//  YImageLoader.h
//  FantasyFootball
//
//  Created by Todd Ditchendorf on 8/4/09.
//  Copyright 2009 Yahoo! Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>

@class YImageLoader;

@protocol YImageLoaderDelegate <NSObject>
- (void)imageLoader:(YImageLoader *)l didSucceed:(UIImage *)img;
- (void)imageLoader:(YImageLoader *)l didFail:(NSError *)err;
@end

@interface YImageLoader : NSObject {
    id <YImageLoaderDelegate>delegate;
    NSURLConnection *connection;
    NSMutableData *receivedData;
    NSURL *baseURL;
    NSString *errorMessage;
}

- (id)initWithDelegate:(id <YImageLoaderDelegate>)d;

// GET
- (void)loadImageForRequest:(NSURLRequest *)req;
- (void)loadImageForURL:(NSURL *)URL;

- (void)cancel;

@property (nonatomic, retain) NSURLConnection *connection;
@property (nonatomic, retain) NSMutableData *receivedData;
@property (nonatomic, retain) NSURL *baseURL;
@property (nonatomic, retain) NSString *errorMessage;
@end
