//
//  TDBackButton.m
//  TechBrowser
//
//  Created by Todd Ditchendorf on 11/22/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import "TDBackButton.h"

#define OFFSET_X 19.0

@implementation TDBackButton

+ (id)backButton {
    return [TDBackButton buttonWithType:UIButtonTypeCustom];
}


- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        UIImage *bgImg = [[UIImage imageNamed:@"button_UINavigationBarDefaultBack.png"] stretchableImageWithLeftCapWidth:15.0 topCapHeight:16.0];
        UIImage *hiBgImg = [[UIImage imageNamed:@"button_UINavigationBarDefaultBackPressed.png"] stretchableImageWithLeftCapWidth:15.0 topCapHeight:16.0];

        [self setBackgroundImage:bgImg forState:UIControlStateNormal];
        [self setBackgroundImage:hiBgImg forState:UIControlStateHighlighted];

        [[self titleLabel] setFont:[UIFont boldSystemFontOfSize:12.0]];
        [[self titleLabel] setShadowOffset:CGSizeMake(0.0, -1.0)];

        [self setTitleShadowColor:[UIColor colorWithWhite:0.0 alpha:0.4] forState:UIControlStateNormal];
        [self setTitle:NSLocalizedString(@"Back", @"") forState:UIControlStateNormal];

        [self sizeToFit];
        frame = self.frame;
        frame.size.width += OFFSET_X;
        self.frame = frame;
    }
    return self;
}


- (void)dealloc {
    
    [super dealloc];
}


- (CGRect)titleRectForContentRect:(CGRect)contentRect {
    CGRect r = [super titleRectForContentRect:contentRect];
    r.origin.x += 3.0;
    return r;
}

@end
