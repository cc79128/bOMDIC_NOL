//
//  DiscoveringCell.m
//  bOMDIC Alpha
//
//  Created by Scott on 2014/7/23.
//  Copyright (c) 2014年 bOMDIC Inc. All rights reserved.
//

#import "DiscoveringCell.h"

@implementation DiscoveringCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        NSArray *arrayOfViews = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:self options:nil];
        self = [arrayOfViews objectAtIndex:0];
    }
    
    _discoveringLabel.textColor = [UIColor grayColor];
    
    return self;
}
/*
- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
*/
@end
