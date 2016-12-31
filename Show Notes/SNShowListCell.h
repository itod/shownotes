//
//  SNShowListCell.h
//  Show Notes
//
//  Created by Todd Ditchendorf on 10/23/12.
//  Copyright (c) 2012 Todd Ditchendorf. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SNShowListCell : UITableViewCell

+ (NSString *)identifier;
+ (NSString *)nibName;
+ (CGFloat)defaultHeight;

@property (nonatomic, strong) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) IBOutlet UILabel *textLabel;
@end
