//
//  NSDate+SNAdditions.m
//  Show Notes
//
//  Created by Todd Ditchendorf on 10/22/12.
//  Copyright (c) 2012 Todd Ditchendorf. All rights reserved.
//

#import "NSDate+SNAdditions.h"

@implementation NSDate (SNAdditions)

+ (NSDate *)pubDateFromString:(NSString *)str {    
    static NSDateFormatter *fmt = nil;
    if (!fmt) {
        fmt = [[NSDateFormatter alloc] init];
        [fmt setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss ZZ"];
    }
    
    NSDate *pubDate = [fmt dateFromString:str];
    return pubDate;
}

@end
