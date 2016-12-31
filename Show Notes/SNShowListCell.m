//
//  SNShowListCell.m
//  Show Notes
//
//  Created by Todd Ditchendorf on 10/23/12.
//  Copyright (c) 2012 Todd Ditchendorf. All rights reserved.
//

#import "SNShowListCell.h"

@implementation SNShowListCell

+ (NSString *)identifier {
    return  NSStringFromClass(self);
}


+ (NSString *)nibName {
    return  NSStringFromClass(self);
}


+ (CGFloat)defaultHeight {
    return 44.0;
}


//- (id)init {
//    self = [self initWithStyle:UITableViewCellStyleDefault reuseIdentifier:[[self class] identifier]];
//    return self;
//}
//
//
//- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
//    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
//    if (self) {
//
//    }
//    return self;
//}
//
//
//- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
//    [super setSelected:selected animated:animated];
//
//    // Configure the view for the selected state
//}

@end
