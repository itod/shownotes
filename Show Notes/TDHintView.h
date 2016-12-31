//
//  TDHintView.h
//  TDAppKit
//
//  Created by Todd Ditchendorf on 11/11/10.
//  Copyright 2010 Todd Ditchendorf. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TDHintView : UIView

- (CGRect)hintTextRectForBounds:(CGRect)bounds;

@property (nonatomic, copy) NSString *hintText;
@property (nonatomic, assign) CGFloat hintTextOffsetY;
@end
