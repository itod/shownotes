//
//  TDHintView.m
//  TDAppKit
//
//  Created by Todd Ditchendorf on 11/11/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import "TDHintView.h"
#import "TDUtils.h"

#define HINT_MIN_WIDTH 100.0
#define HINT_MAX_WIDTH 400.0

#define HINT_HEIGHT 42.0
#define HINT_MARGIN_X 20.0
#define HINT_PADDING_X 22.0
#define HINT_PADDING_Y 4.0

#define HINT_VERT_FUDGE 0.0

static UIColor *sHintBgColor = nil;
static NSDictionary *sHintAttrs = nil;

@implementation TDHintView

+ (void)initialize {
    if ([TDHintView class] == self) {
        
        //[[UIColor colorWithDeviceWhite:.87 alpha:1] set];
        //[[UIColor colorWithDeviceRed:230.0/255.0 green:236.0/255.0 blue:242.0/255.0 alpha:1] set];
        
        sHintBgColor = [[UIColor colorWithWhite:0.0 alpha:0.5] retain];
        
        NSMutableParagraphStyle *paraStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
        [paraStyle setAlignment:NSTextAlignmentCenter];
        [paraStyle setLineBreakMode:NSLineBreakByWordWrapping];
        
        NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
        [shadow setShadowColor:[UIColor colorWithWhite:0 alpha:.2]];
        [shadow setShadowOffset:CGSizeMake(0.0, -1.0)];
        [shadow setShadowBlurRadius:1.0];
        
        sHintAttrs = [[NSDictionary alloc] initWithObjectsAndKeys:
                      [UIFont boldSystemFontOfSize:12.0], NSFontAttributeName,
                      [UIColor whiteColor], NSForegroundColorAttributeName,
                      shadow, NSShadowAttributeName,
                      paraStyle, NSParagraphStyleAttributeName,
                      nil];
    }
}


- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}


- (void)dealloc {
    self.hintText = nil;
    [super dealloc];
}


- (void)awakeFromNib {
    [super awakeFromNib];
    self.backgroundColor = [UIColor clearColor];
}


- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %p '%@'>", [self class], self, _hintText];
}


- (CGRect)hintTextRectForBounds:(CGRect)bounds {
    CGFloat w = bounds.size.width - HINT_MARGIN_X * 2 - HINT_PADDING_X * 2;
    w = w < HINT_MIN_WIDTH ? HINT_MIN_WIDTH : w;
    
    UIFont *font = sHintAttrs[NSFontAttributeName];
    CGFloat actualFontSize = 0.0;
    CGFloat minFontSize = 9.0;
    
    CGSize strSize = [_hintText sizeWithFont:font minFontSize:minFontSize actualFontSize:&actualFontSize forWidth:w lineBreakMode:NSLineBreakByWordWrapping];
    //CGRect strRect = [_hintText boundingRectWithSize:NSMakeSize(w, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:sHintAttrs];

    CGFloat h = strSize.height;
    CGFloat x = HINT_MARGIN_X + HINT_PADDING_X;
    CGFloat y = bounds.size.height / 2 - strSize.height / 2 + HINT_VERT_FUDGE;
    y += _hintTextOffsetY;

    CGRect r = CGRectMake(x, y, w, h);
    return r;
}


- (void)drawRect:(CGRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    CGRect bounds = [self bounds];
    
//    [self.backgroundColor setFill];
//    UIRectFill(bounds);
    
    BOOL showHint = ([_hintText length]);
    if (showHint) {
        CGRect hintTextRect = [self hintTextRectForBounds:bounds];
        
        CGRect hintRect = CGRectInset(hintTextRect, -HINT_PADDING_X, -HINT_PADDING_Y);
        
        CGFloat w = hintRect.size.width;
        w = w > HINT_MAX_WIDTH ? HINT_MAX_WIDTH : w;
        hintRect.size.width = floor(w);
        
        CGFloat x = bounds.size.width / 2 -  hintRect.size.width / 2;
        x = x < HINT_MARGIN_X ? HINT_MARGIN_X : x;
        hintRect.origin.x = floor(x);
        
        hintRect.origin.y = floor(hintRect.origin.y);
        hintRect.size.height = floor(hintRect.size.height);
        CGFloat radius = hintRect.size.height / 2 - 2;
        
        [sHintBgColor setFill];
        
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        TDAddRoundRect(ctx, hintRect, radius);
        CGContextFillPath(ctx);
        
        [[UIColor whiteColor] set];
        
        NSAttributedString *attrStr = [[[NSAttributedString alloc] initWithString:_hintText attributes:sHintAttrs] autorelease];
        [attrStr drawInRect:hintTextRect];
        //[_hintText drawInRect:hintTextRect withAttributes:sHintAttrs];
    }
}

@end
