//
//  DiscoveringCell.h
//  bOMDIC Alpha
//
//  Created by Scott on 2014/7/23.
//  Copyright (c) 2014年 bOMDIC Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DiscoveringCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *discoveringActivity;
@property (strong, nonatomic) IBOutlet UILabel *discoveringLabel;

@end
