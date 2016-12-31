//
//  TDUtils.h
//  Show Notes
//
//  Created by Todd Ditchendorf on 11/4/12.
//  Copyright (c) 2012 Todd Ditchendorf. All rights reserved.
//

#import <Foundation/Foundation.h>

#define TDIsPhone() ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
#define TDIsPad() ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)

#define TDAssertMainThread() NSAssert1([NSThread isMainThread], @"%s should be called on the main thread only.", __PRETTY_FUNCTION__);

void TDPerformOnMainThread(void (^block)(void));
void TDPerformOnBackgroundThread(void (^block)(void));
void TDPerformOnMainThreadAfterDelay(double delay, void (^block)(void));
void TDPerformOnBackgroundThreadAfterDelay(double delay, void (^block)(void));

void TDAddRoundRect(CGContextRef ctx, CGRect rect, CGFloat radius);
