//
//  TDUtils.m
//  Show Notes
//
//  Created by Todd Ditchendorf on 11/4/12.
//  Copyright (c) 2012 Todd Ditchendorf. All rights reserved.
//

#import "TDUtils.h"

void TDPerformOnMainThread(void (^block)(void)) {
    //assert(block);
    dispatch_sync(dispatch_get_main_queue(), block);
}


void TDPerformOnBackgroundThread(void (^block)(void)) {
    //assert(block);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block);
}


void TDPerformOnMainThreadAfterDelay(double delay, void (^block)(void)) {
    //assert(block);
    //assert(delay >= 0.0);
    
    double delayInSeconds = delay;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), block);
}


void TDPerformOnBackgroundThreadAfterDelay(double delay, void (^block)(void)) {
    //assert(block);
    //assert(delay >= 0.0);
    
    double delayInSeconds = delay;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block);
}


void TDAddRoundRect(CGContextRef ctx, CGRect rect, CGFloat radius) {
    CGFloat minx = CGRectGetMinX(rect);
    CGFloat midx = CGRectGetMidX(rect);
    CGFloat maxx = CGRectGetMaxX(rect);
    CGFloat miny = CGRectGetMinY(rect);
    CGFloat midy = CGRectGetMidY(rect);
    CGFloat maxy = CGRectGetMaxY(rect);
    
    CGContextBeginPath(ctx);
    CGContextMoveToPoint(ctx, minx, midy);
    CGContextAddArcToPoint(ctx, minx, miny, midx, miny, radius);
    CGContextAddArcToPoint(ctx, maxx, miny, maxx, midy, radius);
    CGContextAddArcToPoint(ctx, maxx, maxy, midx, maxy, radius);
    CGContextAddArcToPoint(ctx, minx, maxy, minx, midy, radius);
    CGContextClosePath(ctx);
}


